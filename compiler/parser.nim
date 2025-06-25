import types, error, sets, strutils

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
        
        var arguments: seq[Argument]
        
        while true:
            if isCurrentTokenExpressionStart():
                arguments.add(Argument(identifier: nil, value: expression()))
            elif isCurrentTokenKind(TokenKind.Identifier) and tokens[index + 1].tokenKind == TokenKind.Tilde:
                let identifier = tokens[index]
                index.inc(2)
                let value = expression()
                arguments.add(Argument(identifier: identifier, value: value))
            
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
    
    
    proc containerAssignmentStatement(): Statement =
        # ContainerAssignmentStatement* = ref object of Statement
        #     identifier*: Token
        #     parameters*: seq[Parameter]
        #     expression*: Expression
        # 
        # Parameter* = ref object
        #     identifier*: Token
        #     defaultValue*: Expression
        
        if isThisExpressionStatement2(): return expressionStatement()
        let identifier: Token = tokens[index]
        index.inc()
        
        var parameters: seq[Parameter]
        while isCurrentTokenKind(TokenKind.Identifier):
            let identifier: Token = tokens[index]
            index.inc()
            var defaultValue: Expression = nil
            
            if isCurrentTokenKind(TokenKind.Tilde):
                index.inc()
                defaultValue = expression()
            
            parameters.add(Parameter(identifier: identifier, defaultValue: defaultValue))
            
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
        return ContainerAssignmentStatement(identifier: identifier, parameters: parameters, expression: expression)

    
    proc containerReassignmentStatement(): Statement =
        # ContainerReassignmentStatement* = ref object of Statement
        #     identifier*: Token
        #     expression*: Expression
        
        let identifier: Token = tokens[index]
        index.inc()
        
        expect(TokenKind.Equal)
        index.inc()
        
        let expression: Expression = expression()
        ignore(TokenKind.Newline)
        return ContainerReassignmentStatement(identifier: identifier, expression: expression)
        
    
    
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
            if tokens[index + 1].tokenKind == TokenKind.Equal: 
                return containerReassignmentStatement()
            else:
                return containerAssignmentStatement()
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




when isMainModule:
    import lexer, debug, cli

    proc parserToString(input: string): string =
        return astToString parser lexer input
    
    run(parserToString)



