import "parse"
import "../../../tdop_op/src/expression/parse_use_instruction" as opparse
import "../../../lexical_analysis/src/token/token"

proc handleIfStmt*(self: var parse.Parser) =
    #[
    # 1. 跳过if
    # 2. 处理 if 和 { 之间的表达式
    # 3. 处理 { 和 } 之间的stmts
    ]#
    # 跳过 if
    self.skipNextOne()
    # 处理 if { 之间的条件表达式
    var expressParser = opparse.new(self.tokens[self.index..self.length-1])
    expressParser.setOperandEndCb(proc(t: token.Token): bool =
        if t.tokenType == token.TokenType.TokenType_Symbol_Square_Brackets_Left:
            # 遇到 { 结束
            return true
        return false)
    discard expressParser.express(0)
