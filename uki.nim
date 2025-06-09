import tables, strutils, terminal, sets, sequtils, os

type
    TokenKind* {.pure.} = enum
        EndOfFile
    
        # Literals  
        NumericLiteral  
        StringLiteral  
    
        # Identifier  
        Identifier  
      
        # Punctuation  
        LeftRoundBracket   
        RightRoundBracket   
        LeftCurlyBracket   
        RightCurlyBracket 
        LeftSquareBracket   
        RightSquareBracket 
        Dot  
        Comma  
        Exclamation  
        Ampersand  
        Question  
        Colon  
        Equal  
        LessThan  
        MoreThan  
        ExclamationEqual  
        ExclamationLessThan  
        ExclamationMoreThan  
        Plus  
        Minus  
        Asterisk  
        Slash  
        Bar  
        Tilde  
        Hash  
        Underscore  
        UnderscoreLessThan  
        NewLine  
        Dollar  
      
        # Reserved words  
        When  
        Else  
        Try  
        Fix  
        Loop  
        With  
        Import  
        Export  
        Right  
        Wrong
        Exit
        Stop
        Next
      
        # Spacing  
        Indent  
        Dedent  


    Token* = ref object  
        tokenKind*: TokenKind
        lexeme*: string  
        line*: int 
    
    
    # For type checking at analyser phase 
    # And determining the proper `loop statement`, `loop expression`, `when statement` and `when expression` construct at transformer phase
    DataType* {.pure.} = enum
        String 
        Boolean 
        Number
        Procedure
        Structure

    
    
    # Expressions
    Expression* = ref object of RootObj

    ContainerExpression* = ref object of Expression
        identifier*: Token
        arguments*: seq[Expression]

    LiteralExpression* = ref object of Expression
        value*: Literal

    UnaryExpression* = ref object of Expression
        operator*: Token
        right*: Expression
    
    BinaryExpression* = ref object of Expression
        left*: Expression
        operator*: Token
        right*: Expression

    RangeExpression* = ref object of Expression
        start*: Expression
        firstOperator*: Token
        stop*: Expression
        secondOperator*: Token
        step*: Expression
    
    GroupingExpression* = ref object of Expression
        expression*: Expression

    BlockExpression* = ref object of Expression
        statements*: seq[Statement]

    WhenExpression* = ref object of Expression
        dataTypes*: HashSet[DataType]
        whenSubExpressions*: seq[WhenSubExpression]
        
    WhenSubExpression* = ref object
        keyword*: Token
        condition*: Expression
        expression*: Expression

    LoopExpression* = ref object of Expression
        loopKeyword*: Token
        withExpressions*: seq[WithExpression]
        expression*: Expression
    
    WithExpression* = ref object
        withKeyword*: Token
        iterable*: Expression
        iterableDataType*: HashSet[DataType]
        counters*: seq[Token]
    
    TryExpression* = ref object of Expression
        dataTypes*: HashSet[DataType]
        tryKeyword*: Token
        tryExpression*: Expression
        fixExpressions*: seq[FixExpression]
    
    FixExpression* = ref object
        fixKeyword*: Token
        identifier*: Token
        fixExpression*: Expression


    # Literals
    Literal* = ref object of RootObj
    
    NumericLiteral* = ref object of Literal
        value*: float

    StringLiteral* = ref object of Literal
        value*: string
    
    BooleanLiteral* = ref object of Literal
        value*: bool
    

    # Statements
    Statement* = ref object of RootObj
    
    ExpressionStatement* = ref object of Statement
        expression*: Expression

    ContainerStatement* = ref object of Statement
        identifier*: Token
        parameters*: seq[Token]
        expression*: Expression

    WhenStatement* = ref object of Statement
        whenSubStatements*: seq[WhenSubStatement]
        
    WhenSubStatement* = ref object
        keyword*: Token
        condition*: Expression
        `block`*: BlockExpression

    LoopStatement* = ref object of Statement
        loopKeyword*: Token
        withStatements*: seq[WithStatement]
        `block`*: BlockExpression

    WithStatement* = ref object 
        withKeyword*: Token
        iterable*: Expression
        iterableDataType*: HashSet[DataType]
        counters*: seq[Token]

    TryStatement* = ref object of Statement
        tryKeyword*: Token
        tryBlock*: BlockExpression
        fixStatements*: seq[FixStatement]
    
    FixStatement* = ref object
        fixKeyword*: Token
        identifier*: Token
        fixBlock*: BlockExpression
    
    ExitStatement* = ref object of Statement
        keyword*: Token
        expression*: Expression
    
    NextStatement* = ref object of Statement
        keyword*: Token
        counter*: Token
    
    StopStatement* = ref object of Statement
        keyword*: Token
        counter*: Token

    Context* {.pure.} = enum
        Function
        Loop
        Try



proc error*(line: int, message: string) =
    styledEcho fgRed, "Error", resetStyle, " [Line " & $line & "]: " & message
    quit(1)

proc tokenToString(token: Token, indentLevel: int = 0): string =
    let indent = "    ".repeat(indentLevel)
    if token == nil:
        return "nil\n"
    
    result.add "Token {\n" 
    result.add indent & "    kind: " & $token.tokenKind & "\n"
    result.add indent & "    lexeme: \"" & (if token.lexeme == "\n": "\\n" else: token.lexeme) & "\"\n"  
    result.add indent & "    line: " & $token.line & "\n"
    result.add indent & "}\n"

proc tokensToString*(tokens: seq[Token]): string =
    result.add "Token [\n"
    for token in tokens:
        result.add "    " & tokenToString(token, 1)
    result.add "]"


