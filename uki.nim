import os, strutils, json, options, tables, macros, lists, sequtils, strformat


proc uki() =
    type 
        Object* = ref object of RootObj
    
        BooleanObject* = ref object of Object
            data*: bool
        
        NumberObject* = ref object of Object
            data*: float
        
        StringObject* = ref object of Object
            data*: string
        
        TokenKind* = enum
            LeftRoundBracket,    # (
            RightRoundBracket,   # )
            LeftCurlyBracket,    # {
            RightCurlyBracket,   # }
            LeftSquareBracket,   # [
            RightSquareBracket,  # ]
            Comma,          # ,
            Dot,            # .
            Colon,          # :
            Minus,          # -
            Plus,           # +        
            Star,           # *
            Slash,          # /
            Dollar,         # $
            At,             # @
            Range,          # _
            ExclusiveRange, # _
            QuestionMark,   # ?
            And,            # &
            # One or two character tokens.
            ExclamationMark, # !
            Equal,           # =
            MoreThan,        # >
            LessThan,        # <
            NotEqual,        # !=
            NotMoreThan,     # !>
            NotLessThan,     # !<
            # Literals.
            VariableIdentifier,   # [A-Z_a-z][0-9A-Z_a-z]*
            FunctionIdentifier,   # [A-Z_a-z][0-9A-Z_a-z]*
            String,       # "string" | ""
            Number,       # 123 | 123.0
            # Keywords.
            When,
            Then,
            Loop,
            With,
            Quit,
            Skip,
            Exit,
            Right,
            Wrong,
            # Whitespace
            Newline, # \n 
            Indent, 
            Dedent,
            EOF           # End-of-file
    
        Token* = object
            kind*: TokenKind
            lexeme*: string
            line*: int
        
        Tokens* = seq[Token]
      
        
        FunctionParameter* = ref object of ExpressionStatement
            name*: string
            default*: Expression
    
        FunctionArgument* = ref object of ExpressionStatement
            value*: Expression  
        
        FunctionParameters* = seq[FunctionParameter]
        FunctionArguments* = seq[FunctionArgument]
       
        # Expressions
        Expression* = ref object of RootObj
        Expressions* = seq[Expression]
    
        BinaryExpression* = ref object of Expression
            left*: Expression
            operator*: Token
            right*: Expression
    
        FunctionExpression* = ref object of Expression
            functionIdentifier*: string
            arguments*: FunctionArguments
        
        VariableExpression* = ref object of Expression
            variableIdentifier*: string
        
        GroupingExpression* = ref object of Expression
            Expression*: Expression
    
        LiteralExpression* = ref object of Expression
            value*: Object
    
        UnaryExpression* = ref object of Expression
            operator*: Token
            right*: Expression
        
    
        # Statement
        Statement* = ref object of RootObj
        Statements* = seq[Statement]
        
        
        
        VariableDeclarationStatement* = ref object of Statement
            variableIdentifier*: string
            value*: Expression
        
        VariableReassignmentStatement* = ref object of Statement
            variableIdentifier*: string
            value*: Expression
        
        FunctionDeclarationStatement* = ref object of Statement
            functionIdentifier*: string
            parameters*: FunctionParameters
            body*: Statement
        
        FunctionReassignmentStatement* = ref object of Statement
            functionIdentifier*: string
            body*: Statement
        
        ExpressionStatement* = ref object of Statement
            expression*: Expression
        
        LoopStatement* = ref object of Statement
            condition*: Expressions
            placeholder*: Statement
        
        WhenStatement* = ref object of Statement
            condition*: Expression
            placeholder*: Statement
            otherwise*: Statement
        
        ControlStatement* = ref object of Statement
            kind*: TokenKind
            value*: Expression
        
        EmptyControlStatement* = ref object of Statement
            kind*: TokenKind
        
        BlockStatement* = ref object of Statement
            statements*: Statements
        



    proc lexer(input: string): Tokens =
        const keywords = {
            "when": When,
            "then": Then,
            "loop": Loop,
            "with": With,
            "quit": Quit,
            "skip": Skip,
            "exit": Exit,
            "right": Right,
            "wrong": Wrong,
        }.toTable
        
        var tokens: Tokens = @[]
        var index = 0
        let size = input.len()
        var line = 1
        var currentIndentLevel: int = 0
        
        proc addToken(lexeme: string, tokenKind: TokenKind) =
            tokens.add(
                Token(
                    kind: tokenKind,
                    lexeme: lexeme,
                    line: line
                )
            )
    
        proc isAtEnd(): bool =
            index >= size
    
        proc isNextCharacter(character: char): bool =
            not isAtEnd() and input[index + 1] == character
    
        proc isDigit(c: char): bool =
            c in {'0' .. '9'}
    
        proc isAlphabet(c: char): bool =
            c in {'A'..'Z', '-', 'a'..'z'}
    
        proc isAlphaNumeric(c: char): bool =
            isAlphabet(c) or isDigit(c)
    
        proc string() =
            var accumulate = ""
            index.inc()
            while (not isAtEnd()) and (input[index] != '"'):
                accumulate = accumulate & $input[index]
                if input[index] == '\n':
                    line.inc()
                index.inc()
            addToken(accumulate, String)
    
        proc identifier() =
            var accumulate = ""
            while (not isAtEnd()) and (isAlphaNumeric(input[index])):
                accumulate = accumulate & $input[index]
                index.inc()
            index.dec()
            
            # Check if the identifier is a keyword
            if keywords.hasKey(accumulate):
                addToken(accumulate, keywords[accumulate])  # Emit the keyword token
            elif accumulate.toLower() == accumulate:
                addToken(accumulate, VariableIdentifier)  # Emit an Identifier token
            else:
                addToken(accumulate, FunctionIdentifier)  # Emit an Identifier token
                
    
        proc number() =
            var accumulate = ""
            while (not isAtEnd()) and (isDigit(input[index])):
                accumulate = accumulate & $input[index]
                index.inc()
            index.dec()
            addToken(accumulate, Number)
    
        proc handleIndentation() =
            var spacesCount: int = 0
            index.inc()
            # Count the number of spaces at the beginning of the line
            while (not isAtEnd()) and input[index] == ' ':
                spacesCount.inc()
                index.inc()
            index.dec()
            # Calculate the indentation level (assuming 4 spaces per level)
            var indentLevel = spacesCount div 4       
            
            # Handle indentation changes
            if indentLevel > currentIndentLevel:
                # Increase indentation level
                if isAtEnd() or input[index] == '\n':
                    return 
                if indentLevel != currentIndentLevel + 1:
                    echo "[line: ", $line, "] Invalid indentation: expected ", currentIndentLevel + 1, " levels, got ", indentLevel
                    quit(1)
                addToken("", Indent)
                currentIndentLevel = indentLevel
            elif indentLevel < currentIndentLevel:
                # Decrease indentation level
                while currentIndentLevel > indentLevel:
                    addToken("", Dedent)
                    currentIndentLevel.dec()
            # Else: indentation level remains the same
        
        
        
        while not isAtEnd():
            var character = input[index]
            
            case character
            of '(':
                addToken($character, LeftRoundBracket)
            of ')':
                addToken($character, RightRoundBracket)
            of '{':
                addToken($character, LeftCurlyBracket)
            of '}':
                addToken($character, RightCurlyBracket)
            of '[':
                addToken($character, LeftSquareBracket)
            of ']':
                addToken($character, RightSquareBracket)
            of ',':
                addToken($character, Comma)
            of '.':
                addToken($character, Dot)
            of ':':
                addToken($character, Colon)
            of '-':
                addToken($character, Minus)
            of '+':
                addToken($character, Plus)
            of '*':
                addToken($character, Star)
            of '/':
                addToken($character, Slash)
            of '$':
                addToken($character, Dollar)
            of '@':
                while (not isAtEnd()) and (input[index] != '\n'):
                    index.inc()
                line.inc()
            of '_':
                if isNextCharacter('<'):
                    index.inc()
                    addToken("_<", ExclusiveRange)
                else:
                    addToken($character, Range)
            of '?':
                addToken($character, QuestionMark)
            of '&':
                addToken($character, And)
            of '=':
                addToken($character, Equal)
            of '>':
                addToken($character, MoreThan)
            of '<':
                addToken($character, LessThan)
            of '\n':
                line.inc()
                addToken($character, NewLine)
                handleIndentation()
            of ' ', '\\':
                discard
            of '!':
                if isNextCharacter('='):
                    index.inc()
                    addToken("!=", NotEqual)
                elif isNextCharacter('>'):
                    index.inc()
                    addToken("!>", NotMoreThan)
                elif isNextCharacter('<'): 
                    index.inc()
                    addToken("!<", NotLessThan)
                else: 
                    addToken($character, ExclamationMark)
            of '"':
                string()
            else:
                if isDigit(character):
                    number()
                elif isAlphabet(character):
                    identifier()
                else:
                    echo "[Line ", $line, "] Unexpected character: `", $character, "`"
                    quit(1)
    
            index.inc()        
    
        while currentIndentLevel != 0:
            addToken("", Dedent)
            currentIndentLevel.dec()
        
        addToken("", EOF)
        return tokens
        

    
  
    
    proc parser(tokens: Tokens): Statements =
        var statements: Statements = @[]
        var index: int = 0
    
    
        proc isAtEnd(): bool =
            tokens[index].kind == EOF
        
        proc isCurrentTokenKind(tokenKind: TokenKind): bool =
            tokens[index].kind == tokenKind
        
        proc isNextTokenKind(tokenKind: TokenKind): bool =
            tokens[index + 1].kind == tokenKind
        
        proc isPreviousTokenKind(tokenKind: TokenKind): bool =
            tokens[index - 1].kind == tokenKind
        
        proc error(message: string) =
            echo fmt"[{tokens[index].line}] {message}"
            quit(1)
            
        proc discardTillTokenKind(tokenKind: TokenKind) =
            while not isCurrentTokenKind(tokenKind):
                if isAtEnd():
                    error("Couldn't find " & $tokenKind)
                index.inc()
        
        proc checkCurrentToken(tokenKind: TokenKind) =
            if not isCurrentTokenKind(tokenKind):
                error(fmt"Couldn't find {tokenKind}")
        
        proc statement(): Statement
        proc declaration(): Statement
        proc expression(): Expression
        
        
        
        proc primary(): Expression =
            # string | number | boolean | identifier
            
            if isCurrentTokenKind(Right):
                return LiteralExpression(value: BooleanObject(data: true))
            elif isCurrentTokenKind(Wrong):
                return LiteralExpression(value: BooleanObject(data: false))
            elif isCurrentTokenKind(Number):
                return LiteralExpression(value: NumberObject(data: parseFloat(tokens[index].lexeme)))
            elif isCurrentTokenKind(String):
                return LiteralExpression(value: StringObject(data: tokens[index].lexeme))
            #[
            elif isCurrentTokenKind(VariableIdentifier):
                return Variable(tokens[index].value)
            elif isCurrentTokenKind(FunctionIdentifier):
                return Function(tokens[index].value)
            ]#
            else:
                error("Expected expression."& "\n" & $tokens[index] & "\n" & $index)
    
        
        proc unary(): Expression =
            return primary()
        
        
        proc factor(): Expression =
            return unary()
        
        proc term(): Expression =
            # factor (("+" | "-") factor)*
            result = factor()
            while isNextTokenKind(Plus) or isNextTokenKind(Minus):
                let operator = tokens[index]
                let right = factor()
            
                result = BinaryExpression(left: result, operator: operator, right: right)
                index.inc()
    
        proc logicAnd(): Expression =
            return term()
        
        proc logicOr(): Expression =
            return logicAnd()
       
        proc expression(): Expression =        
            return logicOr()
        
        proc expressionStatement(): Statement =
            # expression newline
            result = ExpressionStatement(expression: expression())
            while isCurrentTokenKind(Newline):
                index.inc()
       
       
        proc aBlock(): Statement =
            checkCurrentToken(Newline)
            index.inc()
            var statements: Statements = @[]
            while not isCurrentTokenKind(Dedent):
                statements.add(declaration())
            index.inc()
            return BlockStatement(
                statements: statements
            )
            
        proc controlStatement(): Statement = 
            let kind: TokenKind = tokens[index].kind
            index.inc()
            if isCurrentTokenKind(Newline):
                return ControlStatement(
                    kind: kind,
                    value: nil
                )
            return ControlStatement(
                kind: kind,
                value: expression()
            )
        
        proc statement(): Statement =
            # expression-statement |
            # loop-statement       |
            # when-statement       |
            # exit-statement       |
            # block
            #[
            if isCurrentTokenKind(Loop):
                return loopStatement()
            elif isCurrentTokenKind(When):
                return whenStatement()
            elif isCurrentTokenKind(Exit) or isCurrentTokenKind(Quit) or isCurrentTokenKind(Skip):
                return controlStatement()
            elif isCurrentTokenKind(Indent):
                return aBlock()
            else: ]#
            return expressionStatement()
        
        
        proc variableDeclaration(): Statement =
            let variableIdentifier = tokens[index].lexeme
            index.inc()
            checkCurrentToken(Colon)
            index.inc()
            result = VariableDeclarationStatement(
                variableIdentifier: variableIdentifier,
                value: expression()
            )
            index.inc()
            if not (isCurrentTokenKind(Newline) or isCurrentTokenKind(EOF)):
                error("Expected Newline or EOF")
            elif isCurrentTokenKind(Newline):
                index.inc()
        
        proc functionDeclaration(): Statement =
            let functionIdentifier: string = tokens[index].lexeme
            index.inc()
            var parameters: FunctionParameters = @[]
            while isCurrentTokenKind(VariableIdentifier):
                let name: string = tokens[index].lexeme
                index.inc()
                if isCurrentTokenKind(Equal):
                    index.inc()
                    parameters.add(FunctionParameter(
                        name: name,
                        default: expression()
                    ))
                else:
                    parameters.add(FunctionParameter(
                        name: name,
                        default: nil
                    ))
                if isCurrentTokenKind(Comma):
                    index.inc()
                    checkCurrentToken(VariableIdentifier)
            checkCurrentToken(Colon)
            index.inc()
            checkCurrentToken(Newline)
            index.inc()
            return FunctionDeclarationStatement(
                functionIdentifier: functionIdentifier,
                parameters: parameters,
                body: aBlock()
            )
    
        proc functionReassignment(): Statement =
            let functionIdentifier: string = tokens[index].lexeme
            index.inc()
            checkCurrentToken(Equal)
            index.inc()
            return FunctionReassignmentStatement(
                functionIdentifier: functionIdentifier,
                body: aBlock()
            )
            
        proc variableCall(): Statement =
            return expressionStatement()
            
        proc function(): Statement =
            let initialIndex: int = index
            while not isAtEnd() or not isCurrentTokenKind(Newline):
                index.inc()
            if isPreviousTokenKind(Colon):
                index = initialIndex
                return functionDeclaration()
            elif isPreviousTokenKind(Equal):
                index = initialIndex
                return functionReassignment()
            index = initialIndex
            # return functionCall()
        
        proc variable(): Statement =
            if isNextTokenKind(Colon):
                return variableDeclaration()
            #elif isNextTokenKind(Equal):
                # return variableAssignment()
            # return variableCall()
        
        proc declaration(): Statement =
            # function-declaration | 
            # variable-declaration |
            # statement
    
            if isCurrentTokenKind(FunctionIdentifier): # this might not be true
                return function()
            elif isCurrentTokenKind(VariableIdentifier): # nor this
                return variable()
            else: 
                return statement()
            
    
        while not isAtEnd():
            statements.add(declaration())
    
        return statements
    




    proc compiler(input: string): string =
        let tokens: Tokens = lexer(input)
        let ast: Statements = parser(tokens)
        var str:  string = ""
        for statement in ast:
            str &= printAst(statement)
        return tokens.join("\n") & "\n\n\n" & str
    

    if paramCount() < 1:
        echo "Usage: uki input.uki"
        quit(1)

    let inputFile = paramStr(1)
    let outputFile = "e.uki"

    let inputText = readFile(inputFile)
    if inputText.strip(chars = {' ', '\t', '\n'}, leading = true, trailing = false)  == "":
        echo "Empty file"
        quit(1)

    let outputText = compiler(inputText)
    writeFile(outputFile, outputText)


uki()

