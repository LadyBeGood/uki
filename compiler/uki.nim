import lexer, parser, analyser, transformer, generator


proc compiler*(input: string): string =
    return generator transformer analyser parser lexer input


when isMainModule:
    import cli
    
    run(compiler)




