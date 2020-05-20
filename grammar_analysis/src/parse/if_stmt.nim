#[
if语句语法:
  
作用域:
  1. 为 每一个 block 创建一个 Table, 用于存储 块 中的变量 (用于编译时的搜索)
  2. if 语句的应该被 函数 / package 调用 => Scope 中 存在一个 rootBlock, 记录当前 if语句 所在的最上级 block, rootBlock 的 seq[Var] 用于存储 所有的变量, 并将index写在字节码中, 提供给虚拟机

跳转:
  跳转指令: If_Skip 条件成立的跳转位置 条件不成立的跳转位置
  条件成立: 跳转到 成立的语句块中, 执行完成后, 跳转到整个if语句的结尾
  条件不成立: 跳转到 下一个 条件位置 (else if 或者 else)
]#

import "parse"
import "ihandle"
import "../structs/scope"
import "../../../tdop_op/src/expression/parse_use_instruction" as opparse
import "../../../tdop_op/src/opt/optcode"
import "../../../lexical_analysis/src/token/token"
import strformat
import "options"

# 如果存在 else 语句, 那么直接编译语句块, 然后跳转到语句块之后
# 返回值: 待填充的blockEnd语句块的索引
proc handleElseStmt*(self: ihandle.IHandle, parser: var parse.Parser, sc: var scope.Scope): int =
  # 跳过 else
  parser.skipNextOne()
  # 找到 else 后面的 {
  if not parser.findUntilEndTokenType(token.TokenType.TokenType_Symbol_Big_Parenthese_Left):
    quit("expect a {, but got EOF")
  else:
    parser.skipNextOne()
  # 解析 {} 之间的数据, 需要更新curBlock和parentBlock
  # 让当前作用域作为 {} 块中的 父作用域
  #[
  let parentBlock = sc.parentBlock
  sc.parentBlock = some(sc.curBlock) sc.curBlock = scope.newLocalBlock()
  ]#
  sc.enterBlock()
  self.parse(parser, sc,
    some(token.TokenType.TokenType_Symbol_Big_Parenthese_Right),
    expressOperandEndCb=some((opparse.operandEndCbFunc)proc(t: token.Token): tuple[isEnd: bool, isSkipNext: bool] =
      var isSkipNext = true
      result = (false, isSkipNext)
      if (t.tokenType == token.TokenType.TokenType_Symbol_Big_Parenthese_Right) or (t.tokenType == token.TokenType.TokenType_Line_Break) or (t.tokenType == token.TokenType.TokenType_Back_Slash_R) or (t.tokenType == token.TokenType_Semicolon):
        if t.tokenType != token.TokenType.TokenType_Symbol_Big_Parenthese_Right:
          isSkipNext = false
        return (true, isSkipNext)))
  # {} 解析完毕 => 将作用域还原
  #[
  sc.curBlock = sc.parentBlock.get()
  sc.parentBlock = parentBlock
  ]#
  sc.leaveBlock()
  let blockEndOptIndex = parser.opts.len()
  parser.opts.add(opparse.Opt(
    instruction: optcode.Instruction.Instruction_Condition_Block_End,
    values: @[opparse.OptValue()]
  ))
  return blockEndOptIndex

