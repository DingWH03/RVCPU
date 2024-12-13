// dram16.sv
`timescale 1ns / 1ns

module dram(
    input logic clk,
    input logic [16:0]  addr,
    input logic write_en,
    inout logic [15:0] data
);

logic [15:0]  data_mem[0:8191]; // 16-bit data memory
logic [15:0] mem_data;

// 初始化存储器
integer i;
initial begin
    for(i=0; i<8192; i=i+1) 
        data_mem[i] = 0;
end

// 读写逻辑
always @(posedge clk) begin
    if (write_en) begin
        // 写入数据
        data_mem[addr] <= mem; 
        $display("WRITE to addr: %h, data: %h", addr, mem);
    end
end

// 驱动或读取数据
assign mem = write_en ? 16'bz : data_mem[addr]; // 高阻态用于读取
endmodule