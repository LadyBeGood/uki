# Import the os module for path manipulation
import os

# Package

version       = "0.1.0"
author        = "Anonymous"
description   = "Uki programming language"
license       = "MIT"
srcDir        = "src"
bin           = @["uki"]

# Dependencies

requires "nim >= 2.2.0"


# Custom task for building and moving the binary
task uki, "Build the binary and move it to ../../usr/bin":
    # Step 1: Compile the project in release mode
    exec "nim c --hints:off --stackTrace:on --lineTrace:on src/uki.nim"

    # Step 2: Define the target directory
    let targetDir = getCurrentDir() / "../../usr/bin"

    # Step 4: Move the binary to the target directory
    let binaryPath = "src/uki"
    let targetPath = targetDir

    exec "mv " & binaryPath & " " & targetPath

