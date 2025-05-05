import lexer, types#, parser, codegen, tokens
import os, strutils

proc compile*(input: string): string =
    return generator(parser(lexer(input)))


when isMainModule:
    # Read input from input.x
    let inputFile = "input.uki"
    if not fileExists(inputFile):
        echo "Error: Input file 'input.x' not found"
        quit(1)
    
    let source = readFile(inputFile)
    
    # Compile the source
    let jsCode = compile(source)
    
    # Write output to output.js
    let outputFile = "output.js"
    writeFile(outputFile, jsCode)
    

