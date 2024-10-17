// 文件名: pipeline_if_stage.v
// 功能: 5级流水线CPU中的取指阶段 (Instruction Fetch Stage)
// mem: yes
// regs: no

module pipeline_if_stage (
    input wire clk,              // 时钟信号
    input wire reset,            // 复位信号，低电平有效
    input wire stall,            // 流水线暂停信号
    input wire branch_taken,     // 分支跳转信号
    input wire [63:0] branch_target, // 分支跳转目标地址
    
    input wire [31:0] im_dout,   // 连接到顶层模块中的指令存储器输出数据
    output wire [63:0] im_addr,  // 连接到顶层模块中的指令存储器地址
    
    output reg [63:0] pc_IF,     // 当前PC值
    output wire [31:0] instruction_IF  // 取到的指令
);

    // 内部信号
    wire [63:0] pc_plus4_IF;     // 计算出的下一个PC值
    reg [63:0] pc_next;          // 下一个PC的值

    // PC + 4 计算 (组合逻辑)
    assign pc_plus4_IF = pc_IF + 64'h4;

    // PC更新逻辑 (时序逻辑)
    always @(posedge clk or negedge reset) begin
        if (!reset) begin
            pc_IF <= 64'h0;  // 复位时PC初始化为0
        end else if (!stall) begin
            // 判断是否是分支跳转
            if (branch_taken)
                pc_IF <= branch_target;  // 如果分支跳转，则PC更新为目标地址
            else
                pc_IF <= pc_plus4_IF;    // 否则顺序执行，PC更新为PC+4
        end
    end

    // 从外部指令存储器获取指令
    assign instruction_IF = im_dout;

    // 将当前PC作为指令存储器地址
    assign im_addr = pc_IF;

endmodule
