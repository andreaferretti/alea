import sequtils, future, math
import ./core, ./rng

# How to lift a function on values to a function on random variables
proc map*[A, B](x: RandomVar, f: proc(a: A): B): ClosureVar[B] =
  proc inner(rng: var Random): B =
    f(rng.sample(x))

  result.f = inner

# # Useful for monadic composition
# proc flatMap*[A, B](x: RandomVar[A], f: proc(a: A): RandomVar[B]): ClosureVar[B] =
#   proc inner(rng: var Random): B =
#     rng.sample(f(rng.sample(x)))
#
#   result.f = inner

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
proc mean*(rng: var Random, r: RandomVar[float], samples = 100000): float {.inline.} =
  (1 .. samples).foldl(a + rng.sample(r), 0.0) / samples.float

# For a more specific types we can have overloads:
proc mean*(rng: var Random, r: Uniform, samples = 100000): float {.inline.} =
  (r.b + r.a) / 2.0

proc mean*(rng: var Random, r: ConstantVar[float], samples = 100000): float {.inline.} =
  r.value

proc mean*(rng: var Random, r: Discrete[float], samples = 100000): float {.inline.} =
  if r.values[].len < samples:
    r.values[].foldl(a + b, 0.0) / r.values[].len.float
  else:
    (1 .. samples).foldl(a + rng.sample(r), 0.0) / samples.float

proc sq(x: float): float {.inline.} = x * x

proc variance*(rng: var Random, r: RandomVar[float], samples = 100000): float =
  let m = mean(rng, r, samples)
  (1 .. samples).foldl(a + sq(rng.sample(r) - m), 0.0) / samples.float

proc variance*(rng: var Random, r: Uniform, samples = 100000): float =
  sq(r.b - r.a) / 12.0

proc variance*(rng: var Random, r: ConstantVar[float], samples = 100000): float = 0.0

proc variance*(rng: var Random, r: Discrete[float], samples = 100000): float {.inline.} =
  let m = mean(rng, r, samples)
  if r.values[].len < samples:
    r.values[].foldl(a + sq(b - m), 0.0) / r.values[].len.float
  else:
    (1 .. samples).foldl(a + rng.sample(r), 0.0) / samples.float

proc stddev*(rng: var Random, r: RandomVar[float], samples = 100000): float =
  sqrt(variance(rng, r, samples))

# To compute the covariance, we cheat and use a fake random number generator
# that will repeat its results twice. This allows us to get the point in the
# probability space to evaluate both `r` and `s`
proc covariance*(rng: var Random, r, s: RandomVar[float], samples = 100000): float =
  var rep = rng.repeat(2)
  let m1 = mean(rng, r, samples)
  let m2 = mean(rng, s, samples)
  (1 .. samples).foldl(a + (rep.sample(r) - m1) * (rep.sample(s) - m2), 0.0) / samples.float

# The following generates a random variable with the same distribution
# as the input one, but independent of it. The trick is just to neutralize
# the effect of repeated random number generators, by discarding values
# until they are different.
proc clone*(r: RandomVar): auto =
  proc inner(rng: var Random): auto =
    let firstValue = rng.random()
    while rng.random() == firstValue:
      discard
    return rng.sample(r)

  return closure(inner)

# Filter a random variable with respect to a boolean predicate
proc filter*[A](r: RandomVar, p: proc(a: A): bool): auto =
  proc inner(rng: var Random): auto =
    var value = rng.sample(r)
    while not p(value):
      value = rng.sample(r)
    return value

  return closure(inner)

# Filter a  random variable with respect to a boolean predicate
# on a different random variable. We repeat the trick of using
#  repeated rng.
# For some reason, here we need to be specific about `s`
# This constraint should be removed
proc where*[A](r: RandomVar, s: ClosureVar, p: proc(a: A): bool): auto =
  proc inner(rng: var Random): auto =
    var rep = rng.repeat(2)
    var
      value = rep.sample(r)
      cond = rep.sample(s)
    while not p(cond):
      value = rep.sample(r)
      cond = rep.sample(s)
    return value

  return closure(inner)

# Every random variable can be converted into a discrete one
# by sampling a certain number of times
proc discretize*(rng: var Random, r: RandomVar, samples = 10000): auto =
  var values = newSeqOfCap[type(rng.sample(r))](samples)
  for _ in 1 .. samples:
    values.add(rng.sample(r))
  return choose(values)

proc `+`*(x, y: RandomVar[int]): auto =
  map2(x, y, (a: int, b: int) =>  a + b)

proc `+`*(x, y: RandomVar[float]): auto =
  map2(x, y, (a: float, b: float) =>  a + b)

proc `-`*(x, y: RandomVar[int]): auto =
  map2(x, y, (a: int, b: int) =>  a - b)

proc `-`*(x, y: RandomVar[float]): auto =
  map2(x, y, (a: float, b: float) =>  a - b)

proc `*`*(x, y: RandomVar[int]): auto =
  map2(x, y, (a: int, b: int) =>  a * b)

proc `*`*(x, y: RandomVar[float]): auto =
  map2(x, y, (a: float, b: float) =>  a * b)

proc `/`*(x, y: RandomVar[float]): auto =
  map2(x, y, (a: float, b: float) =>  a / b)