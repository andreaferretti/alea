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