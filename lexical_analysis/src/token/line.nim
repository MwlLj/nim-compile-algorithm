import "parse"
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