proc astToString(statements: seq[Statement]): string =

    proc statementToString(statement: Statement, indentLevel: int = 0): string 

    proc expressionToString(expression: Expression, indentLevel: int = 0): string =
        let indent = "    ".repeat(indentLevel)
        
        if expression == nil:
            result.add "nil\n"
        
        elif expression of ContainerExpression:
            let expression = ContainerExpression(expression)
            result.add "ContainerExpression {\n"
            result.add indent & "    identifier: "
            result.add tokenToString(expression.identifier, indentLevel + 1)
            if expression.arguments.len() != 0:
                result.add indent & "    arguments: Expression [\n"
                for argument in expression.arguments:
                    result.add indent & "        " & expressionToString(argument, indentLevel + 2)
                result.add indent & "    ]\n"
            else:
                result.add indent & "    arguments: Expression []\n"
            result.add indent & "}\n"
            
        elif expression of WhenExpression:
            let expression = WhenExpression(expression)
            result.add "WhenExpression {\n"
            result.add indent & "    dataTypes: " & $expression.dataTypes & "\n"
            result.add indent & "    whenSubExpressions: WhenSubExpression [\n"
            for subExpression in expression.whenSubExpressions:                
                result.add indent & "        WhenSubExpression {\n"
                result.add indent & "            keyword: " & tokenToString(subExpression.keyword, indentLevel + 3)
                result.add indent & "            condition: " &  expressionToString(subExpression.condition, indentLevel + 3)
                result.add indent & "            expression: " & expressionToString(subExpression.expression, indentLevel + 3)
                result.add indent & "        }\n"
            result.add indent & "    ]\n"
            result.add indent & "}\n"
            
        elif expression of LoopExpression:
            let expression = LoopExpression(expression)
            result.add "LoopExpression {\n"
            result.add indent & "    loopKeyword: " & tokenToString(expression.loopKeyword, indentLevel + 1)
            result.add indent & "    withExpressions: WithExpression [\n"
            for withExpression in expression.withExpressions:
                result.add indent & "        WithExpression {\n"
                result.add indent & "            withKeyword: " & tokenToString(withExpression.withKeyword, indentLevel + 3)
                result.add indent & "            iterable: " & expressionToString(withExpression.iterable, indentLevel + 3)
                result.add indent & "            iterableDataType: " & $withExpression.iterableDataType & "\n"
                if withExpression.counters.len() == 0:
                    result.add indent & "            counters: Identifier []\n"
                else:
                    result.add indent & "            counters: Identifier [\n"
                    for counter in withExpression.counters:
                        result.add indent & "                Identifier {\n"
                        result.add indent & "                    " & tokenToString(counter, indentLevel + 5)
                        result.add indent & "                }\n"
                    result.add indent & "            ]\n"
                result.add indent & "        }\n"
            result.add indent & "    ]\n"
            result.add indent & "    expression: " & expressionToString(expression.expression, indentLevel + 1)
            result.add indent & "}\n"
            
        elif expression of TryExpression:
            let expression = TryExpression(expression)
            result.add "TryExpression {\n"
            result.add indent & "    dataTypes: " & $expression.dataTypes & "\n"
            result.add indent & "    tryKeyword: " & tokenToString(expression.tryKeyword, indentLevel + 1)
            result.add indent & "    tryExpression: " & expressionToString(expression.tryExpression, indentLevel + 1)
            result.add indent & "    fixExpressions: FixExpression [\n"
            for fixExpression in expression.fixExpressions:
                result.add indent & "        FixExpression {\n"
                result.add indent & "            fixKeyword: " & tokenToString(fixExpression.fixKeyword, indentLevel + 3)
                result.add indent & "            identifier: " & tokenToString(fixExpression.identifier, indentLevel + 3)
                result.add indent & "            fixExpression: " & expressionToString(fixExpression.fixExpression, indentLevel + 3)
                result.add indent & "        }\n"
            result.add indent & "    ]\n"
            result.add indent & "}\n"
        
        elif expression of BlockExpression:
            let expression = BlockExpression(expression)
            result.add "BlockExpression {\n"
            result.add indent & "    statements: Statement [\n"
            for statement in expression.statements:
                result.add statementToString(statement, indentLevel + 2)
            result.add indent & "    ]\n"
            result.add indent & "}\n"
        
        elif expression of LiteralExpression:
            let expression = LiteralExpression(expression)
            result.add "LiteralExpression {\n"
            result.add indent & "    value: "
            if expression.value of BooleanLiteral:
                let val = BooleanLiteral(expression.value)
                result.add "BooleanLiteral {\n" 
                result.add indent & "        value: " & $val.value & "\n"
            elif expression.value of StringLiteral:
                let val = StringLiteral(expression.value)
                result.add "StringLiteral {\n" 
                result.add indent & "        value: " & "\"" & $val.value & "\"" & "\n"
            elif expression.value of NumericLiteral:
                let val = NumericLiteral(expression.value)
                result.add "NumericLiteral {\n" 
                result.add indent & "        value: " & $val.value & "\n"
            else:
                result.add "Unknown literal type\n"
            result.add indent & "    }\n"
            result.add indent & "}\n"
        
        elif expression of GroupingExpression:
            let expression = GroupingExpression(expression)
            result.add "GroupingExpression {\n"
            result.add indent & "    expression: " & expressionToString(expression.expression, indentLevel + 1)
            result.add indent & "}\n"
        
        elif expression of UnaryExpression:
            let expression = UnaryExpression(expression)
            result.add "UnaryExpression {\n"
            result.add indent & "    operator: " & tokenToString(expression.operator, indentLevel + 1)
            result.add indent & "    right: " & expressionToString(expression.right, indentLevel + 1)
            result.add indent & "}\n"
            
        elif expression of RangeExpression:
            let expression = RangeExpression(expression)
            result.add "RangeExpression {\n"
            result.add indent & "    start: " & expressionToString(expression.start, indentLevel + 1)
            result.add indent & "    firstOperator: " & tokenToString(expression.firstOperator, indentLevel + 1)
            result.add indent & "    stop: " & expressionToString(expression.stop, indentLevel + 1)
            result.add indent & "    secondOperator: " & tokenToString(expression.secondOperator, indentLevel + 1)
            result.add indent & "    step: " & expressionToString(expression.step, indentLevel + 1)
            result.add indent & "}\n"
    
        elif expression of BinaryExpression:
            let expression = BinaryExpression(expression)
            result.add "BinaryExpression {\n"
            result.add indent & "    left: " & expressionToString(expression.left, indentLevel + 1)
            result.add indent & "    operator: " & tokenToString(expression.operator, indentLevel + 1)
            result.add indent & "    right: " & expressionToString(expression.right, indentLevel + 1)
            result.add indent & "}\n"
        
        else:
            return "Unknown Expression\n"
    
    proc statementToString(statement: Statement, indentLevel: int = 0): string =
        let indent = "    ".repeat(indentLevel)
    
        if statement == nil:
            result.add indent & "nil\n"
    
        elif statement of ExpressionStatement:
            let statement = ExpressionStatement(statement)
            result.add indent & "ExpressionStatement {\n"
            result.add indent & "    expression: " & expressionToString(statement.expression, indentLevel + 1)
            result.add indent & "}\n"
            
        elif statement of ContainerStatement:
            let statement = ContainerStatement(statement)
            result.add indent & "ContainerStatement {\n"
            result.add indent & "    identifier: " & tokenToString(statement.identifier, indentLevel + 1)
            if statement.parameters.len() != 0:
                result.add indent & "    parameters: Token [\n"
                for parameter in statement.parameters:
                    result.add indent & "        " & tokenToString(parameter, indentLevel + 2)
                result.add indent & "    ]\n"
            else:
                result.add indent & "    parameters: Token []\n"
                
            result.add indent & "    expression: "
            result.add expressionToString(statement.expression, indentLevel + 1)
            result.add indent & "}\n"
        
        elif statement of WhenStatement:
            let statement = WhenStatement(statement)
            result.add indent & "WhenStatement {\n"
            result.add indent & "    whenSubStatements: WhenSubStatement [\n"
            for subStatement in statement.whenSubStatements:
                result.add indent & "        WhenSubStatement {\n"
                result.add indent & "            keyword: " & tokenToString(subStatement.keyword, indentLevel + 3)
                result.add indent & "            condition: " & expressionToString(subStatement.condition, indentLevel + 3)
                result.add indent & "            block: " &  expressionToString(subStatement.block, indentLevel + 3)
                result.add indent & "        }\n"
            result.add indent & "    ]\n"
            result.add indent & "}\n"
            
        elif statement of LoopStatement:
            let statement = LoopStatement(statement)
            result.add indent & "LoopStatement {\n"
            result.add indent & "    loopKeyword: " & tokenToString(statement.loopKeyword, indentLevel + 1)
            result.add indent & "    withStatements: WithStatement [\n"
            for i, withStatement in statement.withStatements:
                result.add indent & "        WithStatement {\n"
                result.add indent & "            withKeyword: " & tokenToString(withStatement.withKeyword, indentLevel + 3)
                result.add indent & "            iterable: " & expressionToString(withStatement.iterable, indentLevel + 3)
                result.add indent & "            iterableDataType: " & $withStatement.iterableDataType & "\n"
                result.add indent & "            counters: Identifier [\n"
                for counter in withStatement.counters:
                    result.add indent & "                Identifier {\n"
                    result.add indent & "                    " & tokenToString(counter, indentLevel + 5)
                    result.add indent & "                }\n"
                result.add indent & "            ]\n"
                result.add indent & "        }\n"
            result.add indent & "    ]\n"
            result.add indent & "    block: " & expressionToString(statement.`block`, indentLevel + 1)
            result.add indent & "}\n"
        
        elif statement of TryStatement:
            let statement = TryStatement(statement)
            result.add indent & "TryStatement {\n"
            result.add indent & "    tryKeyword: " & tokenToString(statement.tryKeyword, indentLevel + 1)
            result.add indent & "    tryBlock: " & expressionToString(statement.tryBlock, indentLevel + 1)
            result.add indent & "    fixStatements: FixStatement [\n"
            for fixStatement in statement.fixStatements:
                result.add indent & "        FixStatement {\n"
                result.add indent & "            fixKeyword: " & tokenToString(fixStatement.fixKeyword, indentLevel + 3)
                result.add indent & "            identifier: " & tokenToString(fixStatement.identifier, indentLevel + 3)
                result.add indent & "            fixBlock: " & expressionToString(fixStatement.fixBlock, indentLevel + 3)
                result.add indent & "        }\n"
            result.add indent & "    ]\n"
            result.add indent & "}\n"
            
        elif statement of ExitStatement:
            let statement = ExitStatement(statement)
            result.add indent & "ExitStatement {\n"
            result.add indent & "    keyword: " & tokenToString(statement.keyword, indentLevel + 1)
            result.add indent & "    expression: " & expressionToString(statement.expression, indentLevel + 1)
            result.add indent & "}\n"
        
        elif statement of StopStatement:
            let statement = StopStatement(statement)
            result.add indent & "StopStatement {\n"
            result.add indent & "    keyword: " & tokenToString(statement.keyword, indentLevel + 1)
            result.add indent & "    counter: " & tokenToString(statement.counter, indentLevel + 1)
            result.add indent & "}\n"
        
        elif statement of NextStatement:
            let statement = NextStatement(statement)
            result.add indent & "NextStatement {\n"
            result.add indent & "    keyword: " & tokenToString(statement.keyword, indentLevel + 1)
            result.add indent & "    counter: " & tokenToString(statement.counter, indentLevel + 1)
            result.add indent & "}\n"

        else:
            return "Unknown Statment\n"
        
    result.add "Statement [\n"
    for statement in statements:
        result.add statementToString(statement, 1)
    result.add "]"



