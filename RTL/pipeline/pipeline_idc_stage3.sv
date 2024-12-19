// 文件名: pipeline_idc_stage.sv
// 功能: 从5级流水线CPU中的指令解码阶段分割出来的专用于指令解码控制模块 (Instruction Decode control Stage)
// mem: no
// regs: no

module pipeline_idc_stage3 (
    input logic clk,                   // 时钟信号
    input logic reset,                 // 复位信号，低电平有效
    input logic stall,            // 流水线暂停信号
    input logic flush,               // 流水线冲刷信号
    input logic [31:0] instruction_IF, // 从IF阶段传来的指令
    input logic [63:0] pc_IFR,          // 从IF阶段传来的PC值
    
    output logic [4:0] rd_ID,          // 目的寄存器地址
    output logic [63:0] imm_ID,        // 解码出的立即数

    output logic [63:0] pc_IDC,               // 输出到下一阶段的PC

    // 控制信号
    output logic rf_wr_en,             // 寄存器写使能信号
    output logic do_jump,              // 跳转控制信号
    output logic is_branch,            // 是否b_type
    output logic is_debug,
    output logic alu_a_sel,            // ALU 输入A选择信号
    output logic alu_b_sel,            // ALU 输入B选择信号
    output logic [3:0] alu_ctrl,       // ALU 控制信号
    output logic [2:0] BrType,         // 分支类型控制信号
    output logic [1:0] rf_wr_sel,      // 寄存器写回数据来源选择
    output logic is_rs1_used,
    output logic is_rs2_used,
    output logic m_sel,                // 是否乘除法alu选择信号

    // 与内存模块连接的控制信号 (需要越过ex传递到mem阶段)
    output logic [2:0] dm_rd_ctrl,     // 数据存储器读取控制信号
    output logic [2:0] dm_wr_ctrl,     // 数据存储器写入控制信号

    output logic [4:0] rs1_IDC, rs2_IDC // 需要读取寄存器堆数据的地址(同时连接到寄存器堆(直接读取)和数据前推模块)
);

    // 实例化立即数解码模块
    logic [63:0] imm_ictrl;
    imm imm0 (
        .inst(instruction_IF),
        .out(imm_ictrl)
    );

    // 实例化ictrl控制单元模块
    logic rf_wr_en_ictrl, do_jump_ictrl, is_branch_ictrl, alu_a_sel_ictrl, alu_b_sel_ictrl;
    logic [3:0] alu_ctrl_ictrl;
    logic [2:0] BrType_ictrl, dm_rd_ctrl_ictrl;
    logic [1:0] rf_wr_sel_ictrl;
    logic [2:0] dm_wr_ctrl_ictrl;

    ctrl ctrli (
        .inst(instruction_IF),
        .rf_wr_en(rf_wr_en_ictrl),
        .rf_wr_sel(rf_wr_sel_ictrl),
        .do_jump(do_jump_ictrl),
        .is_branch(is_branch_ictrl),
        .BrType(BrType_ictrl),
        .alu_a_sel(alu_a_sel_ictrl),
        .alu_b_sel(alu_b_sel_ictrl),
        .alu_ctrl(alu_ctrl_ictrl),
        .dm_rd_ctrl(dm_rd_ctrl_ictrl),
        .dm_wr_ctrl(dm_wr_ctrl_ictrl),
        .is_debug(is_debug),
        .is_rs1_used(is_rs1_used),
        .is_rs2_used(is_rs2_used)
    );

    // 实例化ictrl控制单元模块
    logic rf_wr_en_mctrl;
    logic [1:0] rf_wr_sel_mctrl;
    logic alu_a_sel_mctrl, alu_b_sel_mctrl;
    logic [3:0] alu_ctrl_mctrl;
    logic m_sel_mctrl;

    mctrl ctrlm(
        .inst(instruction_IF),
        .rf_wr_en(rf_wr_en_mctrl),
        .rf_wr_sel(rf_wr_sel_mctrl),
        .alu_a_sel(alu_a_sel_mctrl),
        .alu_b_sel(alu_b_sel_mctrl),
        .alu_ctrl(alu_ctrl_mctrl),
        .m_sel(m_sel_mctrl)
    );

    // 时钟上升沿的逻辑，用于锁存信号
    always_ff @(posedge clk or negedge reset) begin
        if (reset||flush) begin
            // 复位时清空寄存器
            rd_ID          <= 5'b0;
            m_sel          <= 0;
            rf_wr_en       <= 1'b0;
            do_jump        <= 1'b0;
            is_branch      <= 1'b0;
            alu_a_sel      <= 1'b0;
            alu_b_sel      <= 1'b0;
            alu_ctrl       <= 4'b0;
            BrType         <= 3'b0;
            rf_wr_sel      <= 2'b0;
            dm_rd_ctrl     <= 3'b0;
            dm_wr_ctrl     <= 3'b0;
            pc_IDC         <= 0;
            rs1_IDC <= 0;  // rs1地址
            rs2_IDC <= 0;  // rs2地址
            imm_ID <= 0;
        end else if(~stall) begin
            // 锁存解码得到的字段
            rd_ID          <= instruction_IF[11:7];   // 目的寄存器

            // 锁存寄存器地址和立即数
            rs1_IDC <= instruction_IF[19:15];  // rs1地址
            rs2_IDC <= instruction_IF[24:20];  // rs2地址
            imm_ID <= imm_ictrl;

            // 锁存控制信号
            m_sel          <= m_sel_mctrl;
            rf_wr_en       <= m_sel_mctrl ? rf_wr_en_mctrl : rf_wr_en_ictrl;
            do_jump        <= do_jump_ictrl;
            is_branch      <= is_branch_ictrl;
            alu_a_sel      <= m_sel_mctrl ? alu_a_sel_mctrl : alu_a_sel_ictrl;
            alu_b_sel      <= m_sel_mctrl ? alu_b_sel_mctrl : alu_b_sel_ictrl;
            alu_ctrl       <= m_sel_mctrl ? alu_ctrl_mctrl : alu_ctrl_ictrl;
            BrType         <= BrType_ictrl;
            rf_wr_sel      <= m_sel_mctrl ? rf_wr_sel_mctrl : rf_wr_sel_ictrl;
            dm_rd_ctrl     <= dm_rd_ctrl_ictrl;
            dm_wr_ctrl     <= dm_wr_ctrl_ictrl;

            pc_IDC         <= pc_IFR;
        end
    end

endmodule
