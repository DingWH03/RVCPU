// 文件名: pipeline_id_stage.v
// 功能: 5级流水线CPU中的指令解码阶段 (Instruction Decode Stage)
// mem: no
// regs: yes

module pipeline_id_stage (
    input wire clk,                   // 时钟信号
    input wire reset,                 // 复位信号，低电平有效
    input wire stall,            // 流水线暂停信号
    input wire flush,               // 流水线冲刷信号
    input wire [31:0] instruction_IF, // 从IF阶段传来的指令
    input wire [63:0] pc_IF,          // 从IF阶段传来的PC值

    // 接入数据前推forwarding模块
    input wire [63:0] forward_rs1_data, // 前递寄存器1数据
    input wire [63:0] forward_rs2_data, // 前递寄存器2数据
    input wire forward_rs1_sel, // 前递寄存器1数据选择信号
    input wire forward_rs2_sel,  // 前递寄存器2数据选择信号

    input wire [63:0] data_reg_read_1, data_reg_read_2, // 从寄存器堆读取的数据
    
    output [63:0] reg_data1_ID,  // 解码出的源操作数1
    output [63:0] reg_data2_ID,  // 解码出的源操作数2
    output reg [4:0] rd_ID,          // 目的寄存器地址
    output [63:0] imm_ID,        // 解码出的立即数

    output reg [63:0] pc_ID,               // 输出到下一阶段的PC

    // 控制信号
    output reg rf_wr_en,             // 寄存器写使能信号
    output reg do_jump,              // 跳转控制信号
    output reg is_branch,
    output reg alu_a_sel,            // ALU 输入A选择信号
    output reg alu_b_sel,            // ALU 输入B选择信号
    output reg [3:0] alu_ctrl,       // ALU 控制信号
    output reg [2:0] BrType,         // 分支类型控制信号
    output reg [1:0] rf_wr_sel,      // 寄存器写回数据来源选择

    // 与内存模块连接的控制信号 (需要越过ex传递到mem阶段)
    output reg [2:0] dm_rd_ctrl,     // 数据存储器读取控制信号
    output reg [2:0] dm_wr_ctrl,     // 数据存储器写入控制信号

    output reg [4:0] addr_reg_read_1, addr_reg_read_2 // 连接源寄存器堆地址
);
    wire is_rs1_used, is_rs2_used;
    reg [31:0] instruction_ID;

    assign reg_data1_ID   = (forward_rs1_sel&is_rs1_used) ? forward_rs1_data : data_reg_read_1;
    assign reg_data2_ID   = (forward_rs2_sel&is_rs2_used) ? forward_rs2_data : data_reg_read_2;

    

    // 实例化立即数解码模块
    wire [63:0] imm_wire;
    imm imm0 (
        .inst(instruction_ID),
        .out(imm_ID)
    );

    // 实例化控制单元模块
    wire rf_wr_en_wire, do_jump_wire, is_branch_wire, alu_a_sel_wire, alu_b_sel_wire;
    wire [3:0] alu_ctrl_wire;
    wire [2:0] BrType_wire, dm_rd_ctrl_wire;
    wire [1:0] rf_wr_sel_wire;
    wire [2:0] dm_wr_ctrl_wire;

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
        .is_rs1_used(is_rs1_used),
        .is_rs2_used(is_rs2_used),
        .opcode(instruction_IF[6:0]),
        .funct3(instruction_IF[14:12]),
        .funct7(instruction_IF[31:25])
    );

    // 时钟上升沿的逻辑，用于锁存信号
    always @(posedge clk or negedge reset) begin
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
            pc_ID         <= 0;
            instruction_ID <= 0;
            addr_reg_read_1 <= 0;  // rs1地址
            addr_reg_read_2 <= 0;  // rs2地址
        end else if(~stall) begin
            // 锁存解码得到的字段
            rd_ID          <= instruction_IF[11:7];   // 目的寄存器

            // 锁存寄存器地址和立即数
            addr_reg_read_1 <= instruction_IF[19:15];  // rs1地址
            addr_reg_read_2 <= instruction_IF[24:20];  // rs2地址
            instruction_ID  <= instruction_IF;

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

            pc_ID         <= pc_IF;
        end
    end

endmodule
