## Utkrisht - the Utkrisht programming language
## Copyright (C) 2025 Haha-jk
##
## This file is part of Utkrisht and is licensed under the AGPL-3.0-or-later.
## See the license.txt file in the root of this repository.

import types, strutils

type
    ParserOutput* = object
        diagnostics: Diagnostics
        abstractSyntaxTree: seq[AstNode]    # Correctly define the abstract syntax tree

proc parser*(lexerOutput: LexerOutput): ParserOutput =
    var index = 0
    var diagnostics: Diagnostics = lexerOutput.diagnostics
    var abstractSyntaxTree: seq[AstNode]    # A sequence of AstNode objects

    let tokenStream = lexerOutput.tokens

    proc current(): Token =
        if index < tokenStream.len: tokenStream[index]
        else: tokenStream[^1]    # fallback to EOF

    proc advance() =
        if index < tokenStream.len: inc index

    proc match(kind: TokenKind): bool =
        if current().tokenKind == kind:
            advance()
            return true
        return false

    proc addDiagnostic(msg: string) =
        let line = current().line
        diagnostics.add Diagnostic(diagnosticKind: DiagnosticKind.Parser, errorMessage: msg, line: line)

    proc isAtEnd(): bool =
        current().tokenKind == TokenKind.EndOfFile

    proc expression(): AstNode

    proc factor(): AstNode =
        let token = current()
        if match(TokenKind.NumericLiteral):
            return AstNode(kind: NodeKind.NumberLiteral, value: token.lexeme)
        else:
            addDiagnostic("Expected number")
            advance()
            return AstNode(kind: NodeKind.Error)

    proc term(): AstNode =
        var node = factor()
        while current().kind == TokenKind.Star:
            let op = current()
            advance()
            let rhs = factor()
            node = AstNode(kind: NodeKind.Binary,
                                         left: node,
                                         operator: op,
                                         right: rhs)
        return node

    proc expression(): AstNode =
        var node = term()
        while current().kind == TokenKind.Plus:
            let op = current()
            advance()
            let rhs = term()
            node = AstNode(kind: NodeKind.Binary,
                                         left: node,
                                         operator: op,
                                         right: rhs)
        return node

    proc declaration(): AstNode =
        expression()

    while not isAtEnd():
        let decl = declaration()
        abstractSyntaxTree.add decl    # Add the parsed nodes to the AST

    result = ParserOutput(
        diagnostics: diagnostics,
        abstractSyntaxTree: abstractSyntaxTree    # Return the AST
    )

# Sample usage
when isMainModule:
    let lexerOutput = LexerOutput(
        diagnostics: @[],
        tokens: @[
            Token(kind: TokenKind.NumericLiteral, lexeme: "2", line: 1),
            Token(kind: TokenKind.Plus, lexeme: "+", line: 1),
            Token(kind: TokenKind.NumericLiteral, lexeme: "5", line: 1),
            Token(kind: TokenKind.Star, lexeme: "*", line: 1),
            Token(kind: TokenKind.NumericLiteral, lexeme: "3", line: 1),
            Token(kind: TokenKind.EndOfFile, lexeme: "", line: 1)
        ]
    )
    echo parser(lexerOutput)