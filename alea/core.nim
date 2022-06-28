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
  # A closure returning a random number
  RandomGen* = proc(): float {.gcsafe.}
  # A closure using an RNG to return a random number
  RandomArgGen*[A] = proc(rng: var Random): A {.gcsafe.}

  # A closure taking one argument and returning a number
  ClosureArg*[A, B] = proc(a: A): B {.gcsafe.}
  # A closure taking two arguments and returning a number
  Closure2Arg*[A, B, C] = proc(a: A, b: B): C {.gcsafe.}
  # A closure taking a number and returning a bool
  ClosureBool*[A] = proc(a: A): bool {.gcsafe.}

  # A random number generator
  Random* = object
    random*: RandomGen
  # A generic typeclass for a random var
  RandomVar*[A] = concept x
    var rng: Random
    rng.sample(x) is A
  # A few concrete instances
  ConstantVar*[A] = object
    value*: A
  Uniform* = object
    a*, b*: float
  Choice*[A] = object
    values*: ref seq[A]
  ClosureVar*[A] = object
    f*: RandomArgGen[A]

# How to sample from various concrete instances
proc sample*[A](rng: var Random, c: ConstantVar[A]): A = c.value

proc sample*(rng: var Random, u: Uniform): float = u.a + (u.b - u.a) * rng.random()

proc sample*[A](rng: var Random, d: Choice[A]): A =
  d.values[rng.randomInt(d.values[].len)]

proc sample*[A](rng: var Random, c: ClosureVar[A]): A = c.f(rng)

# A few constructors
converter constant*[A: not void](a: A): ConstantVar[A] = ConstantVar[A](value: a)

proc uniform*(a, b: float): Uniform = Uniform(a: a, b: b)

proc choice*[A](xs: openarray[A]): Choice[A] =
  new result.values
  result.values[] = @xs

proc closure*[A](f: RandomArgGen[A]): ClosureVar[A] =
  result.f = f
