import os

# Package

version       = "0.1.5"
author        = "Andrea Ferretti"
description   = "A library to work with random variables"
license       = "Apache2"
skipDirs = @["tests"]

# Dependencies

requires "nim >= 0.18.0", "random >= 0.5.6"

task test, "run alea tests":
  withDir "tests":
    exec "nimble test"