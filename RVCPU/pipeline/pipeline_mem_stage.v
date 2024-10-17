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

    output reg [63:0] mem_data_MEM,     // 内存读取的数据
    output reg [63:0] alu_result_MEM,   // 直接传递的ALU结果（用于不需要内存操作的指令）
    output reg [4:0] rd_MEM,            // 传递给下一个阶段的目的寄存器地址
    output reg mem_read_done_MEM        // 内存读取完成信号
);

    // 内存 (假设为64位宽的字地址对齐内存)
    reg [63:0] memory [0:1023];  // 一个简单的模拟内存块，1024个64位字大小

    // 内存操作
    always @(posedge clk or negedge reset) begin
        if (!reset) begin
            // 初始化内存（如果需要），此处省略具体内容
            mem_data_MEM <= 64'b0;
            alu_result_MEM <= 64'b0;
            mem_read_done_MEM <= 1'b0;
        end else begin
            // 内存读操作
            if (mem_read_EX) begin
                mem_data_MEM <= memory[alu_result_EX[11:3]];  // 以字为单位访问内存
                mem_read_done_MEM <= 1'b1;  // 读操作完成信号
            end else begin
                mem_read_done_MEM <= 1'b0;  // 没有读操作
            end

            // 内存写操作
            if (mem_write_EX) begin
                memory[alu_result_EX[11:3]] <= reg_data2_EX;  // 以字为单位写入内存
            end

            // 直接传递ALU结果 (对于不需要访问内存的指令)
            alu_result_MEM <= alu_result_EX;

            // 传递目的寄存器地址
            rd_MEM <= rd_EX;
        end
    end

endmodule
