import math
import ./core

type Gaussian* = object
  mu*, sigma*: float

proc gaussian*(mu, sigma: float): Gaussian =
  Gaussian(mu: mu, sigma: sigma)

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

proc mean*(rng: var Random, g: Gaussian, samples = 100000): float = g.mu