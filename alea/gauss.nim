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

proc variance*(rng: var Random, g: Gaussian, samples = 100000): float =
  g.sigma * g.sigma

proc stddev*(rng: var Random, g: Gaussian, samples = 100000): float = g.sigma