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

存储结构:
    1. 每一个 package 都有一个 大的数组, 用于存储包中所有变量的地址
    2. 虚拟机启动时, 加载 用到的 所有 package, 并分配数组空间
    3. 对变量进行的操作, 在编译期间都会被翻译为 该数组的 index
        目的: 如果不抽象为一个大的数组, 虚拟机必须要知道每一个变量的作用域, 会降低虚拟机的性能 (虚拟机就应该傻傻的叫它干什么就干什么, 它不应该有想法)

类型推断:
    关键字类型(int, uint32, int32, string ...):
        遇到等号后, 调用相关关键字类型的对应方法 (类似的指令: call_string_method 方法名)
    非关键字类型:
        单值:
            从内置类型(系统类型)中匹配
                是内置类型(system包中的类型, 不需要显示import):
                    查找编译过程中记录的类型加载情况(查看该类型是否已经加载过了), 如果加载过了, 取出类型定义所在的索引(类型定义会记录在一个数组中); 如果没有加载过, 从 system 包中找到类型的所有信息(成员变量与成员方法), 然后追加在 类型定义的数组中(将来会序列化在编译文件的头部信息位置) 并 记录索引值; 在遇到 = 后, 调用类型的相关方法(进行初始化操作) (类似的指令: call_method (index) 方法名)
                非内置类型:
                    从当前package中查找
                        在当前package中
                            与内置类型基本一致, 不同的是:
                                如果没有加载过, 不是从 system 中查找类型的定义, 而是从当前package中查找struct的定义, 然后追加到类型定义的数组中, 并记录索引; 遇到 = 后, 调用相关方法生成指令
                        不在当前package中(可能定义在后面, 需要留空, 待当前包解析完毕)
        复合值:
            与内置类型基本一致, 不同的是: 需要从 复合值所在包中查找struct的定义
]#

import "parse"
import "ihandle"
import "../structs/scope"
import "../statics/syspackage"
import "../global/structs"
import "../../../tdop_op/src/expression/parse_use_instruction" as opparse
import "../../../tdop_op/src/opt/optcode"
import "../../../lexical_analysis/src/token/token"
import strformat
import "options"
import tables

proc handleVarDefine*(self: ihandle.IHandle, parser: var parse.Parser, sc: var scope.Scope) =
    # 跳过 var
    parser.skipNextOne()
    # 找到 变量名
    var next = parser.currentToken()
    if next.isNone():
        quit("expect a identify, but found end")
    let nextToken = next.get()
    if nextToken.tokenType != token.TokenType.TokenType_Id:
        quit(fmt"expect a identify, but found {nextToken.tokenType}")
    if nextToken.value.str.get().len() == 0:
        quit("identify is invalid")
    let varName = nextToken.value.str.get()
    # 判断变量名在当前的block中是否存在
    if sc.curBlock.vars.hasKey(varName):
        # 变量在当前的block中存在 => 报错
        quit("var already define")
    # 跳过 变量名
    parser.skipNextOne()
    # 查找 类型
    next = parser.currentToken()
    if next.isNone():
        quit("expect a type, but found end")
    let typToken = next.get()
    # 跳过 类型token
    parser.skipNextOne()
    # 查找类型后面的 token
    next = parser.currentTokenUnfilterWhite()
    if next.isNone():
        # var xxx string 结束
        # 这种情况应该不需要处理, 因为即使这里分配了空间, 但是后续不会使用了
        return
    let afterTypeToken = next.get()
    case afterTypeToken.tokenType
    of token.TokenType.TokenType_Back_Slash_R, token.TokenType.TokenType_Back_Slash_N, token.TokenType.TokenType_Semicolon, token.TokenType.TokenType_Line_Break:
        # var xxx string
        # 跳过 \r / \n / ;
        parser.skipNextOne()
        # 创建指令
        case typToken.tokenType
        of token.TokenType.TokenType_KW_String:
            parser.opts.add(opparse.Opt(
                instruction: optcode.Instruction.Instruction_Call_String_New_Method
            ))
        of token.TokenType.TokenType_KW_Int32:
            parser.opts.add(opparse.Opt(
                instruction: optcode.Instruction.Instruction_Call_Int32_New_Method
            ))
        of token.TokenType.TokenType_Id:
            if typToken.value.str.get().len() == 0:
                quit("type is invalid")
            # 判断在不在 sys package 中
            let id = typToken.value.str.get()
            if syspackage.sysPackageStructs.hasKey(id):
                # 系统类型
                # 查找是否已经加载过
                #[
                if structs.needToUseStructs.hasKey(structs.newSyspackageStructKey(id)):
                    # 加载过了
                    discard
                else:
                    # 没有加载 => 编译 / 加载 (如果存在编译后文件就直接加载, 否则需要编译, 然后写入内存)
                    discard
                ]#
                discard structs.loadSyspackageStruct(id)
            else:
                # 非系统类型
                discard
        else:
            quit(fmt"expect a type, but found {typToken.tokenType}")
    of token.TokenType.TokenType_Symbol_Assignment:
        # var xxx string =
        # 跳过 = 号
        parser.skipNextOne()
        # 查找 = 号后面的 表达式
        var expressParser = opparse.new(parser.tokens[parser.index..parser.length-1])
        expressParser.parse()
        let opts = expressParser.getOpts()
        parser.opts.add(opts)
        parser.skipNextN(expressParser.getUsedTokenTotal())
    else:
        quit(fmt"expect linebreak or ; or =, but found {afterTypeToken.tokenType}")
    # 生成变量定义指令
    parser.opts.add(opparse.Opt(
        instruction: optcode.Instruction.Instruction_Var_Define,
        values: @[opparse.OptValue(
            variable: some(varName)
        )]
    ))

