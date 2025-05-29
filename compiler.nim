import tables, strutils, terminal, sets


##############################
# TYPES
##############################


type
    TokenKind* {.pure.} = enum
        Illegal
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
        WhenKeyword  
        ThenKeyword  
        TryKeyword  
        FixKeyword  
        LoopKeyword  
        WithKeyword  
        ImportKeyword  
        ExportKeyword  
        RightKeyword  
        WrongKeyword  
      
        # Spacing  
        Indent  
        Dedent  


    Token* = ref object  
        tokenKind*: TokenKind
        lexeme*: string  
        line*: int 
    
    Tokens* = seq[Token]
    



    # Expressions
    Expression* = ref object of RootObj
    Expressions* = seq[Expression]

    BinaryExpression* = ref object of Expression
        left*: Expression
        operator*: Token
        right*: Expression

    RangeExpression* = ref object of Expression
        start*: Expression
        stop*: Expression
        step*: Expression
        operator*: Token
    
    UnaryExpression* = ref object of Expression
        operator*: Token
        right*: Expression
    
    GroupingExpression* = ref object of Expression
        expression*: Expression

    LiteralExpression* = ref object of Expression
        value*: Literal
    
    BlockExpression* = ref object of Expression
        statements*: Statements
        
    ContainerExpression* = ref object of Expression
        identifier*: Token
        arguments*: seq[Expression]

    WhenThenExpression* = ref object of Expression
        whenThenSubExpressions*: seq[WhenThenSubExpression]
    
    WhenThenSubExpression* = ref object
        condition*: Expression
        expression*: Expression
    
    LoopWithExpression* = ref object of Expression
        loopWithSubExpressions*: seq[LoopWithSubExpression]
        expression*: Expression
    
    LoopWithSubExpression* = ref object
        iterable*: Expression
        counters*: seq[string]
    
    TryFixExpression* = ref object of Expression
        tryExpression*: Expression
        tryFixSubExpressions*: seq[TryFixSubExpression]
    
    TryFixSubExpression* = ref object
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
    

    # Statements, TODO
    Statement* = ref object of RootObj
    Statements* = seq[Statement]
    
    ExpressionStatement* = ref object of Statement
        expression*: Expression

    ContainerStatement* = ref object of Statement
        identifier*: Token
        parameters*: seq[string]
        expression*: Expression

    WhenThenStatement* = ref object of Statement
        whenThenSubStatements*: seq[WhenThenSubStatement]
    
    WhenThenSubStatement* = ref object
        condition*: Expression
        `block`*: BlockExpression

    LoopWithStatement* = ref object of Statement
        loopWithSubStatements*: seq[LoopWithSubStatement]
        `block`*: BlockExpression

    LoopWithSubStatement* = ref object 
        iterable*: Expression
        counters*: seq[string]

    TryFixStatement* = ref object of Statement
        tryBlock*: BlockExpression
        tryFixSubStatements*: seq[TryFixSubStatement]
    
    TryFixSubStatement* = ref object
        identifier*: Token
        fixBlock*: BlockExpression


##############################
# ERROR
##############################

proc error*(line: int, message: string) =
    styledEcho fgRed, "Error", resetStyle, " [Line " & $line & "]: " & message
    quit(1)


##############################
# LEXER
##############################

