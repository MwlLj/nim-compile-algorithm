import "../opt/optcode"
import "../enums/expr"
import "../../../lexical_analysis/src/token/token" as token
import "express"
import options
import strformat

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
    OptValue = object
        integer: Option[int64]
        variable: Option[string]

type
    Opt* = object
        instruction*: Instruction
        values*: seq[OptValue]

type
    Parse = ref object
        tokens: seq[token.Token]
        index: int
        length: int
        isEnd: bool
        opts: seq[Opt]
        # nup 方法的 操作数回调
        nupOperandCb: proc(parser: var Parse)
        # 返回值: 是否遇到结束符
        operandEndCb: proc(t: token.Token): bool

type operandCallback = proc(parser: var Parse)

proc new*(tokens: seq[token.Token]): Parse
proc getCurrentToken(self: var Parse): Option[token.Token]
proc takeNextOne(self: var Parse): Option[token.Token]
proc lookupNextOne(self: var Parse): Option[token.Token]
proc lookupNextOneExceptLinebreak(self: var Parse): Option[token.Token]
proc skipNextOne(self: var Parse)
proc express*(self: var Parse, rbp: int, isRight: bool = false, exprType: expr.ExprType = expr.ExprType.ExprType_Normal): Option[express.ExprValue]

proc operandEndNormalCb(t: token.Token): bool =
    if (t.tokenType == token.TokenType.TokenType_Line_Break) or (t.tokenType == token.TokenType.TokenType_Back_Slash_R) or (t.tokenType == token.TokenType_Semicolon):
        return true
    return false

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
        if parser.operandEndCb(nextToken.get()):
            # 检测到结束
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
proc nup(self: token.Token, parser: var Parse, exprType: expr.ExprType = expr.ExprType.ExprType_Normal): Option[express.ExprValue] =
    var result: Option[express.ExprValue]
    case self.tokenType
    of token.TokenType.TokenType_Number_Des:
        result = some(express.ExprValue(
            value: some(self.value)
        ))
    of token.TokenType.TokenType_Symbol_Minus:
        # 负号
        parser.skipNextOne()
        let right = parser.express(100, exprType=exprType)
        if right.get().value.isSome():
            parser.opts.add(Opt(
                instruction: Instruction_Load_iConst,
                values: @[OptValue(
                    integer: some(right.get().value.get().i64.get())
                )]
            ))
        parser.opts.add(Opt(
            instruction: Instruction_Prefix_Minus
        ))
        result = some(express.ExprValue(
            exp: some(express.Expr(
                right: right,
                op: self.value
            ))
        ))
    of token.TokenType.TokenType_Id:
        result = some(express.ExprValue(
            value: some(self.value)
        ))
    of token.TokenType.TokenType_Symbol_Parenthese_Left:
        parser.skipNextOne()
        # 创建新的 parser => 直到遇到 ) 为止
        var pr = new(parser.tokens[parser.index..parser.length-1])
        # 跳过 pr 解析的长度
        pr.nupOperandCb = operandRightParenthese
        echo(fmt"parser.index: {parser.index}")
        result = pr.express(0, exprType=expr.ExprType.ExprType_Normal)
        parser.index += pr.index
        echo(fmt"pr.index: {pr.index}, parser.index: {parser.index}")
        parser.opts.add(pr.opts)
    # of token.TokenType.TokenType_Symbol_Parenthese_Right:
        # result = none(express.ExprValue)
    else:
        return none(express.ExprValue)
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
    return result

