import "parse"
import "token"
import options

proc handleMultiplication*(self: var parse.Parse) =
    let v = self.lookupNextOne()
    if v.isNone():
        return
    let c = v.get()
    case c
    of '=':
        self.addString(token.TokenType.TokenType_Symbol_Multiplication_Equal, "*=")
    else:
        self.addChar(token.TokenType.TokenType_Symbol_Multiplication, '*', 50)
