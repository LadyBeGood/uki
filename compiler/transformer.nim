import types

type 
    
    # Ecmascript expressions
    EcmascriptExpression* = ref object of RootObj

    EcmascriptIdentifier* = ref object of EcmascriptExpression
        identifier*: string
        arguments*: seq[EcmascriptArgument]
    
    EcmascriptArgument* = ref object
        identifier*: string
        value*: EcmascriptExpression
    
    EcmascriptLiteralExpression* = ref object of EcmascriptExpression
        value*: EcmascriptLiteral

    EcmascriptUnaryExpression* = ref object of EcmascriptExpression
        operator*: string
        right*: EcmascriptExpression
    
    EcmascriptBinaryExpression* = ref object of EcmascriptExpression
        left*: EcmascriptExpression
        operator*: string
        right*: Expression
    
    EcmascriptGroupingExpression* = ref object of EcmascriptExpression
        expression*: EcmascriptExpression



    # Ecmascript literals
    EcmascriptLiteral* = ref object of RootObj
    
    EcmascriptNumericLiteral* = ref object of EcmascriptLiteral
        value*: float

    EcmascriptStringLiteral* = ref object of EcmascriptLiteral
        value*: string
    
    EcmascriptBooleanLiteral* = ref object of EcmascriptLiteral
        value*: bool

    
    # Ecmascript statements
    EcmascriptStatement* = ref object of RootObj
    
    EcmascriptExpressionStatement* = ref object of EcmascriptStatement
        expression*: Expression
    
    EcmascriptVariableDeclaration* = ref object of EcmascriptStatement 
        identifier*: string
        expression*: Expression
    
    EcmascriptForStatement* = ref object of EcmascriptStatement
        initialisation*: Statement
        condition*: Expression
        update*: Statement
    
    EcmascriptIfStatement* = ref object of EcmascriptStatement
        


    EcmascriptFunctionDeclarationStatement* = ref object of EcmascriptStatement
        identifier*: string
        parameters*: seq[EcmascriptParameter]
        expression*: EcmascriptExpression
    
    EcmascriptParameter* = ref object
        identifier*: string
        defaultValue*: EcmascriptExpression
    
    EcmascriptVariableReassignmentStatement* = ref object of EcmascriptStatement
        identifier*: string
        expression*: EcmascriptExpression

    EcmascriptIfStatement* = ref object of EcmascriptStatement
        EcmascriptIfSubStatements*: seq[EcmascriptIfSubStatement]
        
    EcmascriptIfSubStatement* = ref object
        condition*: EcmascriptExpression
        `block`*: EcmascriptBlockStatement

    EcmascriptBlockStatement* = ref object of EcmascriptStatement
        statements*: seq[EcmascriptStatement]
    

    EcmascriptTryStatement* = ref object of EcmascriptStatement
        tryBlock*: EcmascriptBlockStatement
        fixStatements*: seq[EcmascriptFixStatement]
    
    EcmascriptFixStatement* = ref object
        identifier*: string
        fixBlock*: EcmascriptBlockStatement
    
    EcmascriptReturnStatement* = ref object of EcmascriptStatement
        expression*: EcmascriptExpression
    
    EcmascriptContinueStatement* = ref object of EcmascriptStatement
        counter*: string
    
    EcmascriptBreakStatement* = ref object of EcmascriptStatement
        counter*: string






