import macros, math
import ./core, ./ops

# Lifting functions of one variable
macro lift*[A, B](f: proc(a: A): B): auto =
  let id = !($(f))
  template inner(name: untyped): auto {.inject.} =
    template name(x: RandomVar): auto =
      map(x, name)

  result = getAst(inner(id))

# Use an explicit type hint for overloaded functions
template lift*(f, T: untyped) =
  proc f*(x: RandomVar[T]): auto =
    x.map(proc(t: T): auto = f(t))

lift(abs, float)
lift(sqrt, float)
lift(cbrt, float)
lift(log10, float)
lift(ln, float)
lift(exp, float)
lift(arccos, float)
lift(arcsin, float)
lift(arctan, float)
lift(cos, float)
lift(cosh, float)
lift(sin, float)
lift(sinh, float)
lift(tan, float)
lift(tanh, float)
lift(erf, float)
lift(erfc, float)
lift(lgamma, float)
lift(tgamma, float)
lift(trunc, float)
lift(floor, float)
lift(ceil, float)
lift(degToRad, float)
lift(radToDeg, float)