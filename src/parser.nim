import lists, sequtils, strformat, std/strutils
import types


proc parser*(tokens: Tokens): Statements =
    var statements: Statements = @[]
    var index: int = 0


    proc isAtEnd(): bool =
        tokens[index].kind == EOF
    
    proc isCurrentTokenKind(tokenKind: TokenKind): bool =
        tokens[index].kind == tokenKind
    
    proc isNextTokenKind(tokenKind: TokenKind): bool =
        tokens[index + 1].kind == tokenKind
    
    proc isPreviousTokenKind(tokenKind: TokenKind): bool =
        tokens[index - 1].kind == tokenKind
    
    proc error(message: string) =
        echo fmt"[{tokens[index].line}] {message}"
        quit(1)
        
    proc discardTillTokenKind(tokenKind: TokenKind) =
        while not isCurrentTokenKind(tokenKind):
            if isAtEnd():
                error("Couldn't find " & $tokenKind)
            index.inc()
    
    proc checkCurrentToken(tokenKind: TokenKind) =
        if not isCurrentTokenKind(tokenKind):
            error(fmt"Couldn't find {tokenKind}")
    
    proc statement(): Statement
    proc declaration(): Statement
    proc expression(): Expression
    
    
    
    proc primary(): Expression =
        # string | number | boolean | identifier
        
        if isCurrentTokenKind(Right):
            return LiteralExpression(value: BooleanObject(data: true))
        elif isCurrentTokenKind(Wrong):
            return LiteralExpression(value: BooleanObject(data: false))
        elif isCurrentTokenKind(Number):
            return LiteralExpression(value: NumberObject(data: parseFloat(tokens[index].lexeme)))
        elif isCurrentTokenKind(String):
            return LiteralExpression(value: StringObject(data: tokens[index].lexeme))
        #[
        elif isCurrentTokenKind(VariableIdentifier):
            return Variable(tokens[index].value)
        elif isCurrentTokenKind(FunctionIdentifier):
            return Function(tokens[index].value)
        ]#
        else:
            error("Expected expression."& "\n" & $tokens[index] & "\n" & $index)

    
    proc unary(): Expression =
        return primary()
    
    
    proc factor(): Expression =
        return unary()
    
    proc term(): Expression =
        # factor (("+" | "-") factor)*
        result = factor()
        while isNextTokenKind(Plus) or isNextTokenKind(Minus):
            let operator = tokens[index]
            let right = factor()
        
            result = BinaryExpression(left: result, operator: operator, right: right)
            index.inc()

    proc logicAnd(): Expression =
        return term()
    
    proc logicOr(): Expression =
        return logicAnd()
   
    proc expression(): Expression =        
        return logicOr()
    
    proc expressionStatement(): Statement =
        # expression newline
        result = ExpressionStatement(expression: expression())
        while isCurrentTokenKind(Newline):
            index.inc()
   
   
    proc aBlock(): Statement =
        checkCurrentToken(Newline)
        index.inc()
        var statements: Statements = @[]
        while not isCurrentTokenKind(Dedent):
            statements.add(declaration())
        index.inc()
        return BlockStatement(
            statements: statements
        )
        
    proc controlStatement(): Statement = 
        let kind: TokenKind = tokens[index].kind
        index.inc()
        if isCurrentTokenKind(Newline):
            return ControlStatement(
                kind: kind,
                value: nil
            )
        return ControlStatement(
            kind: kind,
            value: expression()
        )
    
    proc statement(): Statement =
        # expression-statement |
        # loop-statement       |
        # when-statement       |
        # exit-statement       |
        # block
        #[
        if isCurrentTokenKind(Loop):
            return loopStatement()
        elif isCurrentTokenKind(When):
            return whenStatement()
        elif isCurrentTokenKind(Exit) or isCurrentTokenKind(Quit) or isCurrentTokenKind(Skip):
            return controlStatement()
        elif isCurrentTokenKind(Indent):
            return aBlock()
        else: ]#
        return expressionStatement()
    
    
    proc variableDeclaration(): Statement =
        let variableIdentifier = tokens[index].lexeme
        index.inc()
        checkCurrentToken(Colon)
        index.inc()
        result = VariableDeclarationStatement(
            variableIdentifier: variableIdentifier,
            value: expression()
        )
        index.inc()
        if not (isCurrentTokenKind(Newline) or isCurrentTokenKind(EOF)):
            error("Expected Newline or EOF")
        elif isCurrentTokenKind(Newline):
            index.inc()
    
    proc functionDeclaration(): Statement =
        let functionIdentifier: string = tokens[index].lexeme
        index.inc()
        var parameters: FunctionParameters = @[]
        while isCurrentTokenKind(VariableIdentifier):
            let name: string = tokens[index].lexeme
            index.inc()
            if isCurrentTokenKind(Equal):
                index.inc()
                parameters.add(FunctionParameter(
                    name: name,
                    default: expression()
                ))
            else:
                parameters.add(FunctionParameter(
                    name: name,
                    default: nil
                ))
            if isCurrentTokenKind(Comma):
                index.inc()
                checkCurrentToken(VariableIdentifier)
        checkCurrentToken(Colon)
        index.inc()
        checkCurrentToken(Newline)
        index.inc()
        return FunctionDeclarationStatement(
            functionIdentifier: functionIdentifier,
            parameters: parameters,
            body: aBlock()
        )

    proc functionReassignment(): Statement =
        let functionIdentifier: string = tokens[index].lexeme
        index.inc()
        checkCurrentToken(Equal)
        index.inc()
        return FunctionReassignmentStatement(
            functionIdentifier: functionIdentifier,
            body: aBlock()
        )
        
    proc variableCall(): Statement =
        return expressionStatement()
        
    proc function(): Statement =
        let initialIndex: int = index
        while not isAtEnd() or not isCurrentTokenKind(Newline):
            index.inc()
        if isPreviousTokenKind(Colon):
            index = initialIndex
            return functionDeclaration()
        elif isPreviousTokenKind(Equal):
            index = initialIndex
            return functionReassignment()
        index = initialIndex
        # return functionCall()
    
    proc variable(): Statement =
        if isNextTokenKind(Colon):
            return variableDeclaration()
        #elif isNextTokenKind(Equal):
            # return variableAssignment()
        # return variableCall()
    
    proc declaration(): Statement =
        # function-declaration | 
        # variable-declaration |
        # statement

        if isCurrentTokenKind(FunctionIdentifier): # this might not be true
            return function()
        elif isCurrentTokenKind(VariableIdentifier): # nor this
            return variable()
        else: 
            return statement()
        

    while not isAtEnd():
        statements.add(declaration())

    return statements










