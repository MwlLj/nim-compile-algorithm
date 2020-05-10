import "expression/parse"
import "expression/parse_use_instruction" as parserUI
import "expression/express"
from "../../lexical_analysis/src/token/token" as token import nil
# import "../../lexical_analysis/src/token/token" as token
from "../../lexical_analysis/src/token/parse" as token_parse import nil
from "../../lexical_analysis/src/token/handle" as token_handle import nil
import strformat
import options

type
    Test = object
        tokens: seq[token.Token]
        index: int
        length: int

proc iterExpr(self: Test, value: express.ExprValue): int64 =
    if value.exp.isSome():
        var left, right: int64 = 0
        var op: char
        let exp = value.exp.get()
        if exp.op.ch.isSome():
            op = exp.op.ch.get()
            echo(fmt"op: {op}")
        if exp.left.isSome():
            echo("left expr:")
            left = self.iterExpr(exp.left.get())
        if exp.right.isSome():
            echo("right expr: ")
            right = self.iterExpr(exp.right.get())
        case op
        of '+':
            return left + right
        of '-':
            if exp.left.isNone() and exp.right.isSome():
                return -1 * right
            else:
                return left - right
        of '*':
            return left * right
        of '/':
            return left div right
        else:
            discard
    elif value.value.isSome():
        let va = value.value.get()
        if va.i64.isSome():
            let v = va.i64.get()
            echo(v)
            return v
        elif va.str.isSome():
            echo(va.str.get())
            return 0
        else:
            return 0

proc takeNextOne(self: var Test): Option[token.Token] =
    let index = self.index + 1
    if index > self.length - 1:
        return none(token.Token)
    self.index = index
    return some(self.tokens[index])

proc skipNextN(self: var Test, n: int) =
    self.index += n

proc skipNextOne(self: var Test) =
    self.skipNextN(1)

proc lookupNextOne(self: var Test): Option[token.Token] =
    let index = self.index + 1
    if index > self.length - 1:
        return none(token.Token)
    return some(self.tokens[index])

proc parse(self: var Test) =
    while true:
        let v = self.takeNextOne()
        if v.isNone():
            break
        let t = v.get()
        case t.tokenType
        of token.TokenType.TokenType_Single_Comment:
            discard
        of token.TokenType.TokenType_Multi_Comment:
            discard
        else:
            var parser = parse.new(self.tokens[self.index..self.length-1])
            let exprValue = parser.express(0)
            if exprValue.isSome():
                let r = self.iterExpr(exprValue.get())
                echo(fmt"result: {r}")
            self.skipNextN(parser.getUsedTokenTotal())

proc newTest(tokens: seq[token.Token]): Test =
    result = Test(
        tokens: tokens,
        index: -1,
        length: tokens.len()
    )

proc parseTest() =
    let stream = readFile("./resource/test.lion")
    var tokenParser = token_parse.new(stream)
    let tokens = token_handle.parse(tokenParser)
    echo(tokens)
    var test = newTest(tokens)
    test.parse()

proc parseUseInstructionTest() =
    let stream = readFile("./resource/test.lion")
    var tokenParser = token_parse.new(stream)
    let tokens = token_handle.parse(tokenParser)
    echo(tokens)
    # 处理多条表达式语句
    let tokenLength = tokens.len()
    var index = 0
    while index < tokenLength:
        var parser = parserUI.new(tokens[index..tokenLength-1])
        parser.parse()
        # echo(r)
        index += parser.getUsedTokenTotal()
        parser.printOpts()

proc main() =
    # parseTest()
    parseUseInstructionTest()

when isMainModule:
    main()

