// dram_ctrl.v
`timescale 1ns / 1ns
module dram_ctrl(
    input wire clk,
    input wire rst,
    input   [2:0]   dm_rd_ctrl,
    input   [2:0]   dm_wr_ctrl,
    input   [63:0]  dm_addr,
    input   [63:0]  dm_din,
    output reg  [63:0] dm_dout,
    output reg [1:0] state
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


reg temp;


always @(posedge clk or posedge rst ) begin
    if (rst) begin
        temp <= 0;
    end
    else if (dm_wr_ctrl)begin
        temp <= 1;
    end
    else if (dm_rd_ctrl) begin
        temp <= 1;
    end
    else begin
        temp <= 0;
    end
end

// 状态控制
always @(*) begin
    if (temp)
        state = 2'b00;  // 读/写时的状态
    else if (dm_wr_ctrl)
        state = 2'b10;  // 写状态
    else if (dm_rd_ctrl)
        state = 2'b11;  // 读状态
end


endmodule