##############################
# LEXER
##############################


proc lexer*(input: string): seq[Token] =
    var index: int
    var tokens: seq[Token]
    var line: int = 1
    var indentStack = @[0]
    const keywords = {
        "try": TokenKind.Try,
        "fix": TokenKind.Fix,
        "when": TokenKind.When,
        "else": TokenKind.Else,
        "loop": TokenKind.Loop,
        "with": TokenKind.With,
        "right": TokenKind.Right,
        "wrong": TokenKind.Wrong,
        "import": TokenKind.Import,
        "export": TokenKind.Export,
        "exit": TokenKind.Exit,
        "stop": TokenKind.Stop,
        "next": TokenKind.Next,
    }.toTable
    
    var roundBracketStack: seq[int] = @[]
    var squareBracketStack: seq[int] = @[]
    
    proc addToken(tokenKind: TokenKind, lexeme: string = "") =
        add tokens, Token(tokenKind: tokenKind, lexeme: lexeme, line: line)
    
    proc isAtEnd(): bool =
        return index >= input.len

    proc isDigit(character: char): bool =
        return character in {'0' .. '9'}

    proc isAlphabet(character: char): bool =
        return character in {'a'..'z'}
    
    proc isAlphaNumeric(character: char): bool =
        return isAlphabet(character) or isDigit(character) or character == '-'
    
    
    proc string() =
        # Skip the opening quote
        index.inc()  
        var accumulate = ""
        while true:
            if isAtEnd():
                error(line, "Unterminated string")
    
            if input[index] == '"':
                break
            elif input[index] == '\n':
                line.inc()
    
            accumulate.add(input[index])
            index.inc()
    
        # Skip the closing quote
        index.inc()  
        addToken(TokenKind.StringLiteral, accumulate)
    
    proc identifier() =
        var accumulate = ""
        while not isAtEnd() and isAlphaNumeric(input[index]):
            accumulate.add(input[index])
            index.inc()
        
        # Check if the identifier is a keyword
        if keywords.hasKey(accumulate):
            addToken(keywords[accumulate], accumulate)  
        else:
            addToken(TokenKind.Identifier, accumulate) 


    proc number(isNegative: bool = false) =
        var accumulate = if isNegative: "-" else: "" 
        while not isAtEnd() and (isDigit(input[index]) or input[index] == '.'):
            accumulate.add(input[index])
            index.inc()
        addToken(TokenKind.NumericLiteral, accumulate)
    

    proc newline() =
        line.inc()
        index.inc()
        if roundBracketStack.len() != 0: return
        
        var spaceCount = 0
    
        # Count leading spaces
        while not isAtEnd() and input[index] == ' ':
            spaceCount.inc()
            index.inc()
    
        # Skip line if it'statement empty or contains only spaces
        if isAtEnd() or input[index] == '\n' or input[index] == '#':
            return
        
        # Indentation must be a multiple of 4
        if spaceCount mod 4 != 0:
            error(line, "Indentation must be a multiple of 4 spaces")
            return
    
        let indentLevel = spaceCount div 4
        let currentIndentLevel = indentStack[^1]
    
        if indentLevel > currentIndentLevel:
            # Only allow increasing by one level at a time
            if indentLevel != currentIndentLevel + 1:
                error(line, "Unexpected indent level, expected " &
                    $(currentIndentLevel + 1) & " but got " & $indentLevel)
                return
            indentStack.add(indentLevel)
            addToken(TokenKind.Indent, "++++")
    
        elif indentLevel < currentIndentLevel:
            # Dedent to known indentation level
            
            while indentStack.len > 0 and indentStack[^1] > indentLevel:
                indentStack.setLen(indentStack.len - 1)
                addToken(TokenKind.Dedent, "----")
    
            if indentStack.len == 0 or indentStack[^1] != indentLevel:
                error(line, "Inconsistent dedent, expected indent level " &
                    $indentStack[^1] & " but got " & $indentLevel)
            
                                                 # out of bound check
        elif indentLevel == currentIndentLevel and tokens.len() != 0 and tokens[^1].tokenKind notin {TokenKind.Indent, TokenKind.Dedent, TokenKind.Newline}:
            addToken(TokenKind.Newline, "\n")

    
    
    while not isAtEnd():
        let character = input[index]
        
        case character
        of '(':
            roundBracketStack.add(0)
            addToken(TokenKind.LeftRoundBracket, $character)
            index.inc()
        of ')':
            discard roundBracketStack.pop()
            addToken(TokenKind.RightRoundBracket, $character)
            index.inc()
        of '{':
            addToken(TokenKind.LeftCurlyBracket, $character)
            index.inc()
        of '}':
            addToken(TokenKind.RightCurlyBracket, $character)
            index.inc()
        of '[':
            squareBracketStack.add(0)
            addToken(TokenKind.LeftSquareBracket, $character)
            index.inc()
        of ']':
            discard squareBracketStack.pop()
            addToken(TokenKind.RightSquareBracket, $character)
            index.inc()
        of ',':
            addToken(TokenKind.Comma, $character)
            index.inc()
        of '.':
            addToken(TokenKind.Dot, $character)
            index.inc()
        of ':':
            addToken(TokenKind.Colon, $character)
            index.inc()
        of '~':
            addToken(TokenKind.Tilde, $character)
            index.inc()
        of '-':
            if index + 1 < input.len and isDigit(input[index + 1]):
                index.inc()
                number(true)
            elif index + 1 < input.len and input[index + 1] == '-':
                error(line, "Invalid token `--`")
            else:
                addToken(TokenKind.Minus, $character)
                index.inc()
        of '+':
            if index + 1 < input.len and isDigit(input[index + 1]):
                index.inc()
                number()
            elif index + 1 < input.len and input[index + 1] == '+':
                error(line, "Invalid token `++`")
            else:
                addToken(TokenKind.Plus, $character)
                index.inc()
        of '*':
            addToken(TokenKind.Asterisk, $character)
            index.inc()
        of '/':
            addToken(TokenKind.Slash, $character)
            index.inc()
        of '$':
            addToken(TokenKind.Dollar, $character)
            index.inc()
        of '?':
            addToken(TokenKind.Question, $character)
            index.inc()
        of '&':
            addToken(TokenKind.Ampersand, $character)
            index.inc()
        of '=':
            addToken(TokenKind.Equal, $character)
            index.inc()
        of '>':
            addToken(TokenKind.MoreThan, $character)
            index.inc()
        of '<':
            addToken(TokenKind.LessThan, $character)
            index.inc()
        of '|':
            addToken(TokenKind.Bar, $character)
            index.inc()
        of '#':
            # Ignore single line comment
            while not isAtEnd() and not (input[index] == '\n'):
                index.inc()
        of '_':
            if index + 1 < input.len and input[index + 1] == '<':
                index.inc(2)
                addToken(TokenKind.UnderscoreLessThan, "_<")
            else:
                addToken(TokenKind.Underscore, $character)
                index.inc()
        of '\n':
            newline()
        of ' ', '\\':
            index.inc()
        of '!':
            if index + 1 < input.len and input[index + 1] in ['=', '>', '<']:
                if input[index + 1] == '=':
                    addToken(TokenKind.ExclamationEqual, "!=")
                elif input[index + 1] == '>':
                    addToken(TokenKind.ExclamationMoreThan, "!>")
                elif input[index + 1] == '<': 
                    addToken(TokenKind.ExclamationLessThan, "!<")
                index.inc(2)
            else: 
                addToken(TokenKind.Exclamation, $character)
                index.inc()
        of '"':
            string()
        else:
            if isDigit(character):
                number()
            elif isAlphabet(character):
                identifier()
            else:
                error(line, "Invalid character, `" & $character & "`")

    while indentStack.len > 1:  
        indentStack.setLen(indentStack.len - 1)
        addToken(TokenKind.Dedent, "----")
    
    addToken(TokenKind.EndOfFile, "File has ended")
    
    return tokens




