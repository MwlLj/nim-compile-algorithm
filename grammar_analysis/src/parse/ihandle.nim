import "parse"
import "../structs/scope"
from "../../../lexical_analysis/src/token/token" as token import nil
import options

type
    IHandle* = ref object of RootObj

method handleIfStmt*(self: IHandle, parser: var parse.Parser, sc: var scope.Scope) {.base.} =
    quit("must be override handleIfStmt")

method handleExpression*(self: IHandle, parser: var parse.Parser, sc: var scope.Scope) {.base.} =
    quit("must be override handleExpression")

method parse*(self: IHandle, parser: var parse.Parser, sc: var scope.Scope, terminationTokenType: Option[token.TokenType] = none(token.TokenType)) =
    quit("must be override parse")

