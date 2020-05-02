import "parse"
import "token"

proc handleColon*(self: var parse.Parse) =
    self.addChar(token.TokenType.TokenType_Symbol_Colon, ':')
