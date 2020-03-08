import "token"

import sequtils
import strutils
import strformat

type
    Node = ref object
        left: Node
        right: Node
        opt: string
        value: int

proc newOptNode(left: Node, right: Node, opt: string): Node =
    result = Node(
        left: left,
        right: right,
        opt: opt,
    )

proc newValueNode(value: int): Node =
    result = Node(
        value: value
    )

proc defaultNode(): Node =
    result = Node(
    )

type
    Grammar = object
        tokens: seq[token.Token]

#[
## 前置声明
]#
proc lookupOne(self: Grammar): tuple[t: token.Token, ok: bool]
proc takeOne(self: var Grammar): tuple[t: token.Token, ok: bool]
proc first(self: var Grammar): tuple[v: Node, ok: bool]
proc zero(self: var Grammar): tuple[v: Node, ok: bool]
proc calc(self: Grammar, node: Node): int

#[
## 方法定义
]#
proc second(self: var Grammar): tuple[v: Node, ok: bool] =
    let first = self.first()
    if first[1] == false:
        return (first[0], false)
    var value: Node = first[0]
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
                    return (f[0], false)
                value = newOptNode(value, f[0], objValue)
            else:
                return (value, true)
        else:
            discard
    return (value, true)

proc first(self: var Grammar): tuple[v: Node, ok: bool] =
    let zero = self.zero()
    if zero[1] == false:
        return (zero[0], false)
    var value: Node = zero[0]
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
                    return (f[0], false)
                value = newOptNode(value, f[0], objValue)
            else:
                return (value, true)
        else:
            discard
    return (value, true)

proc zero(self: var Grammar): tuple[v: Node, ok: bool] =
    let obj = self.takeOne()
    if obj[1] == false:
        return (defaultNode(), true)
    case obj[0].ident
    of token.number:
        try:
            return (newValueNode(strutils.parseInt(obj[0].value)), true)
        except:
            return (defaultNode(), false)
    of token.operator:
        if obj[0].value == "(":
            let second = self.second()
            if second[1] == false:
                return (second[0], false)
            else:
                self.tokens.delete(0, 0)
                return (second[0], true)
    else:
        return (defaultNode(), false)

proc grammar*(self: Grammar, tokens: seq[token.Token]) =
    discard

proc lookupOne(self: Grammar): tuple[t: token.Token, ok: bool] =
    if len(self.tokens) == 0:
        return (token.defaultToken(), false)
    let t = self.tokens[0]
    if t.ident == token.operator:
        if t.value == ")":
            return (token.defaultToken(), false)
    return (t, true)

proc takeOne(self: var Grammar): tuple[t: token.Token, ok: bool] =
    result = self.lookupOne()
    if result[1] == false:
        return (token.defaultToken(), false)
    self.tokens.delete(0, 0)

proc parse*(self: var Grammar): tuple[v: int, ok: bool] =
    # return self.second()
    let obj = self.second()
    if obj[1] == false:
        return (0, false)
    return (self.calc(obj[0]), true)

proc calc(self: Grammar, node: Node): int =
    if node.left == nil and node.right == nil:
        return node.value
    var leftValue, rightValue: int
    if node.left != nil:
        leftValue = self.calc(node.left)
    if node.right != nil:
        rightValue = self.calc(node.right)
    echo(node.opt, leftValue, rightValue)
    if node.opt == "+":
        return leftValue + rightValue
    if node.opt == "-":
        return leftValue - rightValue
    if node.opt == "*":
        return leftValue * rightValue

proc iter*(self: Grammar, node: Node) =
    if node.left == nil and node.right == nil:
        return
    var leftNode, rightNode: Node
    if node.left != nil:
        self.iter(node.left)
        leftNode = node.left
    if node.right != nil:
        self.iter(node.right)
        rightNode = node.right
    echo(fmt"[{leftNode.value}] {node.opt} [{rightNode.value}]")

proc newGrammar*(tokens: seq[token.Token]): Grammar =
    result = Grammar(
        tokens: tokens
    )
