import "struct"
import options
import tables

type
  VarValue* = object
    str*: Option[string]

type
  Var* = object
    name*: string
    value*: VarValue

type
  Package* = object
    # 包名称
    name*: string
    structs*: seq[struct.Struct]

type
  BlockType* = enum
    BlockType_Package
    BlockType_Function

type
  Block* = object
    # 是否是 package 级别的 块
    blockType*: BlockType
    # 这里不需要存储实际的 变量信息, 只需要一个索引, 因为这里记录的是变量将写入字节码中的位置
    varIndex: int

# 用于 非 Block 的 块 (if 语句的块, for / while 语句的 块, 大括号定义的块)
type
  LocalBlock* = object
    # 这里的变量不会被写入字节码中, 是在编译期间使用的, 所以不需要 seq 结构, 使用 table 结构更加的高效
    vars*: Table[string, Var]

type
  Scope* = object
      # 当前包
      curPackage*: Package
      # 根 block (package / function)
      # 实际存储变量的地方
      rootBlock*: Block
      # 在 rootBlock 创建的同时, 会创建一个存储所有变量的容器
      # key: 作用域所在位置的索引
      # value: 当前作用域下面的变量集合
      localBlocks: Table[int, LocalBlock]
      # 当前块索引
      curBlockIndex: int

# --- local block ---
# 判断给定的变量在block中是否存在
proc newLocalBlock*(): LocalBlock =
  result = LocalBlock(
    vars: initTable[string, Var]()
  )

# --- scope ---
# 进入block
proc enterBlock*(self: var Scope) =
  # 创建新的作用域
  self.curBlockIndex += 1
  self.localBlocks.add(self.curBlockIndex, newLocalBlock())

# 离开block
proc leaveBlock*(self: var Scope) =
  self.curBlockIndex -= 1
  self.localBlocks.del(self.curBlockIndex)

proc isInCurBlock*(self: Scope, name: string): bool =
  let localBlock = self.localBlocks[self.curBlockIndex]
  result = localBlock.vars.hasKey(name)

# 只有 包 可以创建 Scope
proc newScope*(curPackage: Package, rootBlock: Block): Scope =
  let curBlockIndex = 0
  var localBlocks = initTable[int, LocalBlock]()
  localBlocks.add(curBlockIndex, newLocalBlock())
  result = Scope(
    curPackage: curPackage,
    rootBlock: rootBlock,
    localBlocks: localBlocks,
    curBlockIndex: curBlockIndex
  )

# --- block ---
proc pushVar*(self: var Block): int =
  result = self.varIndex
  self.varIndex += 1

proc newBlock*(blockType: BlockType): Block =
  result = Block(
    blockType: blockType,
    varIndex: 0
  )

# --- package ---
# 查找包中的结构体
proc findStruct*(self: Package, name: string): Option[int] =
  result = none(int)
  for index, item in self.structs.pairs:
    if item.name == name:
      return some(index)

proc newPackage*(name: string): Package =
    result = Package(
        name: name,
        structs: newSeq[Struct](),
    )

