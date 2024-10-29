// dram_ctrl.v
`timescale 1ns / 1ns
module dram_ctrl(
    input   [2:0]   dm_rd_ctrl,
    input   [2:0]   dm_wr_ctrl,
    input   [63:0]  dm_addr,
    input   [63:0]  dm_din,
    output reg  [63:0] dm_dout,
    // 下面用来连接存储芯片
    input   [63:0]  mem_out,
    output          write_en,
    output  reg [63:0] dm_din_a,
    output wire [63:0] addr
);

reg [7:0] byte_en;


assign addr = (dm_addr>=64'h80000000)?(dm_addr - 64'h80000000):64'b0; // 地址转换
assign write_en = (byte_en != 8'b0);


// 读取控制逻辑
always @(*) begin
    case (dm_rd_ctrl)
        3'b001: dm_dout = {{56{mem_out[7]}}, mem_out[7:0]};
        3'b010: dm_dout = {{56{1'b0}}, mem_out[7:0]};
        3'b011: dm_dout = {{48{mem_out[15]}}, mem_out[15:0]};
        3'b100: dm_dout = {{48{1'b0}}, mem_out[15:0]};
        3'b101: dm_dout = mem_out; // 64-bit read
        default: dm_dout = 0;
    endcase
end

// 写使能控制逻辑
always @(*) begin
    if (dm_wr_ctrl == 3'b011) 
        byte_en = 8'b00001111;
    else if (dm_wr_ctrl == 3'b010) 
        byte_en = (addr[2] == 1'b1) ? 8'b11110000 : 8'b00001111;
    else if (dm_wr_ctrl == 3'b001) 
        case (addr[2:0])
            3'b000: byte_en = 8'b00000001;
            3'b001: byte_en = 8'b00000010;
            3'b010: byte_en = 8'b00000100;
            3'b011: byte_en = 8'b00001000;
            3'b100: byte_en = 8'b00010000;
            3'b101: byte_en = 8'b00100000;
            3'b110: byte_en = 8'b01000000;
            3'b111: byte_en = 8'b10000000;
        endcase
    else if (dm_wr_ctrl == 3'b100) 
        byte_en = 8'b11111111; // Write all bytes
    else
        byte_en = 8'b00000000;  // 默认值
end

// 数据存储写入
always@(*)
begin
    if((byte_en != 8'b0))
    begin
        dm_din_a = 64'b0;
        case(byte_en)
            8'b00000001: dm_din_a[7:0] = dm_din[7:0];
            8'b00000010: dm_din_a[15:8] = dm_din[15:8];
            8'b00000100: dm_din_a[23:16] = dm_din[23:16];
            8'b00001000: dm_din_a[31:24] = dm_din[31:24];
            8'b00010000: dm_din_a[39:32] = dm_din[39:32];
            8'b00100000: dm_din_a[47:40] = dm_din[47:40];
            8'b01000000: dm_din_a[55:48] = dm_din[55:48];
            8'b10000000: dm_din_a[63:56] = dm_din[63:56];
            8'b00001111: dm_din_a[31:0] = dm_din[31:0];
            8'b11110000: dm_din_a[63:32] = dm_din[63:32];
            8'b11111111: dm_din_a = dm_din;
        endcase
    end
end

endmodule