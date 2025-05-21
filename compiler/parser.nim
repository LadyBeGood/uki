## Utkrisht - the Utkrisht programming language
## Copyright (C) 2025 LadyBeGood
##
## This file is part of Utkrisht and is licensed under the AGPL-3.0-or-later.
## See the license.txt file in the root of this repository.

import types, strutils, error

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
    
    proc expression(): Expression
    proc statement(): Statement
    
    
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
        if not isCurrentTokenKind(TokenKind.Underscore):
            return startExpression
    
        index.inc()
        let stopExpression = unaryExpression()
    
        if isCurrentTokenKind(TokenKind.Underscore):
            index.inc()
            let stepExpression = unaryExpression()
            return RangeExpression(start: startExpression, stop: stopExpression, step: stepExpression, rangeType: "inclusive")
        elif isCurrentTokenKind(TokenKind.UnderscoreLessThan):
            index.inc()
            let stepExpression = unaryExpression()
            return RangeExpression(start: startExpression, stop: stopExpression, step: stepExpression, rangeType: "exclusive")
        else:
            return RangeExpression(
                start: startExpression, 
                stop: stopExpression, 
                step: LiteralExpression(value: NumericLiteral(value: 1.0)),
                rangeType: "inclusive"
            )
    
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
    
    proc containerExpression(): Expression =
        let identifier: string = tokens[index].lexeme
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
        index.inc()
        var whenThenSubExpressions: seq[WhenThenSubExpression] = @[]
        
        let firstCondition: Expression = expression()
        
        expect(TokenKind.Colon)
        ignore(TokenKind.Indent)
        
        let firstExpression: Expression = expression()
        whenThenSubExpressions.add(WhenThenSubExpression(condition: firstCondition, expression: firstExpression))
    
        while isCurrentTokenKind(TokenKind.ThenKeyword):
            index.inc()
            var condition: Expression = nil
            if not isCurrentTokenKind(TokenKind.Colon):
                condition = expression()
            let expression: Expression = expression()
            whenThenSubExpressions.add(WhenThenSubExpression(condition: condition, expression: expression))

        return WhenThenExpression(whenThenSubExpressions: whenThenSubExpressions)
        
    
    proc loopExpression(): Expression =
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
        ignore(TokenKind.Indent)
        let expression: Expression = expression()
        return LoopWithExpression(loopWithSubExpressions: loopWithSubExpressions, expression: expression)


    proc tryExpression(): Expression =
        index.inc()
        expect(TokenKind.Colon)
        ignore(TokenKind.Indent)
        
        let tryExpression: Expression = expression()
        
        var tryFixSubExpressions: seq[TryFixSubExpression] = @[]
        
        while isCurrentTokenKind(TokenKind.FixKeyword):
            index.inc()
            var identifier: string = ""
            if not isCurrentTokenKind(TokenKind.Colon):
                expect(TokenKind.Identifier)
                identifier = tokens[index].lexeme
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

    
    
    
    
    proc expression(): Expression =
        if isCurrentTokenKind(TokenKind.Identifier):
            return containerExpression()
        elif isCurrentTokenKind(TokenKind.WhenKeyword):
            return whenExpression()
        elif isCurrentTokenKind(TokenKind.LoopKeyword):
            return loopExpression()
        elif isCurrentTokenKind(TokenKind.TryKeyword):
            return tryExpression()
        elif isCurrentTokenKind(TokenKind.Indent):
            return blockExpression()
        else:
            return equalityAndInequalityExpression()


    proc expressionStatement(): Statement =
        result = ExpressionStatement(expression: expression())
        expect(TokenKind.Newline, TokenKind.Dedent, TokenKind.EndOfFile)
        if isCurrentTokenKind(TokenKind.Newline): 
            index.inc()
    
    proc containerStatement(): Statement =
        let identifier: string = tokens[index].lexeme
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
        
        return ContainerStatement(identifier: identifier, parameters: parameters, expression: expression)

    
    proc whenStatement(): Statement =
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
        
    
    proc loopStatement(): Statement =
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
        index.inc()
        expect(TokenKind.Indent)
        let tryBlock: BlockExpression = blockExpression()
        
        var tryFixSubStatements: seq[TryFixSubStatement] = @[]
        
        while isCurrentTokenKind(TokenKind.FixKeyword):
            index.inc()
            var identifier: string = ""
            if not isCurrentTokenKind(TokenKind.Indent):
                expect(TokenKind.Identifier)
                identifier = tokens[index].lexeme
            let fixBlock: BlockExpression = blockExpression()
            tryFixSubStatements.add(TryFixSubStatement(identifier: identifier, fixBlock: fixBlock))

        return TryFixStatement(tryBlock: tryBlock, tryFixSubStatements: tryFixSubStatements)

    
    
    proc statement(): Statement =
        if isCurrentTokenKind(TokenKind.Identifier):
            return containerStatement()
        elif isCurrentTokenKind(TokenKind.WhenKeyword):
            return whenStatement()
        elif isCurrentTokenKind(TokenKind.LoopKeyword):
            return loopStatement()
        elif isCurrentTokenKind(TokenKind.TryKeyword):
            return tryFixStatement()
        else:
            return expressionStatement()



    while not isAtEnd():
        abstractSyntaxTree.add(statement())
        
    
    return abstractSyntaxTree






