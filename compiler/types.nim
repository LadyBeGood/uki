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


    Token* = ref object  
        tokenKind*: TokenKind
        lexeme*: string  
        line*: int 
    
    Tokens* = seq[Token]
    



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
        
    ContainerExpression* = ref object of Expression
        identifier*: string
        arguments*: seq[Expression]

    WhenThenExpression* = ref object of Expression
        whenThenSubExpressions*: seq[WhenThenSubExpression]
    
    WhenThenSubExpression* = ref object
        condition*: Expression
        expression*: Expression
    
    LoopWithExpression* = ref object of Expression
        loopWithSubExpressions*: seq[LoopWithSubExpression]
        expression*: Expression
    
    LoopWithSubExpression* = ref object
        iterable*: Expression
        counters*: seq[string]
    
    TryFixExpression* = ref object of Expression
        tryExpression*: Expression
        tryFixSubExpressions*: seq[TryFixSubExpression]
    
    TryFixSubExpression* = ref object
        identifier*: string
        fixExpression*: Expression


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

    ContainerStatement* = ref object of Statement
        identifier*: string
        parameters*: seq[string]
        expression*: Expression

    WhenThenStatement* = ref object of Statement
        whenThenSubStatements*: seq[WhenThenSubStatement]
    
    WhenThenSubStatement* = ref object
        condition*: Expression
        `block`*: BlockExpression

    LoopWithStatement* = ref object of Statement
        loopWithSubStatements*: seq[LoopWithSubStatement]
        `block`*: BlockExpression

    LoopWithSubStatement* = ref object 
        iterable*: Expression
        counters*: seq[string]

    TryFixStatement* = ref object of Statement
        tryBlock*: BlockExpression
        tryFixSubStatements*: seq[TryFixSubStatement]
    
    TryFixSubStatement* = ref object
        identifier*: string
        fixBlock*: BlockExpression




