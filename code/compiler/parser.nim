## Utkrisht - the Utkrisht programming language
## Copyright (C) 2025 Haha-jk
##
## This file is part of Utkrisht and is licensed under the AGPL-3.0-or-later.
## See the license.txt file in the root of this repository.

import tokens, ast, strutils

proc parser*(lexerOutput: LexerOutput): ParserOutput =
    var index: int
    var abstractSyntaxTree: AbstractSyntaxTree
    var diagnostics: Diagnostics = lexerOutput.diagnostics
    
    proc addDiagnostic(errorMessage: string) =
        add diagnostics, Diagnostic(diagnosticKind: DiagnosticKind.Parser, errorMessage: errorMessage, line: line)
    
    proc isAtEnd(): bool =
        tokens[index].kind == TokenKind.EndOfFile
    
    
    proc declaration() =
        
    
    while not isAtEnd():
        add abstractSyntaxTree, declaration




