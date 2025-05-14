## Utkrisht - the Utkrisht programming language
## Copyright (C) 2025 LadyBeGood
##
## This file is part of Utkrisht and is licensed under the AGPL-3.0-or-later.
## See the license.txt file in the root of this repository.


import lexer, parser, generator

proc compiler*(input: string): string =
    return generator(parser(lexer(input)))



when isMainModule:
    import os, terminal
    
    if paramCount() < 1:
        styledEcho(fgRed, "Error: ", resetStyle, "Missing input file")
        styledEcho(fgCyan, "Usage: ", resetStyle, getAppFilename().extractFilename(), " <input_file> [output_file]")
        quit(1)
    
    let
        inputPath = paramStr(1)
        outputPath = if paramCount() >= 2: paramStr(2) else: inputPath.changeFileExt("js")
        inputDir = getAppDir()
        absInputPath = if inputPath.isAbsolute: inputPath else: inputDir / inputPath
        absOutputPath = if outputPath.isAbsolute: outputPath else: inputDir / outputPath
    
    if not fileExists(absInputPath):
        styledEcho(fgRed, "Error: ", resetStyle, "Input file not found: ", fgYellow, absInputPath)
        quit(1)
    
    try:
        let 
            input = readFile(absInputPath)
            output = compiler(input)
        
        # Create output directory if it doesn't exist
        createDir(absOutputPath.parentDir)
        writeFile(absOutputPath, output)
        styledEcho(fgGreen, "Success: ", resetStyle, "Compiled ", fgBlue, absInputPath, 
                             resetStyle, " to ", fgMagenta, absOutputPath)
    except IOError as e:
        styledEcho(fgRed, "Error: ", resetStyle, e.msg)
        quit(1)
    except:
        styledEcho(fgRed, "Error: ", resetStyle, "Unexpected error during compilation")
        quit(1)
