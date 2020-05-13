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
            t = self.tokens[self.index]
        else:
            break
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

proc getOpts*(self: Parser): seq[opparse.Opt] =
    result = self.opts

proc newParser*(tokens: seq[token.Token]): Parser =
    result = Parser(
        tokens: tokens,
        index: 0,
        length: tokens.len()
    )

