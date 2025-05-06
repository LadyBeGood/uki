## Utkrisht - the Utkrisht programming language
## Copyright (C) 2025 Haha-jk
##
## This file is part of Utkrisht and is licensed under the AGPL-3.0-or-later.
## See the license.txt file in the root of this repository.


import ast
import sequtils, strutils

proc generateExpr(expr: Expr): string =
    case expr.kind
    of ExprKind.Number: $expr.numVal
    of ExprKind.String: "\"" & expr.strVal & "\""
    of ExprKind.Boolean: $expr.boolVal
    of ExprKind.Null: "null"
    of ExprKind.Identifier: expr.identName
    of ExprKind.Binary:
        "(" & generateExpr(expr.left) & " " & expr.binaryOp.lexeme & " " & generateExpr(expr.right) & ")"
    of ExprKind.Unary:
        expr.unaryOp.lexeme & generateExpr(expr.operand)
    of ExprKind.Grouping:
        "(" & generateExpr(expr.grouped) & ")"
    of ExprKind.Call:
        generateExpr(expr.callee) & "(" & expr.args.map(generateExpr).join(", ") & ")"
    of ExprKind.Assign:
        expr.assignTo & " = " & generateExpr(expr.value)

proc generateStmt(stmt: Stmt): string =
    case stmt.kind
    of StmtKind.PrintStmt: "console.log(" & generateExpr(stmt.printExpr) & ");"
    of StmtKind.ExprStmt: generateExpr(stmt.expr) & ";"
    of StmtKind.VarDecl:
        "let " & stmt.varName & 
        (if stmt.varInit != nil: " = " & generateExpr(stmt.varInit) else: "") & ";"
    of StmtKind.Block: "{\n" & stmt.statements.map(generateStmt).join("\n") & "\n}"
    of StmtKind.IfStmt:
        "if (" & generateExpr(stmt.condition) & ") " & generateStmt(stmt.thenBranch) &
        (if stmt.elseBranch != nil: " else " & generateStmt(stmt.elseBranch) else: "")
    of StmtKind.WhileStmt:
        "while (" & generateExpr(stmt.whileCond) & ") " & generateStmt(stmt.whileBody)
    of StmtKind.FuncDecl:
        "function " & stmt.funcName & "(" & stmt.params.join(", ") & ") " & generateStmt(stmt.body)
    of StmtKind.ReturnStmt:
        "return" & (if stmt.returnVal != nil: " " & generateExpr(stmt.returnVal) else: "") & ";"

proc generate*(stmts: seq[Stmt]): string =
    stmts.map(generateStmt).join("\n")