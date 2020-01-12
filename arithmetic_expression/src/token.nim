#[
## 将字符串转换为 token对象
]#

type
    Ident* = enum
        number, operator, parentheses

type
    Token* = object
        ident: Ident
        value*: string

proc defaultToken*(): Token =
    result = Token()

proc newToken*(s: string): seq[Token] =
    result = newSeq[Token]()
    var word: string
    for c in s:
        case c
        of '+', '-', '*', '/', '%':
            if word != "":
                result.add(Token(
                    ident: Ident.number,
                    value: word
                    ))
            result.add(Token(
                ident: Ident.operator,
                value: $c
                ))
            word = ""
        of ' ':
            discard
        of '(', ')':
            result.add(Token(
                ident: Ident.parentheses,
                value: $c
                ))
        else:
            word.add(c)
    if word != "":
        result.add(Token(
            ident: Ident.operator,
            value: word
            ))
