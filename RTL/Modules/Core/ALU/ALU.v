`timescale 1ns / 1ns
module ALU(
input [63:0] SrcA, SrcB,
input [3:0]  func,
output reg [63:0] ALUout
);

wire signed [63:0] signed_a;
wire signed [63:0] signed_b;

assign signed_a = SrcA;
assign signed_b = SrcB;

    // 定义func常量
    localparam FUNC_ADD         = 4'b0000; // 加法
    localparam FUNC_SUB         = 4'b1000; // 减法
    localparam FUNC_SLL         = 4'b0001; // 左移
    localparam FUNC_SLT         = 4'b0010; // 有符号小于
    localparam FUNC_SLTU        = 4'b0011; // 无符号小于
    localparam FUNC_XOR         = 4'b0100; // 异或
    localparam FUNC_SRL         = 4'b0101; // 逻辑右移
    localparam FUNC_SRA         = 4'b1101; // 算术右移
    localparam FUNC_OR          = 4'b0110; // 或
    localparam FUNC_AND         = 4'b0111; // 与
    localparam FUNC_PASS_B      = 4'b1110; // 直接输出SrcB

    always @(*) begin
        case(func)
            FUNC_ADD:    ALUout = signed_a + signed_b;                    // 加法
            FUNC_SUB:    ALUout = signed_a - signed_b;                    // 减法
            FUNC_SLL:    ALUout = signed_a << signed_b[5:0];              // 左移，64位需要6位的移位量
            FUNC_SLT:    ALUout = signed_a < signed_b ? 1 : 0;            // 有符号小于
            FUNC_SLTU:   ALUout = SrcA < SrcB ? 1 : 0;                    // 无符号小于
            FUNC_XOR:    ALUout = signed_a ^ signed_b;                    // 异或
            FUNC_SRL:    ALUout = signed_a >> signed_b[5:0];              // 逻辑右移
            FUNC_SRA:    ALUout = signed_a >>> signed_b[5:0];             // 算术右移
            FUNC_OR:     ALUout = signed_a | signed_b;                    // 或
            FUNC_AND:    ALUout = signed_a & signed_b;                    // 与
            FUNC_PASS_B: ALUout = signed_b;                               // 直接输出SrcB
            default:     ALUout = 0;                                      // 默认输出0
        endcase
    end

endmodule
