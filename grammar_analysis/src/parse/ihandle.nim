import "parse"
from "../../../lexical_analysis/src/token/token" as token import nil
import options

type
    IHandle* = ref object of RootObj

method handleIfStmt*(self: IHandle, parser: var parse.Parser) {.base.} =
    quit("must be override handleIfStmt")

method handleExpression*(self: IHandle, parser: var parse.Parser) {.base.} =
    quit("must be override handleExpression")

method parse*(self: IHandle, parser: var parse.Parser, terminationTokenType: Option[token.TokenType] = none(token.TokenType)) =
    quit("must be override parse")

