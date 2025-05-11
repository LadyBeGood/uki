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
        return "(" & expressionGenerator(expression.left) & " " & expression.operator.lexeme & " " & expressionGenerator(expression.right) & ")"
    elif expression of UnaryExpression:
        let expression: UnaryExpression = UnaryExpression(expression)
        return expression.operator.lexeme & expressionGenerator(expression.right)
    elif expression of GroupingExpression:
        let expression: GroupingExpression = GroupingExpression(expression)
        return "(" & expressionGenerator(expression.expression) & ")"



proc generator*(parserOutput: ParserOutput): string =
    var output: string = ""
    let abstractSyntaxTree: AbstractSyntaxTree = parserOutput.abstractSyntaxTree
    
    for expression in abstractSyntaxTree:
        output &= expressionGenerator(expression)
    
    return output




# proc generateStmt(stmt: Stmt): string =
#     case stmt.kind
#     of StmtKind.PrintStmt: "console.log(" & generateExpr(stmt.printExpr) & ");"
#     of StmtKind.ExprStmt: generateExpr(stmt.expr) & ";"
#     of StmtKind.VarDecl:
#         "let " & stmt.varName & 
#         (if stmt.varInit != nil: " = " & generateExpr(stmt.varInit) else: "") & ";"
#     of StmtKind.Block: "{\n" & stmt.statements.map(generateStmt).join("\n") & "\n}"
#     of StmtKind.IfStmt:
#         "if (" & generateExpr(stmt.condition) & ") " & generateStmt(stmt.thenBranch) &
#         (if stmt.elseBranch != nil: " else " & generateStmt(stmt.elseBranch) else: "")
#     of StmtKind.WhileStmt:
#         "while (" & generateExpr(stmt.whileCond) & ") " & generateStmt(stmt.whileBody)
#     of StmtKind.FuncDecl:
#         "function " & stmt.funcName & "(" & stmt.params.join(", ") & ") " & generateStmt(stmt.body)
#     of StmtKind.ReturnStmt:
#         "return" & (if stmt.returnVal != nil: " " & generateExpr(stmt.returnVal) else: "") & ";"


