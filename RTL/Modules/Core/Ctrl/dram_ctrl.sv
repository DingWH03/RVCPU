// dram_ctrl.sv
`timescale 1ns / 1ns
`include "../defines.sv"
module dram_ctrl(
    input logic clk,
    input logic rst,
    input logic [2:0]   dm_rd_ctrl,
    input logic [2:0]   dm_wr_ctrl,
    input logic [63:0]  dm_addr,
    input logic [63:0]  dm_din,
    output logic  [63:0] dm_dout,
    output state_dram_ctrl state,
    // 下面用来连接存储芯片
    inout logic [15:0]  data,
    output logic write_en,
    output logic [18:0] addr
);

logic [15:0] wr_data;

assign addr = (dm_addr>=64'h80000000)?(dm_addr - 64'h80000000):64'b0; // 地址转换\
assign data = write_en?wr_data:16'bz;

always_ff @(posedge clk or posedge rst) begin
    if(rst)begin
        state <= IDLE;
    end else if (dm_wr_ctrl) begin
        state <= WRITE;

    end else if(dm_rd_ctrl)begin

    end
end




endmodule