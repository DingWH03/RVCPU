// 文件名: pipeline_ex_stage.v
// 功能: 从5级流水线CPU中的执行阶段拆分出的运算单元 (Execution alu Stage)
// mem: no
// regs: no

module pipeline_exa_stage6 (
    input logic clk,                  // 时钟信号
    input logic reset,                // 复位信号，低电平有效
    // input logic flush,           // 在分支模块之后，不需要冲刷
    input logic stall,            // 流水线暂停信号
    input logic [63:0] reg_data1_EXB,  // 从ID阶段传递的源操作数1
    input logic [63:0] reg_data2_EXB,  // 从ID阶段传递的源操作数2
    input logic [63:0] imm_EXB,        // 从ID阶段传递的立即数
    input logic [4:0] rd_EXB,          // 目的寄存器地址
    input logic [63:0] pc_EXB,         // 从ID阶段传递的PC值
    input logic rf_wr_en_EXB,          // 从ID阶段传递的寄存器写使能信号，需要传递到wb阶段
    input logic [1:0] rf_wr_sel_EXB,         // 从ID阶段传递的寄存器写数据选择信号，需要传递到wb阶段

    input logic [3:0] alu_ctrl_EXB,       // 用于选择ALU操作的控制信号(来自ctrl)
    input logic alu_a_sel_EXB, alu_b_sel_EXB, // ALU选择信号（来自ctrl）

    input logic [2:0] dm_rd_ctrl_EXB,  // 接受id阶段数据存储器读取控制信号
    input logic [2:0] dm_wr_ctrl_EXB,  // 接受id阶段数据存储器写入控制信号

    output logic [63:0] pc_EXA,               // mem阶段输入pc
    output logic rf_wr_en_EXA,          // 从ID阶段传递的寄存器写使能信号，需要传递到wb阶段
    output logic [1:0] rf_wr_sel_EXA,        // 从ID阶段传递的寄存器写数据选择信号，需要传递到wb阶段

    output logic [63:0] alu_result_EXA, // ALU执行的结果

    output logic [2:0] dm_rd_ctrl_EXA, // 转发读取控制信号
    output logic [2:0] dm_wr_ctrl_EXA, // 转发写入控制信号
    output logic [63:0] reg_data2_EXA,// 转发到mem阶段
    output logic [4:0] rd_EXA        // 转发到mem阶段
);

    logic [63:0] alu_input1; // ALU的第一个输入，可能是寄存器值或立即数
    logic [63:0] alu_input2;  // ALU的第二个输入，可能是寄存器值或立即数

    logic [63:0] alu_result;

    // ALU输入选择 (组合逻辑)
    always_comb @(*) begin
        alu_input1 = alu_a_sel_EXB ? reg_data1_EXB : pc_EXB;
        alu_input2 = alu_b_sel_EXB ? imm_EXB : reg_data2_EXB;  // 对于I型指令，第二个操作数是立即数
    end

    // 实例化 ALU 模块
    ALU alu0(
        .SrcA(alu_input1),
        .SrcB(alu_input2),
        .func(alu_ctrl_EXB),
        .ALUout(alu_result)
    );

    // ALU计算结果的时序逻辑 和其他信号
    always_ff @(posedge clk or negedge reset) begin
        if (reset) begin
            alu_result_EXA <= 64'b0;
            pc_EXA <= 0;
            dm_rd_ctrl_EXA <= 0;
            dm_wr_ctrl_EXA <= 0;
            reg_data2_EXA <= 0;
            rd_EXA <= 0;
            rf_wr_en_EXA <= 0;
            rf_wr_sel_EXA <= 0;
        end else if(~stall) begin
            // ALU结果在时钟上升沿更新
            alu_result_EXA <= alu_result;
            pc_EXA <= pc_EXB;
            dm_rd_ctrl_EXA <= dm_rd_ctrl_EXB;
            dm_wr_ctrl_EXA <= dm_wr_ctrl_EXB;
            reg_data2_EXA <= reg_data2_EXB;
            rd_EXA <= rd_EXB;
            rf_wr_en_EXA <= rf_wr_en_EXB;
            rf_wr_sel_EXA <= rf_wr_sel_EXB;
        end
    end

endmodule
