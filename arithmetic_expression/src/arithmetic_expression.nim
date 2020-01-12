import "token"
import "grammar"

proc main() =
    let t = token.newToken("1 + 1 * 2")
    let g = grammar.newGrammar(t)

when isMainModule:
    main()
