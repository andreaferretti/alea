import sequtils, random
import random, random/urandom, random/mersenne


type
  # A random number generator
  Random = object
    random: proc(): float
  # A generic typeclass for a random var
  RandomVar[A] = concept x
    var rng: Random
    rng.sample(x) is A
  # A few concrete instances
  ConstantVar[A] = object
    value: A
  Uniform = object
    a, b: float
  Discrete[A] = object
    values: ref seq[A]
  ClosureVar[A] = object
    f: proc(rng: var Random): A

# Here we wrap the RNG typeclass
# in a type with dynamic dispatch
# and add a few utility methods
proc wrap[R: RNG](rng: R): Random =
  proc inner(): float =
    var r = rng
    return r.random()

  result.random = inner

proc randomInt(rng: var Random, cap: int): int =
  result = cap
  while result == cap:
    result = (rng.random() * cap.float).int

# How to sample from various concrete instances
proc sample[A](rng: var Random, c: ConstantVar[A]): A = c.value

proc sample(rng: var Random, u: Uniform): float = u.a + (u.b - u.a) * rng.random()

proc sample[A](rng: var Random, d: Discrete[A]): A =
  d.values[rng.randomInt(d.values[].len)]

proc sample[A](rng: var Random, c: ClosureVar[A]): A = c.f(rng)

# A few constructors
converter constant[A](a: A): ConstantVar[A] = ConstantVar[A](value: a)

proc uniform(a, b: float): Uniform = Uniform(a: a, b: b)

proc choose[A](xs: seq[A]): Discrete[A] =
  new result.values
  result.values[] = xs

proc closure[A](f: proc(a: var Random): A): ClosureVar[A] =
  result.f = f

# How to lift a function on values to a function on random variables
proc map[A, B](x: RandomVar, f: proc(a: A): B): ClosureVar[B] =
  proc inner(rng: var Random): B =
    f(rng.sample(x))

  result.f = inner

# We can try to extend `map` to more than one source distribution by using
# tuples of distributions. Unfortunately, here we get an error if we do not
# leave A and B fully generic
proc `&&`[A, B](x: A, y: B): auto =
  proc inner(rng: var Random): auto =
    (rng.sample(x), rng.sample(y))

  return closure(inner)

# Other utilities, e.g. the mean:

# Not the most accurate way to compute the mean, but still
proc mean(rng: var Random, r: RandomVar[float], samples = 10000): float =
  (1 .. samples).foldl(a  + rng.sample(r), 0.0) / samples.float

# For a more specific types we can have overloads:
proc mean(rng: var Random, r: Uniform, samples = 10000): float = (r.b - r.a) / 2.0

when isMainModule:
  import typetraits, future

  proc sq(x: float): float = x * x

  # I would like to be able to auto-generate
  # this with a macro
  template sq(x: RandomVar[float]): auto =
    map(x, sq)

  # template `*`(x, y: RandomVar[float]): auto =
  #   lift2(`*`, x & y)

  let
    c = constant(3)
    u = uniform(2, 18)
    d = choose(@[1, 2, 3])
    s = sq(u)
    t = d.map((x: int) => x * x)
    z = u.map((x: float) => x * x)
    w = t && d

  # I would also like to write
  # (with a different meaning, two different samples)
  # s = u * u
  # This will require a little macro trickery to define overloads
  # for `sq`, `*` and so on

  var rng = wrap(initMersenneTwister(urandom(16)))

  # Check that they are all random variables
  echo(c is RandomVar[int])
  echo(u is RandomVar[float])
  echo(d is RandomVar[int])
  echo(s is RandomVar[float])
  echo(t is RandomVar[int])
  echo(t is RandomVar)
  # Sampling
  echo rng.sample(c)
  echo rng.sample(s)
  echo rng.sample(t)
  echo rng.sample(z)
  echo rng.sample(w)
  echo rng.mean(s)
  echo rng.mean(u)
  # All this rng is repetitive: another macro would allow
  # to use a common context, like this:
  #
  # withRng rng:
  #   echo sample(c)
  #   echo sample(s)
  #   echo mean(s)
  #
  # Whenever a statement does not compile, try to add rng as first parameter