# Package

version       = "0.1.0"
author        = "Andrea Ferretti"
description   = "Distribution tests"
license       = "Apache2"

# Dependencies

requires "nim >= 0.15.0", "random >= 0.5.3", "nimfp >= 0.3.4"

task test, "run distribution tests":
  --hints: off
  --linedir: on
  --stacktrace: on
  --linetrace: on
  --debuginfo
  --path: ".."
  --run
  setCommand "c", "all.nim"