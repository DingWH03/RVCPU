// 文件名: pipeline_ex_stage.v
// 功能: 从5级流水线CPU中的执行阶段拆分出的分支跳转判断单元 (Execution branch Stage)
// mem: no
// regs: no

module pipeline_exb_stage (
    input logic clk,                  // 时钟信号
    input logic reset,                // 复位信号，低电平有效
    input logic flush,
    input logic stall,            // 流水线暂停信号

    //--------------------------需要传递的信号-------------------------------------
    input logic [63:0] pc_IDR,         // 从IDR阶段传递的PC值
    input logic [63:0] reg_data1_IDR,  // 从IDR阶段传递的源操作数1
    input logic [63:0] reg_data2_IDR,  // 从IDR阶段传递的源操作数2
    input logic [63:0] imm_IDR,        // 从IDR阶段传递的立即数
    input logic [4:0] rd_IDR,          // 目的寄存器地址
    input logic rf_wr_en_IDR,          // 从IDR阶段传递的寄存器写使能信号，需要传递到wb阶段
    input logic [1:0] rf_wr_sel_IDR,         // 从IDR阶段传递的寄存器写数据选择信号，需要传递到wb阶段

    input logic [3:0] alu_ctrl_IDR,       // 用于选择ALU操作的控制信号(来自ctrl)
    input logic alu_a_sel_IDR, alu_b_sel_IDR, // ALU选择信号（来自ctrl）

    input logic [2:0] dm_rd_ctrl_IDR,  // 接受idr阶段数据存储器读取控制信号
    input logic [2:0] dm_wr_ctrl_IDR,  // 接受idr阶段数据存储器写入控制信号
    //------------------------------------------------------------------------

    //-------------------------------处理分支跳转输入信号---------------------------
    input logic do_jump_IDR,              // idr阶段传来的jump信号
    input logic is_branch_IDR,            // idr阶段传来的branch信号
    input logic [2:0] BrType_IDR,         // idr阶段传来的Brtype信号
    //----------------------------------------------------------------------------

    //---------------------exb阶段本职工作，处理分支跳转，且无需等到下周期时钟上升沿到来----------------
    output logic branch_taken_EXB,      // 分支跳转信号
    output logic [63:0] branch_target_EXB, // 分支跳转目标地址
    //--------------------------------------------------------------------------------------

    //--------------------------------传出的信号-------------------------------------------
    output logic [63:0] pc_EXB,               // exa阶段输入pc
    output logic [63:0] reg_data1_EXB,// 转发到exa阶段
    output logic [63:0] reg_data2_EXB,// 转发到exa阶段
    output logic [63:0] imm_EXB,        // 转发给alu的立即数
    output logic rf_wr_en_EXB,          // 从ID阶段传递的寄存器写使能信号，需要传递到wb阶段
    output logic [1:0] rf_wr_sel_EXB,        // 从ID阶段传递的寄存器写数据选择信号，需要传递到wb阶段
    output logic [3:0] alu_ctrl_EXB,        // alu控制信号，转发到exa阶段
    output logic alu_a_sel_EXB, alu_b_sel_EXB, // ALU选择信号，转发到exa阶段

    output logic [2:0] dm_rd_ctrl_EXB, // 转发读取控制信号
    output logic [2:0] dm_wr_ctrl_EXB, // 转发写入控制信号
    output logic [4:0] rd_EXB        // 转发到exa阶段
);

    logic BrE;  // 从 branch 模块输出的跳转条件

    always_comb @(*) begin
        branch_taken_EXB = (BrE & is_branch_IDR) | do_jump_IDR;
        branch_target_EXB = pc_IDR + imm_IDR;
    end

    // 实例化 branch 模块
    branch branch_unit (
        .REG1(reg_data1_IDR),
        .REG2(reg_data2_IDR),
        .Type(BrType_IDR),
        .BrE(BrE)
    );

    // ALU计算结果的时序逻辑 和其他信号
    always_ff @(posedge clk or negedge reset) begin
        if (reset||flush) begin
            pc_EXB <= 0;
            dm_rd_ctrl_EXB <= 0;
            dm_wr_ctrl_EXB <= 0;
            reg_data1_EXB <= 0;
            reg_data2_EXB <= 0;
            imm_EXB <= 0;
            rd_EXB <= 0;
            rf_wr_en_EXB <= 0;
            rf_wr_sel_EXB <= 0;
            alu_ctrl_EXB <= 0;
            alu_a_sel_EXB <= 0;
            alu_b_sel_EXB <= 0;
        end else if(~stall) begin
            // 转发到exa在时钟上升沿更新
            pc_EXB <= pc_IDR;
            dm_rd_ctrl_EXB <= dm_rd_ctrl_IDR;
            dm_wr_ctrl_EXB <= dm_wr_ctrl_IDR;
            reg_data1_EXB <= reg_data1_IDR;
            reg_data2_EXB <= reg_data2_IDR;
            imm_EXB <= imm_IDR;
            rd_EXB <= rd_IDR;
            rf_wr_en_EXB <= rf_wr_en_IDR;
            rf_wr_sel_EXB <= rf_wr_sel_IDR;
            alu_ctrl_EXB <= alu_ctrl_IDR;
            alu_a_sel_EXB <= alu_a_sel_IDR;
            alu_b_sel_EXB <= alu_b_sel_IDR;
        end
    end

endmodule
