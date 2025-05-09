## Utkrisht - the Utkrisht programming language
## Copyright (C) 2025 Haha-jk
##
## This file is part of Utkrisht and is licensed under the AGPL-3.0-or-later.
## See the license.txt file in the root of this repository.


import macros, ../compiler/types

macro shout*(args: varargs[untyped]): untyped =
    result = newStmtList()
    for arg in args:
        result.add(quote do:
            echo `arg`.astToStr, " = ", `arg`
        )



proc printAST*(parserOutput: ParserOutput) =
    let nodes: Expressions = parserOutput.abstractSyntaxTree
    proc printExpr(node: Expression): string =
        if node of BinaryExpression:
            let bin = BinaryExpression(node)
            return "(" & printExpr(bin.left) & " " & bin.operator.lexeme & " " & printExpr(bin.right) & ")"
        elif node of UnaryExpression:
            let un = UnaryExpression(node)
            return "(" & un.operator.lexeme & " " & printExpr(un.right) & ")"
        elif node of GroupingExpression:
            let group = GroupingExpression(node)
            return "(" & printExpr(group.expression) & ")"
        elif node of LiteralExpression:
            let lit = LiteralExpression(node)
            if lit.value of NumericLiteral:
                return $NumericLiteral(lit.value).value
            elif lit.value of StringLiteral:
                return "\"" & StringLiteral(lit.value).value & "\""
            elif lit.value of BooleanLiteral:
                return $BooleanLiteral(lit.value).value
            else:
                return "?"
        else:
            return "?"
    
    
    var accumulate: string = ""
    for node in nodes:
        accumulate.add printExpr(node) & "\n"
    
    # strip the first and last round brackets
    echo accumulate[1..^3]


