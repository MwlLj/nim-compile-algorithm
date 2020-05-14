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

proc handleIfStmt*(self: ihandle.IHandle, parser: var parse.Parser, sc: var scope.Scope) =
    #[
    # 1. 跳过if
    # 2. 处理 if 和 { 之间的表达式
    # 3. 处理 { 和 } 之间的stmts
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
    var expressParser = opparse.new(parser.tokens[parser.index..parser.length-1])
    expressParser.setOperandEndCb(proc(t: token.Token): bool =
        if t.tokenType == token.TokenType.TokenType_Symbol_Big_Parenthese_Left:
            # 遇到 { 结束
            return true
        return false)
    expressParser.parse()
    let opts = expressParser.getOpts()
    parser.opts.add(opts)
    # 条件结束
    # 记录之后要修改的操作码位置
    var optIndex = parser.opts.len()
    parser.opts.add(opparse.Opt(
      instruction: optcode.Instruction.Instruction_Condition_Expr_End
    ))
    parser.opts[optIndex].values.add(opparse.OptValue(
      integer: some(int64(parser.opts.len()))
    ))
    # 将表达式使用完毕的token跳过
    parser.skipNextN(expressParser.getUsedTokenTotal())
    # 处理 { } 之间的 语句
    self.parse(parser, sc,
      some(token.TokenType.TokenType_Symbol_Big_Parenthese_Right),
      expressOperandEndCb=some((opparse.operandEndCbFunc)proc(t: token.Token): bool =
        result = false
        if (t.tokenType == token.TokenType.TokenType_Symbol_Big_Parenthese_Right) and (t.tokenType == token.TokenType.TokenType_Line_Break) or (t.tokenType == token.TokenType.TokenType_Back_Slash_R) or (t.tokenType == token.TokenType_Semicolon):
          return true))
    # 查找 else if

