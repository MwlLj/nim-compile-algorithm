import "struct"
import options

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
    # 存储 包级别的变量
    vars*: seq[Var]

type
  Block* = object
    # 是否是 package 级别的 块
    isPackage*: bool
    vars*: seq[Var]

type
    Scope* = object
        # 当前包
        curPackage*: Package
        # 当前块
        curBlock*: Block

proc newVar*(): Var =
    result = Var(
    )

# --- block ---
# name是否存在于 vars 数组中
proc isPackageScope(self: Block): bool =
  result = self.isPackage

proc exists*(self: Block, name: string): bool =
  result = false
  for item in self.vars:
    if item.name == name:
      return true

proc addVar*(self: var Block, v: Var): int =
  self.vars.add(v)
  result = self.vars.len()

proc newBlock*(isPackageScope: bool): Block =
    result = Block(
      isPackage: isPackageScope,
      vars: @[]
    )

# --- package ---
# name是否存在于 package 中的 vars 数组中
proc exists*(self: Package, name: string): bool =
  result = false
  for item in self.vars:
    if item.name == name:
      return true

proc addVar*(self: var Package, v: Var): int =
  self.vars.add(v)
  result = self.vars.len()

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
        vars: newSeq[Var]()
    )

proc newScope*(curPackageName: string, isPackageScope: bool): Scope =
    result = Scope(
        curPackage: newPackage(curPackageName),
        curBlock: newBlock(isPackageScope)
    )

