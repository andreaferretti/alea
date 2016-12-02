package example

import java.util.Random


trait RandomVar[A] {
  def sample(rng: Random): A
}

object RandomVar {
  implicit class MyRandom(val rng: Random) {
    def sample[A](r: RandomVar[A]) = r.sample(rng)
  }

  def lift1[A1, B](f: A1 => B) = (r: RandomVar[A1]) =>
    ProcVar(rng => f(r.sample(rng)))

  def lift2[A1, A2, B](f: (A1, A2) => B) = (r1: RandomVar[A1], r2: RandomVar[A2]) =>
    ProcVar(rng => f(r1.sample(rng), r2.sample(rng)))
}

class Constant[A] private(a: A) extends RandomVar[A] {
  def sample(rng: Random) = a
}

object Constant {
  def apply[A](a: A) = new Constant(a)
}

class Uniform private(a: Double, b: Double) extends RandomVar[Double] {
  def sample(rng: Random) = a + (b - a) * rng.nextDouble()
}

object Uniform {
  def apply(a: Double, b: Double) = new Uniform(a, b)
}

class Discrete[A] private(as: Seq[A]) extends RandomVar[A] {
  def sample(rng: Random) = as(rng.nextInt(as.length))
}

object Discrete {
  def apply[A](as: Seq[A]) = new Discrete(as)
}

class ProcVar[A] private(p: Random => A) extends RandomVar[A] {
  def sample(rng: Random) = p(rng)
}

object ProcVar {
  def apply[A](p: Random => A) = new ProcVar(p)
}


object Distributions extends App {
  import RandomVar._

  def sq(x: Double) = x * x
  def sum(a: Int, b: Int): Int = a + b

  val c = Constant(3)
  val u = Uniform(3, 18)
  val d = Discrete(List(1, 2, 3, 4))
  val s = lift1(sq)
  def sum(r1: RandomVar[Int], r2: RandomVar[Int]): RandomVar[Int] = lift2[Int, Int, Int](sum)(r1, r2)
  val rng = new Random

  println(rng.sample(c))
  println(rng.sample(u))
  println(rng.sample(d))
  println(rng.sample(s(u)))
  println(rng.sample(sum(c, d)))
}