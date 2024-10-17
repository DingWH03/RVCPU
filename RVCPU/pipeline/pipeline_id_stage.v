// 文件名: pipeline_id_stage.v
// 功能: 5级流水线CPU中的指令解码阶段 (Instruction Decode Stage)
// mem: no
// regs: yes

module pipeline_id_stage (
    input wire clk,                   // 时钟信号
    input wire reset,                 // 复位信号，低电平有效
    input wire [31:0] instruction_ID, // 从IF阶段传来的指令
    input wire [63:0] pc_ID,          // 从IF阶段传来的PC值
    input wire reg_write_enable_WB,   // 写回阶段的寄存器写使能信号
    input wire [4:0] reg_write_addr_WB, // 写回阶段的目的寄存器地址
    input wire [63:0] reg_write_data_WB, // 写回阶段的写回数据
    output wire [63:0] reg_data1_ID,  // 解码出的源操作数1
    output wire [63:0] reg_data2_ID,  // 解码出的源操作数2
    output wire [4:0] rs1_ID,         // 源寄存器1地址
    output wire [4:0] rs2_ID,         // 源寄存器2地址
    output wire [4:0] rd_ID,          // 目的寄存器地址
    output wire [6:0] opcode_ID,      // 解码出的操作码
    output wire [2:0] funct3_ID,      // 解码出的功能码 funct3
    output wire [6:0] funct7_ID,      // 解码出的功能码 funct7
    output wire [63:0] imm_ID,        // 解码出的立即数

    // 控制信号
    output wire rf_wr_en,             // 寄存器写使能信号
    output wire do_jump,              // 跳转控制信号
    output wire alu_a_sel,            // ALU 输入A选择信号
    output wire alu_b_sel,            // ALU 输入B选择信号
    output wire [3:0] alu_ctrl,       // ALU 控制信号
    output wire [2:0] BrType,         // 分支类型控制信号
    output wire [1:0] rf_wr_sel,      // 寄存器写回数据来源选择
    output wire [2:0] dm_rd_ctrl,     // 数据存储器读取控制信号
    output wire [1:0] dm_wr_ctrl      // 数据存储器写入控制信号
);

    // 寄存器文件 (32个64位寄存器)
    reg [63:0] register_file [0:31];

    // 解码指令字段
    assign opcode_ID = instruction_ID[6:0];    // 取操作码 (opcode)
    assign rd_ID     = instruction_ID[11:7];   // 目的寄存器地址 (rd)
    assign funct3_ID = instruction_ID[14:12];  // 功能码 funct3
    assign rs1_ID    = instruction_ID[19:15];  // 源寄存器1地址 (rs1)
    assign rs2_ID    = instruction_ID[24:20];  // 源寄存器2地址 (rs2)
    assign funct7_ID = instruction_ID[31:25];  // 功能码 funct7

    // 立即数解码 (假设为立即数指令格式，例如RISC-V指令集)
    assign imm_ID = {{52{instruction_ID[31]}}, instruction_ID[31:20]}; // 符号扩展的立即数

    // 从寄存器文件中读取源操作数
    assign reg_data1_ID = register_file[rs1_ID]; // 读取rs1对应的寄存器数据
    assign reg_data2_ID = register_file[rs2_ID]; // 读取rs2对应的寄存器数据

    // 写回阶段寄存器写入
    always @(posedge clk or negedge reset) begin
        if (!reset) begin
            // 初始化寄存器文件 (寄存器默认值可以根据需求设定)
            integer i;
            for (i = 0; i < 32; i = i + 1)
                register_file[i] <= 64'b0; // 初始化寄存器
        end else if (reg_write_enable_WB && reg_write_addr_WB != 5'b0) begin
            // 写回数据到寄存器文件 (如果写使能信号有效且目的寄存器不为0)
            register_file[reg_write_addr_WB] <= reg_write_data_WB;
        end
    end

    // 实例化 ctrl 模块来生成控制信号
    ctrl control_unit (
        .inst(instruction_ID),
        .rf_wr_en(rf_wr_en),
        .rf_wr_sel(rf_wr_sel),
        .do_jump(do_jump),
        .BrType(BrType),
        .alu_a_sel(alu_a_sel),
        .alu_b_sel(alu_b_sel),
        .alu_ctrl(alu_ctrl),
        .dm_rd_ctrl(dm_rd_ctrl),
        .dm_wr_ctrl(dm_wr_ctrl),
        .opcode(opcode_ID),
        .funct3(funct3_ID),
        .funct7(funct7_ID)
    );

endmodule
