module mem(
input           clk,
input   [31:0]  im_addr,
output  [31:0]  im_dout,
input   [2:0]   dm_rd_ctrl,
input   [1:0]   dm_wr_ctrl,
input   [31:0]  dm_addr,
input   [31:0]  dm_din,
output reg  [31:0]  dm_dout
);
reg     [7:0]  mem[0:16383];
integer i;

initial
begin
    for(i=0;i<16383;i=i+1) mem[i] = 0;
end

initial
begin
  $readmemh("./meminit/inst.dat",mem);
end

assign im_dout[7:0] = mem[im_addr];
assign im_dout[15:8] = mem[im_addr+1];
assign im_dout[23:16] = mem[im_addr+2];
assign im_dout[31:24] = mem[im_addr+3];

// Data memory read logic
always @(dm_rd_ctrl or dm_addr) begin
    case (dm_rd_ctrl)
        3'b001: dm_dout = {{24{mem[dm_addr][7]}}, mem[dm_addr][7:0]}; // Byte with sign extension
        3'b010: dm_dout = {24'b0, mem[dm_addr][7:0]};                 // Byte without sign extension
        3'b011: dm_dout = {{16{mem[dm_addr][15]}}, mem[dm_addr][15:0]}; // Half-word with sign extension
        3'b100: dm_dout = {16'b0, mem[dm_addr][15:0]};                 // Half-word without sign extension
        3'b101: dm_dout = {mem[dm_addr], mem[dm_addr+1], mem[dm_addr+2], mem[dm_addr+3]}; // Word
        default: dm_dout = 32'b0; // Default case
    endcase
end

// Data memory write logic
always @(posedge clk) begin
    if (dm_wr_ctrl != 2'b00) begin // Only write if control is not 00
        case (dm_wr_ctrl)
            2'b11: begin // Write word
                mem[dm_addr] <= dm_din[7:0];
                mem[dm_addr+1] <= dm_din[15:8];
                mem[dm_addr+2] <= dm_din[23:16];
                mem[dm_addr+3] <= dm_din[31:24];
            end
            2'b10: begin // Write half-word
                if (dm_addr[1]) begin
                    mem[dm_addr+2] <= dm_din[7:0];
                    mem[dm_addr+3] <= dm_din[15:8];
                end else begin
                    mem[dm_addr] <= dm_din[7:0];
                    mem[dm_addr+1] <= dm_din[15:8];
                end
            end
            2'b01: begin // Write byte
                case (dm_addr[1:0])
                    2'b00: mem[dm_addr] <= dm_din[7:0];
                    2'b01: mem[dm_addr] <= {dm_din[7:0], mem[dm_addr][7:0]};
                    2'b10: mem[dm_addr] <= {mem[dm_addr][15:8], dm_din[7:0]};
                    2'b11: mem[dm_addr] <= {mem[dm_addr][23:16], dm_din[7:0]};
                endcase
            end
        endcase
    end
end

endmodule