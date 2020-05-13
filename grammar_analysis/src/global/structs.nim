import "../structs/struct"
# import sequtils
import hashes

type
  StructKey = object
    # 文件路径
    filePath: string
    # 结构体名称
    name: string

type
  Value = object
    key: StructKey
    value: struct.Struct

proc toString(self: StructKey): string =
  result = self.filePath
  result.add(".")
  result.add(self.name)

# 需要加载的结构 (整个程序需要加载的结构)
var needToUseStructs*: seq[Value] = newSeq[Value]()

proc exists(key: StructKey): tuple[ok: bool, index: int, value: struct.Struct] =
  result = (false, 0, struct.Struct())
  var i = 0
  for item in needToUseStructs:
    if item.key.toString() == key.toString():
      return (true, i, item.value)
    i += 1

proc loadSyspackageStruct*(name: string): tuple[index: int, value: struct.Struct] =
  let key = StructKey(
    filePath: "$system",
    name: name
  )
  let v = key.exists()
  if v.ok:
    return (v.index, v.value)
  else:
    # to do
    # 1. 加载 struct 的成员
    # 2. 加载 struct 的构造函数(等一些默认存在的方法)
    let value = struct.Struct(
    )
    needToUseStructs.add(Value(
      key: key,
      value: value
    ))
    return (needToUseStructs.len(), value)

