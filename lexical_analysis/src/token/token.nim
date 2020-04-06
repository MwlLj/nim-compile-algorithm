import typeinfo

type
    TokenType = enum
        TokenType_Id

type
    Token* = object
        tokenType*: TokenType
        value*: Any

proc default*(): Token =
    result = Token()

proc new*(tokenType: TokenType, value: Any): Token =
    result = Token(
        tokenType: tokenType,
        value: value
    )
