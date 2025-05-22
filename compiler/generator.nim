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
        let expression = LiteralExpression(expression)
        return literalGenerator(expression.value)

    elif expression of BinaryExpression:
        let expression = BinaryExpression(expression)
        let operator = case expression.operator.lexeme
            of "!<": ">="
            of "!>": "<="
            of "=": "==="
            else: expression.operator.lexeme
        return "(" & expressionGenerator(expression.left) & " " & operator & " " & expressionGenerator(expression.right) & ")"

    elif expression of UnaryExpression:
        let expression = UnaryExpression(expression)
        return expression.operator.lexeme & expressionGenerator(expression.right)

    elif expression of GroupingExpression:
        let expression = GroupingExpression(expression)
        return "(" & expressionGenerator(expression.expression) & ")"

    elif expression of ContainerExpression:
        let expression = ContainerExpression(expression)
        if expression.arguments.len() != 0:
            var args = ""
            for i, arg in expression.arguments:
                if i > 0:
                    args &= ", "
                args &= expressionGenerator(arg)
            return expression.identifier & "(" & args & ")"
        else:
            return expression.identifier
    elif expression of WhenThenExpression:
        let expression = WhenThenExpression(expression)
        var output = "(() => {"
        for i, subExpression in expression.whenThenSubExpressions:
            let condition = subExpression.condition
            let expression = expressionGenerator(subExpression.expression)
            if condition.isNil:
                output &= "else return " & expression & ";"
            else:
                let conditionCode = expressionGenerator(condition)
                if i == 0:
                    output &= "if (" & conditionCode & ") return " & expression & ";"
                else:
                    output &= "else if (" & conditionCode & ") return " & expression & ";"
        output &= "})()"
        return output


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







