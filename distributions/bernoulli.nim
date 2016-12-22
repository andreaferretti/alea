import math
import ./core

type Bernoulli* = object
  p*: float

proc bernoulli*(p: float): Bernoulli =
  assert((p >= 0) and (p <= 1))
  Bernoulli(p: p)

# To make Bernoulli an instance of RandomVar[float],
# just define `sample`
proc sample*(rng: var Random, b: Bernoulli): float =
  if rng.random() <= b.p: 1.0 else: 0.0

# One can also specialize other stats, such as the mean,
# when they are known in advance
proc mean*(rng: var Random, b: Bernoulli, samples = 100000): float = b.p

proc variance*(rng: var Random, b: Bernoulli, samples = 100000): float =
  b.p * (1.0 - b.p)