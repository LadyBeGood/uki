## Utkrisht - the Utkrisht programming language
## Copyright (C) 2025 LadyBeGood
##
## This file is part of Utkrisht and is licensed under the AGPL-3.0-or-later.
## See the license.txt file in the root of this repository.

type
    TokenKind* {.pure.} = enum
        Illegal
        EndOfFile
    
        # Literals  
        NumericLiteral  
        StringLiteral  
    
        # Identifier  
        Identifier  
      
        # Punctuation  
        LeftRoundBracket   
        RightRoundBracket   
        LeftCurlyBracket   
        RightCurlyBracket  
        LeftSquareBracket   
        RightSquareBracket  
        Dot  
        Comma  
        Exclamation  
        Ampersand  
        Question  
        Colon  
        Equal  
        LessThan  
        MoreThan  
        ExclamationEqual  
        ExclamationLessThan  
        ExclamationMoreThan  
        Plus  
        Minus  
        Asterisk  
        Slash  
        Bar  
        Tilde  
        Hash  
        Underscore  
        UnderscoreLessThan  
        NewLine  
        Dollar  
          
      
        # Reserved words  
        WhenKeyword  
        ThenKeyword  
        TryKeyword  
        FixKeyword  
        LoopKeyword  
        WithKeyword  
        ImportKeyword  
        ExportKeyword  
        RightKeyword  
        WrongKeyword  
      
        # Spacing  
        Indent  
        Dedent  
    
    DiagnosticKind* {.pure.} = enum
        Lexer
        Parser
        Validator

    Token* = ref object  
        tokenKind*: TokenKind
        lexeme*: string  
        line*: int 
    
    Tokens* = seq[Token]
    
    Diagnostic* = ref object
        diagnosticKind*: DiagnosticKind
        errorMessage*: string
        line*: int
    
    Diagnostics* = seq[Diagnostic]
    
    LexerOutput* = ref object
        diagnostics*: Diagnostics
        tokens*: Tokens

    
    ParserOutput* = object
        diagnostics*: Diagnostics
        abstractSyntaxTree*: Statements



    # Expressions
    Expression* = ref object of RootObj
    Expressions* = seq[Expression]

    BinaryExpression* = ref object of Expression
        left*: Expression
        operator*: Token
        right*: Expression

    RangeExpression* = ref object of Expression
        start*: Expression
        stop*: Expression
        step*: Expression
        rangeType*: string
    
    UnaryExpression* = ref object of Expression
        operator*: Token
        right*: Expression
    
    GroupingExpression* = ref object of Expression
        expression*: Expression

    LiteralExpression* = ref object of Expression
        value*: Literal
    
    BlockExpression* = ref object of Expression
        statements*: Statements
        
    AccessingExpression* = ref object of Expression
        identifier*: string
        arguments*: seq[Expression]

    
    # Literals
    Literal* = ref object of RootObj
    
    NumericLiteral* = ref object of Literal
        value*: float

    StringLiteral* = ref object of Literal
        value*: string
    
    BooleanLiteral* = ref object of Literal
        value*: bool
    

    # Statements, TODO
    Statement* = ref object of RootObj
    Statements* = seq[Statement]
    
    ExpressionStatement* = ref object of Statement
        expression*: Expression

    DeclarationStatement* = ref object of Statement
        identifier*: string
        parameters*: seq[string]
        value*: Expression

    WhenStatement* = ref object of Statement
        clauses*: seq[WhenClause]
    
    WhenClause* = ref object
        condition*: Expression
        `block`*: BlockExpression

    LoopStatement* = ref object of Statement
        clauses*: seq[LoopClause]
        `block`*: BlockExpression

    LoopClause* = ref object 
        iterable*: Expression
        counters*: seq[string]


    # Error
    ParserError* = object of CatchableError

