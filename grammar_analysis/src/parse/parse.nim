from "../../../tdop_op/src/expression/parse_use_instruction" as opparse import nil
from "../../../lexical_analysis/src/token/token" as token import nil
import "../structs/struct"
import options
import tables

type
  Parser* = object
    tokens*: seq[token.Token]
    index*: int
    length*: int
    opts*: seq[opparse.Opt]

proc skipNextN*(self: var Parser, n: int) =
    self.index += n

proc skipNextOne*(self: var Parser) =
    self.skipNextN(1)

proc currentTokenUnfilterWhite*(self: var Parser): Option[token.Token] =
    if self.index == 0 and self.length > 0:
        return some(self.tokens[0])
    let index = self.index
    if index > self.length - 1:
        return none(token.Token)
    var t = self.tokens[index]
    return some(t)

proc currentToken*(self: var Parser): Option[token.Token] =
    if self.index == 0 and self.length > 0:
        return some(self.tokens[0])
    let index = self.index
    if index > self.length - 1:
        return none(token.Token)
    var t = self.tokens[index]
    while true:
        case t.tokenType
        of token.TokenType.TokenType_Single_Comment,
          token.TokenType.TokenType_Multi_Comment,
          token.TokenType.TokenType_Back_Slash_R,
          token.TokenType.TokenType_Back_Slash_T,
          token.TokenType.TokenType_Line_Break:
            self.skipNextOne()
            if self.index > self.length - 1:
              return none(token.Token)
            t = self.tokens[self.index]
        else:
            break
    return some(t)

proc lookupNextOneUnfilterWhite*(self: var Parser): Option[token.Token] =
    if self.index == 0 and self.length > 0:
        return some(self.tokens[0])
    let index = self.index + 1
    if index > self.length - 1:
        return none(token.Token)
    var t = self.tokens[index]
    return some(t)

proc lookupNextOne*(self: var Parser): Option[token.Token] =
    if self.index == 0 and self.length > 0:
        return some(self.tokens[0])
    let index = self.index + 1
    if index > self.length - 1:
        return none(token.Token)
    var t = self.tokens[index]
    while true:
        case t.tokenType
        of token.TokenType.TokenType_Single_Comment,
          token.TokenType.TokenType_Multi_Comment,
          token.TokenType.TokenType_Back_Slash_R,
          token.TokenType.TokenType_Back_Slash_T,
          token.TokenType.TokenType_Line_Break:
            self.skipNextOne()
            t = self.tokens[self.index]
        else:
            break
    return some(t)

# 直到找到指定的tokenType为止
# 如果在 token 结束之前找到了 指定的 tokenType, 则返回成功, 否则返回失败
# 注意: 不会跳过 指定的 tokenType
proc findUntilEndTokenType*(self: var Parser, tokenType: token.TokenType): bool =
  result = false
  while true:
    let next = self.currentTokenUnfilterWhite()
    if next.isNone:
      return false
    let nextToken = next.get()
    if nextToken.tokenType == tokenType:
      return true
    self.skipNextOne()

proc getOpts*(self: Parser): seq[opparse.Opt] =
    result = self.opts

proc newParser*(tokens: seq[token.Token]): Parser =
    result = Parser(
        tokens: tokens,
        index: 0,
        length: tokens.len()
    )

