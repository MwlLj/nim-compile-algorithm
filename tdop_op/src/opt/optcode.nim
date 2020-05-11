type
    Instruction* = enum
        Instruction_If_Stmt,
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
        Instruction_Var_Define,
        # 调用 string 的 new 方法
        Instruction_Call_String_New_Method,
        # 调用 int32 的 new 方法
        Instruction_Call_Int32_New_Method,
        # 调用 int64 的 new 方法
        Instruction_Call_Int64_New_Method

