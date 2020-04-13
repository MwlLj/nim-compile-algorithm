import "expression/parse"
import "expression/express"
import "../../lexical_analysis/src/token/parse" as token_parse
import "../../lexical_analysis/src/token/handle" as token_handle
import strformat
import options

proc iterExpr(value: express.ExprValue): int64 =
    if value.exp.isSome():
        var left, right: int64 = 0
        var op: char
        let exp = value.exp.get()
        if exp.op.ch.isSome():
            op = exp.op.ch.get()
            echo(fmt"op: {op}")
        if exp.left.isSome():
            echo("left expr:")
            left = iterExpr(exp.left.get())
        if exp.right.isSome():
            echo("right expr: ")
            right = iterExpr(exp.right.get())
        case op
        of '+':
            return left + right
        of '-':
            return left - right
        of '*':
            return left * right
        of '/':
            return left div right
        else:
            discard
    elif value.value.isSome():
        let v = value.value.get().i64.get()
        echo(v)
        return v

proc main() =
    let stream = readFile("./resource/test.dog")
    var tokenParser = token_parse.new(stream)
    let tokens = token_handle.parse(tokenParser)
    echo(tokens)
    var parser = parse.new(tokens)
    let exprValue = parser.express(0)
    if exprValue.isSome():
        let r = iterExpr(exprValue.get())
        echo(fmt"result: {r}")

when isMainModule:
    main()
