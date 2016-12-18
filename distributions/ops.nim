import sequtils, future
import ./core

# How to lift a function on values to a function on random variables
proc map*[A, B](x: RandomVar, f: proc(a: A): B): ClosureVar[B] =
  proc inner(rng: var Random): B =
    f(rng.sample(x))

  result.f = inner

# How to lift a function on two values to a function on random variables
proc map2*[A, B, C](x, y: RandomVar, f: proc(a: A, b: B): C): ClosureVar[C] =
  proc inner(rng: var Random): B =
    f(rng.sample(x), rng.sample(y))

  result.f = inner

# We can try to extend `map` to more than one source distribution by using
# tuples of distributions. Unfortunately, here we get an error if we do not
# leave A and B fully generic
proc `&&`*[A, B](x: A, y: B): auto =
  proc inner(rng: var Random): auto =
    (rng.sample(x), rng.sample(y))

  return closure(inner)

# Other utilities, e.g. the mean:

# Not the most accurate way to compute the mean, but still
proc mean*(rng: var Random, r: RandomVar[float], samples = 100000): float =
  (1 .. samples).foldl(a  + rng.sample(r), 0.0) / samples.float

# For a more specific types we can have overloads:
proc mean*(rng: var Random, r: Uniform, samples = 100000): float = (r.b + r.a) / 2.0

# Every random variable can be converted into a discrete one
# by sampling a certain number of times
proc discretize*(rng: var Random, r: RandomVar, samples = 10000): auto =
  var values = newSeqOfCap[type(rng.sample(r))](samples)
  for _ in 1 .. samples:
    values.add(rng.sample(r))
  return choose(values)

proc `*`*(x, y: RandomVar[int]): auto =
  map2(x, y, (a: int, b: int) =>  a * b)

proc `*`*(x, y: RandomVar[float]): auto =
  map2(x, y, (a: float, b: float) =>  a * b)