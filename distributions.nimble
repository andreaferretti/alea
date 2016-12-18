# Package

version       = "0.1.0"
author        = "Andrea Ferretti"
description   = "Distributions"
license       = "Apache2"
skipDirs = @["tests"]

# Dependencies

requires "nim >= 0.15.0", "random >= 0.5.3"

task tests, "run distribution tests":
  --hints: off
  --linedir: on
  --stacktrace: on
  --linetrace: on
  --debuginfo
  --path: "."
  --run
  setCommand "c", "tests/all"

task test, "run distribution tests":
  setCommand "tests"