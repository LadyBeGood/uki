import strutils, types, json
import lexer, parser, utils

# Define a simple lexer function
proc compiler*(input: string): string =
    let tokens: Tokens = lexer(input)
    let ast: Statements = parser(tokens)
    var str:  string = ""
    for statement in ast:
        str &= printAst(statement)
    return tokens.join("\n") & "\n\n\n" & str


