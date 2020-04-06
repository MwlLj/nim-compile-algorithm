import "token"

type
    Parse = object
        tokens: seq[token.Token]

proc parse*(self: Parse) =
    discard

proc new*(): Parse =
    result = Parse()
