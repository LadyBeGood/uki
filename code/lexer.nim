import macros
import types, tables

macro shout*(args: varargs[untyped]): untyped =
    result = newStmtList()
    for arg in args:
        result.add(quote do:
            echo `arg`.astToStr, " = ", `arg`
        )

const keywords = {
    "try": TryKeyword,
    "fix": FixKeyword,
    "when": WhenKeyword,
    "then": ThenKeyword,
    "loop": LoopKeyword,
    "with": WithKeyword,
    "pick": PickKeyword,
    "case": CaseKeyword,
    "right": RightKeyword,
    "wrong": WrongKeyword,
    "import": ImportKeyword,
    "export": ExportKeyword,
}.toTable

proc lexer*(input: string): Tokens =
    var index: int
    var tokens: Tokens
    var line: int = 1
    var indentStack = @[0]

    proc addToken(lexeme: string = "", tokenKind: TokenKind) =
        add tokens, Token(tokenKind: tokenKind, lexeme: lexeme, line: line)
    
    proc isAtEnd(): bool =
        return index == input.len
    
    proc currentCharacter(): char =
        return input[index]
    
    proc isCurrentCharacter(expected: char): bool =
        return 
            if not isAtEnd() and input[index] == expected:
                true
            else:
                false
    
    
    proc isNextCharacter(expected: char): bool =
        return
            if (index + 1 < input.len) and input[index + 1] == expected:
                true
            else:
                false
    

    proc isDigit(character: char): bool =
        return character in {'0' .. '9'}

    proc isAlphabet(character: char): bool =
        return character in {'A'..'Z', '-', 'a'..'z'}

    proc isAlphaNumeric(character: char): bool =
        isAlphabet(character) or isDigit(character)
    
    
    proc string() =
        var accumulate = ""
        index.inc()
        while not isCurrentCharacter('"'):
            if index >= input.len:
                addToken("Unterminated string literal", TokenKind.Illegal)
                return
            accumulate &= $currentCharacter()
            if currentCharacter() == '\n':
                line.inc()
            index.inc()
        index.inc()
        addToken(accumulate, TokenKind.UninterpolatedStringLiteral)

    proc identifier() =
        var accumulate = ""
        while not isAtEnd() and isAlphaNumeric(currentCharacter()):
            accumulate &= $currentCharacter()
            index.inc()
        
        # Check if the identifier is a keyword
        if keywords.hasKey(accumulate):
            addToken(accumulate, keywords[accumulate])  
        else:
            addToken(accumulate, Identifier) 
            

    proc number() =
        var accumulate = ""
        while not isAtEnd() and isDigit(currentCharacter()):
            accumulate &= currentCharacter()
            index.inc()

        addToken(accumulate, NumericLiteral)
    
    
    proc handleIndentation() =
        var spaceCount = 0
    
        while not isAtEnd() and currentCharacter() == ' ':
            spaceCount.inc()
            index.inc()
    
        if isAtEnd() or currentCharacter() == '\n':
            # Empty or whitespace-only line, ignore indentation
            return
    
        if spaceCount mod 4 != 0:
            echo "[Line ", $line, "] Indentation error: indentation must be a multiple of 4 spaces"
            quit(1)
    
        let indentLevel = spaceCount div 4
        let currentIndentLevel = indentStack[^1]
    
        if indentLevel > currentIndentLevel:
            if indentLevel != currentIndentLevel + 1:
                echo "[Line ", $line, "] Indentation error: unexpected indent"
                quit(1)
            indentStack.add(indentLevel)
            addToken("++++", TokenKind.Indent)
        elif indentLevel < currentIndentLevel:
            while indentStack.len > 0 and indentStack[^1] > indentLevel:
                indentStack.setLen(indentStack.len - 1)
                addToken("----", TokenKind.Dedent)
        
    while not isAtEnd():
        let character = input[index]
        
        case character
        of '(':
            addToken($character, TokenKind.LeftRoundBracket)
            index.inc()
        of ')':
            addToken($character, TokenKind.RightRoundBracket)
            index.inc()
        of '{':
            addToken($character, TokenKind.LeftCurlyBracket)
            index.inc()
        of '}':
            addToken($character, TokenKind.RightCurlyBracket)
            index.inc()
        of '[':
            addToken($character, TokenKind.LeftSquareBracket)
            index.inc()
        of ']':
            addToken($character, TokenKind.RightSquareBracket)
            index.inc()
        of ',':
            addToken($character, TokenKind.Comma)
            index.inc()
        of '.':
            addToken($character, TokenKind.Dot)
            index.inc()
        of ':':
            addToken($character, TokenKind.Colon)
            index.inc()
        of '-':
            addToken($character, TokenKind.Minus)
            index.inc()
        of '+':
            addToken($character, TokenKind.Plus)
            index.inc()
        of '*':
            addToken($character, TokenKind.Asterisk)
            index.inc()
        of '/':
            addToken($character, TokenKind.Slash)
            index.inc()
        of '$':
            addToken($character, TokenKind.Dollar)
            index.inc()
        of '?':
            addToken($character, TokenKind.Question)
            index.inc()
        of '&':
            addToken($character, TokenKind.Ampersand)
            index.inc()
        of '=':
            addToken($character, TokenKind.Equal)
            index.inc()
        of '>':
            addToken($character, TokenKind.MoreThan)
            index.inc()
        of '<':
            addToken($character, TokenKind.LessThan)
            index.inc()
        of '|':
            addToken($character, TokenKind.Bar)
            index.inc()
        of '#':
            while not isAtEnd() and not isCurrentCharacter('\n'):
                index.inc()
        of '_':
            if isNextCharacter('<'):
                index.inc(2)
                addToken("_<", TokenKind.UnderscoreLessThan)
            else:
                addToken($character, TokenKind.Underscore)
                index.inc()
        of '\n':
            line.inc()
            #addToken("\n", TokenKind.NewLine)
            index.inc()
            handleIndentation()
        of ' ', '\\':
            index.inc()
        of '!':
            if isNextCharacter('='):
                addToken("!=", ExclamationEqual)
                index.inc(2)
            elif isNextCharacter('>'):
                addToken("!>", ExclamationMoreThan)
                index.inc(2)
            elif isNextCharacter('<'): 
                addToken("!<", ExclamationLessThan)
                index.inc(2)
            else: 
                addToken($character, Exclamation)
                index.inc()
        of '"':
            string()
        else:
            if isDigit(character):
                number()
            elif isAlphabet(character):
                identifier()
            else:
                addToken("[Line " & $line & "] Unexpected character: `" & $character & "`", TokenKind.Illegal)
                break


    addToken("", TokenKind.EndOfFile)
    
    return tokens



when isMainModule:
    import os, json
    
    let input: string = """
is-prime number:
    exit right
"""

    let tokens = lexer(input)
    let formatted = pretty(%tokens, indent = 4)
    shout formatted






