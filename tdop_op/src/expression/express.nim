import "../../../lexical_analysis/src/token/token" as token
import options

type
    Expr* = ref object
        left*: Option[ExprValue]
        right*: Option[ExprValue]
        op*: token.Value
        # 记录表达式的类型
        typ: string

    ExprValue* = object
        exp*: Option[Expr]
        value*: Option[token.Value]
