import "parse"
import "token"
import options

proc isHex(self: var parse.Parse, c: char): Option[int64] =
    if c >= 'a' and c <= 'f':
        return some((int64)((int64)(c) - 97 + 48))
    elif c >= 'A' and c <= 'F':
        return some((int64)((int64)(c) - 65 + 48))
    elif c >= '0' and c <= '9':
        return some((int64)((int64)(c) - 48))
    return none(int64)

proc isNumber(self: var parse.Parse, c: char): Option[int64] =
    if c >= '0' and c <= '9':
        return some((int64)((int64)(c) - 48))
    return none(int64)

proc handleZeroStart(self: var parse.Parse) =
    let v = self.lookupNextOne()
    if v.isNone():
        return
    let c = v.get()
    var number: int64 = 1
    var tokenType: token.TokenType
    case c
    of 'x', 'X':
        self.skipNextOne()
        let v = self.lookupNextOne()
        if v.isNone():
            echo("after 0x is empty")
            return
        while true:
            let v = self.lookupNextOne()
            if v.isNone():
                break
            else:
                let n = self.isHex(v.get())
                if n.isNone():
                    break
                else:
                    number += number * 16 + n.get()
                    self.skipNextOne()
        tokenType = token.TokenType.TokenType_Number_Hex
    else:
        let v = self.lookupNextOne()
        if v.isNone():
            # 只有一个 0
            number = 0
            tokenType = token.TokenType.TokenType_Number_Des
        else:
            while true:
                let v = self.lookupNextOne()
                if v.isNone():
                    break
                else:
                    let n = self.isNumber(v.get())
                    if n.isNone():
                        break
                    else:
                        number += number * 8 + n.get()
                        self.skipNextOne()
            tokenType = token.TokenType.TokenType_Number_Oct
    self.addInt64(tokenType, number)

proc handleNumber*(self: var parse.Parse, firstChar: char) =
    case firstChar
    of '0':
        self.handleZeroStart()
    else:
        var number: int64 = 1
        while true:
            let v = self.lookupNextOne()
            if v.isNone():
                break
            else:
                let n = self.isNumber(v.get())
                if n.isNone():
                    break
                else:
                    number += number * 10 + n.get()
                    self.skipNextOne()
        let tokenType = token.TokenType.TokenType_Number_Des
        self.addInt64(tokenType, number)

