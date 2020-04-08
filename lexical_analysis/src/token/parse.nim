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

proc addChar*(self: var parse.Parse, tokenType: token.TokenType, c: char) =
    self.tokens.add(token.Token(
        tokenType: tokenType,
        value: token.Value(
            ch: some(c)
        )
    ))

proc addString*(self: var parse.Parse, tokenType: token.TokenType, s: string) =
    self.tokens.add(token.Token(
        tokenType: tokenType,
        value: token.Value(
            str: some(s)
        )
    ))

proc new*(stream: string): Parse =
    result = Parse(
        stream: stream,
        length: stream.len(),
        index: -1
    )
