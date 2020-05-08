from "../../lexical_analysis/src/token/parse" as token_parse import nil
from "../../lexical_analysis/src/token/handle" as token_handle import nil
# from "parse/parse" as grammarparse import nil
import "parse/parse" as grammarparse
import "parse/handle" as grammarhandle

proc main() =
    let stream  = readFile("./resource/test.lion")
    var tokenParser = token_parse.new(stream)
    let tokens = token_handle.parse(tokenParser)
    echo(tokens)
    var parser = grammarparse.newParser(tokens)
    parser.parse()

when isMainModule:
    main()
