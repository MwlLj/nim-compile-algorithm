import "parse"
import "token"
import options

proc handleOr*(self: var parse.Parse) =
    # 处理 &
    let v = self.lookupNextOne()
    if v.isNone():
        return
    let c = v.get()
    case c
    of '|':
        self.addString(token.TokenType.TokenType_Symbol_Or, "||", 30)
        self.skipNextOne()
        return
    else:
        # self.addChar(token.TokenType.TokenType_Symbol_Assignment, '=')
        return

