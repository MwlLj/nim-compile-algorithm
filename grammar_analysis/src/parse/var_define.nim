#[ 
变量定义的语法:
    var xxx string
        步骤:
            1. 创建 string 对象, 并存入 数组中, 记录在数组中的位置 index
            2. 将 xxx 与 index 绑定
        字节码:
            create_string_value
                编译器: 将此时的数值栈索引记录下来, 便于后面的 bind 操作
                虚拟机: 创建string类型的变量, 并追加到数据栈中
            bind_var xxx (index)
                编译器: 将 (xxx, index) 存储在 作用域中的 Map 对象中 (这里的目的是编译器的错误检查)
                    如果存在就提示重定义
                虚拟机: 将 (xxx, index) 存储在 作用域中的 Map 对象中 (加载到内存, 便于后期的计算)
    var xxx string = ""
    var xxx string = s
    var xxx string = string("")
    var xxx Person = Person{
    }
 ]#

import "parse"
import "ihandle"
import "../structs/scope"
import "../../../tdop_op/src/expression/parse_use_instruction" as opparse
import "../../../tdop_op/src/opt/optcode"
import "../../../lexical_analysis/src/token/token"
import strformat
import "options"

proc handleVarDefine*(self: ihandle.IHandle, parser: var parse.Parser) =
    # 跳过 var
    parser.skipNextOne()
    # 找到 变量名
    let next = parser.currentToken()
    echo(fmt"{parser.index}, {next}")
    if next.isNone():
        quit("expect a identify, but found end")
    let nextToken = next.get()
    if nextToken.tokenType != token.TokenType.TokenType_Id:
        quit(fmt"expect a identify, but found {nextToken.tokenType}")
    if nextToken.value.str.get().len() == 0:
        quit("identify is invalid")
    let varName = nextToken.value.str.get()
    # 跳过 变量名
    parser.skipNextOne()
    # 查找 类型
