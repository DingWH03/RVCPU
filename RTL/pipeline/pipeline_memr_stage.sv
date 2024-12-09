// 文件名: pipeline_memr_stage.sv
// 功能: 从5级流水线CPU中的内存访问阶段拆分出来的访问dram的单独阶段 (Dram Access Stage)
// mem: yes
// regs: no
// 这阶段需要判断数据是否读取完毕，等缓存做出来了再完善
module pipeline_memr_stage (
    input logic clk,                     // 时钟信号
    input logic reset,                   // 复位信号，低电平有效
    input logic stall,

    input logic [63:0] sys_bus_dout,          // 从外设读取的数据
    input logic [63:0] dram_dout,            // 从内存读取的数据
    input logic dram_done,

    // 下面为传递来的信号
    input logic is_dram_MEMP,
    input logic [63:0] pc_MEMP,           // 下一阶段的输入pc
    input logic [1:0] rf_wr_sel_MEMP,        // 从ID阶段传递的寄存器写数据选择信号，需要传递到wb阶段
    input logic rf_wr_en_MEMP,            // 传入到wb阶段的寄存器写使能信号
    input logic [63:0] alu_result_MEMP,   // 直接传递的ALU结果（用于不需要内存操作的指令） 并且直接代替sys_bus和dram的地址
    input logic [4:0] rd_MEMP,            // 传递给下一个阶段的目的寄存器地址

    // 传递到下一阶段的信号
    output logic [63:0] mem_data_MEM,     // 内存读取的数据
    output logic [63:0] pc_MEMR,      // 下一阶段的输入PC
    output logic [1:0] rf_wr_sel_MEMR,        // 从ID阶段传递的寄存器写数据选择信号，需要传递到wb阶段
    output logic rf_wr_en_MEMR,            // 传入到wb阶段的寄存器写使能信号
    output logic [63:0] alu_result_MEMR,  // alu运算结果
    output logic [4:0] rd_MEMR            // 传递给wb阶段的目的寄存器地址
);

logic [63:0] selected_data;
always_comb begin
    selected_data = is_dram_MEMP ? dram_dout : sys_bus_dout;
end

always_ff @(posedge clk or negedge reset) begin
    if (reset) begin
        mem_data_MEM <= 0;
        pc_MEMR <= 0;
        rf_wr_sel_MEMR <= 0;
        rf_wr_en_MEMR <= 0;
        alu_result_MEMR <= 0;
        rd_MEMR <= 0;
    end else if ((~stall)&dram_done) begin
        mem_data_MEM <= selected_data;
        pc_MEMR <= pc_MEMP;
        rf_wr_sel_MEMR <= rf_wr_sel_MEMP;
        rf_wr_en_MEMR <= rf_wr_en_MEMP;
        alu_result_MEMR <= alu_result_MEMP;
        rd_MEMR <= rd_MEMP;
    end
end

endmodule