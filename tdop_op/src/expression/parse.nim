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
proc express*(self: var Parse, rbp: int): Option[express.ExprValue]

proc nup(self: token.Token, parser: var Parse): Option[express.ExprValue] =
    case self.tokenType
    of token.TokenType.TokenType_Number_Des:
        return some(express.ExprValue(
            value: some(self.value)
        ))
    of token.TokenType.TokenType_Symbol_Minus:
        # 负号
        parser.skipNextOne()
        let curToken = parser.getCurrentToken()
        if curToken.isNone():
            # panic
            return none(express.ExprValue)
        # if curToken.get().tokenType == token.TokenType.TokenType_Number_Des:
        #     return some(express.ExprValue(
        #         exp: some(express.Expr(
        #             right: some(express.ExprValue(
        #                 value: some(curToken.get().value)
        #             )),
        #             op: self.value
        #         ))
        #     ))
        # else:
        return some(express.ExprValue(
            exp: some(express.Expr(
                right: curToken.get().nup(parser),
                op: self.value
            ))
        ))
    of token.TokenType.TokenType_Symbol_Parenthese_Left:
        parser.skipNextOne()
        return parser.express(0)
    of token.TokenType.TokenType_Symbol_Parenthese_Right:
        return none(express.ExprValue)
    else:
        return none(express.ExprValue)

#[
# 进入 led 时: parser的curToken 一定是 操作数
# 离开 led 时: parser的curToken 一定是 操作符
]#
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
    of token.TokenType.TokenType_Symbol_Division:
        return some(express.Expr(
            left: some(left),
            right: parser.express(2),
            op: self.value
        ))
    else:
        return none(express.Expr)

# 目的: 计算右操作数
#[
# 直到检测到 传入的 rbp >= 下一个操作符的 rbp
# 比如:
#   1 + 2 * 3 + 4
# 使用第一个+号 调用 express 方法
#   下一个操作符是 *号, *的rbp > +的rbp => 无法结束, 继续找下一个
#   下一个操作符是 +号, +的rbp 肯定是等于 +的rbp => 结束 此次 express 的调用
]#
proc express*(self: var Parse, rbp: int): Option[express.ExprValue] =
    # 获取当前token (单目运算 / 数字)
    let t = self.getCurrentToken()
    if t.isNone():
        return none(express.ExprValue)
    # 获取左操作数
    var left = t.get().nup(self)
    if left.isNone():
        return none(express.ExprValue)
    # 获取运算token
    var optToken = self.takeNextOne()
    if optToken.isNone():
        return left
    # 查找表达式中的每一个运算符, 直到找到比rbp小的运算符为止 (双目: lbp == rbp, 这里取 optToken.lbp)
    while rbp < optToken.get().lbp:
        self.skipNextOne()
        let l = optToken.get().led(self, left.get())
        if l.isNone():
            break
        left = some(express.ExprValue(
            exp: some(l.get())
        ))
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
