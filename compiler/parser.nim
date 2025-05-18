## Utkrisht - the Utkrisht programming language
## Copyright (C) 2025 LadyBeGood
##
## This file is part of Utkrisht and is licensed under the AGPL-3.0-or-later.
## See the license.txt file in the root of this repository.

import types, strutils

proc parser*(lexerOutput: LexerOutput): ParserOutput =
    var index = 0
    var diagnostics: Diagnostics = lexerOutput.diagnostics
    var tokens: Tokens = lexerOutput.tokens
    var abstractSyntaxTree: Statements

    proc isAtEnd(): bool =
        return tokens[index].tokenKind == EndOfFile

    proc addDiagnostic(errorMessage: string) =
        add diagnostics, Diagnostic(diagnosticKind: DiagnosticKind.Parser, errorMessage: errorMessage, line: tokens[index].line)
    

    
    proc isCurrentTokenKind(tokenKinds: varargs[TokenKind]): bool =
        for tokenKind in tokenKinds:
            if tokens[index].tokenKind == tokenKind:
                return true
        return false
    
    proc synchronize() =
        while not isAtEnd():
            case tokens[index].tokenKind
            of TokenKind.Newline, TokenKind.Indent, TokenKind.Dedent,
               TokenKind.WhenKeyword, TokenKind.LoopKeyword:
                return
            else:
                index.inc()
    
    proc expect(tokenKinds: varargs[TokenKind]) =
        for tokenKind in tokenKinds:
            if tokens[index].tokenKind == tokenKind:
                return
        addDiagnostic("Expected one of " & $tokenKinds & " but got " & $tokens[index].tokenKind)
        raise newException(ParserError, "")
    
    
    proc expression(): Expression
    proc statement(): Statement
    
    proc blockExpression(): BlockExpression =
        index.inc()            
        var statements: Statements = @[]
        
        while not isAtEnd() and not isCurrentTokenKind(TokenKind.Dedent):
            let statement: Statement = statement()
            if statement == nil:
                synchronize()
            else:
                statements.add(statement)
        
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
        elif isCurrentTokenKind(TokenKind.Identifier):
            let identifier: string = tokens[index].lexeme
            index.inc()
            var arguments: seq[Expression] = @[]
            
            while isCurrentTokenKind(TokenKind.NumericLiteral, TokenKind.StringLiteral, TokenKind.RightKeyword, TokenKind.WrongKeyword, TokenKind.Identifier, TokenKind.LeftRoundBracket):
                arguments.add(expression())
                if isCurrentTokenKind(TokenKind.Comma): 
                    index.inc()
                else:
                    break
                
            result = AccessingExpression(identifier: identifier, arguments: arguments)
        elif isCurrentTokenKind(TokenKind.LeftRoundBracket):
            index.inc()            
            result = GroupingExpression(expression: expression())
            expect(TokenKind.RightRoundBracket)
            index.inc()
        
        elif isCurrentTokenKind(TokenKind.Indent):
            return blockExpression()
    
    
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
    
    proc expression(): Expression =
        return equalityAndInequalityExpression()
    
    proc expressionStatement(): Statement =
        result = ExpressionStatement(expression: expression())
        expect(TokenKind.Newline, TokenKind.Dedent, TokenKind.EndOfFile)
        if isCurrentTokenKind(TokenKind.Newline): 
            index.inc()
    
    proc whenStatement(): Statement =
        index.inc()
        var clauses: seq[WhenClause] = @[]
    
        let firstCondition: Expression = expression()
        let firstBlock: BlockExpression = blockExpression()
        clauses.add(WhenClause(condition: firstCondition, `block`: firstBlock))
    
        while isCurrentTokenKind(TokenKind.ThenKeyword):
            index.inc()
            var condition: Expression = nil
            if not isCurrentTokenKind(TokenKind.Indent):
                condition = expression()
            let `block`: BlockExpression = blockExpression()
            clauses.add(WhenClause(condition: condition, `block`: `block`))

        return WhenStatement(clauses: clauses)
        
    
    proc loopStatement(): Statement =
        echo index # 0
        index.inc()
        var clauses: seq[LoopClause] = @[]
        while true:
            let iterable: Expression = expression()
            var counters: seq[string] = @[]
            if isCurrentTokenKind(TokenKind.WithKeyword):
                index.inc()
                expect(TokenKind.Identifier)
                while isCurrentTokenKind(TokenKind.Identifier):
                    counters.add(tokens[index].lexeme)
                    index.inc()
                    
            clauses.add(LoopClause(iterable: iterable, counters: counters))
            echo index # 4
            if isCurrentTokenKind(TokenKind.Comma):
                index.inc()
                expect(TokenKind.NumericLiteral, TokenKind.Identifier, TokenKind.StringLiteral)
            else:
                break
        
        expect(TokenKind.Indent)
        let `block` = blockExpression()
        return LoopStatement(clauses: clauses, `block`: `block`)
        
    
    
    proc statement(): Statement =
        try:
            if isCurrentTokenKind(TokenKind.WhenKeyword):
                return whenStatement()
            elif isCurrentTokenKind(TokenKind.LoopKeyword):
                return loopStatement()
            else:
                return expressionStatement()
        except ParserError:
            synchronize()


    while not isAtEnd():
        abstractSyntaxTree.add(statement())
        
    
    return ParserOutput(
        diagnostics: diagnostics,
        abstractSyntaxTree: abstractSyntaxTree
    )






