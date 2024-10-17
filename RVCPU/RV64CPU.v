module RVCPU(
input clk,
input rst
);

reg [63:0] pc_ID;
reg [31:0] inst_ID;

wire [31:0] inst_IF;
wire [63:0] pc_IF_wire;
reg [63:0] pc_IF, pc_EX, pc_MEM, pc_WB;
assign pc_IF_wire = pc_IF;

wire [63:0] pc_plus4_IF, pc_plus4_ID;

reg [63:0] imm_out_EX;
wire [63:0] imm_out_ID, imm_out_EX_wire; 
assign imm_out_EX_wire = imm_out_EX;

reg [63:0] rf_wd_WB;

wire [63:0] rf_wd_WB_wire, rf_rd1_ID, rf_rd2_ID;  
assign rf_wd_WB_wire = rf_wd_WB;

reg [63:0] alu_out_MEM;

wire [63:0] alu_out_EX, alu_out_MEM_wire;
reg [63:0] alu_out_WB;
assign alu_out_MEM_wire = alu_out_MEM;

wire [63:0] dm_dout_MEM;
reg [63:0] dm_dout_WB;  

reg [1:0] rf_wr_sel_WB;
wire [1:0] rf_wr_sel_WB_wire;
assign rf_wr_sel_WB_wire = rf_wr_sel_WB;

reg rf_wr_en_WB;
wire rf_wr_en_WB_wire;
assign rf_wr_en_WB_wire = rf_wr_en_WB;

wire do_jump_ID, JUMP_EX;
wire [63:0] alu_a_EX, alu_b_EX;
wire [3:0] alu_ctrl_EX;
wire alu_a_sel_EX, alu_b_sel_EX;
wire [2:0] comp_ctrl_ID, comp_ctrl_EX;
wire BrE_EX, BrE_MEM;

wire [2:0] dm_rd_ctrl_MEM;
wire [1:0] dm_wr_ctrl_MEM;

// IF阶段
assign pc_plus4_IF = pc_IF + 64'h4;

// IF/ID流水线寄存器
always@(posedge clk or posedge rst) begin
    if (rst) begin
        pc_ID <= 64'b0;
        inst_ID <= 32'b0;
    end else begin
        pc_ID <= pc_plus4_IF;
        inst_ID <= inst_IF;
    end
end

// ID阶段
reg_file reg_file0(
    .clk(clk),
    .A1(inst_ID[19:15]),
    .A2(inst_ID[24:20]),
    .A3(inst_ID[11:7]),
    .WD(rf_wd_WB_wire),
    .WE(rf_wr_en_WB),
    .RD1(rf_rd1_ID),  // rf_rd1_ID 是 wire
    .RD2(rf_rd2_ID)   // rf_rd2_ID 是 wire
);

imm imm0(
    .inst(inst_ID),
    .out(imm_out_ID)  // imm_out_ID 是 wire
);

// ID/EX流水线寄存器
always@(posedge clk or posedge rst) begin
    if (rst) begin
        pc_EX <= 64'b0;
        imm_out_EX <= 64'b0;
        comp_ctrl_EX <= 3'b0;   // 比较器控制信号
        alu_a_sel_EX <= 1'b0;   // ALU A源选择信号
        alu_b_sel_EX <= 1'b0;   // ALU B源选择信号
        alu_ctrl_EX <= 4'b0;    // ALU控制信号
        BrE_EX <= 1'b0;         // 分支执行信号
    end else begin
        pc_EX <= pc_ID;
        imm_out_EX <= imm_out_ID;
        comp_ctrl_EX <= comp_ctrl_ID;
        alu_a_sel_EX <= alu_a_sel_EX;
        alu_b_sel_EX <= alu_b_sel_EX;
        alu_ctrl_EX <= alu_ctrl_EX;
        BrE_EX <= BrE_EX;
    end
end


