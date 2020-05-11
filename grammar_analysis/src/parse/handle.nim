import "ihandle"
import "parse"
import "if_stmt"
import "expression"
import "../structs/scope"
import "../../../tdop_op/src/expression/parse_use_instruction" as opparse
from "../../../lexical_analysis/src/token/token" as token import nil
import options
import strformat

type
    Handle* = ref object of ihandle.IHandle

method handleIfStmt*(self: Handle, parser: var parse.Parser, sc: var scope.Scope) =
    if_stmt.handleIfStmt(self, parser, sc)

method handleExpression*(self: Handle, parser: var parse.Parser, sc: var scope.Scope) =
    expression.handleExpression(self, parser, sc)

#[
proc parse*(self: var parse.Parser, terminationToken: Option[token.Token] = none(token.Token)) =
    while true:
        let cur = self.currentToken()
        if cur.isNone():
            return
        let curToken = cur.get()
        case curToken.tokenType:
        of token.TokenType.TokenType_KW_If:
            self.handleIfStmt()
        else:
            # 表达式
            self.handleExpression()
]#

