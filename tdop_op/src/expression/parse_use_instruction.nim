import "../../../lexical_analysis/src/token/token" as token
import "express"
import options

type
    Parse = ref object
        tokens: seq[token.Token]
        index: int
        length: int

proc getCurrentToken(self: var Parse): Option[token.Token]
proc takeNextOne(self: var Parse): Option[token.Token]
proc skipNextOne(self: var Parse)
proc express*(self: var Parse, rbp: int): (int64, bool)

proc nup(self: token.Token, parser: var Parse): (int64, bool) =
    case self.tokenType
    of token.TokenType.TokenType_Number_Des:
        return (self.value.i64.get(), true)
    of token.TokenType.TokenType_Symbol_Minus:
        # 负号
        parser.skipNextOne()
        let curToken = parser.getCurrentToken()
        if curToken.isNone():
            # panic
            return (int64(0), false)
        return (int64(-1) * (curToken.get().nup(parser))[0], true)
    of token.TokenType.TokenType_Symbol_Parenthese_Left:
        parser.skipNextOne()
        return parser.express(0)
    of token.TokenType.TokenType_Symbol_Parenthese_Right:
        return (int64(0), false)
    else:
        return (int64(0), false)

proc led(self: token.Token, parser: var Parse, left: int64): (int64, bool) =
    case self.tokenType
    of token.TokenType.TokenType_Symbol_Multiplication:
        return (left * parser.express(2)[0], true)
    of token.TokenType.TokenType_Symbol_Plus:
        return (left + parser.express(2)[0], true)
    of token.TokenType.TokenType_Symbol_Minus:
        return (left - parser.express(2)[0], true)
    of token.TokenType.TokenType_Symbol_Division:
        return (left div parser.express(2)[0], true)
    else:
        return (int64(0), false)

# 目的: 计算右操作数
proc express*(self: var Parse, rbp: int): (int64, bool) =
    # 获取当前token (单目运算 / 数字)
    let t = self.getCurrentToken()
    if t.isNone():
        return (int64(0), false)
    # 获取左操作数
    var left = t.get().nup(self)
    if not left[1]:
        return (int64(0), false)
    # 获取双目运算token
    var optToken = self.takeNextOne()
    if optToken.isNone():
        return left
    # 查找表达式中的每一个运算符, 直到找到比rbp小的运算符为止 (双目: lbp == rbp, 这里取 optToken.lbp)
    while rbp < optToken.get().lbp:
        self.skipNextOne()
        let l = optToken.get().led(self, left[0])
        if not l[1]:
            break
        left = (l[0], true)
        optToken = self.getCurrentToken()
        if optToken.isNone():
            break
    return left

proc getUsedTokenTotal*(self: Parse): int =
    return self.index + 1

proc tokenIsEnd(self: var Parse, t: token.Token): bool =
    if t.tokenType == token.TokenType_Line_Break:
        self.skipNextOne()
        return true
    #[
    elif t.tokenType == token.TokenType_Symbol_Parenthese_Right:
        self.skipNextOne()
        return true
    ]#
    return false

proc getCurrentToken(self: var Parse): Option[token.Token] =
    if self.index > self.length - 1:
        return none(token.Token)
    let t = self.tokens[self.index]
    if self.tokenIsEnd(t):
        return none(token.Token)
        # return some(t)
    return some(t)

proc takeNextOne(self: var Parse): Option[token.Token] =
    let index = self.index + 1
    if index > self.length - 1:
        return none(token.Token)
    self.index = index
    let t = self.tokens[self.index]
    if self.tokenIsEnd(t):
        return none(token.Token)
    return some(t)

proc skipNextOne(self: var Parse) =
    self.index += 1

proc new*(tokens: seq[token.Token]): Parse =
    result = Parse(
        tokens: tokens,
        index: 0,
        length: tokens.len()
    )
