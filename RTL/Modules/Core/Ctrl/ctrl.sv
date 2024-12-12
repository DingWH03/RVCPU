`timescale 1ns / 1ns
module ctrl(
input  logic    [31:0]  inst,
output logic           rf_wr_en,
output logic    [1:0]   rf_wr_sel,
output logic           do_jump,
output logic           is_branch,
output logic    [2:0]   BrType,
output logic          alu_a_sel,
output logic           alu_b_sel,
output logic    [3:0]   alu_ctrl,
output logic    [2:0]   dm_rd_ctrl,
output logic    [2:0]   dm_wr_ctrl,
output logic               is_debug,
output logic               is_syscall,
output logic    is_rs1_used,
output logic    is_rs2_used // 新加入信号
);

logic    is_lui;
logic    is_auipc;
logic    is_jal;
logic    is_jalr;
logic    is_beq;
logic    is_bne;
logic    is_blt;
logic    is_bge;
logic    is_bltu;
logic    is_bgeu;
logic    is_lb;
logic    is_lh;
logic    is_lw;
logic    is_lbu;
logic    is_lhu;
logic    is_sb;
logic    is_sh;
logic    is_sw;
logic    is_addi;
logic    is_slti;
logic    is_sltiu;
logic    is_xori;
logic    is_ori;
logic    is_andi;
logic    is_slli;
logic    is_srli;
logic    is_srai;
logic    is_add;
logic    is_sub;
logic    is_sll;
logic    is_slt;
logic    is_sltu;
logic    is_xor;
logic    is_srl;
logic    is_sra;
logic    is_or;
logic    is_and;

logic    is_ld; // 64位load
logic    is_sd; // 64位store

logic    is_ebreak;
logic    is_ecall;

logic    is_add_type;
logic    is_u_type;
logic    is_jump_type;
logic    is_b_type;
logic    is_r_type;
logic    is_i_type;
logic    is_s_type;

logic    [6:0]   opcode;
logic    [2:0]   funct3;
logic    [6:0]   funct7;

assign  opcode  = inst[6:0];
assign  funct7  = inst[31:25];
assign  funct3  = inst[14:12];

assign  is_lui  = (opcode == 7'h37) ;
assign  is_auipc= (opcode == 7'h17) ;
assign  is_jal  = (opcode == 7'h6F) ;
assign  is_jalr = (opcode == 7'h67) && (funct3 ==3'h0) ;
assign  is_beq  = (opcode == 7'h63) && (funct3 ==3'h0) ;
assign  is_bne  = (opcode == 7'h63) && (funct3 ==3'h1) ;
assign  is_blt  = (opcode == 7'h63) && (funct3 ==3'h4) ;
assign  is_bge  = (opcode == 7'h63) && (funct3 ==3'h5) ;
assign  is_bltu = (opcode == 7'h63) && (funct3 ==3'h6) ;
assign  is_bgeu = (opcode == 7'h63) && (funct3 ==3'h7) ;
assign  is_lb   = (opcode == 7'h03) && (funct3 ==3'h0) ;
assign  is_lh   = (opcode == 7'h03) && (funct3 ==3'h1) ;
assign  is_lw   = (opcode == 7'h03) && (funct3 ==3'h2) ;
assign  is_lbu  = (opcode == 7'h03) && (funct3 ==3'h4) ;
assign  is_lhu  = (opcode == 7'h03) && (funct3 ==3'h5) ;
assign  is_sb   = (opcode == 7'h23) && (funct3 ==3'h0) ;
assign  is_sh   = (opcode == 7'h23) && (funct3 ==3'h1) ;
assign  is_sw   = (opcode == 7'h23) && (funct3 ==3'h2) ;

assign  is_ld   = (opcode == 7'h03) && (funct3 == 3'b011);  // 64位加载
assign  is_sd   = (opcode == 7'h23) && (funct3 == 3'b011);  // 64位存储
assign  is_ebreak = (inst == 32'b00000000000100000000000001110011);
assign  is_ecall = (inst == 32'b00000000000000000000000001110011);

assign  is_addi = (opcode == 7'h13) && (funct3 ==3'h0) ;
assign  is_slti = (opcode == 7'h13) && (funct3 ==3'h2) ;
assign  is_sltiu= (opcode == 7'h13) && (funct3 ==3'h3) ;
assign  is_xori = (opcode == 7'h13) && (funct3 ==3'h4) ;
assign  is_ori  = (opcode == 7'h13) && (funct3 ==3'h6) ;
assign  is_andi = (opcode == 7'h13) && (funct3 ==3'h7) ;
assign  is_slli = (opcode == 7'h13) && (funct3 ==3'h1) && (funct7 == 7'h00);
assign  is_srli = (opcode == 7'h13) && (funct3 ==3'h5) && (funct7 == 7'h00);
assign  is_srai = (opcode == 7'h13) && (funct3 ==3'h5) && (funct7 == 7'h20);
assign  is_add  = (opcode == 7'h33) && (funct3 ==3'h0) && (funct7 == 7'h00);
assign  is_sub  = (opcode == 7'h33) && (funct3 ==3'h0) && (funct7 == 7'h20);
assign  is_sll  = (opcode == 7'h33) && (funct3 ==3'h1) && (funct7 == 7'h00);
assign  is_slt  = (opcode == 7'h33) && (funct3 ==3'h2) && (funct7 == 7'h00);
assign  is_sltu = (opcode == 7'h33) && (funct3 ==3'h3) && (funct7 == 7'h00);
assign  is_xor  = (opcode == 7'h33) && (funct3 ==3'h4) && (funct7 == 7'h00);
assign  is_srl  = (opcode == 7'h33) && (funct3 ==3'h5) && (funct7 == 7'h00);
assign  is_sra  = (opcode == 7'h33) && (funct3 ==3'h5) && (funct7 == 7'h20);
assign  is_or   = (opcode == 7'h33) && (funct3 ==3'h6) && (funct7 == 7'h00);
assign  is_and  = (opcode == 7'h33) && (funct3 ==3'h7) && (funct7 == 7'h00);

assign  is_add_type = is_auipc | is_jal | is_jalr | is_b_type | is_s_type 
                    | is_lb | is_lh | is_lw | is_lbu | is_lhu | is_add | is_addi ;
assign  is_u_type   = is_lui | is_auipc ;
assign  is_jump_type= is_jal ;
assign  is_b_type   = is_beq | is_bne | is_blt | is_bge | is_bltu | is_bgeu ;
assign  is_r_type   = is_add | is_sub | is_sll | is_slt | is_sltu | is_xor 
                    | is_srl | is_sra | is_or | is_and ;
assign  is_i_type   = is_jalr | is_ld | is_lb | is_lh | is_lw | is_lbu | is_lhu 
                    | is_addi | is_slti | is_sltiu | is_xori | is_ori | is_andi
                    | is_slli | is_srli | is_srai | is_ebreak | is_ecall;
assign  is_s_type   = is_sd | is_sb | is_sh | is_sw ;
//rf_wr_en  
assign rf_wr_en     =  is_u_type | is_jump_type | is_i_type | is_r_type ;  
  
assign is_rs1_used = is_r_type | is_i_type | is_b_type | is_s_type;
assign is_rs2_used = is_r_type | is_b_type | is_s_type;

//[1:0]rf_wr_sel
always_comb begin
    if (is_jal | is_jalr) rf_wr_sel = 2'b01;
    else if (is_r_type | is_u_type | is_addi | is_slti | is_sltiu |
        is_xori | is_ori | is_andi | is_slli | is_srli | is_srai) 
        rf_wr_sel = 2'b10;
    else if (is_ld | is_lb | is_lh | is_lw | is_lbu | is_lhu) 
        rf_wr_sel = 2'b11;
    else rf_wr_sel = 2'b00;
end

// ecall与ebreak
assign is_syscall = is_ecall;
assign is_debug = is_ebreak;
  
//do_jump
assign do_jump      =  is_jalr | is_jal;

// is_branch
assign is_branch = is_b_type; 
  
//[2:0]BrType
always_comb begin
    if (is_beq) BrType = 3'b010;
    else if (is_bne) BrType = 3'b011;
    else if (is_blt) BrType = 3'b100;
    else if (is_bge) BrType = 3'b101;
    else if (is_bltu) BrType = 3'b110;
    else if (is_bgeu) BrType = 3'b111;
    else BrType = 3'b000;
end
  
//alu_a_sel
assign alu_a_sel    =  is_r_type | is_i_type | is_s_type;

//alu_b_sel  
assign alu_b_sel    =  ~is_r_type ;
  
//alu_ctrl
always_comb begin
     /*待填*/
    if (is_auipc | is_jal | is_jalr | is_b_type | 
        is_s_type | is_jalr | is_lb  | is_lh  | 
        is_lw  | is_lbu | is_lhu | is_add | is_addi) alu_ctrl = 4'b0000;
    else if (is_sub) alu_ctrl = 4'b1000;
    else if (is_sll | is_slli) alu_ctrl = 4'b0001;
    else if (is_srl | is_srli) alu_ctrl = 4'b0101;
    else if (is_sra | is_srai) alu_ctrl = 4'b1101;
    else if (is_slt | is_slti) alu_ctrl = 4'b0010;
    else if (is_sltu | is_sltiu) alu_ctrl = 4'b0011;
    else if (is_xor | is_xori) alu_ctrl = 4'b0100;
    else if (is_or | is_ori) alu_ctrl = 4'b0110;
    else if (is_and | is_andi) alu_ctrl = 4'b0111;
    else if (is_lui) alu_ctrl = 4'b1110;
end
  
//[2:0]dm_rd_ctrl
always_comb begin
    if (is_lb) dm_rd_ctrl = 3'b001;
    else if (is_lbu) dm_rd_ctrl = 3'b010;
    else if (is_lh) dm_rd_ctrl = 3'b011;
    else if (is_lhu) dm_rd_ctrl = 3'b100;
    else if (is_lw) dm_rd_ctrl = 3'b101;
    else if (is_ld) dm_rd_ctrl = 3'b110;  // 新增64位加载控制
    else dm_rd_ctrl = 3'b000;
end

// [2:0] dm_wr_ctrl
always_comb begin
    if (is_sb) dm_wr_ctrl = 3'b001;
    else if (is_sh) dm_wr_ctrl = 3'b010;
    else if (is_sw) dm_wr_ctrl = 3'b011;
    else if (is_sd) dm_wr_ctrl = 3'b100;  // 新增64位存储控制
    else dm_wr_ctrl = 3'b000;  // 默认值
end


endmodule
