import "express"
import "../opt/optcode"
import "../enums/expr"
from "../../../grammar_analysis/src/structs/scope" import Scope
import "../../../lexical_analysis/src/token/token" as token
import options
import strformat

#[
  1 || 2 && 3
  #0 expr_start
  #1 iconst 1
  // 如果成功就跳转到 5
  #2 opt_or #5
  #3 iconst 2
  #4 opt_or_calc
  // 如果失败就跳转到 8
  #5 opt_and #8
  #6 iconst 3
  #7 opt_and_calc
  #8 expr_end
]#

type
    OptValue* = object
        integer*: Option[int64]
        variable*: Option[string]

type
    Opt* = object
        instruction*: Instruction
        values*: seq[OptValue]

type operandEndCbFunc* = proc(t: token.Token): tuple[isEnd: bool, isSkipNext: bool]

type
    Parse = ref object
        tokens: seq[token.Token]
        sc: scope.Scope
        index: int
        length: int
        isEnd: bool
        opts: seq[Opt]
        # nup 方法的 操作数回调
        nupOperandCb: proc(parser: var Parse)
        # 返回值: 是否遇到结束符
        operandEndCb: operandEndCbFunc
        nupEnterTimes: int
        nupToken: token.Token

proc new*(tokens: seq[token.Token], sc: scope.Scope): Parse
proc getCurrentToken(self: var Parse): Option[token.Token]
proc takeNextOne(self: var Parse): Option[token.Token]
proc lookupNextOne(self: var Parse): Option[token.Token]
proc lookupNextOneExceptLinebreak(self: var Parse): Option[token.Token]
proc skipNextOne(self: var Parse)
proc express(self: var Parse, rbp: int, isRight: bool = false, exprType: expr.ExprType = expr.ExprType.ExprType_Normal): Option[express.ExprValue]
proc addTokenInstruction(self: var Parse, t: token.Token)
proc addTokenValueInstruction(self: var Parse, value: Option[token.Value])

proc operandEndNormalCb(t: token.Token): tuple[isEnd: bool, isSkipNext: bool] =
    if (t.tokenType == token.TokenType.TokenType_Line_Break) or (t.tokenType == token.TokenType.TokenType_Back_Slash_R) or (t.tokenType == token.TokenType_Semicolon):
        return (true, true)
    return (false, false)

# 小括号结束回调
# proc parenthese
# 操作数+换行结束回调
proc operandLinebreak(parser: var Parse) =
    # 可以到达这里的是 操作数 / 右小括号 => 判断下一个是否是换行
    let nextToken = parser.lookupNextOne()
    if nextToken.isNone():
        # 下一个 token 是空的 => 操作数 / 小括号 后是是结束 => 返回 本次结果
        return
    if parser.operandEndCb != nil:
        let v = parser.operandEndCb(nextToken.get())
        if v.isEnd:
          # 检测到结束
          if v.isSkipNext:
            parser.skipNextOne()
          parser.isEnd = true
    #[
    if (nextToken.get().tokenType == token.TokenType.TokenType_Line_Break) or (nextToken.get().tokenType == token.TokenType.TokenType_Back_Slash_R):
        parser.skipNextOne()
        parser.isEnd = true
    ]#

# 需要保证该函数结束后, index 指向的是 `)`
proc operandRightParenthese(parser: var Parse) =
    # 可以到达这里的是 操作数 / 右小括号 => 判断下一个是否是 `)`
    let nextToken = parser.lookupNextOneExceptLinebreak()
    if nextToken.isNone():
        # 下一个 token 是空的 => 操作数 / 小括号 后是是结束 => 返回 本次结果
        return
    if (nextToken.get().tokenType == token.TokenType.TokenType_Symbol_Parenthese_Right):
        parser.skipNextOne()
        parser.isEnd = true

