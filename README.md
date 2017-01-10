# Distributions

[![nimble](https://raw.githubusercontent.com/yglukhov/nimble-tag/master/nimble.png)](https://github.com/yglukhov/nimble-tag)

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

A few common operations on random variables are supported - in particular
mapping and filtering:

```nim
import distributions, future

let
  a = uniform(3, 12)
  b = a.map((x: float) => 3 - x)
  c = a.filter((x: float) => x > 5)
```

Mapping, in particular, is a common operation, and there is a macro `lift`
that takes a function `A => B` and declares a function of the same name of
type `RandomVar[A] => ClosureVar[B]` that is obtained by mapping. It can be
used with a type hint in case the function is overloaded, as in

```nim
import math

proc sq(x: float): float = x * x

lift(abs, float)
lift(sq) # No ambiguity here

let
  a = uniform(3, 12)
  b = sq(abs(a))
```

There is also a version of two arguments `map2`, that takes two random variables
and a binary function. Generalization for more than two arguments can be done
using the fact that random variables form
[a monad](https://slawekk.wordpress.com/2009/05/31/probability-monad/)
but the relevant functions are still to be implemented.

Many mathematical functions, as well as the arithmetic operations, are already
lifted, so the following is valid:

```nim
let
  a = uniform(3, 12)
  b = choose(@[1.0, 2.5, 3.7])
  c = abs(a - b) * sqrt(a)
```

## Conditioning random variables

Random variables can also be conditioned with respect to each other. For
instance, if `a` and `b` are real random variables and we want to condition
`a` to the occurrence that `b` is positive, we can do:

```nim
let c = a.where(b, (x: float) => x > 0)
```

where the last parameter to `where` is a predicate that should be satisfied
by samples from `b`.

How to make this work? Drawing from `b` will change the status of the random
number generator, which in theory prevents us from sampling `a` at the same
point.

To avoid this issue, we use a fake random number generator that wraps another
instance of `Random`, but repeats its result twice. That is, internally we
use an auxiliary (fake) RNG defined like

```nim
var repeated = rng.repeat(2)
```

You can use the same trick whenever there is the need to draw more than a single
sample from the same point of the probability space.

## Statistics on random variables

A few common statistics are implemented on `RandomVar[float]`, such as the mean,
variance and so on. There is a generic implementation that will work for any
random variable, but particular types of random variables can use more specialized
methods.

An example of their usage is:

```nim
let x = uniform(2, 5) + choose(@[1.2, 3.3, 4.5])
var rng = ...

echo rng.sample(x)
echo rng.mean(x)
echo rng.variance(x)
echo rng.stddev(x)
```

The covariance is also implemented, again by using the trick of a repeating
random number generator to draw from the two distributions at the same time.

All there operations admit an optional parameter which is the number of samples
to compute the statistics with more or less accuracy:

```nim
echo rng.mean(x, samples = 1000000)
```

Finally, complex random variables, that are represented by chains of closures,
can be approximated by sampling enough times. There is a function `discretize`
that will take any `RandomVar[A]` and produce an instance of `Discrete[A]` that
will wrap a certain number of samples:

```nim
let f = ... # Some complex random variable
let d = f.discretize(samples = 20000)
```

## More distributions

A few common real random variables are implemented:

```nim
let
  g = gaussian(mu = 0, sigma = 1)
  p = poisson(3.5)
  b = bernoulli(0.7)
```

Usually, the statistics for these notable random variables are known, so we have
overloads, in such a way that, for instance, the mean of a Gaussian variable
will always be exact.

## Defining custom distributions

To define your own random variables, you can take inspiration, say, from
`bernoulli.nim`. The only mandatory operation for a type `T` to be an instance
of `RandomVar[A]` is

```nim
proc sample(rng: var Random, t: T): A
```

If other statistics are known (such as mean, variance and so on), one can
also define overloads such as

```nim
proc mean(rng: var Random, t: T, samples = 100000)
```

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

* improve the DSL for conditioning
* higher moments and other statistics
* monad composition
* histograms
* add more standard distributions (beta, gamma, geometric...)
* entropy etc.