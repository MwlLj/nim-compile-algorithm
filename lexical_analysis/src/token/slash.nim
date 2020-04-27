import "token"
import "parse"
import "line"
import options

proc handleSingleComment(self: var parse.Parse) =
    # 处理单行注释
    var content: string
    while true:
        let v = self.lookupNextOne()
        if v.isNone():
            break
        let c = v.get()
        if self.isLineEnd():
            break
        else:
            content.add(c)
            self.skipNextOne()
    self.tokens.add(token.Token(
        tokenType: token.TokenType.TokenType_Single_Comment,
        value: token.Value(
            str: some(content)
        )
    ))

proc isMultiCommentStart(self: var parse.Parse): bool =
    let v = self.lookupNextOne()
    if v.isNone():
        return true
    let c = v.get()
    if c == '/':
        let v = self.lookupNextN(2)
        if v.isNone():
            return true
        if v.get() == '*':
            self.skipNextN(2)
            return true
    return false

proc isMultiCommentEnd(self: var parse.Parse): bool =
    let v = self.lookupNextOne()
    if v.isNone():
        return true
    let c = v.get()
    if c == '*':
        let v = self.lookupNextN(2)
        if v.isNone():
            return true
        if v.get() == '/':
            self.skipNextN(2)
            return true
    return false

proc handleMultiComment(self: var parse.Parse) =
    # 处理多行注释
    var content: string
    var count: int = 1
    while true:
        if self.isMultiCommentStart():
            count += 1
            content.add("/*")
        if self.isMultiCommentEnd():
            count -= 1
            if count > 0:
                content.add("*/")
        let v = self.lookupNextOne()
        if v.isNone():
            break
        let c = v.get()
        if count == 0:
            break
        else:
            content.add(c)
            self.skipNextOne()
    if count > 0:
        echo("/* is not full pair")
    self.tokens.add(token.Token(
        tokenType: token.TokenType.TokenType_Multi_Comment,
        value: token.Value(
            str: some(content)
        )
    ))

proc handleSlash*(self: var parse.Parse) =
    let v = self.lookupNextOne()
    if v.isNone():
        return
    let c = v.get()
    case c
    of '/':
        # 处理 //
        self.skipNextOne()
        self.handleSingleComment()
    of '*':
        # 处理 /*
        self.skipNextOne()
        self.handleMultiComment()
    else:
        self.addChar(token.TokenType.TokenType_Symbol_Division, '/', 50)

