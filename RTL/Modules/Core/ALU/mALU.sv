module mALU (
    input logic                  clk,
    input logic                  rst,
    input logic [63:0]           a,      // 输入操作数 A
    input logic [63:0]           b,      // 输入操作数 B
    input logic                  signed_a,
    input logic                  signed_b,
    input logic                  start,  // 启动信号
    output logic [127:0]         result, // 输出结果
    output logic                 ready   // 结果就绪信号
);

    // 符号和绝对值计算
    logic [63:0] a_abs, b_abs;
    logic a_sign, b_sign;
    assign a_sign = signed_a && a[63];
    assign b_sign = signed_b && b[63];
    assign a_abs = a_sign ? (~a + 1'b1) : a; // 补码取绝对值
    assign b_abs = b_sign ? (~b + 1'b1) : b;

    logic result_sign; // 结果符号
    assign result_sign = signed_a && signed_b && (a_sign ^ b_sign);

    // 部分积和累加器
    logic [127:0] partial_products [63:0];
    logic [127:0] sum_stage [31:0];
    logic [127:0] final_sum;

    // 有效信号
    logic [6:0] stage_counter;
    logic running;
    logic computation_done;

    // 部分积生成
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            for (int i = 0; i < 64; i++) begin
                partial_products[i] <= 128'b0;
            end
            stage_counter <= 7'b0;
            computation_done <= 1'b0;
            running <= 0;
        end else if (!start&running) begin
            stage_counter <= 7'b0;
            computation_done <= 1'b0;
            running <= 0;
        end else if (start&!running) begin
            for (int i = 0; i < 64; i++) begin
                partial_products[i] <= a_abs[i] ? (b_abs << i) : 128'b0;
            end
            running <= 1;
            stage_counter <= 7'b1;
            computation_done <= 1'b0;
        end else if (stage_counter > 0 && stage_counter <= 6'd32) begin
            stage_counter <= stage_counter + 1;
        end else if (stage_counter > 6'd32) begin
            computation_done <= 1'b1;
            running <= 0;
            stage_counter <= 7'b0;
        end
    end

    // Wallace Tree 累加 (6个周期)
    always_comb begin
        for (int i = 0; i < 32; i++) begin
            sum_stage[i] = partial_products[2*i] + partial_products[2*i+1];
        end
        final_sum = 128'b0;
        for (int i = 0; i < 32; i++) begin
            final_sum = final_sum + sum_stage[i];
        end
    end

    // 最终结果计算
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            result <= 128'b0;
            ready <= 1'b0;
        end else if (computation_done) begin
            result <= result_sign ? (~final_sum + 1'b1) : final_sum;
            ready <= 1'b1;
        end else begin
            ready <= 1'b0;
        end
    end

endmodule
