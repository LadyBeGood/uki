import macros

macro shout*(args: varargs[untyped]): untyped =
    result = newStmtList()
    for arg in args:
        result.add(quote do:
            echo `arg`.astToStr, " = ", `arg`
        )
