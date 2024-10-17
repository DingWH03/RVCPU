// 文件名: pipeline_ex_stage.v
// 功能: 5级流水线CPU中的执行阶段 (Execution Stage)
// mem: no
// regs: no

module pipeline_ex_stage (
    input wire clk,                  // 时钟信号
    input wire reset,                // 复位信号，低电平有效
    input wire [63:0] reg_data1_EX,  // 从ID阶段传递的源操作数1
    input wire [63:0] reg_data2_EX,  // 从ID阶段传递的源操作数2
    input wire [63:0] imm_EX,        // 从ID阶段传递的立即数
    input wire [4:0] rs1_EX,         // 源寄存器1地址
    input wire [4:0] rs2_EX,         // 源寄存器2地址
    input wire [4:0] rd_EX,          // 目的寄存器地址
    input wire [6:0] opcode_EX,      // 操作码
    input wire [2:0] funct3_EX,      // 功能码 funct3
    input wire [6:0] funct7_EX,      // 功能码 funct7
    input wire [63:0] pc_EX,         // 从ID阶段传递的PC值

    output reg [63:0] alu_result_EX, // ALU执行的结果
    output reg branch_taken_EX,      // 分支跳转信号
    output reg [63:0] branch_target_EX // 分支跳转目标地址
);

    reg [3:0] alu_ctrl;  // 用于选择ALU操作的控制信号
    reg [63:0] alu_input2;  // ALU的第二个输入，可能是寄存器值或立即数

    wire BrE;  // 从 branch 模块输出的跳转条件

    // ALU输入选择 (根据opcode判断是否使用立即数)
    always @(*) begin
        alu_input2 = (opcode_EX == 7'b0010011) ? imm_EX : reg_data2_EX;  // 对于I型指令，第二个操作数是立即数
    end

    // 实例化 branch 模块
    branch branch_unit (
        .REG1(reg_data1_EX),
        .REG2(reg_data2_EX),
        .Type(funct3_EX),
        .BrE(BrE)
    );

    // 分支跳转逻辑 (用 branch 模块替代)
    always @(*) begin
        branch_taken_EX = 1'b0;  // 默认不跳转
        branch_target_EX = 64'b0;

        if (opcode_EX == 7'b1100011) begin  // 如果是分支指令
            branch_taken_EX = BrE;  // 通过 branch 模块判断是否跳转
            if (BrE) begin
                branch_target_EX = pc_EX + imm_EX;  // 跳转目标地址
            end
        end
    end

    // 实例化 ALU 模块
    ALU alu0(
        .SrcA(reg_data1_EX),
        .SrcB(alu_input2),
        .func(alu_ctrl),
        .ALUout(alu_result_EX)
    );

endmodule
