// 文件名: pipeline_exc_stage7.sv
// 功能: 为了整数乘除法运算单独实现的exc流水站 (Execution complex Stage)
// mem: no
// regs: no

module pipeline_exc_stage7(
    input logic clk,                  // 时钟信号
    input logic reset,                // 复位信号，低电平有效
    input logic stall,

    // exc阶段本职工作（乘除法）
    input logic [3:0] alu_ctrl_EXA,
    input logic [63:0] reg_data1_EXA,// 转发到mem阶段
    input logic m_sel_EXA,

    // 下面是转发exa阶段的数据input
    input logic [63:0] pc_EXA,               // mem阶段输入pc
    input logic rf_wr_en_EXA,          // 从ID阶段传递的寄存器写使能信号，需要传递到wb阶段
    input logic [1:0] rf_wr_sel_EXA,        // 从ID阶段传递的寄存器写数据选择信号，需要传递到wb阶段

    input logic [63:0] alu_result_EXA, // ALU执行的结果

    input logic [2:0] dm_rd_ctrl_EXA, // 转发读取控制信号
    input logic [2:0] dm_wr_ctrl_EXA, // 转发写入控制信号
    input logic [63:0] reg_data2_EXA,// 转发到mem阶段
    input logic [4:0] rd_EXA,        // 转发到mem阶段

    // 下面是转发exa阶段的数据output
    output logic [63:0] pc_EXC,               // mem阶段输入pc
    output logic rf_wr_en_EXC,          // 从ID阶段传递的寄存器写使能信号，需要传递到wb阶段
    output logic [1:0] rf_wr_sel_EXC,        // 从ID阶段传递的寄存器写数据选择信号，需要传递到wb阶段

    output logic [63:0] alu_result_EXC, // ALU执行的结果

    output logic [2:0] dm_rd_ctrl_EXC, // 转发读取控制信号
    output logic [2:0] dm_wr_ctrl_EXC, // 转发写入控制信号
    output logic [63:0] reg_data2_EXC,// 转发到mem阶段
    output logic [4:0] rd_EXC        // 转发到mem阶段

);



    // 传递信号到下一周期
    always_ff @(posedge clk or negedge reset) begin
        if (reset) begin
            alu_result_EXC <= 64'b0;
            pc_EXC <= 0;
            dm_rd_ctrl_EXC <= 0;
            dm_wr_ctrl_EXC <= 0;
            reg_data2_EXC <= 0;
            rd_EXC <= 0;
            rf_wr_en_EXC <= 0;
            rf_wr_sel_EXC <= 0;
        end else if(~stall) begin
            // ALU结果在时钟上升沿更新
            alu_result_EXC <= alu_result_EXA;
            pc_EXC <= pc_EXA;
            dm_rd_ctrl_EXC <= dm_rd_ctrl_EXA;
            dm_wr_ctrl_EXC <= dm_wr_ctrl_EXA;
            reg_data2_EXC <= reg_data2_EXA;
            rd_EXC <= rd_EXA;
            rf_wr_en_EXC <= rf_wr_en_EXA;
            rf_wr_sel_EXC <= rf_wr_sel_EXA;
        end
    end

endmodule