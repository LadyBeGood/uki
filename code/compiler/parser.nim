import tokens, ast, strutils


proc parser*(lexerOutput: LexerOutput): Statements =
    var index: int
    var statements: Statements
    var diagnostics: Diagnostics = lexerOutput.diagnostics
    
    proc addDiagnostic(errorMessage: string) =
        add diagnostics, Diagnostic(diagnosticKind: DiagnosticKind.Parser, errorMessage: errorMessage, line: line)
    
    proc isAtEnd(): bool =
        tokens[index].kind == TokenKind.EndOfFile
    
    
    proc declaration() =
        
    
    while not isAtEnd():
        add statements, declaration




