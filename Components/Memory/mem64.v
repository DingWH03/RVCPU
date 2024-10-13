module mem(
    input           clk,
    input   [63:0]  im_addr,        // 64位指令地址
    output  [63:0]  im_dout,        // 64位指令数据输出
    input   [2:0]   dm_rd_ctrl,     // 数据存储器读取控制
    input   [1:0]   dm_wr_ctrl,     // 数据存储器写入控制
    input   [63:0]  dm_addr,        // 64位数据地址
    input   [63:0]  dm_din,         // 64位数据输入
    output reg  [63:0]  dm_dout       // 64位数据输出
);

reg     [7:0]  mem[0:524287];      // 8MB存储器，支持64位地址

integer i;

initial
begin
    for(i=0; i<524287; i=i+1) mem[i] = 0; // 初始化存储器
end

initial
begin
  $readmemh("./problem/inst.dat",mem);
end

// 指令内存输出逻辑，64位宽
assign im_dout[7:0]  = mem[im_addr[31:2]];
assign im_dout[15:8] = mem[im_addr[31:2] + 1];
assign im_dout[23:16] = mem[im_addr[31:2] + 2];
assign im_dout[31:24] = mem[im_addr[31:2] + 3];
assign im_dout[39:32] = mem[im_addr[31:2] + 4];
assign im_dout[47:40] = mem[im_addr[31:2] + 5];
assign im_dout[55:48] = mem[im_addr[31:2] + 6];
assign im_dout[63:56] = mem[im_addr[31:2] + 7];

// Data memory read logic
always @(dm_rd_ctrl or dm_addr) begin
    case (dm_rd_ctrl)
        3'b001: dm_dout = {{56{mem[dm_addr][7]}}, mem[dm_addr][7:0]}; // Byte with sign extension
        3'b010: dm_dout = {56'b0, mem[dm_addr][7:0]};                 // Byte without sign extension
        3'b011: dm_dout = {{48{mem[dm_addr][15]}}, mem[dm_addr][15:0]}; // Half-word with sign extension
        3'b100: dm_dout = {48'b0, mem[dm_addr][15:0]};                 // Half-word without sign extension
        3'b101: dm_dout = {32'b0, mem[dm_addr], mem[dm_addr+1], mem[dm_addr+2], mem[dm_addr+3]}; // Word
        default: dm_dout = 64'b0; // Default case
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