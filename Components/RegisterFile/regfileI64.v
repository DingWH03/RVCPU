`timescale 1ns / 1ns
module reg_file(
    input          clk,
    input  [4:0]   A1, A2, A3,     // 5-bit addresses for registers
    input  [63:0]  WD,             // 64-bit write data
    input          WE,             // Write enable
    output [63:0]  RD1, RD2        // 64-bit read data
);

reg [63:0] reg_file[0:31];         // 64-bit wide registers, 32 registers in total

// 初始化寄存器堆，所有寄存器初始化为0
integer i;
initial begin
    for (i = 0; i < 32; i = i + 1) 
        reg_file[i] = 64'b0;
end

// 写入寄存器，确保x0（即reg_file[0]）始终为0
always @(negedge clk) begin
    if (WE && A3 != 5'b00000)      // 当写使能有效且目标不是x0时才写入
        reg_file[A3] = WD;  // 信号A3控制写入位置
end

// 读取寄存器
// 信号A1、A2控制读取地址
assign RD1 = (A1 == 5'b00000) ? 64'b0 : reg_file[A1];  // 如果读取的是x0，输出0
assign RD2 = (A2 == 5'b00000) ? 64'b0 : reg_file[A2];  // 如果读取的是x0，输出0

endmodule
