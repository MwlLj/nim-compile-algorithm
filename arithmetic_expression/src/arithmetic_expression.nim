import "token"
import "grammar"

proc main() =
    let t = token.newToken("1 + 1 * 2 * 3 + 2 - 10 + 100")
    var g = grammar.newGrammar(t)
    let obj = g.parse()
    echo(obj)

when isMainModule:
    main()
