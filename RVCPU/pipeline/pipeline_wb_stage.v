// 文件名: pipeline_wb_stage.v
// 功能: 5级流水线CPU中的写回阶段 (Write Back Stage)
// mem: no
// regs: yes

module pipeline_wb_stage (
    input wire clk,                    // 时钟信号
    input wire reset,                  // 复位信号，低电平有效
    input wire mem_to_reg_MEM,         // 控制信号，选择从内存还是ALU写回
    input wire [63:0] alu_result_MEM,  // 从MEM阶段传递的ALU结果
    input wire [63:0] mem_data_MEM,    // 从MEM阶段传递的内存数据
    input wire [4:0] rd_MEM,           // 从MEM阶段传递的目的寄存器地址
    input wire reg_write_MEM,          // 来自MEM阶段的写寄存器信号

    output reg [63:0] write_data_WB,   // 写回寄存器的数据
    output reg [4:0] rd_WB,            // 写回的目的寄存器地址
    output reg reg_write_WB            // 写回寄存器的控制信号
);

    // 写回数据选择逻辑
    always @(*) begin
        if (mem_to_reg_MEM) begin
            write_data_WB = mem_data_MEM;  // 从内存读取的数据写回寄存器
        end else begin
            write_data_WB = alu_result_MEM;  // ALU结果写回寄存器
        end
    end

    // 写回目的寄存器和控制信号
    always @(posedge clk or negedge reset) begin
        if (!reset) begin
            rd_WB <= 5'b0;
            reg_write_WB <= 1'b0;
            write_data_WB <= 64'b0;
        end else begin
            rd_WB <= rd_MEM;              // 将目的寄存器地址传递给写回阶段
            reg_write_WB <= reg_write_MEM; // 将寄存器写使能信号传递给写回阶段
        end
    end

endmodule