import "parse"
import "slash"
import "token"
import "double_quotes"
import "back_quotes"
import "id"
import options

proc isIDStart(self: var parse.Parse, c: char): bool =
    if c == '_' or (c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z'):
        return true
    return false

proc parse*(self: var parse.Parse): seq[token.Token] =
    while true:
        let v = self.takeNextOne()
        if v.isNone():
            break
        let c = v.get()
        # echo(c)
        case c
        of '/':
            slash.handleSlash(self)
        of '"':
            double_quotes.handleDoubleQuotes(self)
        of '`':
            back_quotes.handleBackQuotes(self)
        of '!':
            discard
        of '=':
            discard
        of '<':
            discard
        of '>':
            discard
        of '?':
            discard
        of ':':
            discard
        of '(':
            discard
        of ')':
            discard
        of '{':
            discard
        of '}':
            discard
        of '[':
            discard
        of ']':
            discard
        of '+':
            discard
        of '-':
            discard
        of '&':
            discard
        of '#':
            discard
        of '@':
            discard
        of '$':
            discard
        of '%':
            discard
        else:
            if self.isIDStart(c):
                var id: string
                id.add(c)
                self.handleID(id)
    return self.tokens

