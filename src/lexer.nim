import strutils, tables, macros
import types

const keywords = {
    "when": When,
    "then": Then,
    "loop": Loop,
    "with": With,
    "quit": Quit,
    "skip": Skip,
    "exit": Exit,
    "right": Right,
    "wrong": Wrong,
}.toTable


proc lexer*(input: string): Tokens =
    var tokens: Tokens = @[]
    var index = 0
    let size = input.len()
    var line = 1
    var currentIndentLevel: int = 0
    
    proc addToken(lexeme: string, tokenKind: TokenKind) =
        tokens.add(
            Token(
                kind: tokenKind,
                lexeme: lexeme,
                line: line
            )
        )

    proc isAtEnd(): bool =
        index >= size

    proc isNextCharacter(character: char): bool =
        not isAtEnd() and input[index + 1] == character

    proc isDigit(c: char): bool =
        c in {'0' .. '9'}

    proc isAlphabet(c: char): bool =
        c in {'A'..'Z', '-', 'a'..'z'}

    proc isAlphaNumeric(c: char): bool =
        isAlphabet(c) or isDigit(c)

    proc string() =
        var accumulate = ""
        index.inc()
        while (not isAtEnd()) and (input[index] != '"'):
            accumulate = accumulate & $input[index]
            if input[index] == '\n':
                line.inc()
            index.inc()
        addToken(accumulate, String)

    proc identifier() =
        var accumulate = ""
        while (not isAtEnd()) and (isAlphaNumeric(input[index])):
            accumulate = accumulate & $input[index]
            index.inc()
        index.dec()
        
        # Check if the identifier is a keyword
        if keywords.hasKey(accumulate):
            addToken(accumulate, keywords[accumulate])  # Emit the keyword token
        elif accumulate.toLower() == accumulate:
            addToken(accumulate, VariableIdentifier)  # Emit an Identifier token
        else:
            addToken(accumulate, FunctionIdentifier)  # Emit an Identifier token
            

    proc number() =
        var accumulate = ""
        while (not isAtEnd()) and (isDigit(input[index])):
            accumulate = accumulate & $input[index]
            index.inc()
        index.dec()
        addToken(accumulate, Number)

    proc handleIndentation() =
        var spacesCount: int = 0
        index.inc()
        # Count the number of spaces at the beginning of the line
        while (not isAtEnd()) and input[index] == ' ':
            spacesCount.inc()
            index.inc()
        index.dec()
        # Calculate the indentation level (assuming 4 spaces per level)
        var indentLevel = spacesCount div 4       
        
        # Handle indentation changes
        if indentLevel > currentIndentLevel:
            # Increase indentation level
            if isAtEnd() or input[index] == '\n':
                return 
            if indentLevel != currentIndentLevel + 1:
                echo "[line: ", $line, "] Invalid indentation: expected ", currentIndentLevel + 1, " levels, got ", indentLevel
                quit(1)
            addToken("", Indent)
            currentIndentLevel = indentLevel
        elif indentLevel < currentIndentLevel:
            # Decrease indentation level
            while currentIndentLevel > indentLevel:
                addToken("", Dedent)
                currentIndentLevel.dec()
        # Else: indentation level remains the same
    
    
    
    while not isAtEnd():
        var character = input[index]
        
        case character
        of '(':
            addToken($character, LeftRoundBracket)
        of ')':
            addToken($character, RightRoundBracket)
        of '{':
            addToken($character, LeftCurlyBracket)
        of '}':
            addToken($character, RightCurlyBracket)
        of '[':
            addToken($character, LeftSquareBracket)
        of ']':
            addToken($character, RightSquareBracket)
        of ',':
            addToken($character, Comma)
        of '.':
            addToken($character, Dot)
        of ':':
            addToken($character, Colon)
        of '-':
            addToken($character, Minus)
        of '+':
            addToken($character, Plus)
        of '*':
            addToken($character, Star)
        of '/':
            addToken($character, Slash)
        of '$':
            addToken($character, Dollar)
        of '@':
            while (not isAtEnd()) and (input[index] != '\n'):
                index.inc()
            line.inc()
        of '_':
            if isNextCharacter('<'):
                index.inc()
                addToken("_<", ExclusiveRange)
            else:
                addToken($character, Range)
        of '?':
            addToken($character, QuestionMark)
        of '&':
            addToken($character, And)
        of '=':
            addToken($character, Equal)
        of '>':
            addToken($character, MoreThan)
        of '<':
            addToken($character, LessThan)
        of '\n':
            line.inc()
            addToken($character, NewLine)
            handleIndentation()
        of ' ', '\\':
            discard
        of '!':
            if isNextCharacter('='):
                index.inc()
                addToken("!=", NotEqual)
            elif isNextCharacter('>'):
                index.inc()
                addToken("!>", NotMoreThan)
            elif isNextCharacter('<'): 
                index.inc()
                addToken("!<", NotLessThan)
            else: 
                addToken($character, ExclamationMark)
        of '"':
            string()
        else:
            if isDigit(character):
                number()
            elif isAlphabet(character):
                identifier()
            else:
                echo "[Line ", $line, "] Unexpected character: `", $character, "`"
                quit(1)

        index.inc()        

    while currentIndentLevel != 0:
        addToken("", Dedent)
        currentIndentLevel.dec()
    
    addToken("", EOF)
    return tokens
    


#[


parser tokens:
    @ program
    @     declaration* EOF
    
    statements: []
    index: 0

    is-at-end:
        exit tokens.index.kind = "EOF"
    
    iscurrenttokenkind token-type:
        exit tokens.index.kind = token-type
    
    isnexttokenkind token-type:
        exit tokens.(index - 1).kind = token-type
    
    isprevioustokenkind token-type:
        exit tokens.(index + 1).kind = token-type
    
    Statement:
        @ expression-statement |
        @ loop-statement       |
        @ when-statement       |
        @ exit-statement       |
        @ block
        
        when IsCurrentTokenType "loop"
            exit LoopStatement
        then IsCurrentTokenType "when"
            exit WhenStatement
        then IsCurrentTokenType "exit"
            exit ReturnStatement
        then IsCurrentTokenType "indent"
            exit Block
        then
            exit ExpressionStatement
    
    Declaration:
        @ function-declaration | 
        @ variable-declaration |
        @ statement
        
        when IsCurrentTokenKind "colon" 
            when IsPreviousTokenKind "function-identifier"
                exit FunctionDeclaration
            then IsPreviousTokenKind "variable-identifier"
                exit VariableDeclaration
        then
            exit Statement
        
    loop !IsAtEnd
        Insert statements, Declaration
        index = index + 1

    exit statements

]#

