import types, tables, error

proc lexer*(input: string): seq[Token] =
    var index: int
    var tokens: seq[Token]
    var line: int = 1
    var indentStack = @[0]
    const keywords = {
        "try": TokenKind.Try,
        "fix": TokenKind.Fix,
        "when": TokenKind.When,
        "else": TokenKind.Else,
        "loop": TokenKind.Loop,
        "with": TokenKind.With,
        "right": TokenKind.Right,
        "wrong": TokenKind.Wrong,
        "import": TokenKind.Import,
        "export": TokenKind.Export,
        "exit": TokenKind.Exit,
        "stop": TokenKind.Stop,
        "next": TokenKind.Next,
    }.toTable
    
    var roundBracketStack: seq[int] = @[]
    var squareBracketStack: seq[int] = @[]
    
    proc addToken(tokenKind: TokenKind, lexeme: string = "") =
        add tokens, Token(tokenKind: tokenKind, lexeme: lexeme, line: line)
    
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
                error(line, "Unterminated string")
    
            if input[index] == '"':
                break
            elif input[index] == '\n':
                line.inc()
    
            accumulate.add(input[index])
            index.inc()
    
        # Skip the closing quote
        index.inc()  
        addToken(TokenKind.StringLiteral, accumulate)
    
    proc identifier() =
        var accumulate = ""
        while not isAtEnd() and isAlphaNumeric(input[index]):
            accumulate.add(input[index])
            index.inc()
        
        # Check if the identifier is a keyword
        if keywords.hasKey(accumulate):
            addToken(keywords[accumulate], accumulate)  
        else:
            addToken(TokenKind.Identifier, accumulate) 


    proc number(isNegative: bool = false) =
        var accumulate = if isNegative: "-" else: "" 
        while not isAtEnd() and (isDigit(input[index]) or input[index] == '.'):
            accumulate.add(input[index])
            index.inc()
        addToken(TokenKind.NumericLiteral, accumulate)
    

    proc newline() =
        line.inc()
        index.inc()
        if roundBracketStack.len() != 0: return
        
        var spaceCount = 0
    
        # Count leading spaces
        while not isAtEnd() and input[index] == ' ':
            spaceCount.inc()
            index.inc()
    
        # Skip line if it'statement empty or contains only spaces
        if isAtEnd() or input[index] == '\n' or input[index] == '#':
            return
        
        # Indentation must be a multiple of 4
        if spaceCount mod 4 != 0:
            error(line, "Indentation must be a multiple of 4 spaces")
            return
    
        let indentLevel = spaceCount div 4
        let currentIndentLevel = indentStack[^1]
    
        if indentLevel > currentIndentLevel:
            # Only allow increasing by one level at a time
            if indentLevel != currentIndentLevel + 1:
                error(line, "Unexpected indent level, expected " &
                    $(currentIndentLevel + 1) & " but got " & $indentLevel)
                return
            indentStack.add(indentLevel)
            addToken(TokenKind.Indent, "++++")
    
        elif indentLevel < currentIndentLevel:
            # Dedent to known indentation level
            
            while indentStack.len > 0 and indentStack[^1] > indentLevel:
                indentStack.setLen(indentStack.len - 1)
                addToken(TokenKind.Dedent, "----")
    
            if indentStack.len == 0 or indentStack[^1] != indentLevel:
                error(line, "Inconsistent dedent, expected indent level " &
                    $indentStack[^1] & " but got " & $indentLevel)
            
                                                 # out of bound check
        elif indentLevel == currentIndentLevel and tokens.len() != 0 and tokens[^1].tokenKind notin {TokenKind.Indent, TokenKind.Dedent, TokenKind.Newline}:
            addToken(TokenKind.Newline, "\n")

    
    
    while not isAtEnd():
        let character = input[index]
        
        case character
        of '(':
            roundBracketStack.add(0)
            addToken(TokenKind.LeftRoundBracket, $character)
            index.inc()
        of ')':
            discard roundBracketStack.pop()
            addToken(TokenKind.RightRoundBracket, $character)
            index.inc()
        of '{':
            addToken(TokenKind.LeftCurlyBracket, $character)
            index.inc()
        of '}':
            addToken(TokenKind.RightCurlyBracket, $character)
            index.inc()
        of '[':
            squareBracketStack.add(0)
            addToken(TokenKind.LeftSquareBracket, $character)
            index.inc()
        of ']':
            discard squareBracketStack.pop()
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
        of '~':
            addToken(TokenKind.Tilde, $character)
            index.inc()
        of '-':
            if index + 1 < input.len and isDigit(input[index + 1]):
                index.inc()
                number(true)
            elif index + 1 < input.len and input[index + 1] == '-':
                error(line, "Invalid token `--`")
            else:
                addToken(TokenKind.Minus, $character)
                index.inc()
        of '+':
            if index + 1 < input.len and isDigit(input[index + 1]):
                index.inc()
                number()
            elif index + 1 < input.len and input[index + 1] == '+':
                error(line, "Invalid token `++`")
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
            newline()
        of ' ', '\\':
            index.inc()
        of '!':
            if index + 1 < input.len and input[index + 1] in ['=', '>', '<']:
                if input[index + 1] == '=':
                    addToken(TokenKind.ExclamationEqual, "!=")
                elif input[index + 1] == '>':
                    addToken(TokenKind.ExclamationMoreThan, "!>")
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
                error(line, "Invalid character, `" & $character & "`")

    while indentStack.len > 1:  
        indentStack.setLen(indentStack.len - 1)
        addToken(TokenKind.Dedent, "----")
    
    addToken(TokenKind.EndOfFile, "File has ended")
    
    return tokens



when isMainModule:
    import debug, cli
    
    proc lexerToString(input: string): string =
        return tokensToString lexer input
    
    run(lexerToString)






