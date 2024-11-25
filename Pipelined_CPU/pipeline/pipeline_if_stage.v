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
    output reg [31:0] instruction_IF  // 取到的指令
);

    wire [63:0] pc_plus4;

    assign pc_plus4 = pc_IF + 4; // 计算PC + 4

    // 计算PC
    always @(posedge clk or posedge reset) begin
        if (reset) 
            pc_IF <= 64'b0; // 使用非阻塞赋值
        else begin
            if (branch_taken) 
                pc_IF <= branch_target + 4; // 使用非阻塞赋值
            else begin
                if (!stall) 
                    pc_IF <= pc_plus4; // 使用非阻塞赋值
            end
        end
    end

    // 指令存储器地址
    assign im_addr = branch_taken?branch_target:pc_IF; // 假设指令存储器以4字节对齐，取高位地址

    // 在时钟上升沿或复位信号有效时，更新指令和
    always @(posedge clk) begin
        if (reset||branch_taken) begin
            instruction_IF <= 32'b0;    // 复位时指令为0
        end else if (!stall) begin
            instruction_IF <= im_dout;  // 从指令存储器中读取指令
        end
    end

endmodule