proc transformer*(abstractSyntaxTree: seq[Statement]): seq[Statement] =
    var ecmascriptAbstractSyntaxTree: seq[EcmascriptStatement] = @[]
    
    proc expressionTransformer(expression: Expression): EcmascriptExpression =
        if expression of ContainerExpression:
            let expression = ContainerExpression(expression)
            result.add "ContainerExpression {\n"
            result.add indent & "    identifier: "
            result.add tokenToString(expression.identifier, indentLevel + 1)
            if expression.arguments.len() != 0:
                result.add indent & "    arguments: Argument [\n"
                for argument in expression.arguments:
                    result.add indent & "        Argument {\n"
                    result.add indent & "            " & tokenToString(argument.identifier, indentLevel + 3)
                    result.add indent & "            " & expressionToString(argument.value, indentLevel + 3)
                    result.add indent & "        }\n"
                result.add indent & "    ]\n"
            else:
                result.add indent & "    arguments: Expression []\n"
            result.add indent & "}\n"
            
        elif expression of WhenExpression:
            let expression = WhenExpression(expression)
            result.add "WhenExpression {\n"
            result.add indent & "    dataTypes: " & $expression.dataTypes & "\n"
            result.add indent & "    whenSubExpressions: WhenSubExpression [\n"
            for subExpression in expression.whenSubExpressions:                
                result.add indent & "        WhenSubExpression {\n"
                result.add indent & "            keyword: " & tokenToString(subExpression.keyword, indentLevel + 3)
                result.add indent & "            condition: " &  expressionToString(subExpression.condition, indentLevel + 3)
                result.add indent & "            expression: " & expressionToString(subExpression.expression, indentLevel + 3)
                result.add indent & "        }\n"
            result.add indent & "    ]\n"
            result.add indent & "}\n"
            
        elif expression of LoopExpression:
            let expression = LoopExpression(expression)
            result.add "LoopExpression {\n"
            result.add indent & "    loopKeyword: " & tokenToString(expression.loopKeyword, indentLevel + 1)
            result.add indent & "    withExpressions: WithExpression [\n"
            for withExpression in expression.withExpressions:
                result.add indent & "        WithExpression {\n"
                result.add indent & "            withKeyword: " & tokenToString(withExpression.withKeyword, indentLevel + 3)
                result.add indent & "            iterable: " & expressionToString(withExpression.iterable, indentLevel + 3)
                result.add indent & "            iterableDataType: " & $withExpression.iterableDataType & "\n"
                if withExpression.counters.len() == 0:
                    result.add indent & "            counters: Identifier []\n"
                else:
                    result.add indent & "            counters: Identifier [\n"
                    for counter in withExpression.counters:
                        result.add indent & "                Identifier {\n"
                        result.add indent & "                    " & tokenToString(counter, indentLevel + 5)
                        result.add indent & "                }\n"
                    result.add indent & "            ]\n"
                result.add indent & "        }\n"
            result.add indent & "    ]\n"
            result.add indent & "    expression: " & expressionToString(expression.expression, indentLevel + 1)
            result.add indent & "}\n"
            
        elif expression of TryExpression:
            let expression = TryExpression(expression)
            result.add "TryExpression {\n"
            result.add indent & "    dataTypes: " & $expression.dataTypes & "\n"
            result.add indent & "    tryKeyword: " & tokenToString(expression.tryKeyword, indentLevel + 1)
            result.add indent & "    tryExpression: " & expressionToString(expression.tryExpression, indentLevel + 1)
            result.add indent & "    fixExpressions: FixExpression [\n"
            for fixExpression in expression.fixExpressions:
                result.add indent & "        FixExpression {\n"
                result.add indent & "            fixKeyword: " & tokenToString(fixExpression.fixKeyword, indentLevel + 3)
                result.add indent & "            identifier: " & tokenToString(fixExpression.identifier, indentLevel + 3)
                result.add indent & "            fixExpression: " & expressionToString(fixExpression.fixExpression, indentLevel + 3)
                result.add indent & "        }\n"
            result.add indent & "    ]\n"
            result.add indent & "}\n"
        
        elif expression of BlockExpression:
            let expression = BlockExpression(expression)
            result.add "BlockExpression {\n"
            result.add indent & "    statements: Statement [\n"
            for statement in expression.statements:
                result.add statementToString(statement, indentLevel + 2)
            result.add indent & "    ]\n"
            result.add indent & "}\n"
        
        elif expression of LiteralExpression:
            let expression = LiteralExpression(expression)
            result.add "LiteralExpression {\n"
            result.add indent & "    value: "
            if expression.value of BooleanLiteral:
                let val = BooleanLiteral(expression.value)
                result.add "BooleanLiteral {\n" 
                result.add indent & "        value: " & $val.value & "\n"
            elif expression.value of StringLiteral:
                let val = StringLiteral(expression.value)
                result.add "StringLiteral {\n" 
                result.add indent & "        value: " & "\"" & $val.value & "\"" & "\n"
            elif expression.value of NumericLiteral:
                let val = NumericLiteral(expression.value)
                result.add "NumericLiteral {\n" 
                result.add indent & "        value: " & $val.value & "\n"
            else:
                result.add "Unknown literal type\n"
            result.add indent & "    }\n"
            result.add indent & "}\n"
        
        elif expression of GroupingExpression:
            let expression = GroupingExpression(expression)
            result.add "GroupingExpression {\n"
            result.add indent & "    expression: " & expressionToString(expression.expression, indentLevel + 1)
            result.add indent & "}\n"
        
        elif expression of UnaryExpression:
            let expression = UnaryExpression(expression)
            result.add "UnaryExpression {\n"
            result.add indent & "    operator: " & tokenToString(expression.operator, indentLevel + 1)
            result.add indent & "    right: " & expressionToString(expression.right, indentLevel + 1)
            result.add indent & "}\n"
            
        elif expression of RangeExpression:
            let expression = RangeExpression(expression)
            result.add "RangeExpression {\n"
            result.add indent & "    start: " & expressionToString(expression.start, indentLevel + 1)
            result.add indent & "    firstOperator: " & tokenToString(expression.firstOperator, indentLevel + 1)
            result.add indent & "    stop: " & expressionToString(expression.stop, indentLevel + 1)
            result.add indent & "    secondOperator: " & tokenToString(expression.secondOperator, indentLevel + 1)
            result.add indent & "    step: " & expressionToString(expression.step, indentLevel + 1)
            result.add indent & "}\n"
    
        elif expression of BinaryExpression:
            let expression = BinaryExpression(expression)
            result.add "BinaryExpression {\n"
            result.add indent & "    left: " & expressionToString(expression.left, indentLevel + 1)
            result.add indent & "    operator: " & tokenToString(expression.operator, indentLevel + 1)
            result.add indent & "    right: " & expressionToString(expression.right, indentLevel + 1)
            result.add indent & "}\n"
        
    
    proc statementTransformer(statement: Statement): EcmascriptStatement =
        if statement of ExpressionStatement:
            let statement = ExpressionStatement(statement)
            return 
            
        elif statement of ContainerAssignmentStatement:
            let statement = ContainerAssignmentStatement(statement)
            result.add indent & "ContainerAssignmentStatement {\n"
            result.add indent & "    identifier: " & tokenToString(statement.identifier, indentLevel + 1)
            if statement.parameters.len() != 0:
                result.add indent & "    parameters: Parameter [\n"
                for parameter in statement.parameters:
                    result.add indent & "        Parameter {\n"
                    result.add indent & "            identifier: " & tokenToString(parameter.identifier, indentLevel + 3)
                    result.add indent & "            defaultValue: " & expressionToString(parameter.defaultValue, indentLevel + 3)
                    result.add indent & "        }\n"
                result.add indent & "    ]\n"
            else:
                result.add indent & "    parameters: Token []\n"
                
            result.add indent & "    expression: " & expressionToString(statement.expression, indentLevel + 1)
            result.add indent & "}\n"
        
        elif statement of ContainerReassignmentStatement:
            let statement = ContainerReassignmentStatement(statement)
            result.add indent & "ContainerReassignmentStatement {\n"
            result.add indent & "    identifier: " & tokenToString(statement.identifier, indentLevel + 1)
            result.add indent & "    expression: " & expressionToString(statement.expression, indentLevel + 1)
            result.add indent & "}\n"
        
        elif statement of WhenStatement:
            let statement = WhenStatement(statement)
            result.add indent & "WhenStatement {\n"
            result.add indent & "    whenSubStatements: WhenSubStatement [\n"
            for subStatement in statement.whenSubStatements:
                result.add indent & "        WhenSubStatement {\n"
                result.add indent & "            keyword: " & tokenToString(subStatement.keyword, indentLevel + 3)
                result.add indent & "            condition: " & expressionToString(subStatement.condition, indentLevel + 3)
                result.add indent & "            block: " &  expressionToString(subStatement.block, indentLevel + 3)
                result.add indent & "        }\n"
            result.add indent & "    ]\n"
            result.add indent & "}\n"
            
        elif statement of LoopStatement:
            let statement = LoopStatement(statement)
            result.add indent & "LoopStatement {\n"
            result.add indent & "    loopKeyword: " & tokenToString(statement.loopKeyword, indentLevel + 1)
            result.add indent & "    withStatements: WithStatement [\n"
            for i, withStatement in statement.withStatements:
                result.add indent & "        WithStatement {\n"
                result.add indent & "            withKeyword: " & tokenToString(withStatement.withKeyword, indentLevel + 3)
                result.add indent & "            iterable: " & expressionToString(withStatement.iterable, indentLevel + 3)
                result.add indent & "            iterableDataType: " & $withStatement.iterableDataType & "\n"
                result.add indent & "            counters: Identifier [\n"
                for counter in withStatement.counters:
                    result.add indent & "                Identifier {\n"
                    result.add indent & "                    " & tokenToString(counter, indentLevel + 5)
                    result.add indent & "                }\n"
                result.add indent & "            ]\n"
                result.add indent & "        }\n"
            result.add indent & "    ]\n"
            result.add indent & "    block: " & expressionToString(statement.`block`, indentLevel + 1)
            result.add indent & "}\n"
        
        elif statement of TryStatement:
            let statement = TryStatement(statement)
            result.add indent & "TryStatement {\n"
            result.add indent & "    tryKeyword: " & tokenToString(statement.tryKeyword, indentLevel + 1)
            result.add indent & "    tryBlock: " & expressionToString(statement.tryBlock, indentLevel + 1)
            result.add indent & "    fixStatements: FixStatement [\n"
            for fixStatement in statement.fixStatements:
                result.add indent & "        FixStatement {\n"
                result.add indent & "            fixKeyword: " & tokenToString(fixStatement.fixKeyword, indentLevel + 3)
                result.add indent & "            identifier: " & tokenToString(fixStatement.identifier, indentLevel + 3)
                result.add indent & "            fixBlock: " & expressionToString(fixStatement.fixBlock, indentLevel + 3)
                result.add indent & "        }\n"
            result.add indent & "    ]\n"
            result.add indent & "}\n"
            
        elif statement of ExitStatement:
            let statement = ExitStatement(statement)
            result.add indent & "ExitStatement {\n"
            result.add indent & "    keyword: " & tokenToString(statement.keyword, indentLevel + 1)
            result.add indent & "    expression: " & expressionToString(statement.expression, indentLevel + 1)
            result.add indent & "}\n"
        
        elif statement of StopStatement:
            let statement = StopStatement(statement)
            result.add indent & "StopStatement {\n"
            result.add indent & "    keyword: " & tokenToString(statement.keyword, indentLevel + 1)
            result.add indent & "    counter: " & tokenToString(statement.counter, indentLevel + 1)
            result.add indent & "}\n"
        
        elif statement of NextStatement:
            let statement = NextStatement(statement)
            result.add indent & "NextStatement {\n"
            result.add indent & "    keyword: " & tokenToString(statement.keyword, indentLevel + 1)
            result.add indent & "    counter: " & tokenToString(statement.counter, indentLevel + 1)
            result.add indent & "}\n"
 
    
    for statement in abstractSyntaxTree:
        ecmascriptAbstractSyntaxTree.add(statementTransformer(statement))
    
    return ecmascriptAbstractSyntaxTree






