import sets

type
    TokenKind* {.pure.} = enum
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
        When  
        Else  
        Try  
        Fix  
        Loop  
        With  
        Import  
        Export  
        Right  
        Wrong
        Exit
        Stop
        Next
      
        # Spacing  
        Indent  
        Dedent  


    Token* = ref object  
        tokenKind*: TokenKind
        lexeme*: string  
        line*: int 
    
    
    # For type checking at analyser phase 
    # And determining the proper `loop statement`, `loop expression`, `when statement` and `when expression` construct at transformer phase
    DataType* {.pure.} = enum
        String 
        Boolean 
        Number
        Procedure
        Structure

    
    
    # Expressions
    Expression* = ref object of RootObj

    ContainerExpression* = ref object of Expression
        identifier*: Token
        arguments*: seq[Argument]
    
    Argument* = ref object
        identifier*: Token
        value*: Expression
    
    LiteralExpression* = ref object of Expression
        value*: Literal

    UnaryExpression* = ref object of Expression
        operator*: Token
        right*: Expression
    
    BinaryExpression* = ref object of Expression
        left*: Expression
        operator*: Token
        right*: Expression

    RangeExpression* = ref object of Expression
        start*: Expression
        firstOperator*: Token
        stop*: Expression
        secondOperator*: Token
        step*: Expression
    
    GroupingExpression* = ref object of Expression
        expression*: Expression

    BlockExpression* = ref object of Expression
        statements*: seq[Statement]

    WhenExpression* = ref object of Expression
        dataTypes*: HashSet[DataType]
        whenSubExpressions*: seq[WhenSubExpression]
        
    WhenSubExpression* = ref object
        keyword*: Token
        condition*: Expression
        expression*: Expression

    LoopExpression* = ref object of Expression
        loopKeyword*: Token
        withExpressions*: seq[WithExpression]
        expression*: Expression
    
    WithExpression* = ref object
        withKeyword*: Token
        iterable*: Expression
        iterableDataType*: HashSet[DataType]
        counters*: seq[Token]
    
    TryExpression* = ref object of Expression
        dataTypes*: HashSet[DataType]
        tryKeyword*: Token
        tryExpression*: Expression
        fixExpressions*: seq[FixExpression]
    
    FixExpression* = ref object
        fixKeyword*: Token
        identifier*: Token
        fixExpression*: Expression


    # Literals
    Literal* = ref object of RootObj
    
    NumericLiteral* = ref object of Literal
        value*: float

    StringLiteral* = ref object of Literal
        value*: string
    
    BooleanLiteral* = ref object of Literal
        value*: bool
    

    # Statements
    Statement* = ref object of RootObj
    
    ExpressionStatement* = ref object of Statement
        expression*: Expression

    ContainerAssignmentStatement* = ref object of Statement
        identifier*: Token
        parameters*: seq[Parameter]
        expression*: Expression
    
    Parameter* = ref object
        identifier*: Token
        defaultValue*: Expression
    
    ContainerReassignmentStatement* = ref object of Statement
        identifier*: Token
        expression*: Expression

    WhenStatement* = ref object of Statement
        whenSubStatements*: seq[WhenSubStatement]
        
    WhenSubStatement* = ref object
        keyword*: Token
        condition*: Expression
        `block`*: BlockExpression

    LoopStatement* = ref object of Statement
        loopKeyword*: Token
        withStatements*: seq[WithStatement]
        `block`*: BlockExpression

    WithStatement* = ref object 
        withKeyword*: Token
        iterable*: Expression
        iterableDataType*: HashSet[DataType]
        counters*: seq[Token]

    TryStatement* = ref object of Statement
        tryKeyword*: Token
        tryBlock*: BlockExpression
        fixStatements*: seq[FixStatement]
    
    FixStatement* = ref object
        fixKeyword*: Token
        identifier*: Token
        fixBlock*: BlockExpression
    
    ExitStatement* = ref object of Statement
        keyword*: Token
        expression*: Expression
    
    NextStatement* = ref object of Statement
        keyword*: Token
        counter*: Token
    
    StopStatement* = ref object of Statement
        keyword*: Token
        counter*: Token

    Context* {.pure.} = enum
        Procedure
        Loop
        Try