proc lexer*(input: string): Tokens =
    # Index of current character
    var index: int
    
    var tokens: Tokens

    # Line number 
    var line: int = 1
    
    # For managing indentation inside `handleIndentation` proc
    var indentStack = @[0]
    
    # For checking if an identifier is a keyword inside `identifier` proc
    const keywords = {
        "try": TokenKind.TryKeyword,
        "fix": TokenKind.FixKeyword,
        "when": TokenKind.WhenKeyword,
        "then": TokenKind.ThenKeyword,
        "loop": TokenKind.LoopKeyword,
        "with": TokenKind.WithKeyword,
        "right": TokenKind.RightKeyword,
        "wrong": TokenKind.WrongKeyword,
        "import": TokenKind.ImportKeyword,
        "export": TokenKind.ExportKeyword
    }.toTable
    
    # Make sure no newlines or indentation tokens are emitted inside expression
    var roundBracketStack: seq[int] = @[]
    
    # TODO
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
    
        # Skip line if it's empty or contains only spaces
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
        of '-':
            if index + 1 < input.len and isDigit(input[index + 1]):
                index.inc()
                number(true)
            else:
                addToken(TokenKind.Minus, $character)
                index.inc()
        of '+':
            if index + 1 < input.len and isDigit(input[index + 1]):
                index.inc()
                number()
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
            if index + 1 < input.len:
                if input[index + 1] == '=':
                    addToken(TokenKind.ExclamationEqual, "!=")
                    index.inc(2)
                elif input[index + 1] == '>':
                    addToken(TokenKind.ExclamationMoreThan, "!>")
                    index.inc(2)
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


when defined lexer:
    import json
    
    let input: string = readFile("./garbage/input.uki")
    let output: Tokens = lexer(input)
    writeFile("./garbage/output.js", pretty(%output, indent = 4))
    


##############################
# PARSER
##############################

