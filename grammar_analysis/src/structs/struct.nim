import options

type
  Function* = object
    name*: string

type
    Struct* = object
        # 结构体名称
        name*: string
        # 构造方法
        constructionMethod: seq[Function]
        methods: seq[Function]

# 查找无参数构造函数 (函数名 == 结构体名)
proc findNoparamConstruction*(self: Struct): Option[int] =
  result = none(int)
  for index, item in self.constructionMethod.pairs:
    if item.name == self.name:
      # 与struct同名的构造函数 (且无参数, 如果有参数 name == name_param1type_param2type...)
      return some(index)

