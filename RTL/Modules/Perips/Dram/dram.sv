module dram(
    input logic clk,
    input logic [63:0] spo,
    input logic [12:0] a,
    input logic we,
    output logic [63:0] d
);

logic [63:0] data [0:8191];
assign d  = data[a];
always_ff @(posedge clk) begin
    if(we) data[a] <= spo;
end

endmodule