import "parse"
import "token"
import "change"
import options

proc handleDoubleQuotes*(self: var parse.Parse) =
    var content: string
    while true:
        let v = self.lookupNextOne()
        if v.isNone():
            break
        let c = v.get()
        case c
        of '"':
            self.skipNextOne()
            break
        of '\\':
            let r = self.changeEscape()
            if r.isNone():
                content.add("\\")
            else:
                content.add(r.get())
        else:
            content.add(c)
            self.skipNextOne()
    self.tokens.add(token.Token(
        tokenType: token.TokenType.TokenType_Double_Quotes,
        value: token.Value(
            str: some(content)
        )
    ))

