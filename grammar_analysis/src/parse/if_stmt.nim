import "parse"
import "ihandle"
import "../../../tdop_op/src/expression/parse_use_instruction" as opparse
import "../../../tdop_op/src/opt/optcode"
import "../../../lexical_analysis/src/token/token"
import strformat
import "options"

proc handleIfStmt*(self: ihandle.IHandle, parser: var parse.Parser) =
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
    # 处理 if { 之间的条件表达式
    var expressParser = opparse.new(parser.tokens[parser.index..parser.length-1])
    expressParser.setOperandEndCb(proc(t: token.Token): bool =
        if t.tokenType == token.TokenType.TokenType_Symbol_Big_Parenthese_Left:
            # 遇到 { 结束
            return true
        return false)
    discard expressParser.express(0)
    let opts = expressParser.getOpts()
    parser.opts.add(opts)
    # 将表达式使用完毕的token跳过
    parser.skipNextN(expressParser.getUsedTokenTotal())
    # 处理 { } 之间的 语句
    self.parse(parser, some(token.TokenType.TokenType_Symbol_Big_Parenthese_Right))

