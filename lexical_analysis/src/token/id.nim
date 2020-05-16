import "parse"
import "token"
import options

proc getID(self: var parse.Parse, id: var string) =
    while true:
        let v = self.lookupNextOne()
        if v.isNone():
            break
        let c = v.get()
        if self.isIDEnd(c):
            id.add(c)
            self.skipNextOne()
        else:
            break

proc handleAfterElse(self: var parse.Parse): token.TokenType =
  result = token.TokenType.TokenType_KW_Else
  let oldIndex = self.getIndex()
  # 找到下一个ID
  while true:
    let v = self.takeNextOne()
    if v.isNone():
      # 直到结束都没有找到ID
      self.setIndex(oldIndex)
      return
    else:
      let c = v.get()
      if self.isIDStart(c):
        var id: string
        id.add(c)
        self.getID(id)
        if id != "if":
          # 后面不是 if
          self.setIndex(oldIndex)
          return
        else:
          result = token.TokenType.TokenType_KW_Else_If
          return

proc handleID*(self: var parse.Parse, id: var string) =
    self.getID(id)
    var tokenType: token.TokenType
    case id
    of "if":
        tokenType = token.TokenType.TokenType_KW_If
    of "elif":
        tokenType = token.TokenType.TokenType_KW_Else_If
    of "else":
        # tokenType = token.TokenType.TokenType_KW_Else
        tokenType = self.handleAfterElse()
    of "while":
        tokenType = token.TokenType.TokenType_KW_While
    of "for":
        tokenType = token.TokenType.TokenType_KW_For
    of "fn", "func":
        tokenType = token.TokenType.TokenType_KW_Fn
    of "true":
        tokenType = token.TokenType.TokenType_KW_True
    of "false":
        tokenType = token.TokenType.TokenType_KW_False
    of "let":
        tokenType = token.TokenType.TokenType_KW_Let
    of "var":
        tokenType = token.TokenType.TokenType_KW_Var
    of "string":
        tokenType = token.TokenType.TokenType_KW_String
    of "i32", "int32":
        tokenType = token.TokenType.TokenType_KW_Int32
    of "u32", "uint32":
        tokenType = token.TokenType.TokenType_KW_UInt32
    of "f32", "float32":
        tokenType = token.TokenType.TokenType_KW_Float32
    of "f64", "float64":
        tokenType = token.TokenType.TokenType_KW_Float64
    else:
        tokenType = token.TokenType.TokenType_ID
    self.tokens.add(token.Token(
        tokenType: tokenType,
        value: token.Value(
            str: some(id)
        )
    ))

