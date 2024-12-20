// 此模块功能异常，可以计算但结果错误，并且也不打算修
module dALU(
    input clk,
    input rst,
    input start,               // 启动信号
    input signed_dividend,     // 被除数是否为有符号数
    input signed_divisor,      // 除数是否为有符号数
    input [63:0] dividend,     // 被除数rs1
    input [63:0] divisor,      // 除数rs2
    output reg [63:0] quotient, // 商
    output reg [63:0] remainder, // 余数
    output reg ready
);

    // 状态和寄存器定义
    reg [63:0] abs_dividend, abs_divisor;
    reg [127:0] temp_remainder;
    reg dividend_sign, divisor_sign, result_sign;
    reg [6:0] i; // 使用 7 位计数器表示 0 到 64
    reg running; // 是否正在运行

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            quotient <= 0;
            remainder <= 0;
            ready <= 0;
            i <= 0;
            running <= 0;
        end else if (!start&running) begin
            quotient <= 0;
            remainder <= 0;
            ready <= 0;
            i <= 0;
            running <= 0;
        end else if (start && !running) begin
            // 检查特殊情况：最小负数除以 -1
            if (signed_dividend && signed_divisor &&
                dividend == 64'h8000000000000000 && divisor == 64'hFFFFFFFFFFFFFFFF) begin
                quotient <= dividend; // 商直接返回被除数
                remainder <= 0;       // 余数为 0
                ready <= 1;
                running <= 0;         // 停止计算
            end else begin
                // 初始化状态
                dividend_sign <= signed_dividend && dividend[63];
                divisor_sign <= signed_divisor && divisor[63];
                abs_dividend <= dividend_sign ? (~dividend + 1'b1) : dividend;
                abs_divisor <= divisor_sign ? (~divisor + 1'b1) : divisor;
                temp_remainder <= {64'b0, abs_dividend};
                quotient <= 0;
                ready <= 0;
                result_sign <= dividend_sign ^ divisor_sign; // 结果符号
                i <= 0;
                running <= 1;
            end
        end else if (running) begin
            if (i < 64) begin
                // 逐位除法运算
                temp_remainder <= temp_remainder - (abs_divisor << (63 - i));
                if (temp_remainder[127]) begin
                    temp_remainder <= temp_remainder + (abs_divisor << (63 - i));
                end else begin
                    quotient[63 - i] <= 1'b1;
                end
                i <= i + 1;
            end else begin
                // 计算完成
                remainder <= temp_remainder[63:0];
                quotient <= result_sign ? (~quotient + 1'b1) : quotient;
                remainder <= dividend_sign ? (~remainder + 1'b1) : remainder;
                ready <= 1;
                running <= 0;
            end
        end
    end
endmodule
