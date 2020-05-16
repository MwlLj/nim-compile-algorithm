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
  LocalBlock* = ref object
    # 这里的变量不会被写入字节码中, 是在编译期间使用的, 所以不需要 seq 结构, 使用 table 结构更加的高效
    vars*: Table[string, Var]

type
  Scope* = object
      # 当前包
      curPackage*: Package
      # 根 block (package / function)
      # 实际存储变量的地方
      rootBlock*: Block
      # 当前块
      curBlock*: LocalBlock
      # 父级块
      parentBlock*: Option[LocalBlock]
      # 用于切换时临时存储 parentBlock
      tmpParentBlock: Option[LocalBlock]

proc newLocalBlock*(): LocalBlock

# --- scope ---
# block切换
proc blockSwitch*(self: var Scope) =
  # 将 parentBlock 保存 (还原时需要使用)
  self.tmpParentBlock = self.parentBlock
  # 将 curBlock 作为新block的 parentBlock
  self.parentBlock = some(self.curBlock)
  # 创建新的 block
  self.curBlock = newLocalBlock()

# block还原
proc blockReduction*(self: var Scope) =
  # 将父block给curBlock
  self.curBlock = self.parentBlock.get()
  # 将进入新作用域前保存的 parent 还原
  self.parentBlock = self.tmpParentBlock

# --- local block ---
# 判断给定的变量在block中是否存在
proc exists*(self: LocalBlock, name: string): bool =
  result = self.vars.hasKey(name)

proc newLocalBlock*(): LocalBlock =
  result = LocalBlock(
    vars: initTable[string, Var]()
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

