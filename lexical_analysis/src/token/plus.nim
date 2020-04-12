import "parse"
import "token"
import options

proc handlePlus*(self: var parse.Parse) =
    let v = self.lookupNextOne()
    if v.isNone():
        return
    let c = v.get()
    case c
    of '=':
        discard
    else:
        self.addChar(token.TokenType.TokenType_Symbol_Plus, '+', 1)
