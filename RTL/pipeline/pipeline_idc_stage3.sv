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

    // 与内存模块连接的控制信号 (需要越过ex传递到mem阶段)
    output logic [2:0] dm_rd_ctrl,     // 数据存储器读取控制信号
    output logic [2:0] dm_wr_ctrl,     // 数据存储器写入控制信号

    output logic [4:0] rs1_IDC, rs2_IDC // 需要读取寄存器堆数据的地址(同时连接到寄存器堆(直接读取)和数据前推模块)
);

    // 实例化立即数解码模块
    logic [63:0] imm_wire;
    imm imm0 (
        .inst(instruction_IF),
        .out(imm_wire)
    );

    // 实例化控制单元模块
    logic rf_wr_en_wire, do_jump_wire, is_branch_wire, alu_a_sel_wire, alu_b_sel_wire;
    logic [3:0] alu_ctrl_wire;
    logic [2:0] BrType_wire, dm_rd_ctrl_wire;
    logic [1:0] rf_wr_sel_wire;
    logic [2:0] dm_wr_ctrl_wire;

    ctrl control_unit (
        .inst(instruction_IF),
        .rf_wr_en(rf_wr_en_wire),
        .rf_wr_sel(rf_wr_sel_wire),
        .do_jump(do_jump_wire),
        .is_branch(is_branch_wire),
        .BrType(BrType_wire),
        .alu_a_sel(alu_a_sel_wire),
        .alu_b_sel(alu_b_sel_wire),
        .alu_ctrl(alu_ctrl_wire),
        .dm_rd_ctrl(dm_rd_ctrl_wire),
        .dm_wr_ctrl(dm_wr_ctrl_wire),
        .is_debug(is_debug),
        .opcode(instruction_IF[6:0]),
        .funct3(instruction_IF[14:12]),
        .funct7(instruction_IF[31:25])
    );

    // 时钟上升沿的逻辑，用于锁存信号
    always_ff @(posedge clk or negedge reset) begin
        if (reset||flush) begin
            // 复位时清空寄存器
            rd_ID          <= 5'b0;
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
            imm_ID < =;
        end else if(~stall) begin
            // 锁存解码得到的字段
            rd_ID          <= instruction_IF[11:7];   // 目的寄存器

            // 锁存寄存器地址和立即数
            rs1_IDC <= instruction_IF[19:15];  // rs1地址
            rs2_IDC <= instruction_IF[24:20];  // rs2地址
            imm_ID <= imm_wire;

            // 锁存控制信号
            rf_wr_en       <= rf_wr_en_wire;
            do_jump        <= do_jump_wire;
            is_branch      <= is_branch_wire;
            alu_a_sel      <= alu_a_sel_wire;
            alu_b_sel      <= alu_b_sel_wire;
            alu_ctrl       <= alu_ctrl_wire;
            BrType         <= BrType_wire;
            rf_wr_sel      <= rf_wr_sel_wire;
            dm_rd_ctrl     <= dm_rd_ctrl_wire;
            dm_wr_ctrl     <= dm_wr_ctrl_wire;

            pc_IDC         <= pc_IFR;
        end
    end

endmodule