#[ 
1. 终结符(操作数 / 右括号) + 换行 是一条完整的语句
2. 非终结符(左括号 / 操作符) + 换行 是非法的语句
 ]#
proc nup(self: token.Token, parser: var Parse, exprType: expr.ExprType = expr.ExprType.ExprType_Normal): Option[ExprValue] =
    var result: Option[ExprValue]
    var isPrefixOpt: bool = false
    case self.tokenType
    of token.TokenType.TokenType_Number_Des:
        result = some(ExprValue(
            value: some(self.value)
        ))
    of token.TokenType.TokenType_Symbol_Minus:
        isPrefixOpt = true
        # 负号
        parser.skipNextOne()
        let right = parser.express(100, exprType=exprType)
        parser.addTokenValueInstruction(right.get().value)
        parser.opts.add(Opt(
            instruction: Instruction_Prefix_Minus
        ))
        result = some(ExprValue(
            exp: some(Expr(
                right: right,
                op: self.value
            ))
        ))
    of token.TokenType.TokenType_Id:
        result = some(ExprValue(
            value: some(self.value)
        ))
    of token.TokenType.TokenType_Symbol_Parenthese_Left:
        parser.skipNextOne()
        # 创建新的 parser => 直到遇到 ) 为止
        var pr = new(parser.tokens[parser.index..parser.length-1], parser.sc)
        # 跳过 pr 解析的长度
        pr.nupOperandCb = operandRightParenthese
        result = pr.express(0, exprType=expr.ExprType.ExprType_Normal)
        if pr.nupEnterTimes == 1:
            pr.addTokenInstruction(pr.nupToken)
        parser.index += pr.index
        parser.opts.add(pr.opts)
    # of token.TokenType.TokenType_Symbol_Parenthese_Right:
        # result = none(express.ExprValue)
    else:
        return none(ExprValue)
    #[
    # 可以到达这里的是 操作数 / 右小括号 => 判断下一个是否是换行
    let nextToken = parser.lookupNextOne()
    if nextToken.isNone():
        # 下一个 token 是空的 => 操作数 / 小括号 后是是结束 => 返回 本次结果
        return result
    if (nextToken.get().tokenType == token.TokenType.TokenType_Line_Break) or (nextToken.get().tokenType == token.TokenType.TokenType_Back_Slash_R):
        parser.skipNextOne()
        parser.isEnd = true
    ]#
    #if parser.nupOperandCb != nil:
        #parser.nupOperandCb(parser)
    if not isPrefixOpt:
        parser.nupEnterTimes += 1
        parser.nupToken = self
    return result

