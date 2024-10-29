`timescale 1ns / 1ns

// 顶层总线模块
module system_bus(
    input               clk,
    input       [63:0]  addr,          // 系统总线地址
    input       [63:0]  data_in,       // 输入数据
    input       [2:0]   rd_ctrl,       // 读取控制信号
    input       [2:0]   wr_ctrl,       // 写入控制信号
    output  reg [63:0]  data_out,      // 输出数据
    output  reg         valid          // 有效信号
);

// 地址解码
wire is_dram = (addr >= 64'h80000000) && (addr < 64'h80001000);  // DRAM地址范围
wire is_rom  = (addr < 64'h00004000);                            // ROM地址范围
wire is_gpio = (addr >= 64'h40000000) && (addr < 64'h40000010);  // GPIO地址范围（假设4个寄存器）

// 中间连接信号
wire [63:0] dram_dout;
wire [31:0] rom_dout;
wire [31:0] gpio_dout;

// DRAM 模块实例
dram dram_inst(
    .clk(clk),
    .dm_rd_ctrl(rd_ctrl),
    .dm_wr_ctrl(wr_ctrl),
    .dm_addr(addr),
    .dm_din(data_in),
    .dm_dout(dram_dout)
);

// ROM 模块实例
rom rom_inst(
    .clk(clk),
    .im_addr(addr),
    .im_dout(rom_dout)
);

// GPIO 模块实例
gpio gpio_inst(
    .clk(clk),
    .addr(addr),
    .data_in(data_in[31:0]),  // GPIO为32位数据宽度
    .wr_ctrl(wr_ctrl),
    .data_out(gpio_dout)
);

// 根据地址范围选择输出
always @(*) begin
    if (is_dram) begin
        data_out = dram_dout;
        valid = 1'b1; // DRAM 有效
    end else if (is_rom) begin
        data_out = {32'b0, rom_dout}; // 将32位ROM数据扩展为64位
        valid = 1'b1; // ROM 有效
    end else if (is_gpio) begin
        data_out = {32'b0, gpio_dout}; // 将32位GPIO数据扩展为64位
        valid = 1'b1; // GPIO 有效
    end else begin
        data_out = 64'b0;
        valid = 1'b0; // 地址无效
    end
end

endmodule