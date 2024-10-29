`timescale 1ns / 1ns

module gpio(
    input               clk,            // 时钟信号
    input       [63:0]  addr,           // GPIO地址
    input       [31:0]  data_in,        // 输入数据（32位）
    input               wr_enable,      // 写使能信号
    input               rd_enable,      // 读使能信号
    output  reg [31:0]  data_out        // 输出数据（32位）
);

    // 定义4个32位GPIO寄存器
    reg [31:0] gpio_reg[3:0];
    integer i;

    // 初始化寄存器为0
    initial begin
        for (i = 0; i < 4; i = i + 1)
            gpio_reg[i] = 32'b0;
    end

    // GPIO写入逻辑
    always @(posedge clk) begin
        if (wr_enable) begin
            case(addr[3:2]) // 选择目标寄存器
                2'b00: gpio_reg[0] <= data_in;
                2'b01: gpio_reg[1] <= data_in;
                2'b10: gpio_reg[2] <= data_in;
                2'b11: gpio_reg[3] <= data_in;
            endcase
        end
    end

    // GPIO读取逻辑
    always @(*) begin
        if (rd_enable) begin
            case(addr[3:2]) // 选择输出的寄存器
                2'b00: data_out = gpio_reg[0];
                2'b01: data_out = gpio_reg[1];
                2'b10: data_out = gpio_reg[2];
                2'b11: data_out = gpio_reg[3];
                default: data_out = 32'b0;
            endcase
        end else begin
            data_out = 32'b0;
        end
    end

endmodule
