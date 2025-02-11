import options

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
    
    