# 返回值: optIndex 和 blockEndOptIndex
proc handleIfElseStmt*(self: ihandle.IHandle, parser: var parse.Parser, sc: var scope.Scope): tuple[optIndex: int, blockEndOptIndex: int] =
    #[
    # 1. 跳过 else if
    # 2. 处理 else if 和 { 之间的表达式
    # 3. 处理 { 和 } 之间的stmts
    ]#
    # 跳过 else if
    parser.skipNextOne()
    parser.opts.add(opparse.Opt(
        instruction: optcode.Instruction.Instruction_If_Else_Stmt
    ))
    # 条件开始
    parser.opts.add(opparse.Opt(
      instruction: optcode.Instruction.Instruction_Condition_Expr_Start
    ))
    # 处理 else if { 之间的条件表达式
    var expressParser = opparse.new(parser.tokens[parser.index..parser.length-1], sc)
    expressParser.setOperandEndCb(proc(t: token.Token): tuple[isEnd: bool, isSkipNext: bool] =
        if t.tokenType == token.TokenType.TokenType_Symbol_Big_Parenthese_Left:
            # 遇到 { 结束
            return (true, true)
        return (false, false))
    expressParser.parse()
    let opts = expressParser.getOpts()
    # 如果 opts 的结果个数是0, 说明, 表达式的计算为空 => 表示的是, 这里不存在一个表达式
    if opts.len() == 0:
      quit("expect express")
    parser.opts.add(opts)
    # 条件结束
    # 记录之后要修改的操作码位置
    parser.opts.add(opparse.Opt(
      instruction: optcode.Instruction.Instruction_Condition_Expr_End
    ))
    var optIndex = parser.opts.len() - 1
    # 注意: 这里先将第二个占位符填充为 none, 因为 if 语句结束后, 可能就是文件尾部, 如果不填写为 none, 虚拟机不知道 在条件不成立的情况下跳转到哪里
    parser.opts[optIndex].values = @[opparse.OptValue(
      integer: some(int64(parser.opts.len()))
    ), opparse.OptValue()]
    # 将表达式使用完毕的token跳过
    parser.skipNextN(expressParser.getUsedTokenTotal())
    # 处理 { } 之间的 语句
    # 让当前作用域作为 {} 块中的 父作用域
    sc.enterBlock()
    self.parse(parser, sc,
      some(token.TokenType.TokenType_Symbol_Big_Parenthese_Right),
      expressOperandEndCb=some((opparse.operandEndCbFunc)proc(t: token.Token): tuple[isEnd: bool, isSkipNext: bool] =
        var isSkipNext = true
        result = (false, isSkipNext)
        if (t.tokenType == token.TokenType.TokenType_Symbol_Big_Parenthese_Right) or (t.tokenType == token.TokenType.TokenType_Line_Break) or (t.tokenType == token.TokenType.TokenType_Back_Slash_R) or (t.tokenType == token.TokenType_Semicolon):
          if t.tokenType != token.TokenType.TokenType_Symbol_Big_Parenthese_Right:
            isSkipNext = false
          return (true, isSkipNext)))
    sc.leaveBlock()
    parser.opts.add(opparse.Opt(
      instruction: optcode.Instruction.Instruction_Condition_Block_End,
      values: @[opparse.OptValue()]
    ))
    let blockEndOptIndex = parser.opts.len() - 1
    return (optIndex, blockEndOptIndex)

