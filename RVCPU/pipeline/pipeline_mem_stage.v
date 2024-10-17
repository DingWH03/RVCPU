// 文件名: pipeline_mem_stage.v
// 功能: 5级流水线CPU中的内存访问阶段 (Memory Access Stage)
// mem: yes
// regs: no

module pipeline_mem_stage (
    input wire clk,                     // 时钟信号
    input wire reset,                   // 复位信号，低电平有效
    input wire mem_read_EX,             // 来自EX阶段的内存读信号
    input wire mem_write_EX,            // 来自EX阶段的内存写信号
    input wire [63:0] alu_result_EX,    // 从EX阶段传递的ALU计算结果，作为地址
    input wire [63:0] reg_data2_EX,     // 从EX阶段传递的源寄存器2的值 (用于存储数据)
    input wire [4:0] rd_EX,             // 从EX阶段传递的目的寄存器地址
    input wire [63:0] pc_MEM,           // 从EX阶段传递的PC值

    // 与内存接口的信号
    output wire [63:0] dm_addr,         // 传递给内存的地址信号
    output wire [63:0] dm_din,          // 传递给内存的数据（写入）
    input wire [63:0] dm_dout,          // 从内存读取的数据
    output wire [2:0] dm_rd_ctrl,       // 内存读控制信号
    output wire [1:0] dm_wr_ctrl,       // 内存写控制信号

    // 传递给下一个阶段的信号
    output reg [63:0] mem_data_MEM,     // 内存读取的数据
    output reg [63:0] alu_result_MEM,   // 直接传递的ALU结果（用于不需要内存操作的指令）
    output reg [4:0] rd_MEM,            // 传递给下一个阶段的目的寄存器地址
    output reg mem_read_done_MEM        // 内存读取完成信号
);

    // 内存操作
    always @(posedge clk or negedge reset) begin
        if (!reset) begin
            // 复位时清空寄存器
            mem_data_MEM <= 64'b0;
            alu_result_MEM <= 64'b0;
            mem_read_done_MEM <= 1'b0;
            rd_MEM <= 5'b0;
        end else begin
            // 传递给下一个阶段的ALU结果 (对于不需要访问内存的指令)
            alu_result_MEM <= alu_result_EX;

            // 传递目的寄存器地址
            rd_MEM <= rd_EX;

            // 内存读操作
            if (mem_read_EX) begin
                mem_data_MEM <= dm_dout;         // 从内存读取数据
                mem_read_done_MEM <= 1'b1;       // 读操作完成信号
            end else begin
                mem_read_done_MEM <= 1'b0;       // 没有读操作
            end
        end
    end

    // 内存访问信号
    assign dm_addr = alu_result_EX;      // 地址由ALU结果提供
    assign dm_din = reg_data2_EX;        // 写入的数据来自寄存器堆中的第二个源寄存器


endmodule
