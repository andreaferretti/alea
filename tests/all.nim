import future, unittest, math
import random, random/urandom, random/mersenne
import distributions

proc isBetween(x, a, b: float): bool = x >= a and x <= b

proc `~`(x, a: float): bool =
  if a != 0:
    abs((x - a) / a) < 0.1
  else:
    abs(x - a) < 0.1

proc isInt(x: float): bool = x.int.float == x

suite "test random number generators":
  # We initialize the random number generator
  var rng = wrap(initMersenneTwister(urandom(16)))

  test "random number generation":
    check(rng.random().isBetween(0, 1))

  test "repeatable random numbers":
    var repeated = rng.repeat(2)
    let
      a1 = repeated.random()
      a2 = repeated.random()
      a3 = repeated.random()
      a4 = repeated.random()
    check(a1 == a2)
    check(a3 == a4)
    check(a2 != a3)


suite "test distributions":
  # We initialize the random number generator
  var rng = wrap(initMersenneTwister(urandom(16)))

  test "creating RandomVar instances":
    let
      c = constant(3)
      u = uniform(2, 18)
      d = choose(@[1, 2, 3])
      f = closure((r: var Random) => 3.0 * r.random())

    check(c is RandomVar[int] == true)
    check(u is RandomVar[float] == true)
    check(d is RandomVar[int] == true)
    check(f is RandomVar[float] == true)

  test "sampling from random variables":
    let
      c = constant(3)
      u = uniform(2, 18)
      d = choose(@[1, 2, 3])
      f = closure((r: var Random) => 3.0 * r.random())

    check(rng.sample(c) == 3)
    check(rng.sample(u).isBetween(2, 18))
    check(@[1, 2, 3].contains(rng.sample(d)))
    check(rng.sample(f).isBetween(0, 3))

  test "mapping random variables":
    let
      d = choose(@[1, 2, 3])
      u = uniform(2, 5)
      s = d.map((x: int) => x * x)
      t = u.map((x: float) => x * x)

    check(@[1, 4, 9].contains(rng.sample(s)))
    check(rng.sample(t).isBetween(4, 25))

  test "filtering random variables":
    let
      d = choose(@[1, 2, 3, 4, 5, 6])
      s = d.filter((x: int) => x mod 2 == 0)

    check(@[2, 4, 6].contains(rng.sample(s)))

  test "computing the mean":
    let
      c = constant(3.5)
      u = uniform(2, 6)
      d = choose(@[1.0, 2.0, 3.0])
      t = choose(@[1, 2, 3]).map((x: int) => x.float)

    check(rng.mean(c) == 3.5)
    check(rng.mean(u) == 4.0)
    check(rng.mean(d) == 2.0)
    check(rng.mean(t) ~ 2.0)

  test "computing the variance and standard deviation":
    let
      c = constant(3.5)
      u = uniform(2, 8)
      d = choose(@[2.0, 4.0, 4.0, 4.0, 5.0, 5.0, 7.0, 9.0])
      t = choose(@[1, 2, 3]).map((x: int) => x.float)

    check(rng.variance(c) == 0.0)
    check(rng.variance(u) == 3.0)
    check(rng.variance(d) == 4.0)
    check(rng.variance(t) ~ 2.0 / 3.0)
    check(rng.stddev(c) == 0.0)
    check(rng.stddev(u) == sqrt(3.0))
    check(rng.stddev(d) == 2.0)
    check(rng.stddev(t) ~ sqrt(2.0 / 3.0))

  test "computing the covariance":
    let u = uniform(2, 6)

    check(rng.covariance(u, u) ~ rng.variance(u))

  test "generating independent variables":
    let
      u1 = uniform(2, 6)
      u2 = uniform(2, 6)
      u3 = u2.clone()

    check(rng.covariance(u1, u2) ~ rng.variance(u1))
    check(rng.covariance(u1, u3) ~ 0)

  test "discretizing random variables":
    let
      u = uniform(2, 5)
      d = rng.discretize(u)

    check(rng.mean(u) ~ rng.mean(d))

  test "arithmetic over random variables":
    let
      u = uniform(3, 5)
      s = u * u

    check(rng.mean(s) ~ 16)

  test "gaussian random variables":
    let
      g = gaussian(3, 5)
      h = g - g

    check(g is RandomVar[float] == true)
    check(rng.mean(g) == 3)
    check(rng.stddev(g) == 5)
    check(rng.mean(h) ~ 0)

  test "bernoulli random variables":
    let
      b = bernoulli(0.6)
      b1 = b.map((x:float) => x)

    check(b is RandomVar[float] == true)
    check(@[0.0, 1.0].contains(rng.sample(b)))
    check(rng.mean(b) == 0.6)
    check(rng.variance(b) == 0.24)
    check(rng.stddev(b) == sqrt(0.24))
    # We also check the empirical mean and variance
    # to make sure we are sampling correctly
    check(rng.mean(b1) ~ 0.6)
    check(rng.variance(b1) ~ 0.24)

  test "poisson random variables":
    let
      p = poisson(9)
      p1 = p.map((x:float) => x)

    check(p is RandomVar[float] == true)
    check(rng.sample(p).isInt)
    check(rng.mean(p) == 9)
    check(rng.variance(p) == 9)
    check(rng.stddev(p) == 3)
    # We also check the empirical mean and variance
    # to make sure we are sampling correctly
    check(rng.mean(p1) ~ 9)
    check(rng.stddev(p1) ~ 3)

  test "poisson random variables with large lambda":
    let
      p = poisson(900)
      p1 = p.map((x:float) => x)

    check(p is RandomVar[float] == true)
    check(rng.sample(p).isInt)
    check(rng.mean(p) == 900)
    check(rng.variance(p) == 900)
    check(rng.stddev(p) == 30)
    # We also check the empirical mean and variance
    # to make sure we are sampling correctly
    check(rng.mean(p1) ~ 900)
    check(rng.stddev(p1) ~ 30)

  test "pairs of random variables":
    let
      d = choose(@[1, 2, 3])
      c = constant(5)
      s = c && d

    check(@[(5, 1), (5, 2), (5, 3)].contains(rng.sample(s)))

  test "lifting functions to random variables":
    proc sq(x: int): int = x * x

    lift(sq)
    let
      d = choose(@[1, 2, 3])
      s = sq(d)

    check(@[1, 4, 9].contains(rng.sample(s)))

  test "conditioning random variables":
    proc sq(x: int): int = x * x

    lift(sq)

    let
      d = choose(@[1, 2, 3, 4, 5, 6])
      s = sq(d)
      t = d.where(s, (x: int) => x > 9)

    check(@[4, 5, 6].contains(rng.sample(t)))

  test "lifts of math operations":
    let
      u = uniform(0, 9)
      s = sqrt(u)

    check(rng.sample(s).isBetween(0, 3))

  test "more complicated math operations":
    let
      a = uniform(0, 9)
      b = choose([1, 2, 3, 4, 5]).map((x: int) => x.float)
      p = poisson(13)
      s = ln(abs((sqrt(a) * b) - (a.floor / log10(p))))

    discard rng.sample(s)