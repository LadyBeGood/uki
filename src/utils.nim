import strformat, strutils, sequtils, types

proc printAst*(ast: Expression, indentLevel: int = 0): string
proc printAst*(ast: Statement, indentLevel: int = 0): string

# Helper function to create indentation
proc indent(level: int): string =
    return "    ".repeat(level)

# Helper function to print Object
proc printObject(obj: Object, indentLevel: int): string =
    if obj of BooleanObject:
        return fmt"{indent(indentLevel)}BooleanObject(data: {BooleanObject(obj).data})"
    elif obj of NumberObject:
        return fmt"{indent(indentLevel)}NumberObject(data: {NumberObject(obj).data})"
    elif obj of StringObject:
        return &"{indent(indentLevel)}StringObject(data: \"{StringObject(obj).data}\")"
    else:
        return fmt"{indent(indentLevel)}Unknown Object"

proc printAst*(ast: Expression, indentLevel: int = 0): string =
    if ast of BinaryExpression:
        let binExpr = BinaryExpression(ast)
        return fmt"""
{indent(indentLevel)}BinaryExpression:
{indent(indentLevel)}    left: {printAst(binExpr.left, indentLevel + 1)}
{indent(indentLevel)}    operator: {binExpr.operator.lexeme}
{indent(indentLevel)}    right: {printAst(binExpr.right, indentLevel + 1)}"""
    elif ast of FunctionExpression:
        let funcExpr = FunctionExpression(ast)
        return fmt"""
{indent(indentLevel)}FunctionExpression:
{indent(indentLevel)}    functionIdentifier: {funcExpr.functionIdentifier}
{indent(indentLevel)}    arguments: [
{funcExpr.arguments.map(proc (x: Expression): string = printAst(x, indentLevel + 2)).join(",\n")}
{indent(indentLevel)}  ]"""
    elif ast of VariableExpression:
        let varExpr = VariableExpression(ast)
        return fmt"{indent(indentLevel)}VariableExpression(variableIdentifier: {varExpr.variableIdentifier})"
    elif ast of GroupingExpression:
        let groupExpr = GroupingExpression(ast)
        return fmt"""
{indent(indentLevel)}GroupingExpression:
{indent(indentLevel)}    expression: {printAst(groupExpr.Expression, indentLevel + 1)}"""
    elif ast of LiteralExpression:
        let litExpr = LiteralExpression(ast)
        return fmt"""
{indent(indentLevel)}LiteralExpression:
{printObject(litExpr.value, indentLevel + 1)}"""
    elif ast of UnaryExpression:
        let unaryExpr = UnaryExpression(ast)
        return fmt"""
{indent(indentLevel)}UnaryExpression:
{indent(indentLevel)}    operator: {unaryExpr.operator.lexeme}
{indent(indentLevel)}    right: {printAst(unaryExpr.right, indentLevel + 1)}
"""
    else:
        return fmt"{indent(indentLevel)}Unknown Expression"

proc printAst*(ast: Statement, indentLevel: int = 0): string =
    if ast of VariableDeclarationStatement:
        let varDecl = VariableDeclarationStatement(ast)
        return fmt"""
{indent(indentLevel)}VariableDeclarationStatement:
{indent(indentLevel)}    variableIdentifier: {varDecl.variableIdentifier}
{indent(indentLevel)}    value: {printAst(varDecl.value, indentLevel + 1)}
"""
    elif ast of VariableReassignmentStatement:
        let varReassign = VariableReassignmentStatement(ast)
        return fmt"""
{indent(indentLevel)}VariableReassignmentStatement:
{indent(indentLevel)}    variableIdentifier: {varReassign.variableIdentifier}
{indent(indentLevel)}    value: {printAst(varReassign.value, indentLevel + 1)}"""
    elif ast of FunctionDeclarationStatement:
        let funcDecl = FunctionDeclarationStatement(ast)
        return fmt"""
{indent(indentLevel)}FunctionDeclarationStatement:
{indent(indentLevel)}    functionIdentifier: {funcDecl.functionIdentifier}
{indent(indentLevel)}    placeholder: {printAst(funcDecl.placeholder, indentLevel + 1)}"""
    elif ast of FunctionReassignmentStatement:
        let funcReassign = FunctionReassignmentStatement(ast)
        return fmt"""
{indent(indentLevel)}FunctionReassignmentStatement:
{indent(indentLevel)}    functionIdentifier: {funcReassign.functionIdentifier}
{indent(indentLevel)}    placeholder: {printAst(funcReassign.placeholder, indentLevel + 1)}"""
    elif ast of ExpressionStatement:
        let exprStmt = ExpressionStatement(ast)
        return fmt"""
{indent(indentLevel)}ExpressionStatement:
{indent(indentLevel)}    expression: {printAst(exprStmt.expression, indentLevel + 1)}"""
    elif ast of LoopStatement:
        let loopStmt = LoopStatement(ast)
        return fmt"""
{indent(indentLevel)}LoopStatement:
{indent(indentLevel)}    condition: printAst(loopStmt.condition, indentLevel + 1)
{indent(indentLevel)}    placeholder: {printAst(loopStmt.placeholder, indentLevel + 1)}"""
    elif ast of WhenStatement:
        let whenStmt = WhenStatement(ast)
        return fmt"""
{indent(indentLevel)}WhenStatement:
{indent(indentLevel)}    condition: {printAst(whenStmt.condition, indentLevel + 1)}
{indent(indentLevel)}    placeholder: {printAst(whenStmt.placeholder, indentLevel + 1)}
{indent(indentLevel)}    otherwise: {printAst(whenStmt.otherwise, indentLevel + 1)}"""
    elif ast of ControlStatement:
        let controlStmt = ControlStatement(ast)
        return fmt"""
{indent(indentLevel)}ControlStatement:
{indent(indentLevel)}    keyword: {controlStmt.keyword}
{indent(indentLevel)}    value: {printAst(controlStmt.value, indentLevel + 1)}"""
    elif ast of BlockStatement:
        let blockStmt = BlockStatement(ast)
        return fmt"""
{indent(indentLevel)}BlockStatement:
{indent(indentLevel)}    statements: [
{blockStmt.statements.map(proc (x: Statement): string = printAst(x, indentLevel + 2)).join(",\n")}
{indent(indentLevel)}  ]"""
    else:
        return fmt"{indent(indentLevel)}Unknown Statement"