proc handleIfStmt*(self: ihandle.IHandle, parser: var parse.Parser, sc: var scope.Scope) =
    #[
    # 1. 跳过if
    # 2. 处理 if 和 { 之间的表达式
    # 3. 处理 { 和 } 之间的stmts
    # 4. 注意: 为了跳转, 会在 每一个块的尾部添加一个结束的指令: Instruction_Condition_Block_End
    ]#
    # 跳过 if
    parser.skipNextOne()
    parser.opts.add(opparse.Opt(
        instruction: optcode.Instruction.Instruction_If_Stmt
    ))
    # 条件开始
    parser.opts.add(opparse.Opt(
      instruction: optcode.Instruction.Instruction_Condition_Expr_Start
    ))
    # 处理 if { 之间的条件表达式
    var expressParser = opparse.new(parser.tokens[parser.index..parser.length-1], sc)
    expressParser.setOperandEndCb(proc(t: token.Token): tuple[isEnd: bool, isSkipNext: bool] =
        if t.tokenType == token.TokenType.TokenType_Symbol_Big_Parenthese_Left:
            # 遇到 { 结束
            return (true, true)
        return (false, false))
    expressParser.parse()
    let opts = expressParser.getOpts()
    # 如果 opts 的结果个数是0, 说明, 表达式的计算为空 => 表示的是, 这里不存在一个表达式
    if opts.len() == 0:
      quit("expect express")
    parser.opts.add(opts)
    # 条件结束
    parser.opts.add(opparse.Opt(
      instruction: optcode.Instruction.Instruction_Condition_Expr_End
    ))
    # 记录之后要修改的操作码位置
    var optIndex = parser.opts.len() - 1
    # 注意: 这里先将第二个占位符填充为 none, 因为 if 语句结束后, 可能就是文件尾部, 如果不填写为 none, 虚拟机不知道 在条件不成立的情况下跳转到哪里
    parser.opts[optIndex].values = @[opparse.OptValue(
      integer: some(int64(parser.opts.len()))
    ), opparse.OptValue()]
    # 将表达式使用完毕的token跳过
    parser.skipNextN(expressParser.getUsedTokenTotal())
    # 处理 { } 之间的 语句
    # 进入子作用域
    sc.enterBlock()
    self.parse(parser, sc,
      some(token.TokenType.TokenType_Symbol_Big_Parenthese_Right),
      expressOperandEndCb=some((opparse.operandEndCbFunc)proc(t: token.Token): tuple[isEnd: bool, isSkipNext: bool] =
        var isSkipNext = true
        result = (false, isSkipNext)
        if (t.tokenType == token.TokenType.TokenType_Symbol_Big_Parenthese_Right) or (t.tokenType == token.TokenType.TokenType_Line_Break) or (t.tokenType == token.TokenType.TokenType_Back_Slash_R) or (t.tokenType == token.TokenType_Semicolon):
          if t.tokenType == token.TokenType.TokenType_Symbol_Big_Parenthese_Right:
            isSkipNext = false
          return (true, isSkipNext)))
    sc.leaveBlock()
    # 语句块处理完毕应该跳转到 整个if语句的最后
    var blockEndOptIndexs = newSeq[int]()
    # 添加 if 语句结束标识 (也就是 {}中) 的最后一个指令
    parser.opts.add(opparse.Opt(
      instruction: optcode.Instruction.Instruction_Condition_Block_End,
      values: @[opparse.OptValue()]
    ))
    var blockEndOptIndex = parser.opts.len() - 1
    blockEndOptIndexs.add(blockEndOptIndex)
    # 在 optIndex 的第二个参数填充下一个语句的位置 (但是在这之前, 需要判断token结束之前 后面还有没有有效的token)
    let cur = parser.currentToken()
    if cur.isNone():
      return
    parser.opts[optIndex].values[1] = (opparse.OptValue(
      integer: some(int64(parser.opts.len()))
    ))
    # 查找 else if / else
    while true:
      let tok = parser.currentToken()
      if tok.isNone():
        return
      let curToken = tok.get()
      case curToken.tokenType
      of token.TokenType.TokenType_KW_Else_If:
        # optIndex:
        # 如果是 if 后的第一个 else if, 那么: 这里的 optIndex 就是 if 语句条件表达式结束指令的索引
        # 如果不是 if 后的第一个 else if, 那么: 这里的 optIndex 就是 上一个 else if 语句条件表达式结束指令的索引
        # 所以这里不需要判断是否是 if 后的第一个 else if (都可以用 optIndex 表示)
        let v = self.handleIfElseStmt(parser, sc)
        optIndex = v.optIndex
        parser.opts[optIndex].values[1] = (opparse.OptValue(
          integer: some(int64(parser.opts.len()))
          # integer: some(int64(v.blockEndOptIndex))
        ))
        blockEndOptIndexs.add(v.blockEndOptIndex)
      of token.TokenType.TokenType_KW_Else:
        # 填充 optIndex 的第二个参数
        let blockEndOptIndex = self.handleElseStmt(parser, sc)
        # parser.opts[optIndex].values[1] = (opparse.OptValue(
        #   integer: some(int64(parser.opts.len()))
        # ))
        blockEndOptIndexs.add(blockEndOptIndex)
        break
      else:
        break
    #[
    # 从当前位置找, 找到下一个非空白token为止
    let cur = parser.currentToken()
    if cur.isSome():
      # 如果 cur 存在, 说明没有到文件尾部, 那么填充之前的跳转位置, 如:
      #[ 
      情况1:
      if 1 {
      } else if 0 {
      } else {
      }
      情况2:
      if 1 {
      } else if 0 {
      } else {
      }
      a = 1
      ]#
      # 情况1: 就不需要填充if结束的跳转位置, 因为默认的跳转位置就是 none, 也就是尾部
      # 情况2: 这种情况就需要跳转到 a = 1 的位置, 所以需要填充 跳转的位置
      for index in blockEndOptIndexs:
        parser.opts[index].values[0] = opparse.OptValue(
          integer: some(int64(parser.opts.len()))
        )
    ]#
    for index in blockEndOptIndexs:
      parser.opts[index].values[0] = opparse.OptValue(
        integer: some(int64(parser.opts.len()))
      )

