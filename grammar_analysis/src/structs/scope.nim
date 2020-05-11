import tables
import options

# 作用域结构体
type
    Struct* = object
        # 结构体名称
        name*: string

type
    Package* = object
        # 包名称
        name*: string
        structs*: Table[string, Struct]

type
    VarValue = object
        str*: Option[string]

type
    Var = object
        name*: string
        value*: VarValue

type
    Block* = object
        vars*: Table[string, Var]

type
    Scope* = object
        # 当前包
        curPackage*: Package
        # 当前块
        curBlock*: Block

proc newVar*(): Var =
    result = Var(
    )

proc newBlock*(): Block =
    result = Block(
        vars: initTable[string, Var]()
    )

proc newPackage*(name: string): Package =
    result = Package(
        name: name,
        structs: initTable[string, Struct]()
    )

proc newScope*(curPackageName: string): Scope =
    result = Scope(
        curPackage: newPackage(curPackageName),
        curBlock: newBlock()
    )

