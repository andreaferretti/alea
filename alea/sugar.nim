# Copyright 2017 UniCredit S.p.A.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

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
lift(gamma, float)
lift(trunc, float)
lift(floor, float)
lift(ceil, float)
lift(degToRad, float)
lift(radToDeg, float)
