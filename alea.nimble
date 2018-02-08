# Package

version       = "0.1.2"
author        = "Andrea Ferretti"
description   = "A library to work with random variables"
license       = "Apache2"
skipDirs = @["tests"]

# Dependencies

requires "nim >= 0.17.3", "random >= 0.5.3"

task test, "run alea tests":
  withDir "tests":
    exec "nimble test"