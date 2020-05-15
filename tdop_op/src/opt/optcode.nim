type
    Instruction* = enum
        Instruction_If_Stmt,
        Instruction_If_Else_Stmt,
        Instruction_Express_Stmt,
        Instruction_Load_iConst,
        Instruction_Plus,
        Instruction_Multiplication,
        Instruction_Prefix_Minus,
        Instruction_Opt_Or,
        Instruction_Opt_Or_Calc,
        Instruction_Opt_And,
        Instruction_Opt_And_Calc,
        Instruction_Assignment,
        # 普通作用域的变量定义
        Instruction_Normal_Scope_Var_Define,
        # 包作用域的变量定义
        Instruction_Package_Scope_Var_Define,
        # 调用 string 的 new 方法
        Instruction_Call_String_New_Method,
        # 调用 int32 的 new 方法
        Instruction_Call_Int32_New_Method,
        # 调用 int64 的 new 方法
        Instruction_Call_Int64_New_Method,
        # 结构体方法调用
        # 第一个参数: 类定义的索引
        # 第二个参数: 类中方法定义的索引
        Instruction_Call_Struct_Method,
        # 条件表达式开始
        Instruction_Condition_Expr_Start,
        # 条件表达式结束
        # 第一个参数: 条件成立后的跳转位置
        # 第二个参数: 条件不成立后的跳转位置
        Instruction_Condition_Expr_End
        # 条件语句块结束后的跳转
        # 参数: 位置
        Instruction_Condition_Block_End

