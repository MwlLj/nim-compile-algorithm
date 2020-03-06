#[
## 将字符串转换为 token对象
]#

import strutils

type
    Ident* = enum
        number, operator, parentheses_start, parentheses_end

type
    Token* = object
        ident*: Ident
        value*: string

const ops = ['+', '-', '*', '/', '%', '(', ')']

proc defaultToken*(): Token =
    result = Token()

proc newToken*(s: string): seq[Token] =
    result = newSeq[Token]()
    var word: string
    for c in s:
        if c in ops:
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
        elif c == ' ':
            discard
        else:
            word.add(c)
    if word != "":
        result.add(Token(
            ident: Ident.number,
            value: word
            ))

proc newToken2*(s: string): seq[Token] =
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
        of '(':
            result.add(Token(
                ident: Ident.parentheses_start,
                value: $c
                ))
        of ')':
            result.add(Token(
                ident: Ident.parentheses_end,
                value: $c
                ))
        else:
            word.add(c)
    if word != "":
        result.add(Token(
            ident: Ident.number,
            value: word
            ))