proc led(self: token.Token, parser: var Parse, left: ExprValue, exprType: expr.ExprType = expr.ExprType.ExprType_Normal): Option[Expr] =
    case self.tokenType
    of token.TokenType.TokenType_Symbol_Multiplication:
        parser.addTokenValueInstruction(left.value)
        let right = parser.express(self.lbp, exprType=exprType)
        if right.isSome():
            parser.addTokenValueInstruction(right.get().value)
        parser.opts.add(Opt(
            instruction: Instruction_Multiplication
        ))
        return some(Expr(
            left: some(left),
            right: right,
            op: self.value
        ))
    of token.TokenType.TokenType_Symbol_Plus:
        parser.addTokenValueInstruction(left.value)
        let right = parser.express(self.lbp, exprType=exprType)
        if right.isSome():
            parser.addTokenValueInstruction(right.get().value)
        parser.opts.add(Opt(
            instruction: Instruction_Plus
        ))
        return some(Expr(
            left: some(left),
            right: right,
            op: self.value
        ))
    of token.TokenType.TokenType_Symbol_Minus:
        return some(Expr(
            left: some(left),
            right: parser.express(self.lbp, exprType=exprType),
            op: self.value
        ))
    of token.TokenType.TokenType_Symbol_Division:
        return some(Expr(
            left: some(left),
            right: parser.express(self.lbp, exprType=exprType),
            op: self.value
        ))
    of token.TokenType.TokenType_Symbol_And:
        parser.addTokenValueInstruction(left.value)
        let optIndex = parser.opts.len()
        parser.opts.add(Opt(
            instruction: Instruction_Opt_And
        ))
        let right = parser.express(self.lbp, exprType=exprType)
        if right.isSome():
            parser.addTokenValueInstruction(right.get().value)
        parser.opts.add(Opt(
            instruction: Instruction_Opt_And_Calc
        ))
        # 更新 optIndex 的跳转数
        parser.opts[optIndex].values = @[OptValue(
            integer: some((int64)parser.opts.len())
            )]
        return some(Expr(
            left: some(left),
            right: right,
            op: self.value
        ))
    of token.TokenType.TokenType_Symbol_Or:
        parser.addTokenValueInstruction(left.value)
        let optIndex = parser.opts.len()
        parser.opts.add(Opt(
            instruction: Instruction_Opt_Or
        ))
        let right = parser.express(self.lbp, exprType=exprType)
        if right.isSome():
            parser.addTokenValueInstruction(right.get().value)
        parser.opts.add(Opt(
            instruction: Instruction_Opt_Or_Calc
        ))
        # 更新 optIndex 的跳转数
        parser.opts[optIndex].values = @[OptValue(
            integer: some((int64)parser.opts.len())
            )]
        return some(Expr(
            left: some(left),
            right: right,
            op: self.value
        ))
    of token.TokenType.TokenType_Symbol_Assignment:
        if left.exp.isSome():
            echo("left is not assign")
            raise newException(OSError, "left is not assign")
        let right = parser.express(self.lbp, true, exprType=exprType)
        if right.isSome():
            parser.addTokenValueInstruction(right.get().value)
        parser.opts.add(Opt(
            instruction: Instruction_Assignment,
            values: @[OptValue(
                variable: some(left.value.get().str.get())
            )]
        ))
        #[ 
        虚拟机:
            1. 从栈中获取栈顶元素
            2. 将栈顶元素 新增/更新 到左值中
            3. 将赋值的计算结果入栈
         ]#
        return some(Expr(
            left: some(left),
            #[ 
            右结合, 可能是 a = b = 1
             ]#
            right: right,
            op: self.value
        ))
    else:
        return none(Expr)

# 目的: 计算右操作数
proc express(self: var Parse, rbp: int, isRight: bool, exprType: expr.ExprType): Option[ExprValue] =
    # 获取当前token (单目运算 / 数字)
    let t = self.getCurrentToken()
    if t.isNone():
        return none(ExprValue)
    # 获取左操作数
    var left = t.get().nup(self, exprType=exprType)
    if left.isNone():
        return none(ExprValue)
    # 获取双目运算token
    #[
    var optToken = self.takeNextOne()
    if optToken.isNone():
        return left
    ]#
    if self.nupOperandCb != nil:
        self.nupOperandCb(self)
    if self.isEnd:
        return left
    # 检测下一个token是否是结束符
    var optToken = self.lookupNextOneExceptLinebreak()
    if optToken.isNone():
        return left
    self.skipNextOne()
    # 查找表达式中的每一个运算符, 直到找到比rbp小的运算符为止 (双目: lbp == rbp, 这里取 optToken.lbp)
    while (not self.isEnd) and ((rbp < optToken.get().lbp) or (isRight and (rbp <= optToken.get().lbp))):
        self.skipNextOne()
        # 当前的 token: 操作数 / 左括号 / 前缀运算符
        let l = optToken.get().led(self, left.get(), exprType=exprType)
        if l.isNone():
            break
        left = some(ExprValue(
            exp: some(l.get())
        ))
        if self.isEnd:
            break
        optToken = self.getCurrentToken()
        if optToken.isNone():
            break
    return left

