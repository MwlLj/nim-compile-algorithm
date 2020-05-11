import "parse"
import "ihandle"
import "../structs/scope"
import "../../../tdop_op/src/opt/optcode"
import "../../../tdop_op/src/expression/parse_use_instruction" as opparse

proc handleExpression*(handle: ihandle.IHandle, parser: var parse.Parser, sc: var scope.Scope) =
    parser.opts.add(opparse.Opt(
        instruction: optcode.Instruction.Instruction_Express_Stmt
    ))
    # handle
    var expressParser = opparse.new(parser.tokens[parser.index..parser.length-1])
    expressParser.parse()
    let opts = expressParser.getOpts()
    parser.opts.add(opts)
    let total = expressParser.getUsedTokenTotal()
    parser.skipNextN(total)

