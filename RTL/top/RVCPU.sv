`timescale 1ns / 1ns

module RVCPU(
input clk,
input rst,
output [7:0] led,
input uart_rxd, // uart 接收端
output uart_txd // uart 发送端
);

// ------------sys_bus连接到rom和dram----------------------------
wire [63:0] im_addr_mem0;
wire [31:0] im_dout_mem0;
wire [2:0] dm_rd_ctrl_mem;
wire [2:0] dm_wr_ctrl_mem;
wire [63:0] dm_addr_mem;
wire [63:0] dm_din_mem;
wire [63:0] dm_dout_mem;
wire [1:0] state;
// ----------------------------------------------------------------

// ------------sys_bus连接到uart-------------------------------
wire [63:0] uart_addr;
wire [31:0] uart_write_data, uart_read_data;
wire uart_wen;
// ---------------------------------------------------------

// ------------sys_bus连接到gpio-------------------------------
wire [63:0] gpio_addr;
wire [63:0] gpio_data_in, gpio_dout;
wire [2:0] gpio_rd_ctrl, gpio_wr_ctrl;
// ---------------------------------------------------------

// ------------id阶段与寄存器堆的连接信号----------------------
wire [63:0] data_reg_read_1, data_reg_read_2; // 寄存器堆返回的数据信号
wire [4:0] addr_reg_read_1, addr_reg_read_2; // 连接源寄存器堆地址
// --------------------------------------------------------

// --------------wb阶段的输出(与寄存器堆的连线)-----------------
wire [63:0] write_data_WB;   // 数据信号
wire [4:0] rd_WB;            // 地址信号
wire reg_write_WB;           // 使能控制信号
// -------------------------------------------------------------

// --------------------连接dram和dram_ctrl的线路----------------------------------
wire [63:0] dm_din_a;
wire write_en;
wire output_en;
wire sram_en;
wire upper_en;
wire lower_en;
wire [18:0] addr_dram_ctrl;
wire [15:0] data;
// ----------------------------------------------------------

// ------------------连接dcache和data_path的信号
wire data_ready;
// wire [63:0] dcache_addr;
// wire [63:0] dcache_din, dcache_dout;
// wire [2:0] dcache_rd_ctrl, dcache_wr_ctrl;

// --------------------连接dcache和dram_ctrl的信号
wire [63:0] dcache_dram_addr;
wire [63:0] dcache_dram_din, dcache_dram_dout;
wire [2:0] dcache_dram_rd_ctrl, dcache_dram_wr_ctrl;


// -------------------data_path-sys_bus-----------------------
wire [63:0] dm_addr, im_addr;
// ------------------------------------------------------------

// ------------------sys_bus wire------------------------------
wire [63:0] bus_addr;
wire [63:0] bus_dout, bus_din;
wire [2:0] bus_wr_ctrl, bus_rd_ctrl;
// ------------------------------------------------------------

// 初始化内存控制器
// module dram_ctrl(
//     input   [2:0]   dm_rd_ctrl,
//     input   [2:0]   dm_wr_ctrl,
//     input   [63:0]  dm_addr,
//     input   [63:0]  dm_din,
//     output reg  [63:0] dm_dout,
//     // 下面用来连接存储芯片
//     input   [63:0]  mem_out,
//     output          write_en,
//     output  reg [63:0] dm_din_a,
//     output wire [63:0] addr
// );
dram_ctrl dram_ctrl0(
    .clk(clk),
    .rst(rst),
    .dm_rd_ctrl(dcache_dram_rd_ctrl),
    .dm_wr_ctrl(dcache_dram_wr_ctrl),
    .dm_addr(dcache_dram_addr),
    .dm_din(dcache_dram_din),
    .dm_dout(dcache_dram_dout),
    .state(state)
);


// 初始化dcache实例
dcache dcache0(
    .clk(clk),
    .rst(rst),
    .addr(dm_addr_mem),
    .din(dm_din_mem),
    .dout(dm_dout_mem),
    .rd_ctrl(dm_rd_ctrl_mem),
    .wr_ctrl(dm_wr_ctrl_mem),
    .data_ready(data_ready),
    .dram_addr(dcache_dram_addr),
    .dram_din(dcache_dram_din),
    .dram_dout(dcache_dram_dout),
    .dram_rd_ctrl(dcache_dram_rd_ctrl),
    .dram_wr_ctrl(dcache_dram_wr_ctrl),
    .state(state)
);

// 初始化rom实例
// module rom(
//     input           clk,
//     input   [63:0]  im_addr,
//     output  reg [31:0]  im_dout
// );
rom rom0(
    .clk(clk),
    .im_addr(im_addr_mem0),
    .im_dout(im_dout_mem0)
);

// 初始化GPIO实例
// module gpio(
//     input               clk,
//     input               rst,
//     input   [63:0]      addr,        // GPIO地址
//     input   [2:0]       rd_ctrl,     // 读取控制信号
//     input   [2:0]       wr_ctrl,     // 写入控制信号
//     input   [63:0]      data_in,     // 写入数据
//     output reg [63:0]   data_out,    // 读取数据
//     output reg          valid        // 数据有效信号
// );

gpio gpio0(
    .clk(clk),
    .rst(rst),
    .addr(gpio_addr),
    .rd_ctrl(gpio_rd_ctrl),
    .wr_ctrl(gpio_wr_ctrl),
    .data_in(gpio_data_in),
    .data_out(gpio_dout),
    .valid()
);

// uart模块初始化
// module uart_top (
// input               clk     , // Top level system clock input.
// input               rst_n    , // reset_n .
// input   wire        uart_rxd, // UART Recieve pin.
// output  wire        uart_txd, // UART transmit pin.
// output  wire [7:0]  led,

// output  [31:0] uart_read_data,     // uart -> cpu
// input   [31:0] uart_write_data,    // cpu -> uart
// input   [31:0] uart_addr,          // cpu -> uart
// input          uart_wen
// );
uart_top uart0(
    .clk(clk),
    .rst_n(!rst),
    .uart_rxd(uart_rxd),
    .uart_txd(uart_txd),
    .led(led),
    .uart_read_data(uart_read_data),
    .uart_write_data(uart_write_data),
    .uart_addr(uart_addr),
    .uart_wen(uart_wen)
);


// // 顶层总线模块
// module system_bus(
//     input               clk,
//     input       [63:0]  addr,          // 系统总线地址
//     input       [63:0]  data_in,       // 输入数据
//     input       [2:0]   rd_ctrl,       // 读取控制信号
//     input       [2:0]   wr_ctrl,       // 写入控制信号
//     output  reg [63:0]  data_out,      // 输出数据
//     output  reg         valid,          // 有效信号
//     // 连接dram_ctrl
//     output [2:0] dm_rd_ctrl,
//     output [2:0] dm_wr_ctrl,
//     output [63:0] dm_addr,
//     output [63:0] dm_din,
//     input [63:0] dram_dout,
//     // 连接rom
//     output [63:0] rom_addr,
//     input [31:0] rom_dout,
//     // 连接gpio
//     output [63:0] gpio_addr,
//     output [63:0] gpio_data_in,
//     input [63:0] gpio_dout,
//     output [2:0] gpio_wr_ctrl,
//     // 连接uart
//     output [63:0] uart_addr,
//     output [31:0] uart_write_data,
//     input [31:0] uart_read_data,
//     output uart_wen
// );
system_bus bus0(
    .clk(clk),
    .addr(bus_addr),
    .data_in(bus_din),
    .rd_ctrl(bus_rd_ctrl),
    .wr_ctrl(bus_wr_ctrl),
    .data_out(bus_dout),
    .valid(),
    .gpio_addr(gpio_addr),
    .gpio_data_in(gpio_data_in),
    .gpio_dout(gpio_dout),
    .gpio_wr_ctrl(gpio_wr_ctrl),
    .gpio_rd_ctrl(gpio_rd_ctrl),
    .uart_addr(uart_addr),
    .uart_write_data(uart_write_data),
    .uart_read_data(uart_read_data),
    .uart_wen(uart_wen)
);

// 顶层模块初始化寄存器堆
reg_file reg_file0(
	.clk        (clk),
	.A1         (addr_reg_read_1), // Read 1
	.A2         (addr_reg_read_2), // Read 2
	.A3         (rd_WB), // Write
	.WD         (write_data_WB), // Write data [63:0]
	.WE         (reg_write_WB), // Write Enable (high)
	.RD1        (data_reg_read_1), // Read 1 data [63:0]
	.RD2        (data_reg_read_2)  // Read 2 data [63:0]
);

// module data_path(
//     input rst,
//     input clk,
//     // -------------到sys_bus的连线---------------------------------
//     output [2:0] bus_rd_ctrl,
//     output [2:0] bus_wr_ctrl,
//     output [63:0] bus_addr,
//     output [63:0] bus_din,
//     input [63:0] bus_dout,
//     // ------------id阶段与寄存器堆的连接信号----------------------
//     input [63:0] data_reg_read_1, data_reg_read_2, // 寄存器堆返回的数据信号
//     output [4:0] addr_reg_read_1, addr_reg_read_2,  // 连接源寄存器堆地址
//     // --------------wb阶段的输出(与寄存器堆的连线)-----------------
//     output [63:0] write_data_WB,   // 数据信号
//     output [4:0] rd_WB,            // 地址信号
//     output reg_write_WB           // 使能控制信号
//     // -------------------------------------------------------------
// );
data_path data_path0(
    .rst(rst),
    .clk(clk),
    .bus_rd_ctrl(bus_rd_ctrl),
    .bus_wr_ctrl(bus_wr_ctrl),
    .bus_addr(bus_addr),
    .bus_din(bus_din),
    .bus_dout(bus_dout),
    .dram_rd_ctrl(dm_rd_ctrl_mem),
    .dram_wr_ctrl(dm_wr_ctrl_mem),
    .dram_addr(dm_addr_mem),
    .dram_din(dm_din_mem),
    .dram_dout(dm_dout_mem),
    .data_ready(data_ready),
    .rom_addr(im_addr_mem0),
    .rom_dout(im_dout_mem0),
    .data_reg_read_1(data_reg_read_1),
    .data_reg_read_2(data_reg_read_2),
    .rs1_IDC(addr_reg_read_1),
    .rs2_IDC(addr_reg_read_2),
    .write_data_WB(write_data_WB),
    .rd_WB(rd_WB),
    .reg_write_WB(reg_write_WB)
);


endmodule