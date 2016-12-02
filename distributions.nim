import macros
import random, random/urandom, random/mersenne


type
  RandomVar[A] = concept x
    var rng = initMersenneTwister(urandom(16))
    rng.sample(x) is A
  ConstantVar[A] = object
    value: A
  Uniform = object
    a, b: float
  Discrete[A] = object
    values: ref seq[A]
  ProcVar[A; B; C] = object
    source: ref B
    transform: proc(a: A): C

proc sample[A](rng: var RNG, c: ConstantVar[A]): A = c.value

proc sample[A; B; C](rng: var RNG, p: ProcVar[A, B, C]): C =
  p.transform(sample(rng, p.source[]))

proc sample(rng: var RNG, u: Uniform): float = u.a + (u.b - u.a) * rng.random()

proc sample[A](rng: var RNG, d: Discrete[A]): A = rng.randomChoice(d.values[])

converter constant[A](a: A): ConstantVar[A] = ConstantVar[A](value: a)

proc uniform(a, b: float): Uniform = Uniform(a: a, b: b)

proc choose[A](xs: seq[A]): Discrete[A] =
  new result.values
  result.values[] = xs

# proc sq(x: int): int = x * x

proc sq(x: float): float = x * x

proc lift1[A; B; C](f: proc(a: A): C, b: B): ProcVar[A, B, C] =
  new result.source
  result.source[] = b
  result.transform = f

# template lift1(f, b: typed): auto =
#   ProcVar(source = b, transform = f)

when isMainModule:
  let
    c = constant(3)
    u = uniform(2, 18)
    d = choose(@[1, 2, 3])
    s = lift1(sq, u)

  var rng = initMersenneTwister(urandom(16))

  echo(c is RandomVar[int])
  echo(u is RandomVar[float])
  echo(d is RandomVar[int])
  echo(s is RandomVar[int])
  echo rng.sample(c)
  echo rng.sample(s)