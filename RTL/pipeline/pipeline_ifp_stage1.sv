// 文件名: pipeline_ifp_stage.sv
// 功能: 从5级流水线CPU中的指令预取阶段新增的指令预取准备阶段 (Instruction Fetch Prepare Stage)
// mem: yes
// regs: no
`include "include/defines.sv"
module pipeline_ifp_stage1 (
    input logic clk,               // 时钟信号
    input logic reset,             // 复位信号，低电平有效
    input logic stall,             // 流水线暂停信号
    input logic branch_taken,      // 分支跳转信号
    input logic [63:0] branch_target, // 分支跳转目标地址

    output logic [63:0] im_addr,   // 指令存储器地址
    output logic [63:0] dram_addr, // 可能需要访问数据存储器
    output logic [2:0] dm_rd_ctrl, // 访问数据存储器控制信号
    output logic if_channel_sel,   // 选择从rom还是dram中读取数据，dram置1

    output logic [63:0] pc_IFP      // 当前PC值
);

    logic [63:0] pc_next;           // 下一个PC值寄存器
    logic [63:0] pc_plus4;         // 计算 PC + 4
    logic init;                     // 初始化阶段信号

    assign pc_plus4 = pc_IFP + 4;

    // 初始化阶段逻辑
    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            init <= 1'b1; // 复位后进入初始化阶段
        else if (init && !stall)
            init <= 1'b0; // 加载第一条指令后结束初始化阶段
    end

    // 计算下一个PC值
    always_comb begin
        if (init)
            pc_next = 64'b0; // 初始化阶段PC强制为0
        else if (branch_taken)
            pc_next = branch_target; // 跳转目标地址
        else if (stall)
            pc_next = pc_IFP; // 暂停保持当前PC
        else
            pc_next = pc_plus4; // 顺序执行
    end

    // 更新PC寄存器
    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            pc_IFP <= 64'b0; // 复位时PC为0
        else if (!stall)
            pc_IFP <= pc_next; // 在时钟上升沿更新PC
    end

    // 指令存储器地址
    always_comb begin
        if (pc_next>=`DRAM_BASE_ADDR) begin
            im_addr = 64'bz;
            if_channel_sel = 1;
            dram_addr = pc_next;
            dm_rd_ctrl = 3'b101;
        end
        else begin
            im_addr = pc_IFP;
            if_channel_sel = 0;
            dram_addr = 64'bz;
            dm_rd_ctrl = 3'b000;
        end
    end


endmodule
