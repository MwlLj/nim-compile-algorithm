import "token"

import sequtils
import strutils

type
    Grammar = object
        tokens: seq[token.Token]

#[
## 前置声明
]#
proc lookupOne(self: Grammar): tuple[t: token.Token, ok: bool]
proc takeOne(self: var Grammar): tuple[t: token.Token, ok: bool]
proc first(self: var Grammar): tuple[v: int, ok: bool]
proc zero(self: var Grammar): tuple[v: int, ok: bool]

#[
## 方法定义
]#
proc second(self: var Grammar): tuple[v: int, ok: bool] =
    let first = self.first()
    if first[1] == false:
        return (0, false)
    var value: int = first[0]
    while true:
        let obj = self.lookupOne()
        if obj[1] == false:
            break
        case obj[0].ident
        of token.operator:
            let objValue = obj[0].value
            if objValue == "+" or objValue == "-":
                let takeObj = self.takeOne()
                if takeObj[1] == false:
                    return (value, true)
                let f = self.first()
                if f[1] == false:
                    return (0, false)
                if objValue == "+":
                    value += f[0]
                elif objValue == "-":
                    value -= f[0]
            else:
                return (value, true)
        else:
            discard
    return (value, true)

proc first(self: var Grammar): tuple[v: int, ok: bool] =
    let zero = self.zero()
    if zero[1] == false:
        return (0, false)
    var value: int = zero[0]
    while true:
        let obj = self.lookupOne()
        if obj[1] == false:
            break
        case obj[0].ident
        of token.operator:
            let objValue = obj[0].value
            if objValue == "*" or objValue == "/":
                let takeObj = self.takeOne()
                if takeObj[1] == false:
                    return (value, true)
                let f = self.first()
                if f[1] == false:
                    return (0, false)
                if objValue == "*":
                    value *= f[0]
                # elif objValue == "/":
                #     value /= f[0]
            else:
                return (value, true)
        else:
            discard
    return (value, true)

proc zero(self: var Grammar): tuple[v: int, ok: bool] =
    let obj = self.takeOne()
    if obj[1] == false:
        return (0, false)
    case obj[0].ident
    of token.number:
        try:
            return (strutils.parseInt(obj[0].value), true)
        except:
            return (0, false)
    else:
        return (0, false)

proc grammar*(self: Grammar, tokens: seq[token.Token]) =
    discard

proc lookupOne(self: Grammar): tuple[t: token.Token, ok: bool] =
    if len(self.tokens) == 0:
        return (token.defaultToken(), false)
    let t = self.tokens[0]
    return (t, true)

proc takeOne(self: var Grammar): tuple[t: token.Token, ok: bool] =
    result = self.lookupOne()
    if result[1] == false:
        return (token.defaultToken(), false)
    self.tokens.delete(0, 0)

proc parse*(self: var Grammar): tuple[v: int, ok: bool] =
    # return self.first()
    return self.second()

proc newGrammar*(tokens: seq[token.Token]): Grammar =
    result = Grammar(
        tokens: tokens
    )
