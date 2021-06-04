# Package

version       = "1.2.2"
author        = "Andreas Rumpf"
description   = "Karax is a framework for developing single page applications in Nim."
license       = "MIT"

# Dependencies

requires "nim >= 0.18.0"
requires "ws"
requires "dotenv"
skipDirs = @["examples", "experiments", "tests"]

bin = @["karax/tools/karun"]
installExt = @["nim"]
