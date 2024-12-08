// dram.v
`timescale 1ns / 1ns
module dram(
    input           clk,
    input   [63:0]  addr,
    input   [63:0]  dm_din,
    input           write_en,
    output reg  [63:0] mem_out
);

reg     [63:0]  data_mem[0:4095]; // 64-bit data memory
integer i;

initial begin
    for(i=0; i<4096; i=i+1) data_mem[i] = 0;
end

// Read data from memory
always @(posedge clk) begin
    if (addr[30:12] == 19'b0) begin // Valid address check
        mem_out <= data_mem[addr[13:3]];
    end else begin
        mem_out <= 64'b0; // Invalid address
    end
end

// Write data to memory
always @(posedge clk) begin
    if (write_en && (addr[30:12] == 19'b0)) begin
        data_mem[addr[13:3]] <= dm_din; // Write data
    end
end

endmodule
