import "parse"
import "../structs/scope"
import "../../../tdop_op/src/expression/parse_use_instruction" as opparse
from "../../../lexical_analysis/src/token/token" as token import nil
import options

type
    IHandle* = ref object of RootObj

method handleIfStmt*(self: IHandle, parser: var parse.Parser, sc: var scope.Scope) {.base.} =
    quit("must be override handleIfStmt")

method handleExpression*(self: IHandle, parser: var parse.Parser, sc: var scope.Scope) {.base.} =
    quit("must be override handleExpression")

method parse*(self: IHandle, parser: var parse.Parser, sc: var scope.Scope, terminationTokenType: Option[token.TokenType] = none(token.TokenType), expressOperandEndCb: Option[opparse.operandEndCbFunc] = none(opparse.operandEndCbFunc)) =
    quit("must be override parse")

