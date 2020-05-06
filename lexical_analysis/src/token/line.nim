import "parse"
import "token"
import options

proc isLineEnd*(self: var parse.Parse): bool =
    let v = self.lookupNextOne()
    if v.isNone():
        return true
    let c = v.get()
    case c
    of '\n':
        self.skipNextOne()
        return true
    of '\r':
        self.skipNextOne()
        let v = self.lookupNextOne()
        if v.isNone():
            return true
        if v.get() == '\n':
            self.skipNextOne()
            return true
        else:
            echo("after \\r is not \\n")
    else:
        discard
    return false

proc handleBackSlashR*(self: var parse.Parse) =
    # self.skipNextOne()
    let v = self.lookupNextOne()
    if v.isNone():
        # 下一个是字符串的结尾
        self.addChar(token.TokenType.TokenType_Back_Slash_R, '\r')
        return
    if v.get() == '\n':
        self.skipNextOne()
        self.addString(token.TokenType.TokenType_Line_Break, "\r\n")
        return
    else:
        # \r后面不是\n
        self.addChar(token.TokenType.TokenType_Back_Slash_R, '\r')
        return

proc handleBackSlashN*(self: var parse.Parse) =
    # self.skipNextOne()
    self.addChar(token.TokenType.TokenType_Line_Break, '\n')

