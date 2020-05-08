import "parse"
import "if_stmt"
from "../../../lexical_analysis/src/token/token" as token import nil
import options

proc parse*(self: var parse.Parser, terminationToken: Option[token.Token] = none(token.Token)) =
    let next = self.lookupNextOne()
    if next.isNone():
        return
    let nextToken = next.get()
    case nextToken.tokenType:
    of token.TokenType.TokenType_KW_If:
        self.handleIfStmt()
    else:
        # 表达式
        discard

