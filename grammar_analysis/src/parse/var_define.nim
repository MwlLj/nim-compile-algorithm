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
    1. 每一个 block作用域(不包括package级别的作用域) 都有一个数组, 用于存储包中所有全局变量
    2. 虚拟机读取到加载 block 指令后, 将创建一个指定大小的数组
    3. 对变量进行的操作, 在编译期间都会被翻译为 该数组的 index
        目的: 如果不抽象为一个数组, 虚拟机必须要知道每一个变量的作用域, 会降低虚拟机的性能 (虚拟机就应该傻傻的叫它干什么就干什么, 它不应该有自己的想法)

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
import "../structs/struct"
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
    if sc.curBlock.exists(varName):
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
                #[
                # loadSyspackageStruct: 如果存在就返回索引; 如果不存在就添加到内存中, 然后返回索引
                ]#
                let v = structs.loadSyspackageStruct(id)
                let index = v.index
                let structObj = v.value
                # 生成指令:
                # 调用index 处类型的结构体的构造方法 (虚拟机调用后创建一个实例对象, push到计算栈中)
                let constructionMethodIndex = structObj.findNoparamConstruction()
                if constructionMethodIndex.isNone():
                  quit(fmt"{id}() not exists in struct {id}")
                parser.opts.add(opparse.Opt(
                  instruction: optcode.Instruction.Instruction_Call_Struct_Method,
                  values: @[opparse.OptValue(
                    integer: some(int64(index))
                  ),
                  opparse.OptValue(
                    integer: some(int64(constructionMethodIndex.get()))
                  )]
                ))
            else:
                # 非系统类型
                # 这里暂时不考虑多值(包名.结构名)的情况, 认为只有一个文件
                # 所以这里在本包中查找
                # 1. 如果从 curPackage 中找到 对应的结构体(在使用前就定义了), 则返回索引值
                # 2. 如果不存在于 curPackage, 添加占位符, 并记录到未定义队列中, 待当前包解析完成之后, 再填充 (解析完成之后, 如果还是没有找到, 就报错)
                let r = sc.curPackage.findStruct(id)
                if r.isSome():
                  # 在curPackage中找到了结构体 => 写入
                  let structIndex = r.get()
                  # to do ... (在解析package后需要改动)
                else:
                  # 没有在curPackage中找到结构体
                  discard
        else:
            quit(fmt"expect a type, but found {typToken.tokenType}")
    of token.TokenType.TokenType_Symbol_Assignment:
        # var xxx string =
        # 先计算类型 (不用生成指令)
        # 两个目的:
        # 1. 判断右边的表达式的计算结果和左边的是否相同
        # 2. 如果是非内置类型, 并且没有加载到内存, 可以顺便加载到内存中
        case typToken.tokenType
        of token.TokenType.TokenType_KW_String:
          discard
        of token.TokenType.TokenType_KW_Int32:
          discard
        of token.TokenType.TokenType_Id:
            if typToken.value.str.get().len() == 0:
                quit("type is invalid")
            # 判断在不在 sys package 中
            let id = typToken.value.str.get()
            if syspackage.sysPackageStructs.hasKey(id):
                let v = structs.loadSyspackageStruct(id)
                let index = v.index
                let structObj = v.value
            else:
                # 非系统类型
                discard
        else:
            quit(fmt"expect a type, but found {typToken.tokenType}")
        # 跳过 = 号
        parser.skipNextOne()
        # 查找 = 号后面的 表达式
        var expressParser = opparse.new(parser.tokens[parser.index..parser.length-1], sc)
        expressParser.parse()
        let opts = expressParser.getOpts()
        parser.opts.add(opts)
        parser.skipNextN(expressParser.getUsedTokenTotal())
    else:
        quit(fmt"expect linebreak or ; or =, but found {afterTypeToken.tokenType}")
    # 将变量写入package域中的vars中
    let index = sc.rootBlock.pushVar()
    # 生成变量定义指令
    parser.opts.add(opparse.Opt(
      instruction: optcode.Instruction.Instruction_Current_Scope_Var_Define,
      values: @[opparse.OptValue(
        integer: some(int64(index))
      )]
    ))

