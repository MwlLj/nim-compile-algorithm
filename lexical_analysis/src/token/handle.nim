import "parse"
import "slash"
import "token"
import "double_quotes"
import "back_quotes"
import "exclamation_mark"
import "assignment"
import "than"
import "backslash"
import "id"
import "line"
import options

proc isIDStart(self: var parse.Parse, c: char): bool =
    if c == '_' or (c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z'):
        return true
    return false

proc parse*(self: var parse.Parse): seq[token.Token] =
    while true:
        let v = self.takeNextOne()
        if v.isNone():
            break
        let c = v.get()
        # echo((int)c)
        case c
        of '\r':
            line.handleBackSlashR(self)
        of '\n':
            line.handleBackSlashN(self)
        of '/':
            slash.handleSlash(self)
        of '\\':
            backslash.handleBackSlash(self)
        of '"':
            double_quotes.handleDoubleQuotes(self)
        of '`':
            back_quotes.handleBackQuotes(self)
        of '!':
            exclamation_mark.handleExclamationMark(self)
        of '=':
            assignment.handleAssignment(self)
        of '<':
            than.handleLessThan(self)
        of '>':
            than.handleMoreThan(self)
        of '?':
            discard
        of ':':
            self.addChar(token.TokenType.TokenType_Symbol_Colon, c)
        of '(':
            self.addChar(token.TokenType.TokenType_Symbol_Parenthese_Left, c)
        of ')':
            self.addChar(token.TokenType.TokenType_Symbol_Parenthese_Right, c)
        of '{':
            self.addChar(token.TokenType.TokenType_Symbol_Big_Parenthese_Left, c)
        of '}':
            self.addChar(token.TokenType.TokenType_Symbol_Big_Parenthese_Right, c)
        of '[':
            self.addChar(token.TokenType.TokenType_Symbol_Square_Brackets_Left, c)
        of ']':
            self.addChar(token.TokenType.TokenType_Symbol_Square_Brackets_Right, c)
        of '+':
            discard
        of '-':
            discard
        of '&':
            discard
        of '#':
            discard
        of '@':
            discard
        of '$':
            discard
        of '%':
            discard
        of ';':
            discard
        else:
            if self.isIDStart(c):
                var id: string
                id.add(c)
                self.handleID(id)
        #[
        ]#
    return self.tokens

