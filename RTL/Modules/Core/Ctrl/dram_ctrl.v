// dram_ctrl.v
`timescale 1ns / 1ns
module dram_ctrl(
    input wire clk,
    input wire rst,
    input   [2:0]   dm_rd_ctrl,
    input   [2:0]   dm_wr_ctrl,
    input   [63:0]  dm_addr,
    input   [63:0]  dm_din,
    output reg  [63:0] dm_dout
);
wire [12:0] addr;
assign addr = (dm_addr >= 64'h80000000) ? (dm_addr - 64'h80000000) >> 3 : 0;
dram dram0 (
    .clk(clk),
    .we(|dm_wr_ctrl),             // 写使能信号
    .a(addr),        // 地址的低14位
    .spo(dm_din),                // 输入数据
    .d(dm_dout)               // 输出数据
);
endmodule