proc addTokenValueInstruction(self: var Parse, value: Option[token.Value]) =
    if value.isSome():
        if value.get().i64.isSome():
            self.opts.add(Opt(
                instruction: Instruction_Load_iConst,
                values: @[OptValue(
                    integer: some(value.get().i64.get())
                )]
            ))

proc addTokenInstruction(self: var Parse, t: token.Token) =
    self.addTokenValueInstruction(some(t.value))

proc parse*(self: var Parse) =
    discard self.express(0)
    if self.nupEnterTimes == 1:
        self.addTokenInstruction(self.nupToken)

proc getUsedTokenTotal*(self: Parse): int =
    return self.index + 1

proc tokenIsEnd(self: var Parse, t: token.Token): bool =
    # if t.tokenType == token.TokenType_Semicolon or t.tokenType == token.TokenType.TokenType_Symbol_Parenthese_Right:
    if t.tokenType == token.TokenType_Semicolon:
        # self.skipNextOne()
        return true
    return false

proc getCurrentToken(self: var Parse): Option[token.Token] =
    if self.index > self.length - 1:
        return none(token.Token)
    var t = self.tokens[self.index]
    # 如果当前的 token 是 换行 => 跳过
    while true:
        if (t.tokenType == token.TokenType.TokenType_Line_Break) or (t.tokenType == token.TokenType.TokenType_Back_Slash_R):
            self.skipNextOne()
        else:
            # 当前的 t 不是 换行
            break
        let tok = self.getCurrentToken()
        if tok.isNone():
            return none(token.Token)
        else:
            t = tok.get()
    #[
    if self.tokenIsEnd(t):
        return none(token.Token)
        # return some(t)
    ]#
    return some(t)

proc takeNextOne(self: var Parse): Option[token.Token] =
    let index = self.index + 1
    if index > self.length - 1:
        return none(token.Token)
    self.index = index
    var t = self.tokens[self.index]
    # 如果下一个 token 是 换行 => 跳过
    while true:
        if (t.tokenType == token.TokenType.TokenType_Line_Break) or (t.tokenType == token.TokenType.TokenType_Back_Slash_R):
            self.skipNextOne()
        else:
            # 当前的 t 不是 换行
            break
        let tok = self.takeNextOne()
        if tok.isNone():
            return none(token.Token)
        else:
            t = tok.get()
    #[
    if self.tokenIsEnd(t):
        return none(token.Token)
    ]#
    return some(t)

proc lookupNextOne(self: var Parse): Option[token.Token] =
    let index = self.index + 1
    if index > self.length - 1:
        return none(token.Token)
    return some(self.tokens[index])

proc lookupNextOneExceptLinebreak(self: var Parse): Option[token.Token] =
    let index = self.index + 1
    if index > self.length - 1:
        return none(token.Token)
    var t = self.tokens[index]
    # 如果下一个 token 是 换行 => 跳过
    while true:
        if (t.tokenType == token.TokenType.TokenType_Line_Break) or (t.tokenType == token.TokenType.TokenType_Back_Slash_R):
            self.skipNextOne()
        else:
            # 当前的 t 不是 换行
            break
        let tok = self.lookupNextOneExceptLinebreak()
        if tok.isNone():
            return none(token.Token)
        else:
            t = tok.get()
    return some(t)

proc skipNextOne(self: var Parse) =
    self.index += 1

proc getOpts*(self: Parse): seq[Opt] =
    return self.opts

proc printOpts*(self: var Parse) =
    echo(self.opts)

proc setOperandEndCb*(self: var Parse, cb: operandEndCbFunc) =
    self.operandEndCb = cb

proc new*(tokens: seq[token.Token], sc: scope.Scope): Parse =
    # echo(tokens)
    result = Parse(
        tokens: tokens,
        sc: sc,
        index: 0,
        length: tokens.len(),
        nupOperandCb: operandLinebreak,
        operandEndCb: operandEndNormalCb
    )
