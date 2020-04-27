import "../../../lexical_analysis/src/token/token" as token
import "express"
import options

#[
  1 || 2 && 3
  #0 expr_start
  #1 iconst 1
  #2 opt_or #5
  #3 iconst 2
  #4 opt_or_calc
  #5 opt_and #8
  #6 iconst 3
  #7 opt_and_calc
  #8 expr_end
]#

type
    Instruction = enum
        Instruction_Load_iConst,
        Instruction_Plus,
        Instruction_Multiplication,
        Instruction_Prefix_Minus,
        Instruction_Opt_Or,
        Instruction_Opt_Or_Calc,
        Instruction_Opt_And,
        Instruction_Opt_And_Calc

type
    OptValue = object
        integer: Option[int64]

type
    Opt = object
        instruction: Instruction
        values: seq[OptValue]

type
    Parse = ref object
        tokens: seq[token.Token]
        index: int
        length: int
        opts: seq[Opt]

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
        var right: Option[express.ExprValue]
        let n = curToken.get().nup(parser)
        if n.isNone():
            right = n
        else:
            if n.get().value.isSome():
                parser.opts.add(Opt(
                    instruction: Instruction_Load_iConst,
                    values: @[OptValue(
                        integer: some(n.get().value.get().i64.get())
                    )]
                ))
            parser.opts.add(Opt(
                instruction: Instruction_Prefix_Minus
            ))
        return some(express.ExprValue(
            exp: some(express.Expr(
                right: right,
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

proc led(self: token.Token, parser: var Parse, left: express.ExprValue): Option[express.Expr] =
    case self.tokenType
    of token.TokenType.TokenType_Symbol_Multiplication:
        if left.value.isSome():
            if left.value.get().i64.isSome():
                parser.opts.add(Opt(
                    instruction: Instruction_Load_iConst,
                    values: @[OptValue(
                        integer: some(left.value.get().i64.get())
                    )]
                ))
        let right = parser.express(2)
        if right.isSome():
            let r = right.get()
            if r.value.isSome():
                if r.value.get().i64.isSome():
                    parser.opts.add(Opt(
                        instruction: Instruction_Load_iConst,
                        values: @[OptValue(
                            integer: some(r.value.get().i64.get())
                        )]
                    ))
        parser.opts.add(Opt(
            instruction: Instruction_Multiplication
        ))
        return some(express.Expr(
            left: some(left),
            right: right,
            op: self.value
        ))
    of token.TokenType.TokenType_Symbol_Plus:
        if left.value.isSome():
            if left.value.get().i64.isSome():
                parser.opts.add(Opt(
                    instruction: Instruction_Load_iConst,
                    values: @[OptValue(
                        integer: some(left.value.get().i64.get())
                    )]
                ))
        let right = parser.express(1)
        if right.isSome():
            let r = right.get()
            if r.value.isSome():
                if r.value.get().i64.isSome():
                    parser.opts.add(Opt(
                        instruction: Instruction_Load_iConst,
                        values: @[OptValue(
                            integer: some(r.value.get().i64.get())
                        )]
                    ))
        parser.opts.add(Opt(
            instruction: Instruction_Plus
        ))
        return some(express.Expr(
            left: some(left),
            right: right,
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
proc express*(self: var Parse, rbp: int): Option[express.ExprValue] =
    # 获取当前token (单目运算 / 数字)
    let t = self.getCurrentToken()
    if t.isNone():
        return none(express.ExprValue)
    # 获取左操作数
    var left = t.get().nup(self)
    if left.isNone():
        return none(express.ExprValue)
    # 获取双目运算token
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

proc printOpts*(self: var Parse) =
    echo(self.opts)

proc new*(tokens: seq[token.Token]): Parse =
    result = Parse(
        tokens: tokens,
        index: 0,
        length: tokens.len()
    )
