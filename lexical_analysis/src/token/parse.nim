import "token"
import options

type
    Parse* = object
        stream: string
        length: int
        index: int
        tokens*: seq[token.Token]

proc lookupNextN*(self: Parse, n: int): Option[char] =
    let index = self.index + n
    if index > self.length - 1:
        return none(char)
    return some(self.stream[index])

proc lookupNextOne*(self: Parse): Option[char] =
    return self.lookupNextN(1)

proc takeNextN*(self: var Parse, n: int): Option[char] =
    result = self.lookupNextN(n)
    if result.isNone():
        return
    self.index += n

proc takeNextOne*(self: var Parse): Option[char] =
    return self.takeNextN(1)

proc skipNextN*(self: var Parse, n: int) =
    self.index += n

proc skipNextOne*(self: var Parse) =
    self.skipNextN(1)

proc isIDStart*(self: var parse.Parse, c: char): bool =
    if c == '_' or (c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z'):
        return true
    return false

# 除第一位外是否是 id 的元素
proc isIDEnd*(self: parse.Parse, c: char): bool =
    if (c == '_') or (c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z') or (c >= '0' and c <= '9'):
        return true
    return false

proc isNumberStart*(self: var parse.Parse, c: char): bool =
    if c >= '0' and c <= '9':
        return true
    return false

proc addChar*(self: var parse.Parse, tokenType: token.TokenType, c: char) =
    self.tokens.add(token.Token(
        tokenType: tokenType,
        value: token.Value(
            ch: some(c)
        )
    ))

proc addChar*(self: var parse.Parse, tokenType: token.TokenType, c: char, lbp: int) =
    self.tokens.add(token.Token(
        tokenType: tokenType,
        value: token.Value(
            ch: some(c)
        ),
        lbp: lbp
    ))

proc addString*(self: var parse.Parse, tokenType: token.TokenType, s: string) =
    self.tokens.add(token.Token(
        tokenType: tokenType,
        value: token.Value(
            str: some(s)
        )
    ))

proc addInt64*(self: var parse.Parse, tokenType: token.TokenType, i: int64) =
    self.tokens.add(token.Token(
        tokenType: tokenType,
        value: token.Value(
            i64: some(i)
        )
    ))

proc new*(stream: string): Parse =
    result = Parse(
        stream: stream,
        length: stream.len(),
        index: -1
    )
