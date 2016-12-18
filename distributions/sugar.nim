import macros
import ./core, ./ops

# Lifting functions of one variable

macro lift*[A, B](f: proc(a: A): B): auto =
  let id = !($(f))
  template inner(name: untyped): auto {.inject.} =
    template name(x: RandomVar): auto =
      map(x, name)

  result = getAst(inner(id))