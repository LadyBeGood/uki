import os, strutils, json, options, tables, macros

type 
    Object* = ref object of RootObj

    BooleanObject* = ref object of Object
        data*: bool
    
    NumberObject* = ref object of Object
        data*: float
    
    StringObject* = ref object of Object
        data*: string
    
    TokenKind* = enum
        LeftRoundBracket,    # (
        RightRoundBracket,   # )
        LeftCurlyBracket,    # {
        RightCurlyBracket,   # }
        LeftSquareBracket,   # [
        RightSquareBracket,  # ]
        Comma,          # ,
        Dot,            # .
        Colon,          # :
        Minus,          # -
        Plus,           # +        
        Star,           # *
        Slash,          # /
        Dollar,         # $
        At,             # @
        Range,          # _
        ExclusiveRange, # _
        QuestionMark,   # ?
        And,            # &
        # One or two character tokens.
        ExclamationMark, # !
        Equal,           # =
        MoreThan,        # >
        LessThan,        # <
        NotEqual,        # !=
        NotMoreThan,     # !>
        NotLessThan,     # !<
        # Literals.
        VariableIdentifier,   # [A-Z_a-z][0-9A-Z_a-z]*
        FunctionIdentifier,   # [A-Z_a-z][0-9A-Z_a-z]*
        String,       # "string" | ""
        Number,       # 123 | 123.0
        # Keywords.
        When,
        Then,
        Loop,
        With,
        Quit,
        Skip,
        Exit,
        Right,
        Wrong,
        # Whitespace
        Newline, # \n 
        Indent, 
        Dedent,
        EOF           # End-of-file

    Token* = object
        kind*: TokenKind
        lexeme*: string
        line*: int
    
    Tokens* = seq[Token]
  
    
    FunctionParameter* = ref object of ExpressionStatement
        name*: string
        default*: Expression

    FunctionArgument* = ref object of ExpressionStatement
        value*: Expression  
    
    FunctionParameters* = seq[FunctionParameter]
    FunctionArguments* = seq[FunctionArgument]
   
    # Expressions
    Expression* = ref object of RootObj
    Expressions* = seq[Expression]

    BinaryExpression* = ref object of Expression
        left*: Expression
        operator*: Token
        right*: Expression

    FunctionExpression* = ref object of Expression
        functionIdentifier*: string
        arguments*: FunctionArguments
    
    VariableExpression* = ref object of Expression
        variableIdentifier*: string
    
    GroupingExpression* = ref object of Expression
        Expression*: Expression

    LiteralExpression* = ref object of Expression
        value*: Object

    UnaryExpression* = ref object of Expression
        operator*: Token
        right*: Expression
    

    # Statement
    Statement* = ref object of RootObj
    Statements* = seq[Statement]
    
    
    
    VariableDeclarationStatement* = ref object of Statement
        variableIdentifier*: string
        value*: Expression
    
    VariableReassignmentStatement* = ref object of Statement
        variableIdentifier*: string
        value*: Expression
    
    FunctionDeclarationStatement* = ref object of Statement
        functionIdentifier*: string
        parameters*: FunctionParameters
        body*: Statement
    
    FunctionReassignmentStatement* = ref object of Statement
        functionIdentifier*: string
        body*: Statement
    
    ExpressionStatement* = ref object of Statement
        expression*: Expression
    
    LoopStatement* = ref object of Statement
        condition*: Expressions
        placeholder*: Statement
    
    WhenStatement* = ref object of Statement
        condition*: Expression
        placeholder*: Statement
        otherwise*: Statement
    
    ControlStatement* = ref object of Statement
        kind*: TokenKind
        value*: Expression
    
    EmptyControlStatement* = ref object of Statement
        kind*: TokenKind
    
    BlockStatement* = ref object of Statement
        statements*: Statements
    
    
    


proc uki() =
  

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
    






    
    proc compiler*(input: string): string =
        let tokens: Tokens = lexer(input)
        let ast: Statements = parser(tokens)
        var str:  string = ""
        for statement in ast:
            str &= printAst(statement)
        return tokens.join("\n") & "\n\n\n" & str
    

    if paramCount() < 1:
        echo "Usage: uki input.uki"
        quit(1)

    let inputFile = paramStr(1)
    let outputFile = "e.uki"

    # Read the input file
    let inputText = readFile(inputFile)
    if inputText.strip(chars = {' ', '\t', '\n'}, leading = true, trailing = false)  == "":
        echo "Empty file"
        quit(1)

    # Process the input through the lexer
    let outputText = compiler(inputText)

    # Write the output to the output file
    writeFile(outputFile, outputText)


uki()
