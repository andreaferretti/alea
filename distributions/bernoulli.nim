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