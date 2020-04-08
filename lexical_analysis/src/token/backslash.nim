import "parse"
import "token"
import options

proc handleN(self: var parse.Parse) =
    self.skipNextOne()
    self.addChar(token.TokenType.TokenType_Line_Break, '\n')

proc handleR(self: var parse.Parse) =
    self.skipNextOne()
    let v = self.lookupNextOne()
    if v.isNone():
        # \r 后面是字符串的结尾
        self.addChar(token.TokenType.TokenType_Back_Slash_R, '\r')
        return
    let c = v.get()
    case c
    of '\\':
        self.skipNextOne()
        self.addString(token.TokenType.TokenType_Line_Break, "\r\n")
    else:
        # \r 后面不是 \
        self.addChar(token.TokenType.TokenType_Back_Slash_R, '\r')

proc handleT(self: var parse.Parse) =
    self.skipNextOne()

proc handleBackslash*(self: var parse.Parse) =
    # 处理 \
    let v = self.lookupNextOne()
    if v.isNone():
        return
    let c = v.get()
    case c
    of 'r':
        self.handleR()
    of 'n':
        self.handleN()
    of 't':
        self.handleT()
    else:
        discard

