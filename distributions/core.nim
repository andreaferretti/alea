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

proc choose*[A](xs: seq[A]): Discrete[A] =
  new result.values
  result.values[] = xs

proc closure*[A](f: proc(a: var Random): A): ClosureVar[A] =
  result.f = f