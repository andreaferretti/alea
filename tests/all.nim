import future, unittest
import random, random/urandom, random/mersenne
import distributions

template isBetween(x, a, b: float): bool = x >= a and x <= b

template `~`(x, a: float): bool = abs(x - a) < 0.1

suite "test distributions":
  # We initialize the random number generator
  var rng = wrap(initMersenneTwister(urandom(16)))

  test "creating ranvom var instances":
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
      u = uniform(2, 6)
      t = choose(@[1, 2, 3]).map((x: int) => x.float)

    check(rng.mean(u) == 4.0)
    check(rng.mean(t) ~ 2.0)

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

  test "pairs of random variables":
    let
      d = choose(@[1, 2, 3])
      c = constant(5)
      s = c && d

    check(@[(5, 1), (5, 2), (5, 3)].contains(rng.sample(s)))

  test "lifting functions random variables":
    proc sq(x: int): int = x * x

    lift(sq)
    let
      d = choose(@[1, 2, 3])
      s = sq(d)

    check(@[1, 4, 9].contains(rng.sample(s)))