`timescale 1ns / 1ns

// 顶层总线模块
module system_bus(
    input               clk,
    input       [63:0]  addr,          // 系统总线地址
    input       [63:0]  data_in,       // 输入数据
    input       [2:0]   rd_ctrl,       // 读取控制信号
    input       [2:0]   wr_ctrl,       // 写入控制信号
    output  reg [63:0]  data_out,      // 输出数据
    output  reg         valid,          // 有效信号
    // 连接gpio
    output [63:0] gpio_addr,
    output [63:0] gpio_data_in,
    input [63:0] gpio_dout,
    output [2:0] gpio_wr_ctrl,
    output [2:0] gpio_rd_ctrl,
    // 连接uart
    output [63:0] uart_addr,
    output [31:0] uart_write_data,
    input [31:0] uart_read_data,
    output uart_wen
);

// 地址解码
wire is_gpio = (addr >= 64'h40000000) && (addr < 64'h40000010);  // GPIO地址范围（假设4个寄存器）
wire is_uart = (addr >= 64'h50000000) && (addr < 64'h50000010);  // UART地址范围

// 连接GPIO模块
assign gpio_addr = addr;
assign gpio_data_in = data_in;
assign gpio_wr_ctrl = wr_ctrl;

// 连接UART模块
assign uart_addr = addr;
assign uart_write_data = data_in[31:0];  // UART为32位数据宽度
assign uart_wen = (wr_ctrl != 3'b000) && is_uart;

// 根据地址范围选择输出
always @(*) begin
    if (is_gpio) begin
        data_out = {32'b0, gpio_dout}; // 将32位GPIO数据扩展为64位
        valid = 1'b1; // GPIO 有效
    end else if (is_uart) begin
        data_out = {32'b0, uart_read_data}; // 将32位UART数据扩展为64位
        valid = 1'b1; // UART 有效
    end else begin
        data_out = 64'b0;
        valid = 1'b0; // 地址无效
    end
end

endmodule
