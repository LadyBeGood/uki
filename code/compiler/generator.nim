## Utkrisht - the Utkrisht programming language
## Copyright (C) 2025 Haha-jk
##
## This file is part of Utkrisht and is licensed under the AGPL-3.0-or-later.
## See the license.txt file in the root of this repository.


import types

proc literalGenerator(literal: Literal): string =
    if literal of NumericLiteral:
        let literal: NumericLiteral = NumericLiteral(literal)
        return $literal.value
    elif literal of StringLiteral: 
        let literal: StringLiteral = StringLiteral(literal)
        return "\"" & literal.value & "\""
    elif literal of BooleanLiteral: 
        let literal: BooleanLiteral = BooleanLiteral(literal)
        return $literal.value

proc expressionGenerator(expression: Expression): string =
    if expression of LiteralExpression:
        let expression: LiteralExpression = LiteralExpression(expression)
        return literalGenerator(expression.value)
    elif expression of BinaryExpression:
        let expression: BinaryExpression = BinaryExpression(expression)
        return "(" & expressionGenerator(expression.left) & " " & (
            case expression.operator.lexeme
            of "!<": ">="
            of "!>": "<="
            of "=": "==="
            else: expression.operator.lexeme
        ) & " " & expressionGenerator(expression.right) & ")"
    elif expression of UnaryExpression:
        let expression: UnaryExpression = UnaryExpression(expression)
        return expression.operator.lexeme & expressionGenerator(expression.right)
    elif expression of GroupingExpression:
        let expression: GroupingExpression = GroupingExpression(expression)
        return "(" & expressionGenerator(expression.expression) & ")"


proc statementGenerator(statement: Statement): string =
    if statement of ExpressionStatement:
        let statement: ExpressionStatement = ExpressionStatement(statement)
        return expressionGenerator(statement.expression)


proc generator*(parserOutput: ParserOutput): string =
    var output: string = ""
    let abstractSyntaxTree: Statements = parserOutput.abstractSyntaxTree
    
    for statement in abstractSyntaxTree:
        output &= statementGenerator(statement)
    
    return output






