`timescale 1ns / 1ns
module RVCPU(
input clk,
input rst
);

wire [63:0] im_addr;
wire [31:0] im_dout;
wire [2:0] dm_rd_ctrl;
wire [2:0] dm_wr_ctrl;
wire [63:0] dm_addr;
wire [63:0] dm_din;
wire [63:0] dm_dout;

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
    .dm_rd_ctrl(dm_rd_ctrl),
    .dm_wr_ctrl(dm_wr_ctrl),
    .dm_addr(dm_addr),
    .dm_din(dm_din),
    .dm_dout(dm_dout),
    .mem_out(mem_out),
    .write_en(write_en),
    .dm_din_a(dm_din_a),
    .addr(addr_dram_ctrl)
);

// 连接dram和dram_ctrl的线路----------------------------------
wire [63:0] dm_din_a;
wire write_en;
wire [63:0] addr_dram_ctrl;
wire [63:0] mem_out;
// -----------------------------------------------------

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
    .im_addr(im_addr),
    .im_dout(im_dout)
);

wire    [31:0]  inst;

wire    [1:0]   rf_wr_sel;
reg     [63:0]  rf_wd;  
wire            rf_wr_en;
wire    [63:0]  rf_rd1,rf_rd2;
  
wire [63:0] pc;
wire [63:0] pc_plus4;
wire do_jump;
wire is_branch;
wire JUMP;
  
wire    [63:0]  imm_out;
  
wire    [2:0]   comp_ctrl;
wire		BrE;

wire            alu_a_sel;
wire            alu_b_sel;
wire    [63:0]  alu_a,alu_b,alu_out; 
wire    [3:0]   alu_ctrl;
  
// wire    [2:0]   dm_rd_ctrl;
// wire    [2:0]   dm_wr_ctrl;
// wire    [63:0]  dm_dout;
  
always@(*)
begin
    case(rf_wr_sel)
    2'b00:  rf_wd = 64'h0;
    2'b01:  rf_wd = pc_plus4;
    2'b10:  rf_wd = alu_out;
    2'b11:  rf_wd = dm_dout;
    default:rf_wd = 64'h0;
    endcase
end
assign		pc_plus4 = pc + 64'h4;
assign		JUMP = (is_branch && BrE) || do_jump;
assign      alu_a = alu_a_sel ? rf_rd1 : pc ;
assign      alu_b = alu_b_sel ? imm_out : rf_rd2 ;

assign im_addr = pc;
assign inst = im_dout;
assign dm_addr = alu_out;
assign dm_din = rf_rd2;


reg_file reg_file0(
	.clk        (clk),
	.A1         (inst[19:15]),
	.A2         (inst[24:20]),
	.A3         (inst[11:7]),
	.WD         (rf_wd),
	.WE         (rf_wr_en),
	.RD1        (rf_rd1),
	.RD2        (rf_rd2)
);
PC	pc0(
    .clk        (clk),
    .rst		(rst),
    .JUMP		(JUMP),
	.JUMP_PC    (pc+imm_out),
	.stall		(1'b0),
	.pc         (pc)
);
imm	imm0(
	.inst		(inst),
	.out    	(imm_out)
);
branch branch0(
	.REG1		(rf_rd1),
	.REG2		(rf_rd2),
	.Type		(comp_ctrl),
 	.BrE		(BrE)
);
ALU alu0(
    .SrcA     	(alu_a),
	.SrcB      	(alu_b),
	.func   	(alu_ctrl),
	.ALUout    	(alu_out)
);

ctrl ctrl0(
	.inst       (inst),
	.rf_wr_en   (rf_wr_en),
	.rf_wr_sel  (rf_wr_sel),
	.do_jump    (do_jump),
	.is_branch(is_branch),
	.BrType		(comp_ctrl),
	.alu_a_sel  (alu_a_sel),
	.alu_b_sel  (alu_b_sel),
	.alu_ctrl   (alu_ctrl),
	.dm_rd_ctrl (dm_rd_ctrl),
	.dm_wr_ctrl (dm_wr_ctrl),
	.opcode(inst[6:0]),
	.funct7(inst[31:25]),
	.funct3(inst[14:12])
);

endmodule