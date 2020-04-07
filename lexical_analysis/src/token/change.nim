import "parse"
import options

# 改变转义字符
proc changeEscape*(self: var parse.Parse): Option[char] =
    self.skipNextOne()
    let v = self.lookupNextOne()
    if v.isNone():
        return none(char)
    let c = v.get()
    case c
    of '"':
        self.skipNextOne()
        return some('"')
    of '\'':
        self.skipNextOne()
        return some('\'')
    of 't':
        self.skipNextOne()
        return some('\t')
    of 'r':
        self.skipNextOne()
        return some('\r')
    of 'n':
        self.skipNextOne()
        return some('\n')
    of '\\':
        self.skipNextOne()
        return some('\\')
    else:
        discard

