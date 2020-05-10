import "ihandle"
import "handle"
import "parse"
import "if_stmt"
import "expression"
import "var_define"
import "../../../tdop_op/src/expression/parse_use_instruction" as opparse
from "../../../lexical_analysis/src/token/token" as token import nil
import options
import strformat

method parse*(self: handle.Handle, parser: var parse.Parser, terminationTokenType: Option[token.TokenType]) =
    while true:
        let cur = parser.currentToken()
        echo(cur)
        if cur.isNone():
            return
        let curToken = cur.get()
        if terminationTokenType.isSome() and (terminationTokenType.get() == curToken.tokenType):
            parser.skipNextOne()
            break
        case curToken.tokenType:
        of token.TokenType.TokenType_KW_If:
            self.handleIfStmt(parser)
        of token.TokenType.TokenType_KW_Var:
            self.handleVarDefine(parser)
        else:
            # 表达式
            self.handleExpression(parser)

