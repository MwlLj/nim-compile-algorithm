import options

type
    Value* = object
        str*: Option[string]
        ch*: Option[char]

type
    TokenType* = enum
        # id
        TokenType_Id,
        # if
        TokenType_KW_If,
        # while
        TokenType_KW_While,
        # for
        TokenType_KW_For,
        # 函数 fn
        TokenType_KW_Fn,
        # let
        TokenType_KW_Let,
        # true
        TokenType_KW_True,
        # false
        TokenType_KW_False,
        # 小括号 (左) (
        TokenType_Symbol_Parenthese_Left,
        # 小括号 (右) )
        TokenType_Symbol_Parenthese_Right,
        # 大括号 (左) {
        TokenType_Symbol_Big_Parenthese_Left,
        # 大括号 (右) }
        TokenType_Symbol_Big_Parenthese_Right,
        # 中括号 (左) [
        TokenType_Symbol_Square_Brackets_Left,
        # 中括号 (右) ]
        TokenType_Symbol_Square_Brackets_Right,
        # 冒号 !
        TokenType_Symbol_Colon,
        # 感叹号 !
        TokenType_Symbol_Exclamation_Mark,
        # 小于号 <
        TokenType_Symbol_Less_Than,
        # 大于号 >
        TokenType_Symbol_More_Than,
        # 赋值 =
        TokenType_Symbol_Assignment,
        # 加号 +
        TokenType_Symbol_Plus,
        # 加号 +=
        TokenType_Symbol_Plus_Equal,
        # 减号 -
        TokenType_Symbol_Minus,
        # 减号 -=
        TokenType_Symbol_Minus_Equal,
        # 乘号 *
        TokenType_Symbol_Multiplication,
        # 乘号 *=
        TokenType_Symbol_Multiplication_Equal,
        # 除号 /
        TokenType_Symbol_Division,
        # 等于号 ==
        TokenType_Symbol_Equal,
        # 不等号 !=
        TokenType_Symbol_Not_Equal,
        # <=
        TokenType_Symbol_Less_Than_Equal,
        # >=
        TokenType_Symbol_More_Than_Equal,
        # 右箭头 ->
        TokenType_Symbol_Right_Arrow,
        # 单行注释 //
        TokenType_Single_Comment,
        # 多行注释 /**/
        TokenType_Multi_Comment,
        # 双引号 ""
        TokenType_Double_Quotes,
        # 反引号 ``
        TokenType_Back_Quotes,
        # 换行
        TokenType_Line_Break,
        # \r
        TokenType_Back_Slash_R,
        # \n
        TokenType_Back_Slash_N,
        # \t
        TokenType_Back_Slash_T

type
    Token* = object
        tokenType*: TokenType
        value*: Value

proc default*(): Token =
    result = Token()

proc new*(tokenType: TokenType, value: Value): Token =
    result = Token(
        tokenType: tokenType,
        value: value
    )
