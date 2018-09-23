# Package

version       = "0.2.0"
author        = "Xored Software, Inc."
description   = "Karax is a framework for developing single page applications in Nim."
license       = "MIT"

# Dependencies

requires "nim >= 0.16.1"

skipDirs = @["examples", "experiments", "tests"]

bin = @["karax/tools/karun"]
installExt = @["nim"]
