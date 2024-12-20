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
    output logic mALU_runing,

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
    logic [127:0] mALU_result;
    logic [63:0] dALU_quotient, dALU_remainder;
    logic signed_a, signed_b;
    logic start;
    logic mALU_start;
    logic dALU_start;
    logic ready;
    logic mALU_ready;
    logic dALU_ready;
    logic result_high;
    logic [63:0] result_high_val, result_low_val;

    assign start = mALU_start | dALU_start;
    assign ready = mALU_ready | dALU_ready;
    assign mALU_runing = start & !ready;

    always_comb begin
        if (mALU_start) begin
            result_high_val = mALU_result[127:64];
            result_low_val = mALU_result[63:0];
        end else if (dALU_start) begin
            result_high_val = dALU_quotient;
            result_low_val = dALU_remainder;
        end else begin
            result_high_val = 0;
            result_low_val = 0;
        end
    end

    always_comb begin           // 控制mALU和dALU运行
        if(m_sel_EXA)begin
            case (alu_ctrl_EXA)
                4'b0000: begin  // mul
                    signed_a = 1;
                    signed_b = 1;
                    mALU_start = 1;
                    dALU_start = 0;
                    result_high = 0;
                end
                4'b0001: begin  // mulh
                    signed_a = 1;
                    signed_b = 1;
                    mALU_start = 1;
                    dALU_start = 0;
                    result_high = 1;
                end
                4'b0010: begin  // mulhsu
                    signed_a = 1;
                    signed_b = 0;
                    mALU_start = 1;
                    dALU_start = 0;
                    result_high = 1;
                end
                4'b0011: begin  // mulhu
                    signed_a = 0;
                    signed_b = 0;
                    mALU_start = 1;
                    dALU_start = 0;
                    result_high = 1;
                end
                4'b0100: begin  // div
                    signed_a = 1;
                    signed_b = 1;
                    mALU_start = 0;
                    dALU_start = 1;
                    result_high = 1;
                end
                4'b0101: begin  // divu
                    signed_a = 0;
                    signed_b = 0;
                    mALU_start = 0;
                    dALU_start = 1;
                    result_high = 1;
                end
                4'b0110: begin  // rem
                    signed_a = 1;
                    signed_b = 1;
                    mALU_start = 0;
                    dALU_start = 1;
                    result_high = 0;
                end
                4'b0111: begin  // remu
                    signed_a = 0;
                    signed_b = 0;
                    mALU_start = 0;
                    dALU_start = 1;
                    result_high = 0;
                end
                default: begin
                    mALU_start = 0;
                    dALU_start = 0;
                end
            endcase
        end else begin
            mALU_start = 0;
            dALU_start = 0;
        end
    end

    mALU malu(
        .rst(reset),
        .clk(clk),
        .a({64{m_sel_EXA}}&reg_data1_EXA),
        .b({64{m_sel_EXA}}&reg_data2_EXA),
        .signed_a(m_sel_EXA&signed_a),
        .signed_b(m_sel_EXA&signed_b),
        .start(mALU_start),
        .result(mALU_result),
        .ready(mALU_ready)
    );

    dALU dalu(
        .rst(reset),
        .clk(clk),
        .dividend({64{m_sel_EXA}}&reg_data1_EXA),
        .divisor({64{m_sel_EXA}}&reg_data2_EXA),
        .signed_dividend(m_sel_EXA&signed_a),
        .signed_divisor(m_sel_EXA&signed_b),
        .start(dALU_start),
        .quotient(dALU_quotient), // 商
        .remainder(dALU_remainder), // 余数
        .ready(dALU_ready)
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
            alu_result_EXC <= m_sel_EXA ? (result_high?result_high_val:result_low_val) : alu_result_EXA;
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