##############################
# PARSER
##############################

proc parser*(tokens: seq[Token]): seq[Statement] =
    var index = 0
    var tokens: seq[Token] = tokens
    var abstractSyntaxTree: seq[Statement]

    
    proc isAtEnd(): bool =
        return tokens[index].tokenKind == EndOfFile

    
    proc isCurrentTokenKind(tokenKinds: varargs[TokenKind]): bool =
        for tokenKind in tokenKinds:
            if tokens[index].tokenKind == tokenKind:
                return true
        return false
    
    
    proc isCurrentTokenExpressionStart(): bool =
        return isCurrentTokenKind(
            TokenKind.NumericLiteral,
            TokenKind.StringLiteral,
            TokenKind.Right,
            TokenKind.Wrong,
            TokenKind.Identifier,
            TokenKind.LeftRoundBracket
        )
    
    proc expect(tokenKinds: varargs[TokenKind]) =
        if isCurrentTokenKind(tokenKinds):
            return
    
        let expected = 
            if tokenKinds.len == 1:
                $tokenKinds[0]
            else:
                "one of " & $tokenKinds
    
        let found = 
            if isCurrentTokenKind(TokenKind.EndOfFile):
                "reached end of code"
            else:
                "got " & $tokens[index].tokenKind
    
        error(tokens[index].line, "Expected " & expected & ", but " & found)

    proc ignore(tokenKinds: varargs[TokenKind]) =
        if isCurrentTokenKind(tokenKinds):
            index.inc()
    
    
    proc isThisExpressionStatement(): bool =
        var temp: int = index
        while tokens[temp].tokenKind notin {TokenKind.Indent, TokenKind.EndOfFile}:
            if tokens[temp].tokenKind == TokenKind.Colon:
                return true
            temp.inc()
        return false
    
    proc isThisExpressionStatement2(): bool =
        var temp: int = index
        if tokens[temp + 1].tokenKind == TokenKind.Colon: return false
        while tokens[temp].tokenKind notin {TokenKind.EndOfFile}:
            if tokens[temp].tokenKind == TokenKind.Colon and tokens[temp + 1].tokenKind == TokenKind.Indent:
                return false
            if tokens[temp].tokenKind in {TokenKind.Newline, TokenKind.Dedent}:
                return true
            temp.inc()
        # if reached end of file
        return true
    
    
    proc expression(): Expression
    proc statement(): Statement
    
    
    proc containerExpression(): Expression =
        # ContainerExpression* = ref object of Expression
        #     identifier*: Token
        #     arguments*: seq[Expression]
        
        let identifier: Token = tokens[index]
        index.inc()
        
        var arguments: seq[Expression]
        while isCurrentTokenExpressionStart():
            arguments.add(expression())
            if isCurrentTokenKind(TokenKind.Comma): 
                index.inc()
            else:
                break
    
        return ContainerExpression(identifier: identifier, arguments: arguments)
        
    
    proc whenExpression(): Expression =
        # WhenExpression* = ref object of Expression
        #     dataTypes*: seq[DataType]
        #     whenSubExpressions*: seq[WhenSubExpression]
        #   
        # WhenSubExpression* = ref object
        #     keyword*: Token
        #     condition*: Expression
        #     expression*: expression
        
        var whenSubExpressions: seq[WhenSubExpression] = @[]
        let whenKeyword: Token = tokens[index]
        index.inc()

        let whenCondition: Expression = expression()
        expect(TokenKind.Colon)
        index.inc()
        ignore(TokenKind.Indent)
    
        let whenExpression: Expression = expression()
        ignore(TokenKind.Dedent)
        
        whenSubExpressions.add(WhenSubExpression(
            keyword: whenKeyword,
            condition: whenCondition,
            expression: whenExpression
        ))
        
        while isCurrentTokenKind(TokenKind.Else):
            let keyword = tokens[index]
            index.inc()
            var condition: Expression = nil
            if not isCurrentTokenKind(TokenKind.Colon):
                condition = expression()
            expect(TokenKind.Colon)
            index.inc()
            ignore(TokenKind.Indent)
            let expression: Expression = expression()
            ignore(TokenKind.Dedent)
            whenSubExpressions.add(WhenSubExpression(
                keyword: keyword, 
                condition: condition, 
                expression: expression
            ))
        
        return WhenExpression(
            dataTypes: initHashSet[DataType](),
            whenSubExpressions: whenSubExpressions
        )
        

    proc loopExpression(): Expression =
        # LoopExpression* = ref object of Expression
        #     loopKeyword*: Token
        #     withExpressions*: seq[WithExpression]
        #     expression*: Expression
        #
        # WithExpression* = ref object
        #     withKeyword*: Token
        #     iterable*: Expression
        #     iterableDataType*: DataType
        #     counters*: seq[Token]
        
        let loopKeyword: Token = tokens[index]
        index.inc()
        
        var withExpressions: seq[WithExpression] = @[]
        while isCurrentTokenExpressionStart():
            let iterable: Expression = expression()
            var counters: seq[Token] = @[]
            var withKeyword: Token = nil
            
            if isCurrentTokenKind(TokenKind.With):
                withKeyword = tokens[index]
                index.inc()
                expect(TokenKind.Identifier)
                while isCurrentTokenKind(TokenKind.Identifier):
                    counters.add(tokens[index])
                    index.inc()
                    
            withExpressions.add(WithExpression(
                withKeyword: withKeyword, 
                iterable: iterable, 
                iterableDataType: initHashSet[DataType](),
                counters: counters,
            ))
            if isCurrentTokenKind(TokenKind.Comma):
                index.inc()
            else:
                break
        
        expect(TokenKind.Colon)
        index.inc()
        
        ignore(TokenKind.Indent)
        let expression: Expression = expression()
        ignore(TokenKind.Dedent)
        
        return LoopExpression(
            loopKeyword: loopKeyword,
            withExpressions: withExpressions, 
            expression: expression
        )


    proc tryExpression(): Expression =
        # TryExpression* = ref object of Expression
        #     dataTypes*: HashSet[DataType]
        #     tryKeyword*: Token
        #     tryExpression*: Expression
        #     fixExpressions*: seq[FixExpression]
        #
        # FixExpression* = ref object
        #     fixKeyword*: Token
        #     identifier*: Token
        #     fixExpression*: Expression

        let tryKeyword: Token = tokens[index]
        index.inc()
        expect(TokenKind.Colon)
        index.inc()
        
        ignore(TokenKind.Indent)
        let tryExpression: Expression = expression()
        ignore(TokenKind.Dedent)
        
        var fixExpressions: seq[FixExpression] = @[]
        
        while isCurrentTokenKind(TokenKind.Fix):
            let fixKeyword: Token = tokens[index]
            index.inc()
            var identifier: Token = nil
            if isCurrentTokenKind(TokenKind.Identifier):
                identifier = tokens[index]
                index.inc()
            expect(TokenKind.Colon)
            index.inc()
            ignore(TokenKind.Indent)
            let fixExpression: Expression = expression()
            ignore(TokenKind.Dedent)
            fixExpressions.add(FixExpression(
                fixKeyword: fixKeyword,
                identifier: identifier, 
                fixExpression: fixExpression
            ))

        return TryExpression(
            dataTypes: initHashSet[DataType](),
            tryKeyword: tryKeyword,
            tryExpression: tryExpression, 
            fixExpressions: fixExpressions
        )

    
    proc blockExpression(): BlockExpression =
        # BlockExpression* = ref object of Expression
        #     statements*: seq[Statement]

        expect(TokenKind.Indent)
        index.inc()            
        var statements: seq[Statement] = @[]
        
        while not isAtEnd() and not isCurrentTokenKind(TokenKind.Dedent):
            statements.add(statement())
        
        expect(TokenKind.Dedent)
        index.inc()
        
        return BlockExpression(statements: statements)

    
    
    proc primaryExpression(): Expression =
        if isCurrentTokenKind(TokenKind.Right):
            # LiteralExpression* = ref object of Expression
            #     value*: Literal
            #
            # BooleanLiteral* = ref object of Literal
            #     value*: bool
            
            result = LiteralExpression(value: BooleanLiteral(value: true))
            index.inc()            
        elif isCurrentTokenKind(TokenKind.Wrong):
            # LiteralExpression* = ref object of Expression
            #     value*: Literal
            #
            # BooleanLiteral* = ref object of Literal
            #     value*: bool
            
            result = LiteralExpression(value: BooleanLiteral(value: false))
            index.inc()            
        elif isCurrentTokenKind(TokenKind.StringLiteral):
            # LiteralExpression* = ref object of Expression
            #     value*: Literal
            #
            # StringLiteral* = ref object of Literal
            #     value*: string
            
            result = LiteralExpression(value: StringLiteral(value: tokens[index].lexeme))
            index.inc()            
        elif isCurrentTokenKind(TokenKind.NumericLiteral):
            # LiteralExpression* = ref object of Expression
            #     value*: Literal
            #
            # NumericLiteral* = ref object of Literal
            #     value*: float
        
            result = LiteralExpression(value: NumericLiteral(value: parseFloat(tokens[index].lexeme)))
            index.inc()
        elif isCurrentTokenKind(TokenKind.LeftRoundBracket):
            # GroupingExpression* = ref object of Expression
            #     expression*: Expression
            index.inc()            
            result = GroupingExpression(expression: expression())
            expect(TokenKind.RightRoundBracket)
            index.inc()
        elif isCurrentTokenKind(TokenKind.Identifier):
            return containerExpression()
        elif isCurrentTokenKind(TokenKind.When):
            return whenExpression()
        elif isCurrentTokenKind(TokenKind.Loop):
            return loopExpression()
        elif isCurrentTokenKind(TokenKind.Try):
            return tryExpression()
        elif isCurrentTokenKind(TokenKind.Indent):
            return blockExpression()
        else:
            if isCurrentTokenKind(TokenKind.With):
                error(tokens[index].line, "Can not use with expression without loop expression")
            elif isCurrentTokenKind(TokenKind.Else):
                error(tokens[index].line, "Can not use else expression without when expression")
            elif isCurrentTokenKind(TokenKind.Fix):
                error(tokens[index].line, "Can not use fix expression without try expression")
            
            error(tokens[index].line, "Expected an expression but " & (
                if isCurrentTokenKind(TokenKind.EndOfFile):
                    "reached end of code"
                else:
                    "got " & $tokens[index].tokenKind
            ))
    
    proc unaryExpression(): Expression =
        # UnaryExpression* = ref object of Expression
        #     operator*: Token
        #     right*: Expression
        
        if isCurrentTokenKind(TokenKind.Exclamation, TokenKind.Minus):
            let operator: Token = tokens[index]
            index.inc()
            let right: Expression = unaryExpression()
            return UnaryExpression(operator: operator, right: right)
            
        return primaryExpression()
    
    proc rangeExpression(): Expression =
        # RangeExpression* = ref object of Expression
        #     start*: Expression
        #     firstOperator*: Token
        #     stop*: Expression
        #     secondOperator*: Token
        #     step*: Expression
        
        var startExpression = unaryExpression()
        if not isCurrentTokenKind(TokenKind.Underscore, TokenKind.UnderscoreLessThan):
            return startExpression
        
        let firstOperator: Token = tokens[index]
        index.inc()
        let stopExpression = unaryExpression()
        var secondOperator: Token = nil
        var stepExpression: Expression = LiteralExpression(value: NumericLiteral(value: 1.0))
        
        if isCurrentTokenKind(TokenKind.Underscore):
            secondOperator = tokens[index]
            index.inc()
            stepExpression = unaryExpression()
        
        return RangeExpression(
            start: startExpression, 
            firstOperator: firstOperator,
            stop: stopExpression, 
            secondOperator: secondOperator,
            step: stepExpression, 
        )

    
    proc multiplicationAndDivisionExpression(): Expression =
        # BinaryExpression* = ref object of Expression
        #     left*: Expression
        #     operator*: Token
        #     right*: Expression
        
        var expression: Expression = rangeExpression()
        
        while isCurrentTokenKind(TokenKind.Asterisk, TokenKind.Slash):  
            let operator: Token = tokens[index]
            index.inc()
            let right: Expression = rangeExpression()
            expression = BinaryExpression(left: expression, operator: operator, right: right)
        
        return expression
    
    
    proc additionAndSubstractionExpression(): Expression =
        # BinaryExpression* = ref object of Expression
        #     left*: Expression
        #     operator*: Token
        #     right*: Expression
        
        var expression: Expression = multiplicationAndDivisionExpression()

        while isCurrentTokenKind(TokenKind.Plus, TokenKind.Minus):
            let operator: Token = tokens[index]
            index.inc()
            let right: Expression = multiplicationAndDivisionExpression()
            expression = BinaryExpression(left: expression, operator: operator, right: right)
        
        return expression
    
    
    proc comparisonExpression(): Expression =
        # BinaryExpression* = ref object of Expression
        #     left*: Expression
        #     operator*: Token
        #     right*: Expression

        var expression: Expression = additionAndSubstractionExpression()
        
        while isCurrentTokenKind(TokenKind.MoreThan, TokenKind.LessThan, TokenKind.ExclamationMoreThan, TokenKind.ExclamationLessThan):
            let operator: Token = tokens[index]
            index.inc()
            let right: Expression = additionAndSubstractionExpression()
            expression = BinaryExpression(left: expression, operator: operator, right: right)

        return expression
    
    
    proc equalityAndInequalityExpression(): Expression =
        # BinaryExpression* = ref object of Expression
        #     left*: Expression
        #     operator*: Token
        #     right*: Expression

        var expression: Expression = comparisonExpression()
        
        while isCurrentTokenKind(TokenKind.Equal, TokenKind.ExclamationEqual):
            let operator: Token = tokens[index]
            index.inc()
            let right: Expression = comparisonExpression()
            expression = BinaryExpression(left: expression, operator: operator, right: right)

        return expression

    
    proc expression(): Expression =
        # Expression* = ref object of RootObj
        return equalityAndInequalityExpression()


    proc expressionStatement(): Statement =
        # ExpressionStatement* = ref object of Statement
        #     expression*: expression
        result = ExpressionStatement(expression: expression())
        expect(TokenKind.Newline, TokenKind.Dedent, TokenKind.EndOfFile)
        ignore(TokenKind.Newline)
    
    
    proc containerStatement(): Statement =
        # ContainerStatement* = ref object of Statement
        #     identifier*: Token
        #     parameters*: seq[Token]
        #     expression*: Expression
        
        if isThisExpressionStatement2(): return expressionStatement()
        let identifier: Token = tokens[index]
        index.inc()
        
        var parameters: seq[Token]
        while isCurrentTokenKind(TokenKind.Identifier):
            parameters.add(tokens[index])
            index.inc()
        
            if isCurrentTokenKind(TokenKind.Comma):
                index.inc()
            else:
                break
        
        expect(TokenKind.Colon)
        index.inc()
        if parameters.len() != 0:
            expect(TokenKind.Indent)
        
        let expression: Expression = expression()
        ignore(TokenKind.Newline)
        return ContainerStatement(identifier: identifier, parameters: parameters, expression: expression)

    
    proc whenStatement(): Statement =
        # WhenStatement* = ref object of Statement
        #     whenSubStatements*: seq[WhenSubStatement]
        #   
        # WhenSubStatement* = ref object
        #     keyword*: Token
        #     condition*: Expression
        #     `block`*: blockExpression
        
        if isThisExpressionStatement(): return expressionStatement()
        
        var whenSubStatements: seq[WhenSubStatement] = @[]
        let whenKeyword: Token = tokens[index]
        index.inc()
        
        let whenCondition: Expression = expression()
        let whenBlock: BlockExpression = blockExpression()

        whenSubStatements.add(WhenSubStatement(
            keyword: whenKeyword,
            condition: whenCondition,
            `block`: whenBlock
        ))
        
        while isCurrentTokenKind(TokenKind.Else):
            let keyword = tokens[index]
            index.inc()
            var condition: Expression = nil
            if not isCurrentTokenKind(TokenKind.Indent):
                condition = expression()

            let `block`: BlockExpression = blockExpression()

            whenSubStatements.add(WhenSubStatement(keyword: keyword, condition: condition, `block`: `block`))
        

            
        return WhenStatement(
            whenSubStatements: whenSubStatements
        )
    
    proc loopStatement(): Statement =
        # LoopStatement* = ref object of Statement
        #     loopKeyword*: Token
        #     withStatements*: seq[WithStatement]
        #     `block`*: BlockExpression
        #
        # WithStatement* = ref object 
        #     withKeyword*: Token
        #     iterable*: Expression
        #     iterableDataType*: DataType
        #     counters*: seq[Token]
        
        if isThisExpressionStatement(): return expressionStatement()
        
        let loopKeyword: Token = tokens[index]
        index.inc()
        
        var withStatements: seq[WithStatement] = @[]
        while isCurrentTokenExpressionStart():
            var withKeyword: Token
            let iterable: Expression = expression()
            var counters: seq[Token] = @[]
            
            if isCurrentTokenKind(TokenKind.With):
                withKeyword = tokens[index]
                index.inc()
                expect(TokenKind.Identifier)
                while isCurrentTokenKind(TokenKind.Identifier):
                    counters.add(tokens[index])
                    index.inc()
                    
            withStatements.add(WithStatement(
                withKeyword: withKeyword, 
                iterable: iterable, 
                iterableDataType: initHashSet[DataType](),
                counters: counters
            ))
            if isCurrentTokenKind(TokenKind.Comma):
                index.inc()
            else:
                break
        

        let `block` = blockExpression()

        return LoopStatement(
            loopKeyword: loopKeyword,
            withStatements: withStatements, 
            `block`: `block`
        )


    proc tryStatement(): Statement =
        # TryStatement* = ref object of Statement
        #     tryKeyword*: Token
        #     tryBlock*: BlockExpression
        #     fixStatements*: seq[FixStatement]
        #
        # FixStatement* = ref object
        #     fixKeyword*: Token
        #     identifier*: Token
        #     fixBlock*: BlockExpression
    
        if isThisExpressionStatement(): return expressionStatement()
        
        let tryKeyword: Token = tokens[index]
        index.inc()

        
        let tryBlock: BlockExpression = blockExpression()

        
        var fixStatements: seq[FixStatement] = @[]
        
        while isCurrentTokenKind(TokenKind.Fix):
            let fixKeyword: Token = tokens[index]
            index.inc()
            var identifier: Token = nil
            if isCurrentTokenKind(TokenKind.Identifier):
                identifier = tokens[index]
                index.inc()
            

            let fixBlock: BlockExpression = blockExpression()
            
            fixStatements.add(FixStatement(
                fixKeyword: fixKeyword,
                identifier: identifier, 
                fixBlock: fixBlock
            ))

        return TryStatement(
            tryKeyword: tryKeyword,
            tryBlock: tryBlock, 
            fixStatements: fixStatements
        )


    proc exitStatement(): Statement =
        # ExitStatement* = ref object of Statement
        #     keyword*: Token
        #     expression*: Expression
        
        let keyword: Token = tokens[index]
        index.inc()
        var expression: Expression = nil
        if isCurrentTokenExpressionStart():
            expression = expression()
        
        # EndOfFile should not be expected here but it helps 
        # in skipping this error message and giving a more suitable
        # error message at analysis phase
        expect(TokenKind.Dedent, TokenKind.Newline, TokenKind.EndOfFile)
        
        ignore(TokenKind.Newline)
        return ExitStatement(keyword: keyword, expression: expression)

    proc stopOrNextStatement(): Statement =
        # NextStatement* = ref object of Statement
        #     keyword*: Token
        #     counter*: Token
        #
        # StopStatement* = ref object of Statement
        #     keyword*: Token
        #     counter*: tokens
        
        let keyword: Token = tokens[index]
        index.inc()
        var counter: Token = nil
        if isCurrentTokenKind(TokenKind.Identifier):
            counter = tokens[index]
        
        
        # EndOfFile should not be expected here but it helps 
        # in skipping this parser error message and giving a more suitable
        # error message at analysis phase
        expect(TokenKind.Dedent, TokenKind.Newline, TokenKind.EndOfFile)
        
        ignore(TokenKind.Newline)
        if keyword.tokenKind == TokenKind.Stop: 
            return StopStatement(keyword: keyword, counter: counter)
        else:
            return NextStatement(keyword: keyword, counter: counter)
            
    
    proc statement(): Statement =
        # Statement* = ref object of RootObj
        
        if isCurrentTokenKind(TokenKind.Identifier):
            return containerStatement()
        elif isCurrentTokenKind(TokenKind.When):
            return whenStatement()
        elif isCurrentTokenKind(TokenKind.Loop):
            return loopStatement()
        elif isCurrentTokenKind(TokenKind.Try):
            return tryStatement()
        elif isCurrentTokenKind(TokenKind.Exit):
            return exitStatement()
        elif isCurrentTokenKind(TokenKind.Stop, TokenKind.Next):
            return stopOrNextStatement()
        else:
            if isCurrentTokenKind(TokenKind.Else):
                error(tokens[index].line, "Can not use `else` statement without `when` statement")
            elif isCurrentTokenKind(TokenKind.Fix):
                error(tokens[index].line, "Can not use `fix` statement without `try` statement")
            elif isCurrentTokenKind(TokenKind.With):
                error(tokens[index].line, "Can not use `with` statement without `loop` statement")
            else: 
                return expressionStatement()

    while not isAtEnd():
        abstractSyntaxTree.add(statement())
        
    
    return abstractSyntaxTree



