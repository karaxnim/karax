# Package

version       = "1.1.2"
author        = "Andreas Rumpf"
description   = "Karax is a framework for developing single page applications in Nim."
license       = "MIT"

# Dependencies

requires "nim >= 0.16.1"

skipDirs = @["examples", "experiments", "tests"]

bin = @["karax/tools/karun"]
installExt = @["nim"]
