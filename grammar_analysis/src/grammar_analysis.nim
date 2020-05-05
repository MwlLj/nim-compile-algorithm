from "../../lexical_analysis/src/token/token" as token import nil
# import "../../lexical_analysis/src/token/token" as token
from "../../lexical_analysis/src/token/parse" as token_parse import nil
from "../../lexical_analysis/src/token/handle" as token_handle import nil

proc parse() =
    let stream  = readFile("./resource/test.lion")
    var tokenParser = token_parse.new(stream)
    let tokens = token_handle.parse(tokenParser)
    echo(tokens)

proc main() =
    parse()

when isMainModule:
    main()
