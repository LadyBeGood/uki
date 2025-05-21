## Utkrisht - the Utkrisht programming language
## Copyright (C) 2025 LadyBeGood
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
        let expr = LiteralExpression(expression)
        return literalGenerator(expr.value)

    elif expression of BinaryExpression:
        let expr = BinaryExpression(expression)
        let op = case expr.operator.lexeme
            of "!<": ">="
            of "!>": "<="
            of "=": "==="
            else: expr.operator.lexeme
        return "(" & expressionGenerator(expr.left) & " " & op & " " & expressionGenerator(expr.right) & ")"

    elif expression of UnaryExpression:
        let expr = UnaryExpression(expression)
        return expr.operator.lexeme & expressionGenerator(expr.right)

    elif expression of GroupingExpression:
        let expr = GroupingExpression(expression)
        return "(" & expressionGenerator(expr.expression) & ")"

    elif expression of ContainerExpression:
        let expr = ContainerExpression(expression)
        if expr.arguments.len() != 0:
            var args = ""
            for i, arg in expr.arguments:
                if i > 0:
                    args &= ", "
                args &= expressionGenerator(arg)
            return expr.identifier & "(" & args & ")"
        else:
            return expr.identifier

proc statementGenerator(statement: Statement): string =
    if statement of ContainerStatement:
        let statement: ContainerStatement = ContainerStatement(statement)
        return "let " & statement.identifier & " = " & expressionGenerator(statement.expression) & ";"
    elif statement of ExpressionStatement:
        let statement: ExpressionStatement = ExpressionStatement(statement)
        return expressionGenerator(statement.expression) & ";"
    elif statement of WhenThenStatement:
        let statement: WhenThenStatement = WhenThenStatement(statement)
        result = "if (" & expressionGenerator(statement.whenThenSubStatements[0].condition) & ") {\n"
        for s in statement.whenThenSubStatements[0].`block`.statements:
            result &= statementGenerator(s) & "\n"
        result &= "}"
        for i in 1 ..< statement.whenThenSubStatements.len():
            let clause = statement.whenThenSubStatements[i]
            result &= " else"
            if clause.condition != nil:
                result &= " if (" & expressionGenerator(clause.condition) & ")"
            result &= " {\n"
            for s in clause.`block`.statements:
                result &= statementGenerator(s) & "\n"
            result &= "}"
    
    elif statement of LoopWithStatement:
        #let statement: LoopStatement = LoopStatement(statement)
        return "LOOP"
        


proc generator*(abstractSyntaxTree: Statements): string =
    var output: string = ""

    for statement in abstractSyntaxTree:
        output &= statementGenerator(statement)
    
    return output







