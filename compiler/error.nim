import terminal

proc error*(line: int, message: string) =
    styledEcho fgRed, "Error", resetStyle, " [Line " & $line & "]: " & message
    quit(1)

