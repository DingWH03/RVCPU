`timescale 1ns / 1ns
module mctrl(
    input  logic    [31:0]  inst,
    output logic            rf_wr_en,
    output logic    [1:0]   rf_wr_sel,
    output logic          alu_a_sel,
    output logic           alu_b_sel,
    output logic    [3:0]   alu_ctrl,
    output logic            m_sel
);
// RV32M, RV64M指令
logic is_mul;
logic ls_mulh;
logic is_mulhsu;
logic is_mulhu;
logic is_div;
logic is_divu;
logic is_rem;
logic is_remu;

// RV64M指令
logic is_mulw;
logic is_divw;
logic is_divuw;
logic is_remw;
logic is_remuw;

logic is_m_type;
logic is_mw_type;

logic    [6:0]   opcode;
logic    [2:0]   funct3;
logic    [6:0]   funct7;

assign  opcode  = inst[6:0];
assign  funct7  = inst[31:25];
assign  funct3  = inst[14:12];

/// 跟先识别指令种类，哪种方法好？assign is_m_type = (opcode == 7'b0110011);

assign is_mul = (opcode == 7'b0110011) && (funct3 == 3'b000) && (funct7 == 7'b0000001);
assign is_mulh = (opcode == 7'b0110011) && (funct3 == 3'b001) && (funct7 == 7'b0000001);
assign is_mulhsu = (opcode == 7'b0110011) && (funct3 == 3'b010) && (funct7 == 7'b0000001);
assign is_mulhu = (opcode == 7'b0110011) && (funct3 == 3'b011) && (funct7 == 7'b0000001);
assign is_div = (opcode == 7'b0110011) && (funct3 == 3'b100) && (funct7 == 7'b0000001);
assign is_divu = (opcode == 7'b0110011) && (funct3 == 3'b101) && (funct7 == 7'b0000001);
assign is_rem = (opcode == 7'b0110011) && (funct3 == 3'b110) && (funct7 == 7'b0000001);
assign is_remu = (opcode == 7'b0110011) && (funct3 == 3'b111) && (funct7 == 7'b0000001);

assign is_mulw = (opcode == 7'b0111011) && (funct3 == 3'b000) && (funct7 == 7'b0000001);
assign is_divw = (opcode == 7'b0111011) && (funct3 == 3'b100) && (funct7 == 7'b0000001);
assign is_divuw = (opcode == 7'b0111011) && (funct3 == 3'b101) && (funct7 == 7'b0000001);
assign is_remw = (opcode == 7'b0111011) && (funct3 == 3'b110) && (funct7 == 7'b0000001);
assign is_remuw = (opcode == 7'b0111011) && (funct3 == 3'b111) && (funct7 == 7'b0000001);

assign is_m_type = is_mul | is_mulh | is_mulhsu | is_mulhu | 
                    is_div | is_divu | is_rem | is_remu ;
assign is_mw_type = is_mulw | is_divw | is_divuw | is_remw | is_remuw;
assign m_sel = is_m_type | is_mw_type;

assign rf_wr_en = m_sel;
assign rf_wr_sel = m_sel ? 2'b10 : 2'b00;

assign alu_a_sel = 1'b1;
assign alu_b_sel = 1'b0;

always_comb begin
    alu_ctrl[3] = is_mw_type & ~is_m_type;
    if (is_mw_type | is_m_type) begin
        alu_ctrl[2:0] = funct3;
    end else begin
        alu_ctrl = 3'b000;
    end
end

endmodule