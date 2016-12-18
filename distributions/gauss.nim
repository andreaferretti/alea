import math
import ./core

type Gaussian* = object
  mu*, sigma*: float

proc gaussian*(mu, sigma: float): Gaussian =
  Gaussian(mu: mu, sigma: sigma)

# To make Gaussian an instance of RandomVar[float],
# just define `sample`
proc sample*(rng: var Random, g: Gaussian): float =
  var
    s = 0.0
    u = 0.0
    v = 0.0
  while s > 1 or s == 0:
    u = 2.0 * rng.random() - 1.0
    v = 2.0 * rng.random() - 1.0
    s = (u * u) + (v * v)
  let x = u * sqrt(-2.0 * ln(s) / s)
  return g.mu + (g.sigma * x)

# One can also specialize other stats, such as the mean,
# when they are known in advance
proc mean*(rng: var Random, g: Gaussian, samples = 100000): float = g.mu