##############################
# ANALYSER
##############################


proc analyser*(abstractSyntaxTree: seq[Statement]): seq[Statement] =
    var scopes: seq[TableRef[string, HashSet[DataType]]] = @[]
    var contexts: seq[Context] = @[]
    
    proc beginScope() =
        scopes.add(newTable[string, HashSet[DataType]]())

    proc endScope() =
        discard scopes.pop()

    proc addContext(context: Context) =
        contexts.add(context)
    
    proc popContext() =
        discard contexts.pop()
    
    
    proc insideFunction(): bool =
        for i in countdown(contexts.high, 0):
            if contexts[i] == Context.Function:
                return true
        return false
    
    proc insideLoop(): bool =
        for i in countdown(contexts.high, 0):
            case contexts[i]
            of Context.Loop: return true
            of Context.Function: break
            of Context.Try: continue
        return false

    proc defineContainer(name: string, line: int, dataTypes: HashSet[DataType]) =
        if name in scopes[^1]:
            error(line, "Container `" & name & "` already defined in this scope")
        scopes[^1][name] = dataTypes


    proc resolveContainer(name: string, line: int): HashSet[DataType] =
        for i in countdown(scopes.high, 0):
            if name in scopes[i]:
                return scopes[i][name]
        error(line, "Undefined container `" & name & "`")

    proc analyseExpression(expression: Expression): HashSet[DataType] 
    proc analyseStatement(statement: Statement)
    
    proc findParameterScope(name: string): int =
        # Search scopes from inner to outer
        for i in countdown(scopes.high, 0):
            if name in scopes[i]:
                # Check if this is a parameter (empty type set)
                if scopes[i][name].len == 0:
                    return i
        return -1
    
    proc expect(expression: Expression, expectedTypes: varargs[HashSet[DataType]]): HashSet[DataType] =
        let actualTypes = analyseExpression(expression)
        
        # Special case for parameter references
        if expression of ContainerExpression:
            let expression = ContainerExpression(expression)
            let identifier = expression.identifier.lexeme
            let paramScope = findParameterScope(identifier)
            
            if paramScope != -1:  # This is a parameter
                # Union all expected types into parameter's allowed types
                for types in expectedTypes:
                    scopes[paramScope][identifier].incl(types)
                return actualTypes
        
        # Normal type checking for non-parameters
        for expected in expectedTypes:
            if allIt(actualTypes, it in expected):
                return actualTypes
        
        error(-1, "Type mismatch")
    

    proc analyseExpression(expression: Expression): HashSet[DataType] =
        if expression of LiteralExpression:
            let literal = LiteralExpression(expression).value
            if literal of StringLiteral:
                return toHashSet([DataType.String])
            elif literal of NumericLiteral:
                return toHashSet([DataType.Number])
            elif literal of BooleanLiteral:
                return toHashSet([DataType.Boolean])
        
        elif expression of ContainerExpression:
            let expression = ContainerExpression(expression)
            return resolveContainer(expression.identifier.lexeme, expression.identifier.line)
        
        elif expression of UnaryExpression:
            let expression = UnaryExpression(expression)
            if (expression.operator.tokenKind == TokenKind.Exclamation):
                return expect(expression.right, toHashSet([DataType.Boolean]))
            elif (expression.operator.tokenKind == TokenKind.Minus):
                return expect(expression.right, toHashSet([DataType.Number]))
        
        elif expression of BinaryExpression:
            let expression = BinaryExpression(expression)
            
            if expression.operator.tokenKind == TokenKind.Plus:
                let leftDataType =  expect(expression.left,  toHashSet([DataType.String]), toHashSet([DataType.Number]))
                let rightDataType = expect(expression.right, toHashSet([DataType.String]), toHashSet([DataType.Number]))
                
                if leftDataType != rightDataType:
                    error(expression.operator.line, "Expected both to be Numbers or Strings")
                return leftDataType
            else:
                discard expect(expression.left, toHashSet([DataType.Number]))
                discard expect(expression.right, toHashSet([DataType.Number]))
                return toHashSet([DataType.Number])
            
        elif expression of RangeExpression:
            let expression = RangeExpression(expression)
            discard expect(expression.start, toHashSet([DataType.Number]))
            discard expect(expression.stop,  toHashSet([DataType.Number]))
            discard expect(expression.step,  toHashSet([DataType.Number]))
            return toHashSet([DataType.Structure])
        
        elif expression of GroupingExpression:
            let expression = GroupingExpression(expression)
            return analyseExpression(expression.expression)
        
        elif expression of BlockExpression:
            let expression = BlockExpression(expression)
            beginScope()
            for statement in expression.statements:
                analyseStatement(statement)
            endScope()
            return toHashSet([DataType.Procedure])
        
        elif expression of WhenExpression:
            let expression = WhenExpression(expression)
            for subExpression in expression.whenSubExpressions:
                discard expect(subExpression.condition, toHashSet([DataType.Boolean]))
                expression.dataTypes.incl(analyseExpression(subExpression.expression))
            return expression.dataTypes
        
        elif expression of TryExpression:
            let expression = TryExpression(expression)
            beginScope()
            expression.dataTypes.incl(analyseExpression(expression.tryExpression))
            for subExpression in expression.fixExpressions:
                expression.dataTypes.incl(analyseExpression(subExpression.fixExpression))
            endScope()
            return expression.dataTypes
        
        elif expression of LoopExpression:
            let expression = LoopExpression(expression)
            beginScope()
            for subExpression in expression.withExpressions:
                let iterableDataType = analyseExpression(subExpression.iterable)
                subExpression.iterableDataType = iterableDataType
                for counter in subExpression.counters:
                    defineContainer(counter.lexeme, counter.line, initHashSet[DataType]())
            let h = analyseExpression(expression.expression)
            endScope()
            return h
        else:
            error(-1, "Unknown expression (internal error, meant for compiler diagnostics)")

    proc analyseStatement(statement: Statement) =
        if statement of ExpressionStatement:
            let statement =  ExpressionStatement(statement)
            discard analyseExpression(statement.expression)
        
        elif statement of ContainerStatement:
            let statement = ContainerStatement(statement)
            
            # First declare the container with empty types to break recursion
            defineContainer(statement.identifier.lexeme, statement.identifier.line, initHashSet[DataType]())
            
            # Analyze the expression in parameter scope
            beginScope()
            addContext(Context.Function)
            
            # Define parameters as variables in the inner scope
            for parameter in statement.parameters:
                defineContainer(parameter.lexeme, parameter.line, initHashSet[DataType]())
            
            # Analyze the container body
            let bodyTypes = analyseExpression(statement.expression)
            popContext()
            endScope()
            
            # Now update the container with the actual types
            scopes[^1][statement.identifier.lexeme] = bodyTypes
        
        elif statement of WhenStatement:
            let statement = WhenStatement(statement)
            for subStatement in statement.whenSubStatements:
                discard expect(subStatement.condition, toHashSet([DataType.Boolean]))
                discard analyseExpression(subStatement.`block`)
        elif statement of TryStatement:
            let statement = TryStatement(statement)
            beginScope()
            discard analyseExpression(statement.tryBlock)
            for subStatement in statement.fixStatements:
                discard analyseExpression(subStatement.fixBlock)
            endScope()
        elif statement of LoopStatement:
            let statement = LoopStatement(statement)
            beginScope()
            addContext(Context.Loop)
            for withStatement in statement.withStatements:
                withStatement.iterableDataType.incl(analyseExpression(withStatement.iterable))
                for counter in withStatement.counters:
                    defineContainer(counter.lexeme, counter.line, initHashSet[DataType]())
            discard analyseExpression(statement.`block`)
            popContext()
            endScope()
        elif statement of ExitStatement:
            let statement = ExitStatement(statement)
            if not insideFunction():
                error(statement.keyword.line, "Can not exit outside a function")
        elif statement of StopStatement:
            let statement = StopStatement(statement)
            if not insideLoop():
                error(statement.keyword.line, "Can not stop the iteration outside a loop")
        elif statement of NextStatement:
            let statement = NextStatement(statement)
            if not insideLoop():
                error(statement.keyword.line, "Can not skip to next iteration outside a loop")
        else:
            error(-1, "Unknown statement (internal error, meant for compiler diagnostics)")

    # Global scope begin
    beginScope()
    
    defineStandardLibrary()
    
    # Main resolution process
    for statement in abstractSyntaxTree:
        analyseStatement(statement)
    
    # Global scope end
    endScope()

    
    return abstractSyntaxTree



