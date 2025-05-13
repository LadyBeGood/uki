## Utkrisht - the Utkrisht programming language
## Copyright (C) 2025 Haha-jk
##
## This file is part of Utkrisht and is licensed under the AGPL-3.0-or-later.
## See the license.txt file in the root of this repository.

import types, strutils, utilities/debugging

proc parser*(lexerOutput: LexerOutput): ParserOutput =
    var index = 0
    var diagnostics: Diagnostics = lexerOutput.diagnostics
    var tokens: Tokens = lexerOutput.tokens
    var abstractSyntaxTree: Statements

    proc isAtEnd(): bool =
        return tokens[index].tokenKind == EndOfFile

    proc isCurrentTokenKind(tokenKinds: varargs[TokenKind]): bool =
        if isAtEnd(): 
            return false
        for tokenKind in tokenKinds:
            if tokens[index].tokenKind == tokenKind:
                return true
        return false


    proc expression(): Expression
    proc statement(): Statement
    
    
    proc primaryExpression(): Expression =
        if isCurrentTokenKind(TokenKind.RightKeyword):
            index.inc()            
            return LiteralExpression(value: BooleanLiteral(value: true))
        if isCurrentTokenKind(TokenKind.WrongKeyword):
            index.inc()            
            return LiteralExpression(value: BooleanLiteral(value: false))
        if isCurrentTokenKind(TokenKind.StringLiteral):
            index.inc()            
            return LiteralExpression(value: StringLiteral(value: tokens[index].lexeme))
        if isCurrentTokenKind(TokenKind.NumericLiteral):
            index.inc()
            return LiteralExpression(value: NumericLiteral(value: parseFloat(tokens[index - 1].lexeme)))
        if isCurrentTokenKind(TokenKind.LeftRoundBracket):
            index.inc()            
            let expression: Expression = expression()
            if tokens[index].tokenKind == TokenKind.RightRoundBracket: 
                index.inc() 
            else:
                diagnostics.add(Diagnostic(diagnosticKind: DiagnosticKind.Parser, errorMessage: "Bro where is the `)` 🤔", line: tokens[index].line))
                echo "Parser synchronisation is not available currently"
                quit(1)
            return GroupingExpression(expression: expression)


 
    proc unaryExpression(): Expression =
        if isCurrentTokenKind(TokenKind.Exclamation, TokenKind.Minus):
            let operator: Token = tokens[index]
            index.inc()
            let right: Expression = unaryExpression()
            return UnaryExpression(operator: operator, right: right)
            
        return primaryExpression()
    
    proc factorExpression(): Expression =
        var expression: Expression = unaryExpression()
        
        while isCurrentTokenKind(TokenKind.Asterisk, TokenKind.Slash):  
            let operator: Token = tokens[index]
            index.inc()
            let right: Expression = unaryExpression()
            expression = BinaryExpression(left: expression, operator: operator, right: right)
        
        return expression
    
    
    proc termExpression(): Expression =
        var expression: Expression = factorExpression()

        while isCurrentTokenKind(TokenKind.Plus, TokenKind.Minus):
            let operator: Token = tokens[index]
            index.inc()
            let right: Expression = factorExpression()
            expression = BinaryExpression(left: expression, operator: operator, right: right)
        
        return expression
    
    
    proc comparisonExpression(): Expression =
        var expression: Expression = termExpression()
        
        while isCurrentTokenKind(TokenKind.MoreThan, TokenKind.LessThan, TokenKind.ExclamationMoreThan, TokenKind.ExclamationLessThan):
            let operator: Token = tokens[index]
            index.inc()
            let right: Expression = termExpression()
            expression = BinaryExpression(left: expression, operator: operator, right: right)

        return expression
    
    
    proc equalityExpression(): Expression =
        var expression: Expression = comparisonExpression()
        
        while isCurrentTokenKind(TokenKind.Equal, TokenKind.ExclamationEqual):
            let operator: Token = tokens[index]
            index.inc()
            let right: Expression = comparisonExpression()
            expression = BinaryExpression(left: expression, operator: operator, right: right)

        return expression
    
    proc expression(): Expression =
        return equalityExpression()
    
    proc expressionStatement(): Statement =
        return ExpressionStatement(expression: expression())
    
    proc statement(): Statement =
        return expressionStatement()

    while not isAtEnd():
        add abstractSyntaxTree, statement()
    
    return ParserOutput(
        diagnostics: diagnostics,
        abstractSyntaxTree: abstractSyntaxTree
    )



