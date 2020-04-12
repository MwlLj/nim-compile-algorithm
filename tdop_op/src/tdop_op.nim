import "expression/parse"
import "expression/express"
import "../../lexical_analysis/src/token/parse" as token_parse
import "../../lexical_analysis/src/token/handle" as token_handle
import strformat
import options

proc iterExpr(value: express.ExprValue) =
    if value.exp.isSome():
        let exp = value.exp.get()
        if exp.left.isSome():
            echo("left expr:")
        if exp.right.isSome():
            echo("right expr")
        if exp.op.ch.isSome():
            echo(fmt"op: {exp.op.ch.get()}")

proc main() =
    let stream = readFile("./resource/test.dog")
    var tokenParser = token_parse.new(stream)
    let tokens = token_handle.parse(tokenParser)
    echo(tokens)
    var parser = parse.new(tokens)
    let exprValue = parser.express(0)
    if exprValue.isSome():
        iterExpr(exprValue.get())

when isMainModule:
    main()
