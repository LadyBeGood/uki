Statement [
    ContainerAssignmentStatement {
        identifier: Token {
            kind: Identifier
            lexeme: "aaa"
            line: 1
        }
        parameters: Token []
        expression: BlockExpression {
            statements: Statement [
                ContainerReassignmentStatement {
                    identifier: Token {
                        kind: Identifier
                        lexeme: "bbb"
                        line: 2
                    }
                    expression: ContainerExpression {
                        identifier: Token {
                            kind: Identifier
                            lexeme: "ccc"
                            line: 2
                        }
                        arguments: Expression []
                    }
                }
            ]
        }
    }
]