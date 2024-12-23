// dram16.sv
// 按照ego1板卡搭载的SRAM芯片进行设计，但为节省资源容量不太大
// 板卡搭载的IS61WV12816BLL SRAM 芯片，总容量2Mbit。该SRAM为异步式SRAM，最高存取时间可达8ns。操控简单，易于读写。

`timescale 1ns / 1ns

module dram(
    input logic clk,
    input logic [16:0]  addr,
    input logic write_en, // 写使能 低电平有效
    input logic output_en, // 读使能 低电平有效
    input logic sram_en, // SRAM 使能 低电平有效
    input logic upper_en, // 上半字节使能 低电平有效
    input logic lower_en, // 下半字节使能 低电平有效
    inout logic [15:0] data
);

logic [15:0]  data_mem[0:8191]; // 16-bit data memory
logic [15:0] mem_data;

wire [15:0] mem_0 = data_mem[0];
wire [15:0] mem_1 = data_mem[1];
wire [15:0] mem_2 = data_mem[2];
wire [15:0] mem_3 = data_mem[3];

// 初始化存储器
integer i;
initial begin
    for(i=0; i<8192; i=i+1) 
        data_mem[i] = 0;
end

// 读写逻辑
always @(posedge clk) begin
    if (!sram_en) begin
        if (!write_en) begin
            // 写入数据
            if (!upper_en) begin
                data_mem[addr][15:8] <= data[15:8];
            end
            if (!lower_en)begin
                 data_mem[addr][7:0] <= data[7:0];
            end
            
        end
    end
end

// 驱动或读取数据
assign data = (!sram_en && write_en && !output_en) ? 
              {!upper_en ? data_mem[addr][15:8] : 8'bz, !lower_en ? data_mem[addr][7:0] : 8'bz} : 
              16'bz;

always @(data) begin
    if (!sram_en && write_en && !output_en) begin
        $display("READ from addr: %h, data: %h", addr, data);
    end
end


endmodule