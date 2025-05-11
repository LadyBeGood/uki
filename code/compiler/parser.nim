## Utkrisht - the Utkrisht programming language
## Copyright (C) 2025 Haha-jk
##
## This file is part of Utkrisht and is licensed under the AGPL-3.0-or-later.
## See the license.txt file in the root of this repository.

import types, strutils, ../utilities/debugging

proc parser*(lexerOutput: LexerOutput): ParserOutput =
    var index = 0
    var diagnostics: Diagnostics = lexerOutput.diagnostics
    var tokens: Tokens = lexerOutput.tokens
    var abstractSyntaxTree: Expressions

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
    
    
    proc primary(): Expression =
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
            echo 9
            index.inc()
            return LiteralExpression(value: NumericLiteral(value: parseFloat(tokens[index - 1].lexeme)))
        if isCurrentTokenKind(TokenKind.LeftRoundBracket):
            echo 15
            index.inc()            
            let expression: Expression = expression()
            echo 16
            if tokens[index].tokenKind == TokenKind.RightRoundBracket: 
                index.inc() 
                echo 17
            else:
                echo "error"
            echo 18
            return GroupingExpression(expression: expression)


 
    proc unary(): Expression =
        echo 7
        if isCurrentTokenKind(TokenKind.Exclamation, TokenKind.Minus):
            let operator: Token = tokens[index]
            index.inc()
            let right: Expression = unary()
            return UnaryExpression(operator: operator, right: right)
        echo 8
        return primary()
    
    proc factor(): Expression =
        echo 6
        var expression: Expression = unary()
        echo 10
        while isCurrentTokenKind(TokenKind.Asterisk, TokenKind.Slash):  
            let operator: Token = tokens[index]
            index.inc()
            let right: Expression = unary()
            expression = BinaryExpression(left: expression, operator: operator, right: right)
        echo 11
        return expression
    
    
    proc term(): Expression =
        echo 5
        var expression: Expression = factor()
        echo 12
        while isCurrentTokenKind(TokenKind.Plus, TokenKind.Minus):
            echo 13
            let operator: Token = tokens[index]
            index.inc()
            let right: Expression = factor()
            expression = BinaryExpression(left: expression, operator: operator, right: right)
    
        echo 19
        
        return expression
    
    
    proc comparison(): Expression =
        echo 4
        var expression: Expression = term()
        
        while isCurrentTokenKind(TokenKind.MoreThan, TokenKind.LessThan, TokenKind.ExclamationMoreThan, TokenKind.ExclamationLessThan):
            let operator: Token = tokens[index]
            index.inc()
            let right: Expression = term()
            expression = BinaryExpression(left: expression, operator: operator, right: right)
        echo 20
        return expression
    
    
    proc equality(): Expression =
        echo 3
        var expression: Expression = comparison()
        
        while isCurrentTokenKind(TokenKind.Equal, TokenKind.ExclamationEqual):
            let operator: Token = tokens[index]
            index.inc()
            let right: Expression = comparison()
            expression = BinaryExpression(left: expression, operator: operator, right: right)
        echo 21
        return expression
    
    proc expression(): Expression =
        echo 2
        return equality()
    

    while not isAtEnd():
        echo 1 
        add abstractSyntaxTree, expression()
        echo 14
    
    return ParserOutput(
        diagnostics: diagnostics,
        abstractSyntaxTree: abstractSyntaxTree
    )




when isMainModule:
    import lexer, json
    
    let input = readFile("./garbage/input.uki")
    let parsed = parser(lexer(input))
    echo pretty(%parsed, indent = 4)
    echo "=== AST Hierarchy ==="
    printAST(parsed)





