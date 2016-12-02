import sequtils
import random, random/urandom, random/mersenne


type
  # A generic typeclass for a random var
  RandomVar[A] = concept x
    var rng = initMersenneTwister(urandom(16))
    rng.sample(x) is A
  # A few concrete instances
  ConstantVar[A] = object
    value: A
  Uniform = object
    a, b: float
  Discrete[A] = object
    values: ref seq[A]
  ProcVar[A; B; C] = object
    source: ref B
    transform: proc(a: A): C

# How to sample from various concrete instances
proc sample[A](rng: var RNG, c: ConstantVar[A]): A = c.value

proc sample[A; B; C](rng: var RNG, p: ProcVar[A, B, C]): C =
  p.transform(sample(rng, p.source[]))

proc sample(rng: var RNG, u: Uniform): float = u.a + (u.b - u.a) * rng.random()

proc sample[A](rng: var RNG, d: Discrete[A]): A = rng.randomChoice(d.values[])

# A few constructors
converter constant[A](a: A): ConstantVar[A] = ConstantVar[A](value: a)

proc uniform(a, b: float): Uniform = Uniform(a: a, b: b)

proc choose[A](xs: seq[A]): Discrete[A] =
  new result.values
  result.values[] = xs

# How to lift a function on values to a function on random variables
proc lift1[A; B; C](f: proc(a: A): C, b: B): ProcVar[A, B, C] =
  new result.source
  result.source[] = b
  result.transform = f

# Other utilities, e.g. the mean:

# Not the most accurate way to compute the mean, but still
proc mean(rng: var RNG, r: RandomVar[float], samples = 10000): float =
  (1 .. samples).foldl(a  + rng.sample(r), 0.0) / samples.float
  # var total = 0.0
  # for _ in 1 .. samples:
  #   total += rng.sample(r)
  # return total / samples.float

# For a more specific types we can have overloads:
proc mean(rng: var RNG, r: Uniform, samples = 10000): float = (r.b - r.a) / 2.0

when isMainModule:
  proc sq(x: float): float = x * x
  let
    c = constant(3)
    u = uniform(2, 18)
    d = choose(@[1, 2, 3])
    s = lift1(sq, u)

    # This is not ideal yet
    # I would like to write
    # s = sq(u)
    # or (with a different meaning, two different samples)
    # s = u * u
    # This will require a little macro trickery to define overloads
    # for `sq`, `*` and so on

  var rng = initMersenneTwister(urandom(16))

  # Check that they are all random variables
  echo(c is RandomVar[int])
  echo(u is RandomVar[float])
  echo(d is RandomVar[int])
  echo(s is RandomVar[float])
  # Sampling
  echo rng.sample(c)
  echo rng.sample(s)
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