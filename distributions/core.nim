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

type
  # A random number generator
  Random* = object
    random*: proc(): float
  # A generic typeclass for a random var
  RandomVar*[A] = concept x
    var rng: Random
    rng.sample(x) is A
  # A few concrete instances
  ConstantVar*[A] = object
    value*: A
  Uniform* = object
    a*, b*: float
  Discrete*[A] = object
    values*: ref seq[A]
  ClosureVar*[A] = object
    f*: proc(rng: var Random): A

# How to sample from various concrete instances
proc sample*[A](rng: var Random, c: ConstantVar[A]): A = c.value

proc sample*(rng: var Random, u: Uniform): float = u.a + (u.b - u.a) * rng.random()

proc sample*[A](rng: var Random, d: Discrete[A]): A =
  d.values[rng.randomInt(d.values[].len)]

proc sample*[A](rng: var Random, c: ClosureVar[A]): A = c.f(rng)

# A few constructors
converter constant*[A](a: A): ConstantVar[A] = ConstantVar[A](value: a)

proc uniform*(a, b: float): Uniform = Uniform(a: a, b: b)

proc choose*[A](xs: openarray[A]): Discrete[A] =
  new result.values
  result.values[] = @xs

proc closure*[A](f: proc(a: var Random): A): ClosureVar[A] =
  result.f = f