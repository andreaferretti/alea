# Copyright 2017 UniCredit S.p.A.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import math
import ./core

type Poisson* = object
  l*: float

proc poisson*(l: float): Poisson =
  assert(l > 0)
  Poisson(l: l)

# https://en.wikipedia.org/wiki/Poisson_distribution#Generating_Poisson-distributed_random_variables
# algorithm poisson random number (Knuth):
#
#     init:
#          Let L ← e−λ, k ← 0 and p ← 1.
#     do:
#          k ← k + 1.
#          Generate uniform random number u in [0,1] and let p ← p × u.
#     while p > L.
#     return k − 1.
proc sampleKnuth(rng: var Random, p: Poisson): float =
  let L = exp(-p.l)
  var
    k = 0
    p = 1.0
    first = true
  while p > L or first:
    first = false
    k += 1
    p *= rng.random()
  return (k - 1).float

proc sq(x: float): float {.inline.} = x * x

# “method PA” from “The Computer Generation of Poisson Random Variables” by
# A. C. Atkinson, Journal of the Royal Statistical Society Series C
# (Applied Statistics) Vol. 28, No. 1. (1979), pages 29-35. Method PA is on page 32.
#
# http://www.johndcook.com/blog/2010/06/14/generating-poisson-random-values/
#
# c = 0.767 - 3.36/lambda
# beta = PI/sqrt(3.0*lambda)
# alpha = beta*lambda
# k = log(c) - lambda - log(beta)
#
# forever
# {
# 	u = random()
# 	x = (alpha - log((1.0 - u)/u))/beta
# 	n = floor(x + 0.5)
# 	if (n < 0)
# 		continue
# 	v = random()
# 	y = alpha - beta*x
# 	lhs = y + log(v/(1.0 + exp(y))^2)
# 	rhs = k + n*log(lambda) - log(n!)
# 	if (lhs <= rhs)
# 		return n
# }
proc sampleByRejection(rng: var Random, p: Poisson): float =
  let
    c = 0.767 - 3.36 / p.l
    beta = PI/sqrt(3.0 * p.l)
    alpha = beta * p.l
    k = ln(c) - p.l - ln(beta)
  while true:
    let
      u = rng.random()
      x = (alpha - ln((1.0 - u) / u)) / beta
      n = floor(x + 0.5)
    if (n < 0):
      continue
    let
      v = rng.random()
      y = alpha - beta * x
      lhs = y + ln(v / sq(1.0 + exp(y)))
      rhs = k + n * ln(p.l) - lgamma(n + 1)
    if lhs <= rhs:
      return n

# To make Poisson an instance of RandomVar[float],
# just define `sample`
proc sample*(rng: var Random, p: Poisson): float =
  if (p.l < 30):
    sampleKnuth(rng, p)
  else:
    sampleByRejection(rng, p)

# One can also specialize other stats, such as the mean,
# when they are known in advance
proc mean*(rng: var Random, p: Poisson, samples = 100000): float = p.l

proc variance*(rng: var Random, p: Poisson, samples = 100000): float = p.l