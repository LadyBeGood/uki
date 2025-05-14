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

    proc isCurrentTokenKind(tokenKinds: varargs[TokenKind]): bool =
        for tokenKind in tokenKinds:
            if tokens[index].tokenKind == tokenKind:
                return true
        return false


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
        elif isCurrentTokenKind(TokenKind.Identifier):
            result = AccessingExpression(identifier: tokens[index].lexeme)
            index.inc()
        elif isCurrentTokenKind(TokenKind.LeftRoundBracket):
            index.inc()            
            result = GroupingExpression(expression: expression())
            
            if tokens[index].tokenKind == TokenKind.RightRoundBracket: 
                index.inc() 
            else:
                diagnostics.add(Diagnostic(diagnosticKind: DiagnosticKind.Parser, errorMessage: "Bro where is the `)` 🤔", line: tokens[index].line))
                echo "Parser synchronisation is not available currently"
                quit(1)


 
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
        return ExpressionStatement(expression: expression())
    
    proc statement(): Statement =
        if isCurrentTokenKind(TokenKind.Identifier):
            var index2 = index
            let identifier = tokens[index2].lexeme
            index2.inc()
            var parameters: seq[string]
            
            while tokens[index2].tokenKind == TokenKind.Identifier:
                if tokens[index2].tokenKind == TokenKind.Comma:
                    index2.inc()
                elif tokens[index2].tokenKind == TokenKind.Identifier:
                    parameters.add(tokens[index2].lexeme)
                    index2.inc()
                else:
                    break
            
            if tokens[index2].tokenKind == TokenKind.Colon:
                index2.inc()
                index = index2
                let value = expression()
                return DeclarationStatement(identifier: identifier, parameters: parameters, value: value)
        
        return expressionStatement()

    while not isAtEnd():
        add abstractSyntaxTree, statement()
    
    return ParserOutput(
        diagnostics: diagnostics,
        abstractSyntaxTree: abstractSyntaxTree
    )



