// 文件名: pipeline_idr_stage.sv
// 功能: 从5级流水线CPU中的指令解码阶段分割出来的专用于访问寄存器堆模块 (Instruction Decode regfile Stage)
// mem: no
// regs: yes

module pipeline_idr_stage4 (
    input logic clk,                   // 时钟信号
    input logic reset,                 // 复位信号，低电平有效
    input logic stall,            // 流水线暂停信号
    input logic flush,               // 流水线冲刷信号
    input logic nop,                // 插入气泡

    // 从上一个ID阶段传递进来的信号
    input logic [63:0] pc_IDC,          // 从IDC阶段传来的PC值
    input logic [4:0] rs1_IDC, rs2_IDC, // 读取寄存器地址
    input logic is_rs1_used, is_rs2_used,
    //下面是只需要传递的信号
    input logic [4:0] rd_ID,          // 目的寄存器地址
    input logic [63:0] imm_ID,        // 解码出的立即数
    input logic rf_wr_en,             // 寄存器写使能信号
    input logic do_jump,              // 跳转控制信号
    input logic is_branch,            // 是否b_type
    input logic alu_a_sel,            // ALU 输入A选择信号
    input logic alu_b_sel,            // ALU 输入B选择信号
    input logic [3:0] alu_ctrl,       // ALU 控制信号
    input logic [2:0] BrType,         // 分支类型控制信号
    input logic [1:0] rf_wr_sel,      // 寄存器写回数据来源选择
    // 与内存模块连接的控制信号 (需要越过ex传递到mem阶段)
    input logic [2:0] dm_rd_ctrl,     // 数据存储器读取控制信号
    input logic [2:0] dm_wr_ctrl,     // 数据存储器写入控制信号


    // 接入数据前推forwarding模块
    input logic [63:0] forward_rs1_data, // 前递寄存器1数据
    input logic [63:0] forward_rs2_data, // 前递寄存器2数据
    input logic forward_rs1_sel, // 前递寄存器1数据选择信号
    input logic forward_rs2_sel,  // 前递寄存器2数据选择信号

    input logic [63:0] data_reg_read_1, data_reg_read_2, // 从寄存器堆读取的数据
    
    // IDR阶段本职工作：读取寄存器和处理数据前递
    output logic [63:0] pc_IDR,     // IDR阶段的PC值
    output logic [63:0] reg_data1_IDR,  // 解码出的源操作数1
    output logic [63:0] reg_data2_IDR,  // 解码出的源操作数2

    // IDR阶段锁存后面阶段需要使用的信号
    output logic [4:0] rd_IDR,          // 目的寄存器地址
    output logic [63:0] imm_IDR,        // 解码出的立即数
    output logic rf_wr_en_IDR,             // 寄存器写使能信号
    output logic do_jump_IDR,              // 跳转控制信号
    output logic is_branch_IDR,            // 是否b_type
    output logic alu_a_sel_IDR,            // ALU 输入A选择信号
    output logic alu_b_sel_IDR,            // ALU 输入B选择信号
    output logic [3:0] alu_ctrl_IDR,       // ALU 控制信号
    output logic [2:0] BrType_IDR,         // 分支类型控制信号
    output logic [1:0] rf_wr_sel_IDR,      // 寄存器写回数据来源选择
    output logic [4:0] rs1_IDR, rs2_IDR,
    // 与内存模块连接的控制信号 (需要越过ex传递到mem阶段)
    output logic [2:0] dm_rd_ctrl_IDR,     // 数据存储器读取控制信号
    output logic [2:0] dm_wr_ctrl_IDR     // 数据存储器写入控制信号
    
);

    // 时钟上升沿的逻辑，用于锁存信号
    always_ff @(posedge clk or negedge reset) begin
        if (reset) begin
            // 复位时清空寄存器
            pc_IDR <= 64'b0;
            reg_data1_IDR <= 64'b0;
            reg_data2_IDR <= 64'b0;
            rd_IDR <= 5'b0;
            imm_IDR <= 64'b0;
            rf_wr_en_IDR <= 0;
            do_jump_IDR <= 0;
            is_branch_IDR <= 0;
            alu_a_sel_IDR <= 0;
            alu_b_sel_IDR <= 0;
            alu_ctrl_IDR <= 4'b0;
            BrType_IDR <= 3'b0;
            rf_wr_sel_IDR <= 2'b0;
            dm_rd_ctrl_IDR <= 3'b0;
            dm_wr_ctrl_IDR <= 3'b0;
            rs1_IDR <= 0;
            rs2_IDR <= 0;

        end else if (~stall&flush) begin
            // 复位时清空寄存器
            pc_IDR <= 64'b0;
            reg_data1_IDR <= 64'b0;
            reg_data2_IDR <= 64'b0;
            rd_IDR <= 5'b0;
            imm_IDR <= 64'b0;
            rf_wr_en_IDR <= 0;
            do_jump_IDR <= 0;
            is_branch_IDR <= 0;
            alu_a_sel_IDR <= 0;
            alu_b_sel_IDR <= 0;
            alu_ctrl_IDR <= 4'b0;
            BrType_IDR <= 3'b0;
            rf_wr_sel_IDR <= 2'b0;
            dm_rd_ctrl_IDR <= 3'b0;
            dm_wr_ctrl_IDR <= 3'b0;
            rs1_IDR <= 0;
            rs2_IDR <= 0;
        end else if (~stall & nop) begin
        // nop 插入气泡
        pc_IDR <= 64'b0; // 或根据需要设置特殊的NOP值
        reg_data1_IDR <= 64'b0;
        reg_data2_IDR <= 64'b0;
        rd_IDR <= 5'b0;
        imm_IDR <= 64'b0;
        rf_wr_en_IDR <= 0;
        do_jump_IDR <= 0;
        is_branch_IDR <= 0;
        alu_a_sel_IDR <= 0;
        alu_b_sel_IDR <= 0;
        alu_ctrl_IDR <= 4'b0;
        BrType_IDR <= 3'b0;
        rf_wr_sel_IDR <= 2'b0;
        dm_rd_ctrl_IDR <= 3'b0;
        dm_wr_ctrl_IDR <= 3'b0;
        rs1_IDR <= 0;
        rs2_IDR <= 0;

        end else if(~stall) begin
            pc_IDR <= pc_IDC;
            reg_data1_IDR <= (forward_rs1_sel) ? forward_rs1_data : data_reg_read_1;
            reg_data2_IDR <= (forward_rs2_sel) ? forward_rs2_data : data_reg_read_2;
            rd_IDR <= rd_ID;
            imm_IDR <= imm_ID;
            rf_wr_en_IDR <= rf_wr_en;
            do_jump_IDR <= do_jump;
            is_branch_IDR <= is_branch;
            alu_a_sel_IDR <= alu_a_sel;
            alu_b_sel_IDR <= alu_b_sel;
            alu_ctrl_IDR <= alu_ctrl;
            BrType_IDR <= BrType;
            rf_wr_sel_IDR <= rf_wr_sel;
            dm_rd_ctrl_IDR <= dm_rd_ctrl;
            dm_wr_ctrl_IDR <= dm_wr_ctrl;
            rs1_IDR <= rs1_IDC;
            rs2_IDR <= rs2_IDC;
        
        end

    end

endmodule
