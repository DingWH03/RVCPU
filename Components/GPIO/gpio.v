`timescale 1ns / 1ns
module gpio(
    input               clk,
    input               rst,
    input   [63:0]      addr,        // GPIO地址
    input   [2:0]       rd_ctrl,     // 读取控制信号
    input   [2:0]       wr_ctrl,     // 写入控制信号
    input   [63:0]      data_in,     // 写入数据
    output reg [63:0]   data_out,    // 读取数据
    output reg          valid        // 数据有效信号
);

reg [63:0] gpio_data; // GPIO寄存器

// 读操作
always @(*) begin
    valid = 1'b0;
    data_out = 64'b0;
    
    if (rd_ctrl != 3'b000) begin
        valid = 1'b1;  // 标记数据有效
        
        case (rd_ctrl)
            3'b001: data_out = {{56{1'b0}}, gpio_data[7:0]};    // 8-bit read
            3'b011: data_out = {{48{1'b0}}, gpio_data[15:0]};   // 16-bit read
            3'b101: data_out = gpio_data;                       // 64-bit read
            default: data_out = 64'b0;
        endcase
    end
end

// 写操作
always @(posedge clk or posedge rst) begin
    if (rst) begin
        gpio_data <= 64'b0;
    end else if (wr_ctrl != 3'b000) begin
        case (wr_ctrl)
            3'b001: begin // 8-bit write
                case (addr[2:0])
                    3'b000: gpio_data[7:0]   <= data_in[7:0];
                    3'b001: gpio_data[15:8]  <= data_in[7:0];
                    3'b010: gpio_data[23:16] <= data_in[7:0];
                    3'b011: gpio_data[31:24] <= data_in[7:0];
                    3'b100: gpio_data[39:32] <= data_in[7:0];
                    3'b101: gpio_data[47:40] <= data_in[7:0];
                    3'b110: gpio_data[55:48] <= data_in[7:0];
                    3'b111: gpio_data[63:56] <= data_in[7:0];
                endcase
            end
            3'b011: gpio_data[31:0] <= data_in[31:0];  // 32-bit write
            3'b100: gpio_data <= data_in;              // 64-bit write
        endcase
    end
end

endmodule
