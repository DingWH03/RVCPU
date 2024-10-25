module RVCPU(
input clk,
input rst,
output [63:0] im_addr,
input [31:0] im_dout,
output [2:0] dm_rd_ctrl,
output [2:0] dm_wr_ctrl,
output [63:0] dm_addr,
output [63:0] dm_din,
input [63:0] dm_dout
);

wire    [31:0]  inst;

wire    [1:0]   rf_wr_sel;
reg     [63:0]  rf_wd;  
wire            rf_wr_en;
wire    [63:0]  rf_rd1,rf_rd2;
  
wire [63:0] pc;
wire [63:0] pc_plus4;
wire do_jump;
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
assign		JUMP = BrE || do_jump;
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