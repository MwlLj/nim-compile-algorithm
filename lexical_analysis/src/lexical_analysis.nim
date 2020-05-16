import "./token/parse"
import "./token/handle"
import "./token/token"
import options
import strformat

proc main() =
    let stream = readFile("./resource/test.lion")
    var parser = parse.new(stream)
    let tokens = handle.parse(parser)
    for t in tokens:
        if t.value.str.isSome():
            echo(fmt"tokenType: {t.tokenType}, value: {t.value.str.get()}")
        elif t.value.ch.isSome():
            echo(fmt"tokenType: {t.tokenType}, value: {t.value.ch.get()}")
        elif t.value.i64.isSome():
            echo(fmt"tokenType: {t.tokenType}, value: {t.value.i64.get()}")
        else:
            discard

when isMainModule:
    main()
