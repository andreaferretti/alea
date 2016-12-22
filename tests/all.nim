import future, unittest, math
import random, random/urandom, random/mersenne
import distributions

template isBetween(x, a, b: float): bool = x >= a and x <= b

template `~`(x, a: float): bool = abs(x - a) < 0.1

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
    let b = bernoulli(0.6)

    check(b is RandomVar[float] == true)
    check(@[0.0, 0.1].contains(rng.sample(b)))
    check(rng.mean(b) == 0.6)
    check(rng.variance(b) == 0.24)
    check(rng.stddev(b) == sqrt(0.24))

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

  test "lifts of math operations":
    let
      u = uniform(0, 9)
      s = sqrt(u)

    check(rng.sample(s).isBetween(0, 3))

  test "more complicated math operations":
    let
      a = uniform(0, 9)
      b = choose([1, 2, 3, 4, 5]).map((x: int) => x.float)
      s = ln(abs((sqrt(a) * b) - (a.floor / log10(b))))

    discard rng.sample(s)