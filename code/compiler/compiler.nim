## Utkrisht - the Utkrisht programming language
## Copyright (C) 2025 Haha-jk
##
## This file is part of Utkrisht and is licensed under the AGPL-3.0-or-later.
## See the license.txt file in the root of this repository.


import types, lexer, parser, generator

proc compiler*(input: string): string =
    return generator(parser(lexer(input)))


when isMainModule:
    let input: string = readFile("./garbage/input.uki")
    let output: string = compiler(input)
    writeFile("./garbage/output.js", output)
    



