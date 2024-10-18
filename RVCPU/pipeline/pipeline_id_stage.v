// 文件名: pipeline_id_stage.v
// 功能: 5级流水线CPU中的指令解码阶段 (Instruction Decode Stage)
// mem: no
// regs: yes

module pipeline_id_stage (
    input wire clk,                   // 时钟信号
    input wire reset,                 // 复位信号，低电平有效
    input wire [31:0] instruction_ID, // 从IF阶段传来的指令
    input wire [63:0] pc_ID,          // 从IF阶段传来的PC值

    input wire [63:0] data_reg_read_1, data_reg_read_2, // 从寄存器堆读取的数据
    
    output reg [63:0] reg_data1_ID,  // 解码出的源操作数1
    output reg [63:0] reg_data2_ID,  // 解码出的源操作数2
    output reg [4:0] rs1_ID,         // 源寄存器1地址
    output reg [4:0] rs2_ID,         // 源寄存器2地址
    output reg [4:0] rd_ID,          // 目的寄存器地址
    output reg [6:0] opcode_ID,      // 解码出的操作码
    output reg [2:0] funct3_ID,      // 解码出的功能码 funct3
    output reg [6:0] funct7_ID,      // 解码出的功能码 funct7
    output reg [63:0] imm_ID,        // 解码出的立即数

    output reg pc_out,               // 输出到下一阶段的PC

    // 控制信号
    output reg rf_wr_en,             // 寄存器写使能信号
    output reg do_jump,              // 跳转控制信号
    output reg alu_a_sel,            // ALU 输入A选择信号
    output reg alu_b_sel,            // ALU 输入B选择信号
    output reg [3:0] alu_ctrl,       // ALU 控制信号
    output reg [2:0] BrType,         // 分支类型控制信号
    output reg [1:0] rf_wr_sel,      // 寄存器写回数据来源选择

    // 与内存模块连接的控制信号
    output reg [2:0] dm_rd_ctrl,     // 数据存储器读取控制信号
    output reg [1:0] dm_wr_ctrl,     // 数据存储器写入控制信号

    output reg [4:0] addr_reg_read_1, addr_reg_read_2 // 连接源寄存器堆地址
);

    // 实例化立即数解码模块
    wire [63:0] imm_wire;
    imm imm0 (
        .inst(instruction_ID),
        .out(imm_wire)
    );

    // 实例化控制单元模块
    wire rf_wr_en_wire, do_jump_wire, alu_a_sel_wire, alu_b_sel_wire;
    wire [3:0] alu_ctrl_wire;
    wire [2:0] BrType_wire, dm_rd_ctrl_wire;
    wire [1:0] rf_wr_sel_wire, dm_wr_ctrl_wire;

    ctrl control_unit (
        .inst(instruction_ID),
        .rf_wr_en(rf_wr_en_wire),
        .rf_wr_sel(rf_wr_sel_wire),
        .do_jump(do_jump_wire),
        .BrType(BrType_wire),
        .alu_a_sel(alu_a_sel_wire),
        .alu_b_sel(alu_b_sel_wire),
        .alu_ctrl(alu_ctrl_wire),
        .dm_rd_ctrl(dm_rd_ctrl_wire),
        .dm_wr_ctrl(dm_wr_ctrl_wire),
        .opcode(opcode_ID),
        .funct3(funct3_ID),
        .funct7(funct7_ID)
    );

    // 时钟上升沿的逻辑，用于锁存信号
    always @(posedge clk or negedge reset) begin
        if (!reset) begin
            // 复位时清空寄存器
            opcode_ID      <= 7'b0;
            rd_ID          <= 5'b0;
            funct3_ID      <= 3'b0;
            rs1_ID         <= 5'b0;
            rs2_ID         <= 5'b0;
            funct7_ID      <= 7'b0;
            imm_ID         <= 64'b0;
            reg_data1_ID   <= 64'b0;
            reg_data2_ID   <= 64'b0;
            rf_wr_en       <= 1'b0;
            do_jump        <= 1'b0;
            alu_a_sel      <= 1'b0;
            alu_b_sel      <= 1'b0;
            alu_ctrl       <= 4'b0;
            BrType         <= 3'b0;
            rf_wr_sel      <= 2'b0;
            dm_rd_ctrl     <= 3'b0;
            dm_wr_ctrl     <= 2'b0;
            pc_out         <= 0;
        end else begin
            // 锁存解码得到的字段
            opcode_ID      <= instruction_ID[6:0];    // 操作码
            rd_ID          <= instruction_ID[11:7];   // 目的寄存器
            funct3_ID      <= instruction_ID[14:12];  // 功能码 funct3
            rs1_ID         <= instruction_ID[19:15];  // 源寄存器1
            rs2_ID         <= instruction_ID[24:20];  // 源寄存器2
            funct7_ID      <= instruction_ID[31:25];  // 功能码 funct7

            // 锁存寄存器地址和立即数
            addr_reg_read_1 <= instruction_ID[19:15];  // rs1地址
            addr_reg_read_2 <= instruction_ID[24:20];  // rs2地址
            imm_ID         <= imm_wire;                // 立即数

            // 锁存寄存器文件数据
            reg_data1_ID   <= data_reg_read_1;
            reg_data2_ID   <= data_reg_read_2;

            // 锁存控制信号
            rf_wr_en       <= rf_wr_en_wire;
            do_jump        <= do_jump_wire;
            alu_a_sel      <= alu_a_sel_wire;
            alu_b_sel      <= alu_b_sel_wire;
            alu_ctrl       <= alu_ctrl_wire;
            BrType         <= BrType_wire;
            rf_wr_sel      <= rf_wr_sel_wire;
            dm_rd_ctrl     <= dm_rd_ctrl_wire;
            dm_wr_ctrl     <= dm_wr_ctrl_wire;

            pc_out         <= pc_ID;
        end
    end

endmodule
