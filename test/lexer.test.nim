## Utkrisht - the Utkrisht programming language
## Copyright (C) 2025 Haha-jk
##
## This file is part of Utkrisht and is licensed under the AGPL-3.0-or-later.
## See the license.txt file in the root of this repository.

import unittest

suite "Lexer Tests":
    test "Empty input":
        let tokens = lexer("")
        check tokens.len == 1
        check tokens[0].tokenKind == TokenKind.EndOfFile
    
    test "Only whitespace input":
        let tokens = lexer("            \n      \n ")
        check tokens.len == 1
        check tokens[0].tokenKind == TokenKind.EndOfFile
    
    test "Keyword tokens":
        let tokens = lexer("try fix when then loop")
        check tokens[0].tokenKind == TokenKind.TryKeyword
        check tokens[1].tokenKind == TokenKind.FixKeyword
        check tokens[2].tokenKind == TokenKind.WhenKeyword
        check tokens[3].tokenKind == TokenKind.ThenKeyword
        check tokens[4].tokenKind == TokenKind.LoopKeyword
        check tokens[^1].tokenKind == TokenKind.EndOfFile

    test "Identifiers":
        let tokens = lexer("hello haha12 myVar-123")
        check tokens[0].tokenKind == TokenKind.Identifier
        check tokens[0].lexeme == "hello"
        check tokens[1].tokenKind == TokenKind.Identifier
        check tokens[1].lexeme == "haha12"
        check tokens[2].tokenKind == TokenKind.Identifier
        check tokens[2].lexeme == "myVar-123"
        check tokens[^1].tokenKind == TokenKind.EndOfFile

    test "Numeric literals":
        let tokens = lexer("123 45678 0")
        check tokens[0].tokenKind == TokenKind.NumericLiteral
        check tokens[0].lexeme == "123"
        check tokens[1].tokenKind == TokenKind.NumericLiteral
        check tokens[1].lexeme == "45678"
        check tokens[2].tokenKind == TokenKind.NumericLiteral
        check tokens[2].lexeme == "0"
        check tokens[^1].tokenKind == TokenKind.EndOfFile

    test "String literals":
        let tokens = lexer("\"hello\" \"world\"")
        check tokens[0].tokenKind == TokenKind.UninterpolatedStringLiteral
        check tokens[0].lexeme == "hello"
        check tokens[1].tokenKind == TokenKind.UninterpolatedStringLiteral
        check tokens[1].lexeme == "world"
        check tokens[^1].tokenKind == TokenKind.EndOfFile

    test "Symbols and operators":
        let tokens = lexer("(){},.:+-*/$?&=><_")
        let expectedKinds = [
            TokenKind.LeftRoundBracket, 
            TokenKind.RightRoundBracket, 
            TokenKind.LeftCurlyBracket, 
            TokenKind.RightCurlyBracket,
            TokenKind.Comma, 
            TokenKind.Dot, 
            TokenKind.Colon, 
            TokenKind.Plus, 
            TokenKind.Minus, 
            TokenKind.Asterisk, 
            TokenKind.Slash,
            TokenKind.Dollar, 
            TokenKind.Question, 
            TokenKind.Ampersand, 
            TokenKind.Equal, 
            TokenKind.MoreThan, 
            TokenKind.LessThan,
            TokenKind.Underscore
        ]
        for i, kind in expectedKinds:
            check tokens[i].tokenKind == kind
        check tokens[^1].tokenKind == TokenKind.EndOfFile

    test "Indentation and Dedentation":
        let input = """
root
child
    grandchild
sibling
peer
"""
        let tokens = lexer(input)
        var indentCount = 0
        var dedentCount = 0
        for token in tokens:
            case token.tokenKind
            of Indent:
                indentCount.inc()
            of Dedent:
                dedentCount.inc()
            else:
                discard
        check indentCount == 2
        check dedentCount == 2
        check tokens[^1].tokenKind == TokenKind.EndOfFile

    test "Comments are ignored":
        let tokens = lexer("# this is a comment\nactualCode")
        check tokens[0].tokenKind == TokenKind.Identifier
        check tokens[0].lexeme == "actualCode"
        check tokens[^1].tokenKind == TokenKind.EndOfFile

    test "Compound symbols (!=, !>, !<)":
        let tokens = lexer("!= !> !<")
        check tokens[0].tokenKind == TokenKind.ExclamationEqual
        check tokens[1].tokenKind == TokenKind.ExclamationMoreThan
        check tokens[2].tokenKind == TokenKind.ExclamationLessThan
        check tokens[^1].tokenKind == TokenKind.EndOfFile
    
    test "Unterminated string gives error":
        let tokens = lexer("\"hello")
        check tokens[0].tokenKind == TokenKind.Illegal
        check tokens[0].lexeme == "Unterminated string literal"