proc parser*(tokens: Tokens): Statements =
    var index = 0
    var tokens: Tokens = tokens
    var abstractSyntaxTree: Statements

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
            TokenKind.RightKeyword,
            TokenKind.WrongKeyword,
            TokenKind.Identifier,
            TokenKind.LeftRoundBracket
        )
    
    proc expect(tokenKinds: varargs[TokenKind]) =
        if isCurrentTokenKind(tokenKinds):
            return
        error(tokens[index].line, "Expected " & (if tokenKinds.len() == 1: $tokenKinds[0] else: "one of " & $tokenKinds) & " but got " & $tokens[index].tokenKind)

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
        
    
    proc whenThenExpression(): Expression =
        index.inc()
        var whenThenSubExpressions: seq[WhenThenSubExpression] = @[]
        
        
        let firstCondition: Expression = expression()
        
        expect(TokenKind.Colon)
        index.inc()
        ignore(TokenKind.Indent)
        
        let firstExpression: Expression = expression()
        whenThenSubExpressions.add(WhenThenSubExpression(condition: firstCondition, expression: firstExpression))
    
        while isCurrentTokenKind(TokenKind.ThenKeyword):
            index.inc()
            var condition: Expression = nil
            if not isCurrentTokenKind(TokenKind.Colon):
                condition = expression()
            index.inc()
            let expression: Expression = expression()
            whenThenSubExpressions.add(WhenThenSubExpression(condition: condition, expression: expression))
        
        ignore(TokenKind.Dedent)
        return WhenThenExpression(whenThenSubExpressions: whenThenSubExpressions)
        
    
    proc loopWithExpression(): Expression =
        index.inc()
        var loopWithSubExpressions: seq[LoopWithSubExpression] = @[]
        while isCurrentTokenExpressionStart():
            let iterable: Expression = expression()
            var counters: seq[string] = @[]
            if isCurrentTokenKind(TokenKind.WithKeyword):
                index.inc()
                expect(TokenKind.Identifier)
                while isCurrentTokenKind(TokenKind.Identifier):
                    counters.add(tokens[index].lexeme)
                    index.inc()
                    
            loopWithSubExpressions.add(LoopWithSubExpression(iterable: iterable, counters: counters))
            if isCurrentTokenKind(TokenKind.Comma):
                index.inc()
            else:
                break
        
        expect(TokenKind.Colon)
        index.inc()
        ignore(TokenKind.Indent)
        
        let expression: Expression = expression()
        ignore(TokenKind.Dedent)
        return LoopWithExpression(loopWithSubExpressions: loopWithSubExpressions, expression: expression)


    proc tryFixExpression(): Expression =
        index.inc()
        expect(TokenKind.Colon)
        ignore(TokenKind.Indent)
        
        let tryExpression: Expression = expression()
        
        var tryFixSubExpressions: seq[TryFixSubExpression] = @[]
        
        while isCurrentTokenKind(TokenKind.FixKeyword):
            index.inc()
            var identifier: Token = nil
            if not isCurrentTokenKind(TokenKind.Colon):
                expect(TokenKind.Identifier)
                identifier = tokens[index]
            ignore(TokenKind.Indent)
            let fixExpression: Expression = expression()
            tryFixSubExpressions.add(TryFixSubExpression(identifier: identifier, fixExpression: fixExpression))

        return TryFixExpression(tryExpression: tryExpression, tryFixSubExpressions: tryFixSubExpressions)

    
    proc blockExpression(): BlockExpression =
        index.inc()            
        var statements: Statements = @[]
        
        while not isAtEnd() and not isCurrentTokenKind(TokenKind.Dedent):
            statements.add(statement())
        
        expect(TokenKind.Dedent)
        index.inc()
        
        return BlockExpression(statements: statements)

    
    
    proc primaryExpression(): Expression =
        if isCurrentTokenKind(TokenKind.RightKeyword):
            result = LiteralExpression(value: BooleanLiteral(value: true))
            index.inc()            
        elif isCurrentTokenKind(TokenKind.WrongKeyword):
            result = LiteralExpression(value: BooleanLiteral(value: false))
            index.inc()            
        elif isCurrentTokenKind(TokenKind.StringLiteral):
            result = LiteralExpression(value: StringLiteral(value: tokens[index].lexeme))
            index.inc()            
        elif isCurrentTokenKind(TokenKind.NumericLiteral):
            result = LiteralExpression(value: NumericLiteral(value: parseFloat(tokens[index].lexeme)))
            index.inc()
        elif isCurrentTokenKind(TokenKind.LeftRoundBracket):
            index.inc()            
            result = GroupingExpression(expression: expression())
            expect(TokenKind.RightRoundBracket)
            index.inc()
        elif isCurrentTokenKind(TokenKind.Identifier):
            return containerExpression()
        elif isCurrentTokenKind(TokenKind.WhenKeyword):
            return whenThenExpression()
        elif isCurrentTokenKind(TokenKind.LoopKeyword):
            return loopWithExpression()
        elif isCurrentTokenKind(TokenKind.TryKeyword):
            return tryFixExpression()
        elif isCurrentTokenKind(TokenKind.Indent):
            return blockExpression()
        else:
            error(tokens[index].line, "Expected expression but got " & $tokens[index].tokenKind)
    
    proc unaryExpression(): Expression =
        if isCurrentTokenKind(TokenKind.Exclamation, TokenKind.Minus):
            let operator: Token = tokens[index]
            index.inc()
            let right: Expression = unaryExpression()
            return UnaryExpression(operator: operator, right: right)
            
        return primaryExpression()
    
    proc rangeExpression(): Expression =
        var startExpression = unaryExpression()
        if not isCurrentTokenKind(TokenKind.Underscore, TokenKind.UnderscoreLessThan):
            return startExpression
        
        let operator: Token = tokens[index]
        index.inc()
        let stopExpression = unaryExpression()
        var stepExpression: Expression = LiteralExpression(value: NumericLiteral(value: 1.0))
        
        if isCurrentTokenKind(TokenKind.Underscore):
            index.inc()
            stepExpression = unaryExpression()
        
        return RangeExpression(start: startExpression, stop: stopExpression, step: stepExpression, operator: operator)

    
    proc multiplicationAndDivisionExpression(): Expression =
        var expression: Expression = rangeExpression()
        
        while isCurrentTokenKind(TokenKind.Asterisk, TokenKind.Slash):  
            let operator: Token = tokens[index]
            index.inc()
            let right: Expression = rangeExpression()
            expression = BinaryExpression(left: expression, operator: operator, right: right)
        
        return expression
    
    
    proc additionAndSubstractionExpression(): Expression =
        var expression: Expression = multiplicationAndDivisionExpression()

        while isCurrentTokenKind(TokenKind.Plus, TokenKind.Minus):
            let operator: Token = tokens[index]
            index.inc()
            let right: Expression = multiplicationAndDivisionExpression()
            expression = BinaryExpression(left: expression, operator: operator, right: right)
        
        return expression
    
    
    proc comparisonExpression(): Expression =
        var expression: Expression = additionAndSubstractionExpression()
        
        while isCurrentTokenKind(TokenKind.MoreThan, TokenKind.LessThan, TokenKind.ExclamationMoreThan, TokenKind.ExclamationLessThan):
            let operator: Token = tokens[index]
            index.inc()
            let right: Expression = additionAndSubstractionExpression()
            expression = BinaryExpression(left: expression, operator: operator, right: right)

        return expression
    
    
    proc equalityAndInequalityExpression(): Expression =
        var expression: Expression = comparisonExpression()
        
        while isCurrentTokenKind(TokenKind.Equal, TokenKind.ExclamationEqual):
            let operator: Token = tokens[index]
            index.inc()
            let right: Expression = comparisonExpression()
            expression = BinaryExpression(left: expression, operator: operator, right: right)

        return expression

    
    proc expression(): Expression =
        return equalityAndInequalityExpression()


    proc expressionStatement(): Statement =
        result = ExpressionStatement(expression: expression())
        expect(TokenKind.Newline, TokenKind.Dedent, TokenKind.EndOfFile)
        ignore(TokenKind.Newline)
    
    proc containerStatement(): Statement =
        if isThisExpressionStatement2(): return expressionStatement()
        echo 56
        let identifier: Token = tokens[index]
        index.inc()
        
        var parameters: seq[string]
        while isCurrentTokenKind(TokenKind.Identifier):
            parameters.add(tokens[index].lexeme)
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

    
    proc whenThenStatement(): Statement =
        if isThisExpressionStatement(): return expressionStatement()
        
        index.inc()
        var whenThenSubStatements: seq[WhenThenSubStatement] = @[]
        
        let firstCondition: Expression = expression()
        
        expect(TokenKind.Indent)
        let firstBlock: BlockExpression = blockExpression()
        whenThenSubStatements.add(WhenThenSubStatement(condition: firstCondition, `block`: firstBlock))
    
        while isCurrentTokenKind(TokenKind.ThenKeyword):
            index.inc()
            var condition: Expression = nil
            if not isCurrentTokenKind(TokenKind.Indent):
                condition = expression()
            let `block`: BlockExpression = blockExpression()
            whenThenSubStatements.add(WhenThenSubStatement(condition: condition, `block`: `block`))

        return WhenThenStatement(whenThenSubStatements: whenThenSubStatements)
        
    
    proc loopWithStatement(): Statement =
        if isThisExpressionStatement(): return expressionStatement()
        
        index.inc()
        var loopWithSubStatements: seq[LoopWithSubStatement] = @[]
        while isCurrentTokenExpressionStart():
            let iterable: Expression = expression()
            var counters: seq[string] = @[]
            if isCurrentTokenKind(TokenKind.WithKeyword):
                index.inc()
                expect(TokenKind.Identifier)
                while isCurrentTokenKind(TokenKind.Identifier):
                    counters.add(tokens[index].lexeme)
                    index.inc()
                    
            loopWithSubStatements.add(LoopWithSubStatement(iterable: iterable, counters: counters))
            if isCurrentTokenKind(TokenKind.Comma):
                index.inc()
            else:
                break
        
        expect(TokenKind.Indent)
        let `block` = blockExpression()
        return LoopWithStatement(loopWithSubStatements: loopWithSubStatements, `block`: `block`)


    proc tryFixStatement(): Statement =
        if isThisExpressionStatement(): return expressionStatement()
        
        index.inc()
        expect(TokenKind.Indent)
        let tryBlock: BlockExpression = blockExpression()
        
        var tryFixSubStatements: seq[TryFixSubStatement] = @[]
        
        while isCurrentTokenKind(TokenKind.FixKeyword):
            index.inc()
            var identifier: Token = nil
            if not isCurrentTokenKind(TokenKind.Indent):
                expect(TokenKind.Identifier)
                identifier = tokens[index]
            let fixBlock: BlockExpression = blockExpression()
            tryFixSubStatements.add(TryFixSubStatement(identifier: identifier, fixBlock: fixBlock))

        return TryFixStatement(tryBlock: tryBlock, tryFixSubStatements: tryFixSubStatements)

    
    
    proc statement(): Statement =
        if isCurrentTokenKind(TokenKind.Identifier):
            return containerStatement()
        elif isCurrentTokenKind(TokenKind.WhenKeyword):
            return whenThenStatement()
        elif isCurrentTokenKind(TokenKind.LoopKeyword):
            return loopWithStatement()
        elif isCurrentTokenKind(TokenKind.TryKeyword):
            return tryFixStatement()
        else:
            return expressionStatement()



    while not isAtEnd():
        abstractSyntaxTree.add(statement())
        
    
    return abstractSyntaxTree





