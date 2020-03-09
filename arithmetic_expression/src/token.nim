#[
## 将字符串转换为 token对象
]#

type
    Ident* = enum
        number, operator, parentheses_start, parentheses_end

type
    Mode = enum
        ModeNormal,
        # &
        ModeVersus,
        # |
        ModeOr,
        # =
        ModeEqual

type
    Token* = object
        ident*: Ident
        value*: string

const ops = ['+', '-', '*', '/', '%', '(', ')']
const white = [' ', '\r', '\n', '\t']

proc defaultToken*(): Token =
    result = Token()

proc newToken*(s: string): seq[Token] =
    result = newSeq[Token]()
    var word: string
    var mode: Mode
    for c in s:
        case mode
        of Mode.ModeVersus:
            if c == '&':
                word.add(c)
            else:
                discard
            result.add(Token(
                ident: Ident.operator,
                value: word
                ))
            mode = Mode.ModeNormal
            word = ""
        of Mode.ModeOr:
            if c == '|':
                word.add(c)
            else:
                discard
            result.add(Token(
                ident: Ident.operator,
                value: word
                ))
            mode = Mode.ModeNormal
            word = ""
        of Mode.ModeEqual:
            if c == '=':
                word.add(c)
            else:
                discard
            result.add(Token(
                ident: Ident.operator,
                value: word
                ))
            mode = Mode.ModeNormal
            word = ""
        of Mode.ModeNormal:
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
            elif c in white:
                discard
            elif c == '&':
                if word != "":
                    result.add(Token(
                        ident: Ident.number,
                        value: word
                        ))
                word = ""
                mode = Mode.ModeVersus
                word.add(c)
            elif c == '|':
                if word != "":
                    result.add(Token(
                        ident: Ident.number,
                        value: word
                        ))
                word = ""
                mode = Mode.ModeOr
                word.add(c)
            elif c == '=' or c == '!' or c == '<' or c == '>':
                if word != "":
                    result.add(Token(
                        ident: Ident.number,
                        value: word
                        ))
                word = ""
                mode = Mode.ModeEqual
                word.add(c)
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
