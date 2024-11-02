// 文件名: pipeline_ex_stage.v
// 功能: 5级流水线CPU中的执行阶段 (Execution Stage)
// mem: no
// regs: no

module pipeline_ex_stage (
    input wire clk,                  // 时钟信号
    input wire reset,                // 复位信号，低电平有效
    input wire stall,            // 流水线暂停信号
    input wire [63:0] reg_data1_EX,  // 从ID阶段传递的源操作数1
    input wire [63:0] reg_data2_EX,  // 从ID阶段传递的源操作数2
    input wire [63:0] imm_EX,        // 从ID阶段传递的立即数
    input wire [4:0] rd_EX,          // 目的寄存器地址
    input wire [63:0] pc_EX,         // 从ID阶段传递的PC值
    input wire rf_wr_en_ID,          // 从ID阶段传递的寄存器写使能信号，需要传递到wb阶段
    input wire [1:0] rf_wr_sel_ID,         // 从ID阶段传递的寄存器写数据选择信号，需要传递到wb阶段

    input wire [3:0] alu_ctrl,       // 用于选择ALU操作的控制信号(来自ctrl)
    input wire alu_a_sel, alu_b_sel, // ALU选择信号（来自ctrl）

    input wire [2:0] dm_rd_ctrl_ID,  // 接受id阶段数据存储器读取控制信号
    input wire [2:0] dm_wr_ctrl_ID,  // 接受id阶段数据存储器写入控制信号

    input wire do_jump,              // id阶段传来的jump信号
    input wire is_branch,            // id阶段传来的branch信号
    input wire [2:0] BrType,         // id阶段传来的Brtype信号

    output reg [63:0] pc_MEM,               // mem阶段输入pc
    output reg rf_wr_en_EX,          // 从ID阶段传递的寄存器写使能信号，需要传递到wb阶段
    output reg [1:0] rf_wr_sel_EX,        // 从ID阶段传递的寄存器写数据选择信号，需要传递到wb阶段

    output reg [63:0] alu_result_EX, // ALU执行的结果
    output reg branch_taken_EX,      // 分支跳转信号
    output reg [63:0] branch_target_EX, // 分支跳转目标地址
    output reg [2:0] dm_rd_ctrl_EX, // 转发读取控制信号
    output reg [2:0] dm_wr_ctrl_EX, // 转发写入控制信号
    output reg [63:0] reg_data2_MEM,// 转发到mem阶段
    output reg [4:0] rd_MEM        // 转发到mem阶段
);

    // reg [3:0] alu_ctrl;  // 用于选择ALU操作的控制信号
    reg [63:0] alu_input1; // ALU的第一个输入，可能是寄存器值或立即数
    reg [63:0] alu_input2;  // ALU的第二个输入，可能是寄存器值或立即数

    wire BrE;  // 从 branch 模块输出的跳转条件
    wire JUMP; // 跳转信号
    assign		JUMP = BrE || do_jump;

    wire [63:0] alu_result;

    // ALU输入选择 (组合逻辑)
    always @(*) begin
        alu_input1 = alu_a_sel ? reg_data1_EX : pc_EX;
        alu_input2 = alu_b_sel ? imm_EX : reg_data2_EX;  // 对于I型指令，第二个操作数是立即数
    end

    // 实例化 branch 模块
    branch branch_unit (
        .REG1(reg_data1_EX),
        .REG2(reg_data2_EX),
        .Type(BrType),
        .BrE(BrE)
    );

    // 分支跳转逻辑 (组合逻辑?)
    always @(posedge clk or negedge reset) begin
        if (reset) begin
            branch_taken_EX <= 1'b0;
            branch_target_EX <= 64'b0;
        end else if (~stall) begin
            branch_taken_EX <= 1'b0;  // 默认不跳转
            branch_target_EX <= 64'b0;

            if (is_branch) begin  // 如果是分支指令
                branch_taken_EX <= JUMP;  // 通过 branch 模块判断是否跳转
                if (JUMP) begin
                    branch_target_EX <= pc_EX + imm_EX;  // 跳转目标地址
                end
            end
        end
    end

    // 实例化 ALU 模块
    ALU alu0(
        .SrcA(alu_input1),
        .SrcB(alu_input2),
        .func(alu_ctrl),
        .ALUout(alu_result)
    );

    // ALU计算结果的时序逻辑 和其他信号
    always @(posedge clk or negedge reset) begin
        if (reset) begin
            alu_result_EX <= 64'b0;
            pc_MEM <= 0;
            dm_rd_ctrl_EX <= 0;
            dm_wr_ctrl_EX <= 0;
            reg_data2_MEM <= 0;
            rd_MEM <= 0;
            rf_wr_en_EX <= 0;
            rf_wr_sel_EX <= 0;
        end else if(~stall) begin
            // ALU结果在时钟上升沿更新
            alu_result_EX <= alu_result;
            pc_MEM <= pc_EX;
            dm_rd_ctrl_EX <= dm_rd_ctrl_ID;
            dm_wr_ctrl_EX <= dm_wr_ctrl_ID;
            reg_data2_MEM <= reg_data2_EX;
            rd_MEM <= rd_EX;
            rf_wr_en_EX <= rf_wr_en_ID;
            rf_wr_sel_EX <= rf_wr_sel_ID;
        end
    end

endmodule