proc led(self: token.Token, parser: var Parse, left: express.ExprValue, exprType: expr.ExprType = expr.ExprType.ExprType_Normal): Option[express.Expr] =
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
        let right = parser.express(self.lbp, exprType=exprType)
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
        let right = parser.express(self.lbp, exprType=exprType)
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
            right: parser.express(self.lbp, exprType=exprType),
            op: self.value
        ))
    of token.TokenType.TokenType_Symbol_Division:
        return some(express.Expr(
            left: some(left),
            right: parser.express(self.lbp, exprType=exprType),
            op: self.value
        ))
    of token.TokenType.TokenType_Symbol_And:
        if left.value.isSome():
            if left.value.get().i64.isSome():
                parser.opts.add(Opt(
                    instruction: Instruction_Load_iConst,
                    values: @[OptValue(
                        integer: some(left.value.get().i64.get())
                    )]
                ))
        let optIndex = parser.opts.len()
        parser.opts.add(Opt(
            instruction: Instruction_Opt_And
        ))
        let right = parser.express(self.lbp, exprType=exprType)
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
            instruction: Instruction_Opt_And_Calc
        ))
        # 更新 optIndex 的跳转数
        parser.opts[optIndex].values = @[OptValue(
            integer: some((int64)parser.opts.len())
            )]
        return some(express.Expr(
            left: some(left),
            right: right,
            op: self.value
        ))
    of token.TokenType.TokenType_Symbol_Or:
        if left.value.isSome():
            if left.value.get().i64.isSome():
                parser.opts.add(Opt(
                    instruction: Instruction_Load_iConst,
                    values: @[OptValue(
                        integer: some(left.value.get().i64.get())
                    )]
                ))
        let optIndex = parser.opts.len()
        parser.opts.add(Opt(
            instruction: Instruction_Opt_Or
        ))
        let right = parser.express(self.lbp, exprType=exprType)
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
            instruction: Instruction_Opt_Or_Calc
        ))
        # 更新 optIndex 的跳转数
        parser.opts[optIndex].values = @[OptValue(
            integer: some((int64)parser.opts.len())
            )]
        return some(express.Expr(
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
            let r = right.get()
            if r.value.isSome():
                if r.value.get().i64.isSome():
                    parser.opts.add(Opt(
                        instruction: Instruction_Load_iConst,
                        values: @[OptValue(
                            integer: some(r.value.get().i64.get())
                        )]
                    ))
        var instruction: Instruction
        case exprType
        of expr.ExprType.ExprType_Normal:
            instruction = Instruction_Assignment
        of expr.ExprType.ExprType_Var_Define:
            instruction = Instruction_Var_Define
        parser.opts.add(Opt(
            instruction: instruction,
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
        return some(express.Expr(
            left: some(left),
            #[ 
            右结合, 可能是 a = b = 1
             ]#
            right: right,
            op: self.value
        ))
    else:
        return none(express.Expr)

# 目的: 计算右操作数
proc express*(self: var Parse, rbp: int, isRight: bool, exprType: expr.ExprType): Option[express.ExprValue] =
    # 获取当前token (单目运算 / 数字)
    let t = self.getCurrentToken()
    if t.isNone():
        return none(express.ExprValue)
    # 获取左操作数
    var left = t.get().nup(self, exprType=exprType)
    if left.isNone():
        return none(express.ExprValue)
    ########################################
    # 检测整个表达式是否只存在一个操作数 (如果只有一个操作数, 需生成一个指令, 因为 所有的指令都在 led 中追加的, 如果只有一个操作数, 无法进入到 led 方法)
    if self.length == 1:
        if left.get().value.get().i64.isSome():
            self.opts.add(Opt(
                instruction: Instruction_Load_iConst,
                values: @[OptValue(
                    integer: some(left.get().value.get().i64.get())
                )]
            ))
    ########################################
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
        left = some(express.ExprValue(
            exp: some(l.get())
        ))
        if self.isEnd:
            break
        optToken = self.getCurrentToken()
        if optToken.isNone():
            break
    return left

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

proc setOperandEndCb*(self: var Parse, cb: proc(t: token.Token): bool) =
    self.operandEndCb = cb

proc new*(tokens: seq[token.Token]): Parse =
    # echo(tokens)
    result = Parse(
        tokens: tokens,
        index: 0,
        length: tokens.len(),
        nupOperandCb: operandLinebreak,
        operandEndCb: operandEndNormalCb
    )
