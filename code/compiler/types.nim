## Utkrisht - the Utkrisht programming language
## Copyright (C) 2025 Haha-jk
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
        input*: string
        tokens*: Tokens




    NodeKind* = enum
        NumberLiteral
        Binary



    AbstractSyntaxTree* = seq[Expression]
    
    ParserOutput* = object
        diagnostics*: Diagnostics
        abstractSyntaxTree*: AbstractSyntaxTree



    # Expressions
    Expression* = ref object of RootObj
    Expressions* = seq[Expression]

    BinaryExpression* = ref object of Expression
        left*: Expression
        operator*: Token
        right*: Expression

    UnaryExpression* = ref object of Expression
        operator*: Token
        right*: Expression
    
    GroupingExpression* = ref object of Expression
        expression*: Expression

    LiteralExpression* = ref object of Expression
        value*: Literal
    
    # Literals
    Literal* = ref object of RootObj
    
    NumericLiteral* = ref object of Literal
        value*: float

    StringLiteral* = ref object of Literal
        value*: string
    
    BooleanLiteral* = ref object of Literal
        value*: bool
    







discard """
    Statment* = object
    
    Statments* = seq[Statment]
    


    Object = ref object of RootObj

    BooleanObject = ref object of Object
        data: bool
    
    NumberObject = ref object of Object
        data: float
    
    StringObject = ref object of Object
        data: string
  
    
    FunctionParameter = ref object of ExpressionStatement
        name: string
        default: Expression

    FunctionArgument = ref object of ExpressionStatement
        value: Expression  
    
    FunctionParameters = seq[FunctionParameter]
    FunctionArguments = seq[FunctionArgument]
   
    # Expressions
    Expression = ref object of RootObj
    Expressions = seq[Expression]

    BinaryExpression = ref object of Expression
        left: Expression
        operator: Token
        right: Expression

    FunctionExpression = ref object of Expression
        functionIdentifier: string
        arguments: FunctionArguments
    
    VariableExpression = ref object of Expression
        variableIdentifier: string
    
    GroupingExpression = ref object of Expression
        Expression: Expression

    LiteralExpression = ref object of Expression
        value: Object

    UnaryExpression = ref object of Expression
        operator: Token
        right: Expression
    

    # Statement
    Statement = ref object of RootObj
    Statements = seq[Statement]
    
    
    
    VariableDeclarationStatement = ref object of Statement
        variableIdentifier: string
        value: Expression
    
    VariableReassignmentStatement = ref object of Statement
        variableIdentifier: string
        value: Expression
    
    FunctionDeclarationStatement = ref object of Statement
        functionIdentifier: string
        parameters: FunctionParameters
        body: Statement
    
    ExpressionStatement = ref object of Statement
        expression: Expression
    
    LoopStatement = ref object of Statement
        condition: Expressions
        placeholder: Statement
    
    WhenStatement = ref object of Statement
        condition: Expression
        placeholder: Statement
        otherwise: Statement
    
    ControlStatement = ref object of Statement
        kind: TokenKind
        value: Expression
    
    EmptyControlStatement = ref object of Statement
        kind: TokenKind
    
    BlockStatement = ref object of Statement
        statements: Statements

"""

