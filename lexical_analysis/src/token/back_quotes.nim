import "parse"
import "token"
import "change"
import options

# 反引号 `
proc handleBackQuotes*(self: var parse.Parse) =
    var content: string
    while true:
        let v = self.lookupNextOne()
        if v.isNone():
            break
        let c = v.get()
        case c
        of '`':
            self.skipNextOne()
            break
        else:
            content.add(c)
            self.skipNextOne()
    self.tokens.add(token.Token(
        tokenType: token.TokenType.TokenType_Back_Quotes,
        value: token.Value(
            str: some(content)
        )
    ))