##############################
# ANALYSER
##############################


proc analyser*(abstractSyntaxTree: Statements): Statements =
    var
        scopes: seq[HashSet[string]] = @[]
        currentFunction = "none"
        currentLoop = 0
        inWhenThen = false
        inTryFix = false
        inLoopWith = false


    proc beginScope() =
        scopes.add(initHashSet[string]())

    proc endScope() =
        discard scopes.pop()

    proc define(statement: ContainerStatement) =
        let name: string = statement.identifier.lexeme
        let line: int = statement.identifier.line

        if scopes.len == 0:
            return
        if name in scopes[^1]:
            error(line, "Variable '" & name & "' already declared in this scope")
        incl scopes[^1], name

    proc analyseLocal(expression: ContainerExpression) =
        let name: string = expression.identifier.lexeme
        let line: int = expression.identifier.line

        for i in countdown(scopes.high, 0):
            if name in scopes[i]:
                return
        error line, "Error: undefined variable '" & name & "'"


    proc analyseExpression(expression: Expression) =
        if expression of ContainerExpression:
            analyseLocal(ContainerExpression(expression))


    proc analyseStatement(statement: Statement) =
        if statement of ContainerStatement:
            define(ContainerStatement(statement))
        elif statement of ExpressionStatement:
            analyseExpression(ExpressionStatement(statement).expression)
        # Add more statement types as needed



    # Main resolution process
    for statement in abstractSyntaxTree:
        analyseStatement(statement)

    return abstractSyntaxTree



##############################
# TRANSFORMER
##############################

proc transformer*(abstractSyntaxTree: Statements): Statements =
    return abstractSyntaxTree



##############################
# GENERATOR
##############################


proc generator*(abstractSyntaxTree: Statements): string =
    return ""
    
    



##############################
# COMPILER
##############################


proc compiler*(input: string): string =
    return generator transformer analyser parser lexer input



when isMainModule:
    import os
    
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
        let 
            input = readFile(absInputPath)
            output = compiler(input)
        
        # Create output directory if it doesn't exist
        createDir(absOutputPath.parentDir)
        writeFile(absOutputPath, output)
        styledEcho(fgGreen, "Success: ", resetStyle, "Compiled ", fgBlue, absInputPath, 
                             resetStyle, " to ", fgMagenta, absOutputPath)
    except IOError as e:
        styledEcho(fgRed, "Error: ", resetStyle, e.msg)
        quit(1)
    except:
        styledEcho(fgRed, "Error: ", resetStyle, "Unexpected error during compilation")
        quit(1)


