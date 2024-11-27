// 文件名: pipeline_if_stage.v
// 功能: 5级流水线CPU中的指令预取阶段 (Instruction Fetch Stage)
// mem: yes
// regs: no
module pipeline_if_stage (
    input wire clk,               // 时钟信号
    input wire reset,             // 复位信号，低电平有效
    input wire stall,             // 流水线暂停信号
    input wire branch_taken,      // 分支跳转信号
    input wire [63:0] branch_target, // 分支跳转目标地址

    input wire [31:0] im_dout,    // 指令存储器输出数据
    output wire [63:0] im_addr,   // 指令存储器地址

    output reg [63:0] pc_IF,      // 当前PC值
    output reg [31:0] instruction_IF // 取到的指令
);

    reg [63:0] pc_next;           // 下一个PC值寄存器
    wire [63:0] pc_plus4;         // 计算 PC + 4
    reg init;                     // 初始化阶段信号

    assign pc_plus4 = pc_IF + 4;

    // 初始化阶段逻辑
    always @(posedge clk or posedge reset) begin
        if (reset)
            init <= 1'b1; // 复位后进入初始化阶段
        else if (init && !stall)
            init <= 1'b0; // 加载第一条指令后结束初始化阶段
    end

    // 计算下一个PC值
    always @(*) begin
        if (init)
            pc_next = 64'b0; // 初始化阶段PC强制为0
        else if (branch_taken)
            pc_next = branch_target; // 跳转目标地址
        else if (stall)
            pc_next = pc_IF; // 暂停保持当前PC
        else
            pc_next = pc_plus4; // 顺序执行
    end

    // 更新PC寄存器
    always @(posedge clk or posedge reset) begin
        if (reset)
            pc_IF <= 64'b0; // 复位时PC为0
        else if (!stall)
            pc_IF <= pc_next; // 在时钟上升沿更新PC
    end

    // 指令存储器地址
    assign im_addr = pc_next; // 输出的是计算后的下一个PC值

    // 更新指令寄存器
    always @(posedge clk or posedge reset) begin
        if (reset)
            instruction_IF <= 32'b0; // 复位时指令为0
        else if (init)
            instruction_IF <= im_dout; // 初始化阶段加载第一条指令
        else if (!stall)
            instruction_IF <= im_dout; // 正常取指
    end

endmodule
