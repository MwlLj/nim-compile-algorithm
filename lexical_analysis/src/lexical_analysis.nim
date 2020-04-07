import "./token/parse"
import "./token/handle"
import "./token/token"
import options
import strformat

proc main() =
    let stream = readFile("./resource/test.dog")
    var parser = parse.new(stream)
    let tokens = handle.parse(parser)
    for t in tokens:
        case t.tokenType
        of token.TokenType.TokenType_Double_Quotes
          , token.TokenType.TokenType_Back_Quotes
          , token.TokenType.TokenType_Single_Comment
          , token.TokenType.TokenType_Multi_Comment
          , token.TokenType.TokenType_KW_If
          , token.TokenType.TokenType_Inner_Func_Print:
            if t.value.str.isSome():
              echo(fmt"tokenType: {t.tokenType}, value: {t.value.str.get()}")
        else:
            discard

when isMainModule:
    main()
