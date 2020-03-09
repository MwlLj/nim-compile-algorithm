import "token"

import sequtils
import strutils
import strformat

type
    NodeType = enum
        NodeTypeDouble
        NodeTypeSingle
        NodeTypeNumber

type
    Node = ref object
        left: Node
        right: Node
        opt: string
        value: int
        nodeType: NodeType

proc newDoubleNode(left: Node, right: Node, opt: string): Node =
    result = Node(
        left: left,
        right: right,
        opt: opt,
        nodeType: NodeType.NodeTypeDouble
    )

proc newSingleNode(left: Node, opt: string): Node =
    result = Node(
        left: left,
        opt: opt,
        nodeType: NodeType.NodeTypeSingle
    )

proc newNumberNode(value: int): Node =
    result = Node(
        value: value,
        nodeType: NodeType.NodeTypeNumber
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
proc six(self: var Grammar): tuple[v: Node, ok: bool]
proc five(self: var Grammar): tuple[v: Node, ok: bool]
proc four(self: var Grammar): tuple[v: Node, ok: bool]
proc third(self: var Grammar): tuple[v: Node, ok: bool]
proc second(self: var Grammar): tuple[v: Node, ok: bool]
proc first(self: var Grammar): tuple[v: Node, ok: bool]
proc zero(self: var Grammar): tuple[v: Node, ok: bool]
proc calc(self: Grammar, node: Node): int

#[
## 方法定义
]#
proc top(self: var Grammar): tuple[v: Node, ok: bool] =
    let six = self.six()
    if six[1] == false:
        return (six[0], false)
    var value: Node = six[0]
    while true:
        let obj = self.lookupOne()
        if obj[1] == false:
            break
        case obj[0].ident
        of token.operator:
            let objValue = obj[0].value
            if objValue == "<" or objValue == "<=" or objValue == ">" or objValue == ">=":
                let takeObj = self.takeOne()
                if takeObj[1] == false:
                    return (value, true)
                let f = self.six()
                if f[1] == false:
                    return (f[0], false)
                value = newDoubleNode(value, f[0], objValue)
            else:
                return (value, true)
        else:
            discard
    return (value, true)

#[
## !=  ==
]#
proc six(self: var Grammar): tuple[v: Node, ok: bool] =
    let five = self.five()
    if five[1] == false:
        return (five[0], false)
    var value: Node = five[0]
    while true:
        let obj = self.lookupOne()
        if obj[1] == false:
            break
        case obj[0].ident
        of token.operator:
            let objValue = obj[0].value
            if objValue == "==" or objValue == "!=":
                let takeObj = self.takeOne()
                if takeObj[1] == false:
                    return (value, true)
                let f = self.five()
                if f[1] == false:
                    return (f[0], false)
                value = newDoubleNode(value, f[0], objValue)
            else:
                return (value, true)
        else:
            discard
    return (value, true)

#[
## &&
]#
proc five(self: var Grammar): tuple[v: Node, ok: bool] =
    let four = self.four()
    if four[1] == false:
        return (four[0], false)
    var value: Node = four[0]
    while true:
        let obj = self.lookupOne()
        if obj[1] == false:
            break
        case obj[0].ident
        of token.operator:
            let objValue = obj[0].value
            if objValue == "&&":
                let takeObj = self.takeOne()
                if takeObj[1] == false:
                    return (value, true)
                let f = self.four()
                if f[1] == false:
                    return (f[0], false)
                value = newDoubleNode(value, f[0], objValue)
            else:
                return (value, true)
        else:
            discard
    return (value, true)

