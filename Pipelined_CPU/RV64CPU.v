`timescale 1ns / 1ns
module RVCPU(
input clk,
input rst
);

// ------------data_path连接到rom和dram----------------------------
wire [63:0] im_addr_mem0;
wire [31:0] im_dout_mem0;
wire [2:0] dm_rd_ctrl_mem;
wire [2:0] dm_wr_ctrl_mem;
wire [63:0] dm_addr_mem;
wire [63:0] dm_din_mem;
wire [63:0] dm_dout_mem;
// ----------------------------------------------------------------

// ------------id阶段与寄存器堆的连接信号----------------------
wire [63:0] data_reg_read_1, data_reg_read_2; // 寄存器堆返回的数据信号
wire [4:0] addr_reg_read_1, addr_reg_read_2; // 连接源寄存器堆地址
// --------------------------------------------------------

// --------------wb阶段的输出(与寄存器堆的连线)-----------------
wire [63:0] write_data_WB;   // 数据信号
wire [4:0] rd_WB;            // 地址信号
wire reg_write_WB;           // 使能控制信号
// -------------------------------------------------------------

// 连接dram和dram_ctrl的线路----------------------------------
wire [63:0] dm_din_a;
wire write_en;
wire [63:0] addr_dram_ctrl;
wire [63:0] mem_out;
// -----------------------------------------------------

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
    .dm_rd_ctrl(dm_rd_ctrl_mem),
    .dm_wr_ctrl(dm_wr_ctrl_mem),
    .dm_addr(dm_addr_mem),
    .dm_din(dm_din_mem),
    .dm_dout(dm_dout_mem),
    .mem_out(mem_out),
    .write_en(write_en),
    .dm_din_a(dm_din_a),
    .addr(addr_dram_ctrl)
);

// 初始化dram实例
dram dram0 (
    .clk(clk),
    .addr(addr_dram_ctrl),
    .dm_din(dm_din_a),
    .write_en(write_en),
    .mem_out(mem_out)
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
//     // -------------到dram和rom的连线------------------------------
//     output [63:0] im_addr_mem0,
//     input [31:0] im_dout_mem0,
//     output [2:0] dm_rd_ctrl_mem,
//     output [2:0] dm_wr_ctrl_mem,
//     output [63:0] dm_addr_mem,
//     output [63:0] dm_din_mem,
//     input [63:0] dm_dout_mem,
//     // ------------id阶段与寄存器堆的连接信号----------------------
//     input [63:0] data_reg_read_1, data_reg_read_2, // 寄存器堆返回的数据信号
//     output [4:0] addr_reg_read_1, addr_reg_read_2,  // 连接源寄存器堆地址
// // --------------wb阶段的输出(与寄存器堆的连线)-----------------
// input [63:0] write_data_WB,   // 数据信号
// output [4:0] rd_WB,            // 地址信号
// output reg_write_WB           // 使能控制信号
// // -------------------------------------------------------------
// );
data_path data_path0(
    .rst(rst),
    .clk(clk),
    .im_addr_mem0(im_addr_mem0),
    .im_dout_mem0(im_dout_mem0),
    .dm_rd_ctrl_mem(dm_rd_ctrl_mem),
    .dm_wr_ctrl_mem(dm_wr_ctrl_mem),
    .dm_addr_mem(dm_addr_mem),
    .dm_din_mem(dm_din_mem),
    .dm_dout_mem(dm_dout_mem),
    .data_reg_read_1(data_reg_read_1),
    .data_reg_read_2(data_reg_read_2),
    .addr_reg_read_1(addr_reg_read_1),
    .addr_reg_read_2(addr_reg_read_2),
    .write_data_WB(write_data_WB),
    .rd_WB(rd_WB),
    .reg_write_WB(reg_write_WB)
);

endmodule
