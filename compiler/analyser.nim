import types, sets, tables, error, sequtils

type
    ContainerInfo* = ref object
        types*: HashSet[DataType]
        assignable*: bool
        line*: int
        origin*: OriginKind


proc analyser*(abstractSyntaxTree: seq[Statement]): seq[Statement] =
    var scopes: seq[TableRef[string, HashSet[DataType]]] = @[]
    var contexts: seq[Context] = @[]
    
    proc beginScope() =
        scopes.add(newTable[string, HashSet[DataType]]())

    proc endScope() =
        discard scopes.pop()

    proc addContext(context: Context) =
        contexts.add(context)
    
    proc popContext() =
        discard contexts.pop()
    
    
    proc insideFunction(): bool =
        for i in countdown(contexts.high, 0):
            if contexts[i] == Context.Procedure:
                return true
        return false
    
    proc insideLoop(): bool =
        for i in countdown(contexts.high, 0):
            case contexts[i]
            of Context.Loop: return true
            of Context.Procedure: break
            of Context.Try: continue
        return false

    proc defineContainer(name: string, line: int, dataTypes: HashSet[DataType]) =
        if name in scopes[^1]:
            error(line, "Container `" & name & "` already defined in this scope")
        scopes[^1][name] = dataTypes


    proc resolveContainer(name: string, line: int): HashSet[DataType] =
        for i in countdown(scopes.high, 0):
            if name in scopes[i]:
                return scopes[i][name]
        error(line, "Undefined container `" & name & "`")

    proc analyseExpression(expression: Expression): HashSet[DataType] 
    proc analyseStatement(statement: Statement)
    
    proc findParameterScope(name: string): int =
        # Search scopes from inner to outer
        for i in countdown(scopes.high, 0):
            if name in scopes[i]:
                # Check if this is a parameter (empty type set)
                if scopes[i][name].len == 0:
                    return i
        return -1
    
    proc expect(expression: Expression, expectedTypes: varargs[HashSet[DataType]]): HashSet[DataType] =
        let actualTypes = analyseExpression(expression)
        
        # Special case for parameter references
        if expression of ContainerExpression:
            let expression = ContainerExpression(expression)
            let identifier = expression.identifier.lexeme
            let paramScope = findParameterScope(identifier)
            
            if paramScope != -1:  # This is a parameter
                # Union all expected types into parameter's allowed types
                for types in expectedTypes:
                    scopes[paramScope][identifier].incl(types)
                return actualTypes
        
        # Normal type checking for non-parameters
        for expected in expectedTypes:
            if allIt(actualTypes, it in expected):
                return actualTypes
        
        error(-1, "Type mismatch")
    



    proc analyseExpression(expression: Expression): HashSet[DataType] =
        if expression of LiteralExpression:
            let literal = LiteralExpression(expression).value
            if literal of StringLiteral:
                return toHashSet([DataType.String])
            elif literal of NumericLiteral:
                return toHashSet([DataType.Number])
            elif literal of BooleanLiteral:
                return toHashSet([DataType.Boolean])
        
        elif expression of ContainerExpression:
            let expression = ContainerExpression(expression)
            return resolveContainer(expression.identifier.lexeme, expression.identifier.line)
        
        elif expression of UnaryExpression:
            let expression = UnaryExpression(expression)
            if (expression.operator.tokenKind == TokenKind.Exclamation):
                return expect(expression.right, toHashSet([DataType.Boolean]))
            elif (expression.operator.tokenKind == TokenKind.Minus):
                return expect(expression.right, toHashSet([DataType.Number]))
        
        elif expression of BinaryExpression:
            let expression = BinaryExpression(expression)
            
            if expression.operator.tokenKind == TokenKind.Plus:
                let leftDataType =  expect(expression.left,  toHashSet([DataType.String]), toHashSet([DataType.Number]))
                let rightDataType = expect(expression.right, toHashSet([DataType.String]), toHashSet([DataType.Number]))
                
                if leftDataType != rightDataType:
                    error(expression.operator.line, "Expected both to be Numbers or Strings")
                return leftDataType
            else:
                discard expect(expression.left, toHashSet([DataType.Number]))
                discard expect(expression.right, toHashSet([DataType.Number]))
                return toHashSet([DataType.Number])
            
        elif expression of RangeExpression:
            let expression = RangeExpression(expression)
            discard expect(expression.start, toHashSet([DataType.Number]))
            discard expect(expression.stop,  toHashSet([DataType.Number]))
            discard expect(expression.step,  toHashSet([DataType.Number]))
            return toHashSet([DataType.Structure])
        
        elif expression of GroupingExpression:
            let expression = GroupingExpression(expression)
            return analyseExpression(expression.expression)
        
        elif expression of BlockExpression:
            let expression = BlockExpression(expression)
            beginScope()
            for statement in expression.statements:
                analyseStatement(statement)
            endScope()
            return toHashSet([DataType.Procedure])
        
        elif expression of WhenExpression:
            let expression = WhenExpression(expression)
            for subExpression in expression.whenSubExpressions:
                discard expect(subExpression.condition, toHashSet([DataType.Boolean]))
                expression.dataTypes.incl(analyseExpression(subExpression.expression))
            return expression.dataTypes
        
        elif expression of TryExpression:
            let expression = TryExpression(expression)
            beginScope()
            expression.dataTypes.incl(analyseExpression(expression.tryExpression))
            for subExpression in expression.fixExpressions:
                expression.dataTypes.incl(analyseExpression(subExpression.fixExpression))
            endScope()
            return expression.dataTypes
        
        elif expression of LoopExpression:
            let expression = LoopExpression(expression)
            beginScope()
            for subExpression in expression.withExpressions:
                let iterableDataType = analyseExpression(subExpression.iterable)
                subExpression.iterableDataType = iterableDataType
                for counter in subExpression.counters:
                    defineContainer(counter.lexeme, counter.line, initHashSet[DataType]())
            let h = analyseExpression(expression.expression)
            endScope()
            return h
        else:
            error(-1, "Unknown expression (internal error, meant for compiler diagnostics)")



    proc analyseStatement(statement: Statement) =
        if statement of ExpressionStatement:
            let statement =  ExpressionStatement(statement)
            discard analyseExpression(statement.expression)
        
        elif statement of ContainerAssignmentStatement:
            let statement = ContainerAssignmentStatement(statement)
            
            # First declare the container with empty types to break recursion
            defineContainer(statement.identifier.lexeme, statement.identifier.line, initHashSet[DataType]())
            
            # Analyze the expression in parameter scope
            beginScope()
            addContext(Context.Procedure)
            
            # Define parameters as variables in the inner scope
            for parameter in statement.parameters:
                defineContainer(parameter.identifier.lexeme, parameter.identifier.line, initHashSet[DataType]())
            
            # Analyze the container body
            let bodyTypes = analyseExpression(statement.expression)
            popContext()
            endScope()
            
            # Now update the container with the actual types
            scopes[^1][statement.identifier.lexeme] = bodyTypes
        
        elif statement of WhenStatement:
            let statement = WhenStatement(statement)
            for subStatement in statement.whenSubStatements:
                discard expect(subStatement.condition, toHashSet([DataType.Boolean]))
                discard analyseExpression(subStatement.`block`)
        elif statement of TryStatement:
            let statement = TryStatement(statement)
            beginScope()
            discard analyseExpression(statement.tryBlock)
            for subStatement in statement.fixStatements:
                discard analyseExpression(subStatement.fixBlock)
            endScope()
        elif statement of LoopStatement:
            let statement = LoopStatement(statement)
            beginScope()
            addContext(Context.Loop)
            for withStatement in statement.withStatements:
                withStatement.iterableDataType.incl(analyseExpression(withStatement.iterable))
                for counter in withStatement.counters:
                    defineContainer(counter.lexeme, counter.line, initHashSet[DataType]())
            discard analyseExpression(statement.`block`)
            popContext()
            endScope()
        elif statement of ExitStatement:
            let statement = ExitStatement(statement)
            if not insideFunction():
                error(statement.keyword.line, "Can not exit outside a function")
        elif statement of StopStatement:
            let statement = StopStatement(statement)
            if not insideLoop():
                error(statement.keyword.line, "Can not stop the iteration outside a loop")
        elif statement of NextStatement:
            let statement = NextStatement(statement)
            if not insideLoop():
                error(statement.keyword.line, "Can not skip to next iteration outside a loop")
        else:
            error(-1, "Unknown statement (internal error, meant for compiler diagnostics)")

    # Global scope begin
    beginScope()
    
    # Main resolution process
    for statement in abstractSyntaxTree:
        analyseStatement(statement)
    
    # Global scope end
    endScope()

    
    return abstractSyntaxTree




