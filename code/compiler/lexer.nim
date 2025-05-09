## Utkrisht - the Utkrisht programming language
## Copyright (C) 2025 Haha-jk
##
## This file is part of Utkrisht and is licensed under the AGPL-3.0-or-later.
## See the license.txt file in the root of this repository.

import tables
import types


proc lexer*(input: string): LexerOutput =
    var index: int
    var tokens: Tokens
    var diagnostics: Diagnostics
    var line: int = 1
    var indentStack = @[0]

    proc addToken(tokenKind: TokenKind, lexeme: string = "") =
        add tokens, Token(tokenKind: tokenKind, lexeme: lexeme, line: line)
    
    proc addDiagnostic(errorMessage: string) =
        add diagnostics, Diagnostic(diagnosticKind: DiagnosticKind.Lexer, errorMessage: errorMessage, line: line)
    
    proc isAtEnd(): bool =
        return index >= input.len

    proc isDigit(character: char): bool =
        return character in {'0' .. '9'}

    proc isAlphabet(character: char): bool =
        return character in {'a'..'z'}
    
    proc isAlphaNumeric(character: char): bool =
        return isAlphabet(character) or isDigit(character) or character == '-'
    
    
    proc string() =
        # Skip the opening quote
        index.inc()  
        var accumulate = ""
        while true:
            if isAtEnd():
                addDiagnostic("Unterminated string literal")
                return
    
            if input[index] == '"':
                break
            elif input[index] == '\n':
                line.inc()
    
            accumulate &= $input[index]
            index.inc()
    
        # Skip the closing quote
        index.inc()  
        addToken(TokenKind.StringLiteral, accumulate)
    
    proc identifier() =
        var accumulate = ""
        while not isAtEnd() and isAlphaNumeric(input[index]):
            accumulate &= $input[index]
        
            index.inc()
        
        const keywords = {
            "try": TokenKind.TryKeyword,
            "fix": TokenKind.FixKeyword,
            "when": TokenKind.WhenKeyword,
            "then": TokenKind.ThenKeyword,
            "loop": TokenKind.LoopKeyword,
            "with": TokenKind.WithKeyword,
            "right": TokenKind.RightKeyword,
            "wrong": TokenKind.WrongKeyword,
            "import": TokenKind.ImportKeyword,
            "export": TokenKind.ExportKeyword
        }.toTable
        
        # Check if the identifier is a keyword
        if keywords.hasKey(accumulate):
            addToken(keywords[accumulate], accumulate)  
        else:
            addToken(TokenKind.Identifier, accumulate) 


    proc number(isNegative: bool = false) =
        var accumulate = if isNegative: "-" else: ""
        while not isAtEnd() and isDigit(input[index]):
            accumulate &= input[index]
            index.inc()

        addToken(TokenKind.NumericLiteral, accumulate)
    
    proc handleIndentation() =
        var spaceCount = 0
    
        # Count leading spaces
        while not isAtEnd() and input[index] == ' ':
            spaceCount.inc()
            index.inc()
    
        # Skip line if it's empty or contains only spaces
        if isAtEnd() or input[index] == '\n':
            return
    
        # Indentation must be a multiple of 4
        if spaceCount mod 4 != 0:
            addDiagnostic("Indentation must be a multiple of 4 spaces")
            return
    
        let indentLevel = spaceCount div 4
        let currentIndentLevel = indentStack[^1]
    
        if indentLevel > currentIndentLevel:
            # Only allow increasing by one level at a time
            if indentLevel != currentIndentLevel + 1:
                addDiagnostic("Unexpected indent level: expected " &
                    $(currentIndentLevel + 1) & " but got " & $indentLevel)
                return
            indentStack.add(indentLevel)
            addToken(TokenKind.Indent)
    
        elif indentLevel < currentIndentLevel:
            # Dedent to known indentation level
            while indentStack.len > 0 and indentStack[^1] > indentLevel:
                indentStack.setLen(indentStack.len - 1)
                addToken(TokenKind.Dedent)
    
            if indentStack.len == 0 or indentStack[^1] != indentLevel:
                addDiagnostic("Inconsistent dedent: expected indent level " &
                    $indentStack[^1] & " but got " & $indentLevel)

    while not isAtEnd():
        let character = input[index]
        
        case character
        of '(':
            addToken(TokenKind.LeftRoundBracket, $character)
            index.inc()
        of ')':
            addToken(TokenKind.RightRoundBracket, $character)
            index.inc()
        of '{':
            addToken(TokenKind.LeftCurlyBracket, $character)
            index.inc()
        of '}':
            addToken(TokenKind.RightCurlyBracket, $character)
            index.inc()
        of '[':
            addToken(TokenKind.LeftSquareBracket, $character)
            index.inc()
        of ']':
            addToken(TokenKind.RightSquareBracket, $character)
            index.inc()
        of ',':
            addToken(TokenKind.Comma, $character)
            index.inc()
        of '.':
            addToken(TokenKind.Dot, $character)
            index.inc()
        of ':':
            addToken(TokenKind.Colon, $character)
            index.inc()
        of '-':
            if index + 1 < input.len and isDigit(input[index + 1]):
                index.inc()
                number(true)
            else:
                addToken(TokenKind.Minus, $character)
                index.inc()
        of '+':
            if index + 1 < input.len and isDigit(input[index + 1]):
                index.inc()
                number()
            else:
                addToken(TokenKind.Plus, $character)
                index.inc()
        of '*':
            addToken(TokenKind.Asterisk, $character)
            index.inc()
        of '/':
            addToken(TokenKind.Slash, $character)
            index.inc()
        of '$':
            addToken(TokenKind.Dollar, $character)
            index.inc()
        of '?':
            addToken(TokenKind.Question, $character)
            index.inc()
        of '&':
            addToken(TokenKind.Ampersand, $character)
            index.inc()
        of '=':
            addToken(TokenKind.Equal, $character)
            index.inc()
        of '>':
            addToken(TokenKind.MoreThan, $character)
            index.inc()
        of '<':
            addToken(TokenKind.LessThan, $character)
            index.inc()
        of '|':
            addToken(TokenKind.Bar, $character)
            index.inc()
        of '#':
            # Ignore single line comment
            while not isAtEnd() and not (input[index] == '\n'):
                index.inc()
        of '_':
            if index + 1 < input.len and input[index + 1] == '<':
                index.inc(2)
                addToken(TokenKind.UnderscoreLessThan, "_<")
            else:
                addToken(TokenKind.Underscore, $character)
                index.inc()
        of '\n':
            line.inc()
            index.inc()
            handleIndentation()
        of ' ', '\\':
            index.inc()
        of '!':
            if index + 1 < input.len:
                if input[index + 1] == '=':
                    addToken(TokenKind.ExclamationEqual, "!=")
                    index.inc(2)
                elif input[index + 1] == '>':
                    addToken(TokenKind.ExclamationMoreThan, "!>")
                    index.inc(2)
                elif input[index + 1] == '<': 
                    addToken(TokenKind.ExclamationLessThan, "!<")
                    index.inc(2)
            else: 
                addToken(TokenKind.Exclamation, $character)
                index.inc()
        of '"':
            string()
        else:
            if isDigit(character):
                number()
            elif isAlphabet(character):
                identifier()
            else:
                addDiagnostic("Unexpected character: `" & $character & "`")
                index.inc()

    while indentStack.len > 1:  
        indentStack.setLen(indentStack.len - 1)
        addToken(TokenKind.Dedent)
    
    addToken(TokenKind.EndOfFile)
    
    return LexerOutput(
        diagnostics: diagnostics, 
        input: input, 
        tokens: tokens
    )



when isMainModule:
    import json, ../utilities/debugging
    
    let input: string = "right != wrong"

    let tokens = lexer(input)
    let formatted = pretty(%tokens, indent = 4)
    shout formatted






