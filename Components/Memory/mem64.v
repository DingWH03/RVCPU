module mem(
    input           clk,
    input   [63:0]  im_addr,
    output  [31:0]  im_dout,
    input   [2:0]   dm_rd_ctrl,
    input   [1:0]   dm_wr_ctrl,
    input   [63:0]  dm_addr,
    input   [63:0]  dm_din,
    output reg  [63:0]  dm_dout
);

reg     [7:0]   byte_en;
reg     [63:0]  mem[0:4095];   // 修改为64位宽度的数据存储
reg     [63:0]  mem_out;
integer i;

initial
begin
    for(i=0;i<4095;i=i+1) mem[i] = 0;
end

initial
begin
    $readmemh("./meminit/inst.dat",mem);
end

// 读取指令存储（IM）
assign im_dout = {im_addr[31:14], im_addr[2:0]} == 0 ? mem[im_addr[13:3]] : 0;

// 数据存储读取
always@(*)
begin
    case(dm_addr[2:0])
        3'b000:  mem_out = mem[dm_addr[13:3]];
        3'b001:  mem_out = {8'h0,mem[dm_addr[13:3]][63:8]};
        3'b010:  mem_out = {16'h0,mem[dm_addr[13:3]][63:16]};
        3'b011:  mem_out = {24'h0,mem[dm_addr[13:3]][63:24]};
        3'b100:  mem_out = {32'h0,mem[dm_addr[13:3]][63:32]};
        3'b101:  mem_out = {40'h0,mem[dm_addr[13:3]][63:40]};
        3'b110:  mem_out = {48'h0,mem[dm_addr[13:3]][63:48]};
        3'b111:  mem_out = {56'h0,mem[dm_addr[13:3]][63:56]};
    endcase
end

// 数据输出控制
always@(*)
begin
    case(dm_rd_ctrl)                                         
        3'b001: dm_dout = {{56{mem_out[7]}}, {mem_out[7:0]}};
        3'b010: dm_dout = {{56{1'b0}}, {mem_out[7:0]}};
        3'b011: dm_dout = {{48{mem_out[15]}}, {mem_out[15:0]}};
        3'b100: dm_dout = {{48{1'b0}}, {mem_out[15:0]}};
        3'b101: dm_dout = mem_out;   // 64位直接读取
        default: dm_dout = 0;
    endcase
end

// 写使能控制
always@(*)
begin
    if(dm_wr_ctrl == 2'b11)
        byte_en = 8'b11111111;
    else if(dm_wr_ctrl == 2'b10)
    begin
        if(dm_addr[2] == 1'b1) 
            byte_en = 8'b11110000;
        else
            byte_en = 8'b00001111;
    end
    else if(dm_wr_ctrl == 2'b01)
    begin
        case(dm_addr[2:0])
        3'b000:  byte_en = 8'b00000001;
        3'b001:  byte_en = 8'b00000010;
        3'b010:  byte_en = 8'b00000100;
        3'b011:  byte_en = 8'b00001000;
        3'b100:  byte_en = 8'b00010000;
        3'b101:  byte_en = 8'b00100000;
        3'b110:  byte_en = 8'b01000000;
        3'b111:  byte_en = 8'b10000000;
        endcase
    end
    else
        byte_en = 8'b00000000;
end

// 数据存储写入
always@(posedge clk)
begin
    if((byte_en != 8'b0) && (dm_addr[30:12]==19'b0))
    begin
        case(byte_en)
            8'b00000001: mem[dm_addr[13:3]][7:0] = dm_din[7:0];
            8'b00000010: mem[dm_addr[13:3]][15:8] = dm_din[15:8];
            8'b00000100: mem[dm_addr[13:3]][23:16] = dm_din[23:16];
            8'b00001000: mem[dm_addr[13:3]][31:24] = dm_din[31:24];
            8'b00010000: mem[dm_addr[13:3]][39:32] = dm_din[39:32];
            8'b00100000: mem[dm_addr[13:3]][47:40] = dm_din[47:40];
            8'b01000000: mem[dm_addr[13:3]][55:48] = dm_din[55:48];
            8'b10000000: mem[dm_addr[13:3]][63:56] = dm_din[63:56];
            8'b00001111: mem[dm_addr[13:3]][31:0] = dm_din[31:0];
            8'b11110000: mem[dm_addr[13:3]][63:32] = dm_din[63:32];
            8'b11111111: mem[dm_addr[13:3]] = dm_din;
        endcase
    end
end

endmodule
