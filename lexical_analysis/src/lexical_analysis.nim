import "./token/parse"

proc main() =
    var parser = parse.new()
    parser.parse()

when isMainModule:
    main()
