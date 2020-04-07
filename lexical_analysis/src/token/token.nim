import options

type
    Value* = object
        str*: Option[string]

type
    TokenType* = enum
        TokenType_Id,
        TokenType_KW_If,
        TokenType_KW_While,
        TokenType_KW_For,
        TokenType_KW_Fn,
        TokenType_KW_True,
        TokenType_KW_False,
        TokenType_Inner_Func_Print,
        TokenType_Single_Comment,
        TokenType_Multi_Comment,
        TokenType_Double_Quotes,
        TokenType_Back_Quotes

type
    Token* = object
        tokenType*: TokenType
        value*: Value

proc default*(): Token =
    result = Token()

proc new*(tokenType: TokenType, value: Value): Token =
    result = Token(
        tokenType: tokenType,
        value: value
    )
