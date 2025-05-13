import compiler/compiler

when isMainModule:
    let input: string = readFile("./garbage/input.uki")
    let output: string = compiler(input)
    writeFile("./garbage/output.js", output)
    
