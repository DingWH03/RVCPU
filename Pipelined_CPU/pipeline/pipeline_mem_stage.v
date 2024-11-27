// 文件名: pipeline_mem_stage.v
// 功能: 5级流水线CPU中的内存访问阶段 (Memory Access Stage)
// mem: yes
// regs: no

module pipeline_mem_stage (
    input wire clk,                     // 时钟信号
    input wire reset,                   // 复位信号，低电平有效
    input wire stall,

    // 上一阶段或id阶段的信号
    input wire [63:0] alu_result_EX,    // 从EX阶段传递的ALU计算结果，作为地址
    input wire [63:0] reg_data2_EX,     // 从EX阶段传递的源寄存器2的值 (用于存储数据)
    input wire [4:0] rd_EX,             // 从EX阶段传递的目的寄存器地址
    input wire [63:0] pc_MEM,           // 从EX阶段传递的PC值
    input wire [2:0] dm_rd_ctrl_EX,     // 内存读控制信号
    input wire [2:0] dm_wr_ctrl_EX,     // 内存写控制信号
    input wire rf_wr_en_EX,             // id阶段传来的寄存器写使能信号
    input wire [1:0] rf_wr_sel_EX,         // 从ID阶段传递的寄存器写数据选择信号，需要传递到wb阶段

    // 与内存接口的信号
    output reg [63:0] dm_addr,          // 传递给内存的地址信号
    output reg [63:0] dm_din,           // 传递给内存的数据（写入）
    input wire [63:0] dm_dout,          // 从内存读取的数据
    output reg [2:0] dm_rd_ctrl,        // 内存读控制信号
    output reg [2:0] dm_wr_ctrl,        // 内存写控制信号

    // 总线占用信号
    output reg memorying,

    // 传递给下一个阶段的信号
    output reg [63:0] pc_WB,           // 下一阶段的输入pc
    output reg [1:0] rf_wr_sel_MEM,        // 从ID阶段传递的寄存器写数据选择信号，需要传递到wb阶段
    output reg rf_wr_en_MEM,            // 传入到wb阶段的寄存器写使能信号
    output [63:0] mem_data_MEM,     // 内存读取的数据
    output reg [63:0] alu_result_MEM,   // 直接传递的ALU结果（用于不需要内存操作的指令）
    output reg [4:0] rd_MEM,            // 传递给下一个阶段的目的寄存器地址
    output reg mem_read_done_MEM        // 内存读取完成信号
);

    assign mem_data_MEM = dm_dout;

    always @(posedge clk or negedge reset) begin
        if (reset) begin
            // 复位时清空寄存器
            // mem_data_MEM <= 64'b0;
            alu_result_MEM <= 64'b0;
            mem_read_done_MEM <= 1'b0;
            rd_MEM <= 5'b0;

            // 复位内存访问信号
            dm_addr <= 64'b0;
            dm_din <= 64'b0;
            dm_rd_ctrl <= 3'b0;
            dm_wr_ctrl <= 3'b0;
            pc_WB <= 0;
            rf_wr_en_MEM <= 0;
            rf_wr_sel_MEM <= 0;
            memorying <= 0;
        end else if (~stall) begin
            // 传递给下一个阶段的ALU结果 (对于不需要访问内存的指令)
            alu_result_MEM <= alu_result_EX;

            // 传递目的寄存器地址
            rd_MEM <= rd_EX;

            // 内存读操作
            // mem_data_MEM <= dm_dout;          // 从内存读取数据
            mem_read_done_MEM <= 1'b1;        // 读操作完成信号

            // 内存访问信号
            dm_addr <= alu_result_EX;         // 地址由ALU结果提供
            dm_din <= reg_data2_EX;           // 写入的数据来自寄存器堆中的第二个源寄存器
            dm_rd_ctrl <= dm_rd_ctrl_EX;      // 直接传递内存读控制信号
            dm_wr_ctrl <= dm_wr_ctrl_EX;      // 直接传递内存写控制信号
            pc_WB <= pc_MEM;
            rf_wr_en_MEM <= rf_wr_en_EX;
            rf_wr_sel_MEM <= rf_wr_sel_EX;
            memorying <= dm_rd_ctrl_EX || dm_wr_ctrl_EX;
        end
    end

endmodule
