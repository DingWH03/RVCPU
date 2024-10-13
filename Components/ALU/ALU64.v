module ALU(
input [63:0] SrcA, SrcB,
input [3:0]  func,
output reg [63:0] ALUout
);

wire signed [63:0] signed_a;
wire signed [63:0] signed_b;

assign signed_a = SrcA;
assign signed_b = SrcB;

always@(*)
begin
  case(func)
      4'b0000: ALUout = signed_a + signed_b;                    // 加法
      4'b1000: ALUout = signed_a - signed_b;                    // 减法
      4'b0001: ALUout = signed_a << signed_b[5:0];              // 左移，64位需要6位的移位量
      4'b0010: ALUout = signed_a < signed_b ? 1 : 0;            // 有符号小于
      4'b0011: ALUout = SrcA < SrcB ? 1 : 0;                    // 无符号小于
      4'b0100: ALUout = signed_a ^ signed_b;                    // 异或
      4'b0101: ALUout = signed_a >> signed_b[5:0];              // 逻辑右移，64位需要6位的移位量
      4'b1101: ALUout = signed_a >>> signed_b[5:0];             // 算术右移
      4'b0110: ALUout = signed_a | signed_b;                    // 或
      4'b0111: ALUout = signed_a & signed_b;                    // 与
      4'b1110: ALUout = SrcB;                                   // 直接输出SrcB
      default: ALUout = 0;                                      // 默认输出0
  endcase
end 

endmodule
