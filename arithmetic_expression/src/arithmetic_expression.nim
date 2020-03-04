import "token"
import "grammar"

proc main() =
    let t = token.newToken("1 + 1 * 2")
    var g = grammar.newGrammar(t)
    let obj = g.parse()

when isMainModule:
    main()
