import sequtils
import random, random/urandom, random/mersenne


type
  MyRNG = type(initMersenneTwister(urandom(16)))
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
  ClosureVar[A] = object
    f: proc(rng: var MyRNG): A

# How to sample from various concrete instances
proc sample[A](rng: var RNG, c: ConstantVar[A]): A = c.value

proc sample[A; B; C](rng: var RNG, p: ProcVar[A, B, C]): C =
  p.transform(sample(rng, p.source[]))

proc sample(rng: var RNG, u: Uniform): float = u.a + (u.b - u.a) * rng.random()

proc sample[A](rng: var RNG, d: Discrete[A]): A = rng.randomChoice(d.values[])

proc sample[A](rng: var MyRNG, c: ClosureVar[A]): A = c.f(rng)

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

template mapper(f: typed, B: typedesc): auto =
  proc inner(rng: var MyRNG): B =
    f(rng.sample(x))

  result.f = inner

proc map[A, B](x: ConstantVar[A], f: proc(a: A): B): ConstantVar[B] =
  result.value = f(x.value)

proc map[A, B](x: Discrete[A], f: proc(a: A): B): ClosureVar[B] =
  mapper(f, B)

proc map[A, B](x: ClosureVar[A], f: proc(a: A): B): ClosureVar[B] =
  mapper(f, B)

# proc lift2[A; B; C; D](f: proc(a: A, b: B): D, c: C): ProcVar[(A, B), C, D] =
#   new result.source
#   result.source[] = c
#   result.transform = f
#
# proc `&`[A, B](x: RandomVar[A], y: RandomVar[B]): ProcVar[(A, B)] =
#   new result.source
#   result.source[] = b
#   result.transform = f

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
  import typetraits, future

  proc sq(x: float): float = x * x

  # I would like to be able to auto-generate
  # this with a macro
  template sq(x: RandomVar[float]): auto =
    lift1(sq, x)

  # template `*`(x, y: RandomVar[float]): auto =
  #   lift2(`*`, x & y)

  let
    c = constant(3)
    u = uniform(2, 18)
    d = choose(@[1, 2, 3])
    s = sq(u)
    t = d.map((x: int) => x * x)
    z = t.map((x: int) => x * x)

  # I would also like to write
  # (with a different meaning, two different samples)
  # s = u * u
  # This will require a little macro trickery to define overloads
  # for `sq`, `*` and so on

  var rng = initMersenneTwister(urandom(16))

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