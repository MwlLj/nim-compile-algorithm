from "../../lexical_analysis/src/token/parse" as token_parse import nil
from "../../lexical_analysis/src/token/handle" as token_handle import nil
# from "parse/parse" as grammarparse import nil
import "parse/parse" as grammarparse
import "parse/handle" as grammarhandle
import "parse/ihandle"
import "parse/handle_parse" as grammarhandleparse
import "structs/scope"
import "strformat"

proc printDividing(n: int) =
    var s: string
    for _ in 0..n:
        s.add("-")
    echo(s)

proc main() =
    let stream  = readFile("./resource/test.lion")
    var tokenParser = token_parse.new(stream)
    let tokens = token_handle.parse(tokenParser)
    echo(tokens)
    printDividing(100)
    var parser = grammarparse.newParser(tokens)
    let handle: ihandle.IHandle = new(grammarhandle.Handle)
    var sc = scope.newScope("main", true)
    handle.parse(parser, sc)
    let opts = parser.getOpts()
    for i, opt in opts.pairs:
      echo(fmt"#{i}: {opt}")

when isMainModule:
    main()
