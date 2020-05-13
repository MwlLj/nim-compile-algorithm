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
  result.add("-")
  result.add(self.name)

# 需要加载的结构 (整个程序需要加载的结构)
var needToUseStructs*: seq[Value] = newSeq[Value]()

proc exists(key: StructKey): tuple[ok: bool, index: int] =
  result = (false, 0)
  var i = 0
  for item in needToUseStructs:
    if item.key.toString() == key.toString():
      return (true, i)
    i += 1

proc loadSyspackageStruct*(name: string): int =
  let key = StructKey(
    filePath: "$system",
    name: name
  )
  let v = key.exists()
  if v.ok:
    return v.index
  else:
    needToUseStructs.add(Value(
      key: key,
      # to do
      value: struct.Struct(
      )
    ))
    return needToUseStructs.len()

