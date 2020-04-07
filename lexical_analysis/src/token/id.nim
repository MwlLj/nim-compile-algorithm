import "parse"
import "token"
import options

proc isIDEnd(self: parse.Parse, c: char): bool =
    if (c == '_') or (c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z') or (c >= '0' and c <= '9'):
        return true
    return false

proc handleID*(self: var parse.Parse, id: var string) =
    while true:
        let v = self.lookupNextOne()
        if v.isNone():
            break
        let c = v.get()
        if self.isIDEnd(c):
            id.add(c)
            self.skipNextOne()
        else:
            break
    var tokenType: token.TokenType
    case id
    of "if":
        tokenType = token.TokenType.TokenType_KW_If
    of "print":
        tokenType = token.TokenType.TokenType_Inner_Func_Print
    else:
        tokenType = token.TokenType.TokenType_ID
    self.tokens.add(token.Token(
        tokenType: tokenType,
        value: token.Value(
            str: some(id)
        )
    ))

