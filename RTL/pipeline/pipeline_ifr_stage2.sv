// 文件名: pipeline_ifr_stage.sv
// 功能: 从5级流水线CPU中的指令预取阶段新增的指令预取就绪阶段 (Instruction Fetch Prepare Stage)
// mem: no
// regs: no
`include "Modules/defines.v"
module pipeline_ifr_stage2 (
    input logic clk,               // 时钟信号
    input logic reset,             // 复位信号，低电平有效
    input logic stall,             // 流水线暂停信号
    input logic flush,             // 流水线冲刷信号（拆分之后第二阶段需要）
    input logic [63:0] pc_IFP,     // 上一阶段传来的PC地址
    input logic if_channel_sel,   // 选择从rom还是dram中读取数据，dram置1

    input logic [31:0] dram_dout,        // 从dram读取的内存数据(指令)
    input logic dram_data_ready,        // dram或cache发出的数据准备完毕信号
    input logic [31:0] rom_dout,        // 从rom读取的内存数据(指令)

    output logic [63:0] pc_IFR,      // 当前PC值
    output logic [31:0] Instruction
);

always_ff @(posedge clk or posedge reset) begin
    if (reset||flush)begin
        pc_IFR <= 64'b0;
        Instruction <= 32'b0;
    end
    else if (!stall) begin
        if (if_channel_sel) begin
            if (dram_data_ready)begin
                Instruction <= dram_dout;
                pc_IFR <= pc_IFP;
            end
            else begin
                Instruction <= 32'b0;
                pc_IFR <= pc_IFP;
            end

        end
        else begin
            Instruction <= rom_dout;
            pc_IFR <= pc_IFP;
        end
    end
end

    


endmodule
