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

    proc expect(tokenKinds: varargs[TokenKind]) =
        var matched = false
        for tokenKind in tokenKinds:
            if tokens[index].tokenKind == tokenKind:
                matched = true
                break
        if not matched:
            addDiagnostic("Expected one of " & $tokenKinds & " but got " & $tokens[index].tokenKind)
    
    proc expression(): Expression
    proc statement(): Statement
    
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
            
            if tokens[index].tokenKind == TokenKind.RightRoundBracket: 
                index.inc() 
            else:
                diagnostics.add(Diagnostic(diagnosticKind: DiagnosticKind.Parser, errorMessage: "Bro where is the `)` 🤔", line: tokens[index].line))
                echo "Parser synchronisation is not available currently"
                quit(1)
        elif isCurrentTokenKind(TokenKind.Indent):
            return blockExpression()
    
    proc unaryExpression(): Expression =
        if isCurrentTokenKind(TokenKind.Exclamation, TokenKind.Minus):
            let operator: Token = tokens[index]
            index.inc()
            let right: Expression = unaryExpression()
            return UnaryExpression(operator: operator, right: right)
            
        return primaryExpression()
    
    proc multiplicationAndDivisionExpression(): Expression =
        var expression: Expression = unaryExpression()
        
        while isCurrentTokenKind(TokenKind.Asterisk, TokenKind.Slash):  
            let operator: Token = tokens[index]
            index.inc()
            let right: Expression = unaryExpression()
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
    
    proc statement(): Statement =
        #if isCurrentTokenKind(TokenKind.Identifier):
        if isCurrentTokenKind(TokenKind.WhenKeyword):
            index.inc()
            var branches: seq[Branch] = @[]
        
            let firstCondition: Expression = expression()
            let firstBlock: BlockExpression = blockExpression()
            branches.add(Branch(condition: firstCondition, `block`: firstBlock))
        
            while isCurrentTokenKind(TokenKind.ThenKeyword):
                index.inc()
                var condition: Expression = nil
                if not isCurrentTokenKind(TokenKind.Indent):
                    condition = expression()
                let `block`: BlockExpression = blockExpression()
                branches.add(Branch(condition: condition, `block`: `block`))

            return WhenStatement(branches: branches)
        
        
        return expressionStatement()

    while not isAtEnd():
        add abstractSyntaxTree, statement()
    
    return ParserOutput(
        diagnostics: diagnostics,
        abstractSyntaxTree: abstractSyntaxTree
    )


