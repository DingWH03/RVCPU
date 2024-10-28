`timescale 1ns / 1ns
module branch(         
    input [63:0]  REG1,  // 源操作数1
    input [63:0]  REG2,  // 源操作数2
    input [2:0]   Type,  // 分支类型 (funct3)
    output reg    BrE    // 分支跳转信号
);

wire signed [63:0] signed_REG1;  // 有符号的REG1
wire signed [63:0] signed_REG2;  // 有符号的REG2

// 将输入的寄存器数据赋给有符号变量
assign signed_REG1 = REG1;
assign signed_REG2 = REG2;

always @(*) begin
    case (Type)
        // 3'b000: BEQ (Branch if Equal)
        3'b000: BrE = (signed_REG1 == signed_REG2) ? 1 : 0;

        // 3'b001: BNE (Branch if Not Equal)
        3'b001: BrE = (signed_REG1 != signed_REG2) ? 1 : 0;

        // 3'b100: BLT (Branch if Less Than, signed)
        3'b100: BrE = (signed_REG1 < signed_REG2) ? 1 : 0;

        // 3'b101: BGE (Branch if Greater or Equal, signed)
        3'b101: BrE = (signed_REG1 >= signed_REG2) ? 1 : 0;

        // 3'b110: BLTU (Branch if Less Than, unsigned)
        3'b110: BrE = (REG1 < REG2) ? 1 : 0;    // 无符号比较

        // 3'b111: BGEU (Branch if Greater or Equal, unsigned)
        3'b111: BrE = (REG1 >= REG2) ? 1 : 0;   // 无符号比较

        // 默认不跳转
        default: BrE = 0;
    endcase
end

endmodule
