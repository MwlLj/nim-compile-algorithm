import tables

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
    Block* = object

type
    Scope* = object
        # 当前包
        curPackage*: Package
        # 当前块
        curBlock*: Block
