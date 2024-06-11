module cpu_test;

    // 定义测试信号
    reg clk;
    reg rst;
    reg [31:0] di;  // 用于模拟数据输入

    // 实例化 CPU 模块
    cpu dut (
        .clk(clk),
        .rst(rst)
    );

    // 时钟驱动
    always #5 clk = ~clk;  // 每个时钟周期切换时钟信号

    // 初始化
    initial begin
        clk = 0;
        rst = 1;  // 在模拟开始时置位复位信号

        // 等待一些时钟周期以确保 CPU 处于复位状态
        #10;

        // 释放复位信号
        rst = 0;

        // 开始模拟指令序列

        // 模拟 addi 指令
        di = 32'h00100001;  // addi, rs=0, rt=1, imm=1
        #10;  // 等待一些时钟周期，确保指令被加载和执行

        // 检查寄存器状态
        // 预期 R[0] = 0, R[1] = 1
        $display("After addi instruction: R[0] = %d, R[1] = %d", dut.q1, dut.q2);

        // 模拟 lw 指令
        di = 32'h8C010001;  // lw, base=R[1], rt=2, offset=1 (Load R[2] from memory)
        #10;  // 等待一些时钟周期，确保指令被加载和执行

        // 检查寄存器状态
        // 预期 R[2] = 1
        $display("After lw instruction: R[2] = %d", dut.q2);

        // 添加更多指令模拟...

        // 结束模拟
        $finish;
    end

endmodule
