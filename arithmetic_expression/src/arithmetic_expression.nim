import "token"
import "grammar_node"

proc main() =
    let t = token.newToken("(1 + 1) * 2 * 3")
    # let t = token.newToken("1 + 1 * 2 * 3 + ((2 - 10) * 2) * 10 + 100 + (0 + 1)")
    # echo(t)
    var g = grammar_node.newGrammar(t)
    # var g = grammar.newGrammar(t)
    let obj = g.parse()
    # g.iter(obj[0])
    echo(obj)

when isMainModule:
    main()
