module mALU #(
    parameter WIDTH = 64
) (
    input logic                  clk,
    input logic                  reset,
    input logic [WIDTH-1:0]      a,      // 输入操作数 A
    input logic [WIDTH-1:0]      b,      // 输入操作数 B
    input logic signed_a,
    input logic signed_b,
    input logic                  start,  // 启动信号
    output logic [2*WIDTH-1:0]   result, // 输出结果
    output logic                 ready   // 结果就绪信号
);

    logic [WIDTH-1:0] a_abs, b_abs; // 绝对值
    logic a_sign, b_sign; // 输入符号

    assign a_sign = signed_a && a[WIDTH-1];
    assign b_sign = signed_b && b[WIDTH-1];
    assign a_abs = a_sign ? (~a + 1'b1) : a; // 取补码或原值
    assign b_abs = b_sign ? (~b + 1'b1) : b;

    logic result_sign; // 结果符号
    assign result_sign = (signed_a && signed_b) && (a_sign ^ b_sign); // 异或判断符号

    // 部分积寄存器：动态更新，减少寄存器占用
    logic [2*WIDTH-1:0] partial_products [0:WIDTH-1];
    logic [2*WIDTH-1:0] sum_stage [0:1]; // 双寄存器轮换存储
    logic valid_stage [0:$clog2(WIDTH)+1]; // 每阶段有效性标志，加1防止越界

    // 部分积生成寄存器(并行，1周期)
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            for (int i = 0; i < WIDTH; i++) begin
                partial_products[i] <= '0;
            end
            valid_stage[0] <= 1'b0;
        end else if (start) begin
            for (int i = 0; i < WIDTH; i++) begin
                partial_products[i] <= a_abs[i] ? (b_abs << i) : 0;
            end
            valid_stage[0] <= 1'b1;
        end
    end

    // Wallace Tree 累加阶段 (2^6=64 6周期)
    genvar j, k;
    generate
        for (j = 0; j < $clog2(WIDTH); j++) begin : wallace_tree_stages
            always_ff @(posedge clk or posedge reset) begin
                if (reset) begin
                    sum_stage[0] <= '0';
                    sum_stage[1] <= '0';
                    valid_stage[j+1] <= 1'b0;
                end else if (valid_stage[j]) begin
                    sum_stage[0] <= '0'; // 重置累加器
                    sum_stage[1] <= '0'; // 重置累加器
                    for (k = 0; k < WIDTH >> (j+1); k++) begin
                        if (k % 2 == 0) begin
                            sum_stage[0] <= sum_stage[0] + partial_products[2*k] + partial_products[2*k+1];
                        end else begin
                            sum_stage[1] <= sum_stage[1] + partial_products[2*k] + partial_produfcts[2*k+1];
                        end
                    end
                    valid_stage[j+1] <= 1'b1;
                end
            end
        end
    endgenerate

    // 最终加法和就绪信号产生 (1周期)
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            result <= '0';
            ready <= 1'b0;
        end else if (valid_stage[$clog2(WIDTH)]) begin
            result <= result_sign ? (~(sum_stage[0] + sum_stage[1]) + 1'b1) : (sum_stage[0] + sum_stage[1]);
            ready <= 1'b1;
        end else begin
            ready <= 1'b0;
        end
    end

endmodule
