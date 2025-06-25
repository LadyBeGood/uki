import terminal, os

proc run*(function: proc(input: string): string) =
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
        let input = readFile(absInputPath)
        let output = function input
        createDir(absOutputPath.parentDir)
        writeFile(absOutputPath, output)
    except IOError as e:
        styledEcho(fgRed, "Error: ", resetStyle, e.msg)
        quit(1)
    except:
        styledEcho(fgRed, "Error: ", resetStyle, "Unexpected error")
        quit(1)


