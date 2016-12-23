import random, random/urandom
import ./core

# Here we wrap the RNG typeclass
# in a type with dynamic dispatch
# and add a few utility methods
proc wrap*[R: RNG](rng: R): Random =
  var r = rng
  proc inner(): float = r.random()

  result.random = inner

proc randomInt*(rng: var Random, cap: int): int =
  result = cap
  while result == cap:
    result = (rng.random() * cap.float).int

proc repeat*(rng: Random, times: int): Random =
  var count = 0
  var lastResult: float

  proc inner(): float =
    if count == 0:
      lastResult = rng.random()
    count += 1
    if count == times:
      count = 0
    return lastResult

  result.random = inner