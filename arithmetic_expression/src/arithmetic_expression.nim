import "token"
import "grammar"

proc main() =
    let t = token.newToken("1 + 1 * 2 * 3 + 2 - 10 + 100 + (0 + 1)")
    echo(t)
    var g = grammar.newGrammar(t)
    let obj = g.parse()
    echo(obj)

when isMainModule:
    main()
