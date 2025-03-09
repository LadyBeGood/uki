import os, strutils, compiler

# Main procedure
proc main() =
    if paramCount() < 1:
        echo "Usage: uki input.uki"
        quit(1)

    let inputFile = paramStr(1)
    let outputFile = "e.uki"

    # Read the input file
    let inputText = readFile(inputFile)
    if inputText.strip(chars = {' ', '\t', '\n'}, leading = true, trailing = false)  == "":
        echo "Empty file"
        quit(1)

    # Process the input through the lexer
    let outputText = compiler(inputText)

    # Write the output to the output file
    writeFile(outputFile, outputText)


main()
