# Package

version       = "0.1.0"
author        = "Andrea Ferretti"
description   = "Distribution tests"
license       = "Apache2"

# Dependencies

requires "nim >= 0.18.0", "random >= 0.5.4", "nimfp >= 0.3.4"

task test, "run distribution tests":
  --hints: off
  --linedir: on
  --stacktrace: on
  --linetrace: on
  --debuginfo
  --path: ".."
  --run
  --define:reportConceptFailures
  setCommand "c", "test.nim"