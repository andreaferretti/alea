# Distributions

Define and compose random variables.

## How to test it

Install `nim` (e.g. with brew), then `nimble test`

## Random numbers

First, we need a way to generate random numbers. Here, a random number generator
is defined dynamically as an object having a method that returns a uniform
number in [0,1]:

```nim
type Random = object
  random: proc(): float
```

One can obtain instances of `Random` by wrapping the RNG defined in
[nim-random](https://github.com/BlaXpirit/nim-random), such as in

```nim
import random/urandom, random/mersenne
import distributions

var rng = wrap(initMersenneTwister(urandom(16)))
```

The reason why we need to wrap them is that random number generators in
nim-random are defined as a [concept](http://nim-lang.org/docs/manual.html#generics-concepts),
while it will be simpler in the sequel to represent them as a single type.

## Random variables

A random variable of type `A` is just something that can take a random number
generator and provide an instance of type `A`:

```nim
type RandomVar[A] = concept x
  var rng: Random
  rng.sample(x) is A
```

In other word, the only operation that we need to define on a type `T` to
make it an instance of `RandomVar[A]` is

```nim
proc sample(rng: var Random, t: T): A = ...
```

Here we require the first parameter to be of type `var Random` because drawing
a random number mutates the internal state of the RNG. It may be more clear to
return a new state together with the value of type `A`, much like in the
[state monad](https://en.wikibooks.org/wiki/Haskell/Understanding_monads/State)
but we avoid doing so for performance reason.

If we think of the internal state space of the random number generator as the
probability space `Ω`, the similarity between our definition and the mathematical
definition of random variable is apparent.

A few core random variables are defined:

* `ConstantVar[A]` is a just a trivial random variable that always samples
  the same value
* `Uniform` is a uniform variable over a real interval
* `Discrete[A]` is a discrete random variable that can take a finite number of
  values with equal probability
* `ClosureVar[A]` is a wrapper over a `proc(rng: var Random): A`

Most random variables that arise by manipulating other variables are of
`ClosureVar` type.

Here is an example showing how to costruct instances of these variables. Types
are inferred, and are there just for explanatory purposes:

```nim
import distributions

proc f(rng: var Random): float = 2 * rng.random()

let
  c: ConstantVar[string] = constant("hello")
  u: Uniform = uniform(2, 14)
  d: Discrete[int] = choose(@[1, 2, 3, 4, 5])
  x: ClosureVar[float] = closure(f)
```

## Operations on random variables

To be documented, see `tests/all.nim`

## Conditioning random variables

To be documented, see `tests/all.nim`

## More distributions

To be documented, see `tests/all.nim`

## A complete example

Here is a small example that combines all of the above:

```nim
import future
import random/urandom, random/mersenne
import distributions

var rng = wrap(initMersenneTwister(urandom(16)))
let
  a = uniform(0, 9)
  b = choose([1, 2, 3, 4, 5]).map((x: int) => x.float)
  c = poisson(13)
  d = gaussian(mu = 3, sigma = 5).filter((x: float) => x > 3)
  s = ln(abs((sqrt(a) * b) - (a.floor / log10(c)))) + d
  t = c.where(s, (x: float) => x > 5)
  u = rng.discretize(t)

echo rng.mean(s)
echo rng.stddev(u)
```

## TODO

* improved the DSL for conditioning
* higher moments
* monad composition
* histograms
* add more standard distributions (beta, gamma, geometric...)
* entropy etc.