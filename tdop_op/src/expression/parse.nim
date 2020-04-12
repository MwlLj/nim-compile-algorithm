import "../../../lexical_analysis/src/token/token" as token
import "express"
import options

type
    Parse = ref object
        tokens: seq[token.Token]
        index: int
        length: int

proc getCurrentToken(self: Parse): Option[token.Token]
proc takeNextOne(self: var Parse): Option[token.Token]
proc skipNextOne(self: var Parse)
proc express*(self: var Parse, rbp: int): Option[express.ExprValue]

proc nup(self: token.Token): Option[express.ExprValue] =
    case self.tokenType
    of token.TokenType.TokenType_Number_Des:
        return some(express.ExprValue(
            value: some(self.value)
        ))
    else:
        return none(express.ExprValue)

proc led(self: token.Token, parser: var Parse, left: express.ExprValue): Option[express.Expr] =
    case self.tokenType
    of token.TokenType.TokenType_Symbol_Multiplication:
        return some(express.Expr(
            left: some(left),
            right: parser.express(2),
            op: self.value
        ))
    of token.TokenType.TokenType_Symbol_Plus:
        return some(express.Expr(
            left: some(left),
            right: parser.express(1),
            op: self.value
        ))
    of token.TokenType.TokenType_Symbol_Minus:
        return some(express.Expr(
            left: some(left),
            right: parser.express(1),
            op: self.value
        ))
    else:
        return none(express.Expr)

# 目的: 计算右操作数
proc express*(self: var Parse, rbp: int): Option[express.ExprValue] =
    # 获取当前token (单目运算 / 数字)
    let t = self.getCurrentToken()
    if t.isNone():
        return none(express.ExprValue)
    # 获取左操作数
    let left = t.get().nup()
    if left.isNone():
        return none(express.ExprValue)
    # 获取双目运算token
    var optToken = self.takeNextOne()
    if optToken.isNone():
        # return none(express.ExprValue)
        return left
    # 查找表达式中的每一个运算符, 直到找到比rbp小的运算符为止 (双目: lbp == rbp, 这里取 optToken.lbp)
    while rbp < optToken.get().lbp:
        self.skipNextOne()
        # optToken.led()
        let l = optToken.get().led(self, left.get())
        if l.isNone():
            echo("11111")
            break
        var le = left.get()
        le = express.ExprValue(
            exp: some(l.get())
        )
        optToken = self.getCurrentToken()
        if optToken.isNone():
            break
    return left

proc getCurrentToken(self: Parse): Option[token.Token] =
    if self.index > self.length - 1:
        return none(token.Token)
    return some(self.tokens[self.index])

proc takeNextOne(self: var Parse): Option[token.Token] =
    let index = self.index + 1
    if index > self.length - 1:
        return none(token.Token)
    self.index = index
    return some(self.tokens[self.index])

proc skipNextOne(self: var Parse) =
    self.index += 1

proc new*(tokens: seq[token.Token]): Parse =
    result = Parse(
        tokens: tokens,
        index: 0,
        length: tokens.len()
    )