##############################
# TRANSFORMER
##############################

proc transformer*(abstractSyntaxTree: seq[Statement]): seq[Statement] =
    return abstractSyntaxTree



##############################
# GENERATOR
##############################


proc generator*(abstractSyntaxTree: seq[Statement]): string =
    return ""
    
    



##############################
# COMPILER
##############################


proc compiler*(input: string): string =
    return generator transformer analyser parser lexer input






proc run(stage: string) =
    if paramCount() < 1:
        styledEcho(fgRed, "Error: ", resetStyle, "Missing input file")
        styledEcho(fgCyan, "Usage: ", resetStyle, getAppFilename().extractFilename(), " <input_file> [output_file]")
        quit(1)

    let
        inputPath = paramStr(1)
        outputPath = if paramCount() >= 2: paramStr(2) else: inputPath.changeFileExt("js")
        inputDir = getAppDir()
        absInputPath = if inputPath.isAbsolute: inputPath else: inputDir / inputPath
        absOutputPath = if outputPath.isAbsolute: outputPath else: inputDir / outputPath

    if not fileExists(absInputPath):
        styledEcho(fgRed, "Error: ", resetStyle, "Input file not found: ", fgYellow, absInputPath)
        quit(1)

    try:
        let input = readFile(absInputPath)
        let output =
            case stage
            of "lexer": tokensToString lexer input
            of "parser": astToString parser lexer input
            of "compiler": compiler input
            else:
                styledEcho(fgRed, "Error: ", resetStyle, "Unknown stage: ", stage)
                quit(1)
        createDir(absOutputPath.parentDir)
        writeFile(absOutputPath, output)
    except IOError as e:
        styledEcho(fgRed, "Error: ", resetStyle, e.msg)
        quit(1)
    except:
        styledEcho(fgRed, "Error: ", resetStyle, "Unexpected error")
        quit(1)



when defined(lexer):
    run("lexer")

when defined(parser):
    run("parser")

when defined(compiler):
    run("compiler")