// EX阶段
assign JUMP_EX = BrE_EX || do_jump_ID;
assign alu_a_EX = alu_a_sel_EX ? rf_rd1_ID : pc_EX;
assign alu_b_EX = alu_b_sel_EX ? imm_out_EX : rf_rd2_ID;

ALU alu0(
    .SrcA(alu_a_EX),
    .SrcB(alu_b_EX),
    .func(alu_ctrl_EX),
    .ALUout(alu_out_EX)  // alu_out_EX 是 wire
);

// EX/MEM流水线寄存器
always@(posedge clk or posedge rst) begin
    if (rst) begin
        pc_MEM <= 64'b0;
        alu_out_MEM <= 64'b0;
        dm_rd_ctrl_MEM <= 3'b0;  // 数据存储器读控制信号
        dm_wr_ctrl_MEM <= 2'b0;  // 数据存储器写控制信号
        BrE_MEM <= 1'b0;         // 分支执行信号
    end else begin
        pc_MEM <= pc_EX;
        alu_out_MEM <= alu_out_EX;
        dm_rd_ctrl_MEM <= dm_rd_ctrl_MEM;
        dm_wr_ctrl_MEM <= dm_wr_ctrl_MEM;
        BrE_MEM <= BrE_EX;
    end
end


// MEM阶段
mem mem0(
    .clk(clk),
    .im_addr(pc_MEM),
    .im_dout(inst_IF),  // 取指阶段的指令
    .dm_rd_ctrl(dm_rd_ctrl_MEM),
    .dm_wr_ctrl(dm_wr_ctrl_MEM),
    .dm_addr(alu_out_MEM),
    .dm_din(rf_rd2_ID), // 从ID阶段传过来的rf_rd2_ID
    .dm_dout(dm_dout_MEM)  // dm_dout_MEM 是 wire
);

// MEM/WB流水线寄存器
always@(posedge clk or posedge rst) begin
    if (rst) begin
        pc_WB <= 64'b0;
        dm_dout_WB <= 64'b0;
        alu_out_WB <= 64'b0;
        rf_wr_sel_WB <= 2'b0;  // 写回选择信号
        rf_wr_en_WB <= 1'b0;   // 写回使能信号
    end else begin
        pc_WB <= pc_MEM;
        dm_dout_WB <= dm_dout_MEM;
        alu_out_WB <= alu_out_MEM;
        rf_wr_sel_WB <= rf_wr_sel_WB;
        rf_wr_en_WB <= rf_wr_en_WB;
    end
end


// WB阶段
always@(*) begin
    case(rf_wr_sel_WB)
        2'b00:  rf_wd_WB = 64'h0;
        2'b01:  rf_wd_WB = pc_WB;
        2'b10:  rf_wd_WB = alu_out_WB;
        2'b11:  rf_wd_WB = dm_dout_WB;
        default:rf_wd_WB = 64'h0;
    endcase
end

// 控制信号的传递
ctrl ctrl0(
    .inst(inst_ID),        // 译码阶段使用的指令
    .rf_wr_en(rf_wr_en_WB),
    .rf_wr_sel(rf_wr_sel_WB_wire),
    .do_jump(do_jump_ID),
    .BrType(comp_ctrl_ID),
    .alu_a_sel(alu_a_sel_EX),
    .alu_b_sel(alu_b_sel_EX),
    .alu_ctrl(alu_ctrl_EX),
    .dm_rd_ctrl(dm_rd_ctrl_MEM),
    .dm_wr_ctrl(dm_wr_ctrl_MEM)
);

// PC模块
PC	pc0(
    .clk(clk),
    .rst(rst),
    .JUMP(JUMP_EX),
    .JUMP_PC(pc_EX + imm_out_EX_wire),
    .pc(pc_IF_wire)  // 给出当前取指阶段的PC
);

branch branch0(
    .REG1(rf_rd1_ID),
    .REG2(rf_rd2_ID),
    .Type(comp_ctrl_EX),
    .BrE(BrE_EX)
);

endmodule
