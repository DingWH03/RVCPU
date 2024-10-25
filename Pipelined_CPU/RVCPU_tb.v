`timescale 1ns / 1ns

module RVCPU_tb;

    reg clk;           // 时钟信号
    reg rst;           // 复位信号
    wire [31:0] im_dout;
    wire [63:0] im_addr, dm_addr, dm_din, dm_dout;
    wire [2:0] dm_rd_ctrl, dm_wr_ctrl;

    mem mem0(
	.clk        (clk),
	.im_addr    (im_addr),
	.im_dout    (im_dout),
	.dm_rd_ctrl (dm_rd_ctrl),
	.dm_wr_ctrl (dm_wr_ctrl),
	.dm_addr    (dm_addr),
	.dm_din     (dm_din),
	.dm_dout    (dm_dout)
    );

    // 实例化 RVCPU 模块
    RVCPU rvcpu (
        .clk(clk),
        .rst(rst),
        .im_addr_mem0(im_addr),
        .im_dout_mem0(im_dout),
        .dm_rd_ctrl_mem(dm_rd_ctrl),
        .dm_wr_ctrl_mem(dm_wr_ctrl),
        .dm_addr_mem(dm_addr),
        .dm_din_mem(dm_din),
        .dm_dout_mem(dm_dout)
    );

    // 时钟生成
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 每5个时间单位翻转一次时钟
    end

    // 复位逻辑
    initial begin
        rst = 1;              // 初始为复位状态
        #10 rst = 0;         // 10个时间单位后解除复位
    end

    // 测试程序
    initial begin
        // 在此处可以添加测试指令
        // 例如，初始化指令内存内容
        // 这里的 inst.dat 文件中需要包含有效的指令
        
        // 结束仿真
        #1000;                 // 运行100个时间单位
        $finish;             // 结束仿真
    end

    // 生成波形文件
    initial begin
        $dumpfile("output/waveform.vcd");  // 指定波形文件名称
        $dumpvars(0, RVCPU_tb);      // 记录 RVCPU_tb 的所有变量
    end

endmodule
