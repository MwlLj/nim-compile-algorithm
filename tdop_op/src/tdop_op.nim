import "expression/parse"
import "../../lexical_analysis/src/token/parse" as token_parse
import "../../lexical_analysis/src/token/handle" as token_handle

proc main() =
    let stream = readFile("./resource/test.dog")
    var tokenParser = token_parse.new(stream)
    let tokens = token_handle.parse(tokenParser)
    echo(tokens)
    var parser = parse.new(tokens)
    let exprValue = parser.express(0)
    echo(exprValue)

when isMainModule:
    main()
