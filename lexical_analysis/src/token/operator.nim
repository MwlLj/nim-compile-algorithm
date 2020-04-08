import "parse"
import "token"
import options

proc handlePlusSymbol*(self: var parse.Parse) =
    # 处理 +
    let v = self.lookupNextOne()
    if v.isNone():
        return
    let c = v.get()
    case c
    of '=':
        self.addString(token.TokenType.TokenType_Symbol_Plus_Equal, "+=")
        self.skipNextOne()
        return
    else:
        self.addChar(token.TokenType.TokenType_Symbol_Plus, '+')
        return

proc handleMinusSymbol*(self: var parse.Parse) =
    # 处理 -
    let v = self.lookupNextOne()
    if v.isNone():
        return
    let c = v.get()
    case c
    of '=':
        self.addString(token.TokenType.TokenType_Symbol_Minus_Equal, "-=")
        self.skipNextOne()
        return
    of '>':
        self.addString(token.TokenType.TokenType_Symbol_Right_Arrow, "->")
        self.skipNextOne()
        return
    else:
        self.addChar(token.TokenType.TokenType_Symbol_Minus, '-')
        return

proc handleMultiplicationSymbol*(self: var parse.Parse) =
    # 处理 *
    let v = self.lookupNextOne()
    if v.isNone():
        return
    let c = v.get()
    case c
    of '=':
        self.addString(token.TokenType.TokenType_Symbol_Multiplication_Equal, "*=")
        self.skipNextOne()
        return
    else:
        self.addChar(token.TokenType.TokenType_Symbol_Multiplication, '*')
        return

