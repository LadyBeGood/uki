import tokens, ast, strutils


proc parser*(lexerOutput: LexerOutput): Statements =
    var index: int
    var statements: Statements
    var diagnostics: Diagnostics = lexerOutput.diagnostics
    
    proc addDiagnostic(errorMessage: string) =
        add diagnostics, Diagnostic(diagnosticKind: DiagnosticKind.Parser, errorMessage: errorMessage, line: line)
    
    proc isAtEnd(): bool =
        tokens[index].kind == TokenKind.EndOfFile
    
    proc peek(): Token =
        if isAtEnd(): Token(kind: TokenKind.EOF, lexeme: "", line: 0)
        else: tokens[index]
    
    proc previous(): Token =
        return tokens[index - 1]
    
    proc advance(): Token =
        if not isAtEnd(): inc(index)
        return previous()
    
    proc check(kind: TokenKind): bool =
        not isAtEnd and peek().kind == kind
    
    proc match(kinds: varargs[TokenKind]): bool =
        for kind in kinds:
            if check(kind):
                discard advance()
                return true
        return false
    
    proc error(token: Token, message: string): ref ParseError =
        new(result)
        result.msg = "[Line " & $token.line & "] Error: " & message
    
    proc consume(kind: TokenKind, message: string): Token =
        if check(kind): return advance()
        raise error(peek(), message)
    
    proc synchronize() =
        discard advance()
        
        while not isAtEnd:
            if previous.kind == TokenKind.Semicolon:
                return
                
            case peek().kind
            of TokenKind.Func, TokenKind.Let, TokenKind.If, 
               TokenKind.While, TokenKind.Print, TokenKind.Return:
                return
            else:
                discard advance()
    
    proc optionalSemicolon() =
        # Semicolon is optional before } or at end of file, or if next token starts a new statement
        if match(TokenKind.Semicolon):
            return
        
        let next = peek()
        if next.kind == TokenKind.RightBrace or next.kind == TokenKind.EOF:
            return
        
        # Check if next token starts a new statement
        case next.kind
        of TokenKind.Func, TokenKind.Let, TokenKind.If, 
           TokenKind.While, TokenKind.Print, TokenKind.Return:
            return
        else:
            discard consume(TokenKind.Semicolon, "Expect ';' after statement")
    
    # Grammar rules
    proc parseExpression(): Expr
    proc parseStatement(): Stmt
    
    proc parseNumber(): Expr =
        return Expr(
            kind: ExprKind.Number,
            numVal: parseFloat(previous.lexeme)
        )
    
    proc parseString(): Expr =
        return Expr(
            kind: ExprKind.String,
            strVal: previous.lexeme
        )
    
    proc parseIdentifier(): Expr =
        Expr(
            kind: ExprKind.Identifier,
            identName: previous.lexeme
        )
    
    proc parseGrouping(): Expr =
        discard advance()  # Consume '('
        let expr = parseExpression()
        discard consume(TokenKind.RightParen, "Expect ')' after expression.")
        Expr(
            kind: ExprKind.Grouping,
            grouped: expr
        )
    
    proc parseUnary(): Expr =
        let op = previous
        let right = parseExpression()
        Expr(
            kind: ExprKind.Unary,
            unaryOp: op,
            operand: right
        )
    
    proc parseBinary(left: Expr): Expr =
        let op = previous
        let right = parseExpression()
        Expr(
            kind: ExprKind.Binary,
            left: left,
            binaryOp: op,
            right: right
        )
    
    proc parseCall(callee: Expr): Expr =
        var args: seq[Expr]
        if not check(TokenKind.RightParen):
            while true:
                args.add(parseExpression())
                if not match(TokenKind.Comma): break
        discard consume(TokenKind.RightParen, "Expect ')' after arguments.")
        Expr(
            kind: ExprKind.Call,
            callee: callee,
            args: args
        )
    
    proc parsePrimary(): Expr =
        if match(TokenKind.Number): parseNumber()
        elif match(TokenKind.String): parseString()
        elif match(TokenKind.True): Expr(kind: ExprKind.Boolean, boolVal: true)
        elif match(TokenKind.False): Expr(kind: ExprKind.Boolean, boolVal: false)
        elif match(TokenKind.Null): Expr(kind: ExprKind.Null)
        elif match(TokenKind.Identifier): parseIdentifier()
        elif match(TokenKind.LeftParen): parseGrouping()
        elif match(TokenKind.Bang, TokenKind.Minus): parseUnary()
        else: raise error(peek(), "Expect expression.")
    
    proc parseExpression(): Expr =
        var expr = parsePrimary()
        while true:
            if match(TokenKind.Plus, TokenKind.Minus, TokenKind.Star, TokenKind.Slash,
                      TokenKind.EqualEqual, TokenKind.BangEqual, TokenKind.Greater,
                      TokenKind.GreaterEqual, TokenKind.Less, TokenKind.LessEqual):
                expr = parseBinary(expr)
            elif match(TokenKind.LeftParen):
                expr = parseCall(expr)
            else: break
        expr
    
    proc parsePrintStmt(): Stmt =
        let expr = parseExpression()
        optionalSemicolon()
        Stmt(
            kind: StmtKind.PrintStmt,
            printExpr: expr
        )
    
    proc parseVarDecl(): Stmt =
        let name = consume(TokenKind.Identifier, "Expect variable name.").lexeme
        var init: Expr
        if match(TokenKind.Equal):
            init = parseExpression()
        optionalSemicolon()
        Stmt(
            kind: StmtKind.VarDecl,
            varName: name,
            varInit: init
        )
    
    proc parseBlock(): Stmt =
        var statements: seq[Stmt]
        while not check(TokenKind.RightBrace) and not isAtEnd:
            statements.add(parseStatement())
        discard consume(TokenKind.RightBrace, "Expect '}' after block.")
        Stmt(
            kind: StmtKind.Block,
            statements: statements
        )
    
    proc parseIfStmt(): Stmt =
        let condition = parseExpression()
        discard consume(TokenKind.LeftBrace, "Expect '{' after if condition.")
        let thenBranch = parseBlock()
        var elseBranch: Stmt
        if match(TokenKind.Else):
            discard consume(TokenKind.LeftBrace, "Expect '{' after else.")
            elseBranch = parseBlock()
        Stmt(
            kind: StmtKind.IfStmt,
            condition: condition,
            thenBranch: thenBranch,
            elseBranch: elseBranch
        )
    
    proc parseWhileStmt(): Stmt =
        let condition = parseExpression()
        discard consume(TokenKind.LeftBrace, "Expect '{' after while condition.")
        let body = parseBlock()
        Stmt(
            kind: StmtKind.WhileStmt,
            whileCond: condition,
            whileBody: body
        )
    
    proc parseFuncDecl(): Stmt =
        let name = consume(TokenKind.Identifier, "Expect function name.").lexeme
        discard consume(TokenKind.LeftParen, "Expect '(' after function name.")
        var params: seq[string]
        if not check(TokenKind.RightParen):
            while true:
                params.add(consume(TokenKind.Identifier, "Expect parameter name.").lexeme)
                if not match(TokenKind.Comma): break
        discard consume(TokenKind.RightParen, "Expect ')' after parameters.")
        discard consume(TokenKind.LeftBrace, "Expect '{' before function body.")
        let body = parseBlock()
        Stmt(
            kind: StmtKind.FuncDecl,
            funcName: name,
            params: params,
            body: body
        )
    
    proc parseReturnStmt(): Stmt =
        var value: Expr
        if not check(TokenKind.Semicolon):
            value = parseExpression()
        optionalSemicolon()
        Stmt(
            kind: StmtKind.ReturnStmt,
            returnVal: value
        )
    
    proc parseExprStmt(): Stmt =
        let expr = parseExpression()
        optionalSemicolon()
        Stmt(
            kind: StmtKind.ExprStmt,
            expr: expr
        )
    
    proc parseStatement(): Stmt =
        try:
            if match(TokenKind.Print): parsePrintStmt()
            elif match(TokenKind.Let): parseVarDecl()
            elif match(TokenKind.If): parseIfStmt()
            elif match(TokenKind.While): parseWhileStmt()
            elif match(TokenKind.Func): parseFuncDecl()
            elif match(TokenKind.Return): parseReturnStmt()
            elif match(TokenKind.LeftBrace): parseBlock()
            else: parseExprStmt()
        except ParseError:
            synchronize()
            raise
    

    while not isAtEnd:
        try:
            statements.add(parseStatement())
        except ParseError as e:
            stderr.writeLine(e.msg)
            synchronize()
    return statements




