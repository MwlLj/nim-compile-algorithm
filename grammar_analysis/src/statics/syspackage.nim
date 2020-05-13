import "../structs/struct"
import tables

# 存储系统定义的方法 (正式编码时, 需要从system编译后的文件中加载到内存中)
var sysPackageStructs*: Table[string, Struct] = initTable[string, Struct]()

