module imm(
input       [31:0] inst,
output reg  [63:0] out
);

wire    [6:0] opcode;
assign  opcode = inst[6:0];

// 初始化输出
initial out = 64'b0;

always@(*)
begin
    case(opcode)
        // AUIPC 和 LUI 类型指令：立即数位于[31:12]，需要扩展到64位
        7'b0010111: begin  // AUIPC
            out[31:12] = inst[31:12];
            out[63:32] = {32{out[31]}};  // 符号扩展
        end
        7'b0110111: begin  // LUI
            out[31:12] = inst[31:12];
            out[63:32] = 32'b0;  // 无符号扩展，LUI指令的高位扩展为0
        end

        // B 型指令：符号扩展的立即数
        7'b1100011: begin  // B type
            out[12] = inst[31];
            out[11] = inst[7];
            out[10:5] = inst[30:25];
            out[4:1] = inst[11:8];
            out[0] = 1'b0;  // 分支指令立即数最低位为0
            out[63:13] = {51{out[12]}};  // 符号扩展
        end

        // JAL 类型指令：符号扩展的立即数
        7'b1101111: begin  // JAL
            out[20] = inst[31];
            out[19:12] = inst[19:12];
            out[11] = inst[20];
            out[10:1] = inst[30:21];
            out[0] = 1'b0;  // JAL 的立即数最低位为0
            out[63:21] = {43{out[20]}};  // 符号扩展
        end

        // JALR、LOAD 和 I 型指令：12位立即数，符号扩展到64位
        7'b1100111, 7'b0000011, 7'b0010011: begin  // JALR, LOAD, I type
            out[11:0] = inst[31:20];
            out[63:12] = {52{out[11]}};  // 符号扩展
        end

        // S 型指令：将立即数的高5位和低7位拼接，符号扩展到64位
        7'b0100011: begin  // S type
            out[11:5] = inst[31:25];
            out[4:0] = inst[11:7];
            out[63:12] = {52{out[11]}};  // 符号扩展
        end

        default: out = 64'b0;  // 默认输出为0
    endcase
end

endmodule
