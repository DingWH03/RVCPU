module dALU(
    input clk,
    input reset,
    input [63:0] dividend,
    input [63:0] divisor,
    output reg [63:0] quotient,
    output reg [63:0] remainder,
    output reg ready
);
    // 状态和寄存器定义
    reg [63:0] curr_dividend, curr_divisor;
    reg [127:0] temp_remainder;
    integer i;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            quotient <= 0;
            remainder <= 0;
            ready <= 0;
            i <= 64;
        end else begin
            if (i == 64) begin
                temp_remainder = {64'b0, dividend};
                curr_divisor = divisor << 63;
                i = 0;
            end else if (i < 64) begin
                temp_remainder = temp_remainder - curr_divisor;
                if (temp_remainder[127] == 1)  // 检查是否为负数
                    temp_remainder = temp_remainder + curr_divisor;
                else
                    quotient[i] = 1;
                curr_divisor = curr_divisor >> 1;  // 准备下一位
                i = i + 1;
            end else if (i == 64) begin
                remainder = temp_remainder[63:0];
                ready = 1;  // 计算完成
            end
        end
    end
endmodule
