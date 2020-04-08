import "parse"
import "token"
import options

proc handleLessThan*(self: var parse.Parse) =
    # 处理 <
    let v = self.lookupNextOne()
    if v.isNone():
        return
    let c = v.get()
    case c
    of '=':
        self.addString(token.TokenType.TokenType_Symbol_Less_Than_Equal, "<=")
        self.skipNextOne()
        return
    else:
        self.addChar(token.TokenType.TokenType_Symbol_Less_Than, '<')
        return

proc handleMoreThan*(self: var parse.Parse) =
    # 处理 >
    let v = self.lookupNextOne()
    if v.isNone():
        return
    let c = v.get()
    case c
    of '=':
        self.addString(token.TokenType.TokenType_Symbol_More_Than_Equal, ">=")
        self.skipNextOne()
        return
    else:
        self.addChar(token.TokenType.TokenType_Symbol_More_Than, '>')
        return