#[
## ||
]#
proc four(self: var Grammar): tuple[v: Node, ok: bool] =
    let third = self.third()
    if third[1] == false:
        return (third[0], false)
    var value: Node = third[0]
    while true:
        let obj = self.lookupOne()
        if obj[1] == false:
            break
        case obj[0].ident
        of token.operator:
            let objValue = obj[0].value
            if objValue == "||":
                let takeObj = self.takeOne()
                if takeObj[1] == false:
                    return (value, true)
                let f = self.third()
                if f[1] == false:
                    return (f[0], false)
                value = newDoubleNode(value, f[0], objValue)
            else:
                return (value, true)
        else:
            discard
    return (value, true)

proc third(self: var Grammar): tuple[v: Node, ok: bool] =
    let second = self.second()
    if second[1] == false:
        return (second[0], false)
    var value: Node = second[0]
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
                let f = self.second()
                if f[1] == false:
                    return (f[0], false)
                value = newDoubleNode(value, f[0], objValue)
            else:
                return (value, true)
        else:
            discard
    return (value, true)

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
            if objValue == "*" or objValue == "/":
                let takeObj = self.takeOne()
                if takeObj[1] == false:
                    return (value, true)
                let f = self.second()
                if f[1] == false:
                    return (f[0], false)
                value = newDoubleNode(value, f[0], objValue)
            else:
                return (value, true)
        else:
            discard
    return (value, true)

proc first(self: var Grammar): tuple[v: Node, ok: bool] =
    let obj = self.lookupOne()
    if obj[1] == false:
        return (defaultNode(), true)
    case obj[0].ident
    of token.operator:
        let objValue = obj[0].value
        if objValue == "!" or objValue == "~" or objValue == "-":
            let takeObj = self.takeOne()
            if takeObj[1] == false:
                return (defaultNode(), true)
            let first = self.first()
            if first[1] == false:
                return (first[0], false)
            return (newSingleNode(first[0], objValue), true)
    else:
        discard
    return self.zero()

proc zero(self: var Grammar): tuple[v: Node, ok: bool] =
    let obj = self.takeOne()
    if obj[1] == false:
        return (defaultNode(), true)
    case obj[0].ident
    of token.number:
        try:
            return (newNumberNode(strutils.parseInt(obj[0].value)), true)
        except:
            return (defaultNode(), false)
    of token.operator:
        if obj[0].value == "(":
            let top = self.top()
            if top[1] == false:
                return (top[0], false)
            else:
                self.tokens.delete(0, 0)
                return (top[0], true)
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
    # return self.third()
    let obj = self.top()
    if obj[1] == false:
        return (0, false)
    return (self.calc(obj[0]), true)

proc calc(self: Grammar, node: Node): int =
    case node.nodeType
    of NodeType.NodeTypeDouble:
        let leftValue = self.calc(node.left)
        let rightValue = self.calc(node.right)
        if node.opt == "+":
            return leftValue + rightValue
        elif node.opt == "-":
            return leftValue - rightValue
        elif node.opt == "*":
            return leftValue * rightValue
        elif node.opt == "||":
            if leftValue > 0 or rightValue > 0:
                return 1
            else:
                return 0
        elif node.opt == "&&":
            if leftValue > 0 and rightValue > 0:
                return 1
            else:
                return 0
        elif node.opt == "==":
            if leftValue == rightValue:
                return 1
            else:
                return 0
        elif node.opt == "!=":
            if leftValue != rightValue:
                return 1
            else:
                return 0
        elif node.opt == "<":
            if leftValue < rightValue:
                return 1
            else:
                return 0
        elif node.opt == "<=":
            if leftValue <= rightValue:
                return 1
            else:
                return 0
        elif node.opt == ">":
            if leftValue > rightValue:
                return 1
            else:
                return 0
        elif node.opt == ">=":
            if leftValue >= rightValue:
                return 1
            else:
                return 0
    of NodeType.NodeTypeSingle:
        let value = self.calc(node.left)
        if node.opt == "!":
            if value > 0:
                return 0
            else:
                return 1
        elif node.opt == "-":
            return -1 * value
    of NodeType.NodeTypeNumber:
        return node.value
    # echo(node.opt, leftValue, rightValue)

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
