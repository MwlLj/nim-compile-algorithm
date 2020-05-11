import "parse"
import "token"
import options

proc handleID*(self: var parse.Parse, id: var string) =
    while true:
        let v = self.lookupNextOne()
        if v.isNone():
            break
        let c = v.get()
        if self.isIDEnd(c):
            id.add(c)
            self.skipNextOne()
        else:
            break
    var tokenType: token.TokenType
    case id
    of "if":
        tokenType = token.TokenType.TokenType_KW_If
    of "while":
        tokenType = token.TokenType.TokenType_KW_While
    of "for":
        tokenType = token.TokenType.TokenType_KW_For
    of "fn", "func":
        tokenType = token.TokenType.TokenType_KW_Fn
    of "true":
        tokenType = token.TokenType.TokenType_KW_True
    of "false":
        tokenType = token.TokenType.TokenType_KW_False
    of "let":
        tokenType = token.TokenType.TokenType_KW_Let
    of "var":
        tokenType = token.TokenType.TokenType_KW_Var
    of "string":
        tokenType = token.TokenType.TokenType_KW_String
    of "i32", "int32":
        tokenType = token.TokenType.TokenType_KW_Int32
    of "u32", "uint32":
        tokenType = token.TokenType.TokenType_KW_UInt32
    of "f32", "float32":
        tokenType = token.TokenType.TokenType_KW_Float32
    of "f64", "float64":
        tokenType = token.TokenType.TokenType_KW_Float64
    else:
        tokenType = token.TokenType.TokenType_ID
    self.tokens.add(token.Token(
        tokenType: tokenType,
        value: token.Value(
            str: some(id)
        )
    ))

