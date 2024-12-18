// 文件名: pipeline_memp_stage.sv
// 功能: 从5级流水线CPU中的内存访问阶段拆分出来的访问外设或CPU的准备阶段 (Mem Prepare Access Stage)
// mem: yes
// regs: no
// 外设以及内存读取的数据在memd阶段进行接收
`include "include/defines.sv"
module pipeline_memp_stage8 (
    input logic clk,                     // 时钟信号
    input logic reset,                   // 复位信号，低电平有效
    input logic stall,

    // 上一阶段或id阶段的信号
    input logic [63:0] pc_EXC,           // 从EX阶段传递的PC值
    input logic rf_wr_en_EXC,             // id阶段传来的寄存器写使能信号
    input logic [1:0] rf_wr_sel_EXC,         // 从ID阶段传递的寄存器写数据选择信号，需要传递到wb阶段
    input logic [63:0] alu_result_EXC,    // 从EX阶段传递的ALU计算结果，作为地址
    input logic [2:0] dm_rd_ctrl_EXC,     // 内存读控制信号
    input logic [2:0] dm_wr_ctrl_EXC,     // 内存写控制信号
    input logic [63:0] reg_data2_EXC,     // 从EX阶段传递的源寄存器2的值 (用于存储数据)
    input logic [4:0] rd_EXC,             // 从EX阶段传递的目的寄存器地址

    // 与外设接口的信号
    output logic [63:0] sys_bus_addr,          // 传递给总线的地址信号
    output logic [63:0] sys_bus_din,           // 传递给总线的数据（写入）
    output logic [2:0] sys_bus_rd_ctrl,        // 内存读控制信号
    output logic [2:0] sys_bus_wr_ctrl,        // 内存写控制信号

    // 与dram接口的信号
    output logic [63:0] dram_addr,          // 传递给内存的地址信号
    output logic [63:0] dram_din,           // 传递给内存的数据（写入）
    output logic [2:0] dram_rd_ctrl,        // 内存读控制信号
    output logic [2:0] dram_wr_ctrl,        // 内存写控制信号

    // 传递给MEMD的信号
    output logic is_dram_MEMP,
    output logic [63:0] pc_MEMP,           // 下一阶段的输入pc
    output logic [1:0] rf_wr_sel_MEMP,        // 从ID阶段传递的寄存器写数据选择信号，需要传递到wb阶段
    output logic rf_wr_en_MEMP,            // 传入到wb阶段的寄存器写使能信号
    output logic [63:0] alu_result_MEMP,   // 直接传递的ALU结果（用于不需要内存操作的指令） 并且直接代替sys_bus和dram的地址
    output logic [4:0] rd_MEMP            // 传递给下一个阶段的目的寄存器地址
);

    logic is_dram;
    logic is_mem;

    // 组合逻辑判定
    always_comb begin
        if (dm_rd_ctrl_EXC||dm_wr_ctrl_EXC) begin
            is_mem = 1;
            is_dram = (alu_result_EXC >= `DRAM_BASE_ADDR);  // 通过地址判定访问的设备类型
        end
        else begin
            is_mem = 0;
            is_dram = 0;
        end
    end

    // 与mem阶段相关的信号
    always_ff @(posedge clk or negedge reset) begin
        if (reset) begin
            // 复位时清空寄存器
            sys_bus_din <= 0;
            sys_bus_rd_ctrl <= 0;
            sys_bus_wr_ctrl <= 0;
            dram_din <= 0;
            dram_rd_ctrl <= 0;
            dram_wr_ctrl <= 0;
        end else if (~stall) begin
            if(is_mem&~is_dram)begin // 访问外设
                sys_bus_addr <= alu_result_EXC;
                sys_bus_din <= reg_data2_EXC;
                sys_bus_rd_ctrl <= dm_rd_ctrl_EXC;
                sys_bus_wr_ctrl <= dm_wr_ctrl_EXC;
                dram_addr <= 0;
                dram_din <= 0;
                dram_rd_ctrl <= 0;
                dram_wr_ctrl <= 0;
            end
            else if(is_mem&is_dram) begin  // 访问dram
                sys_bus_addr <= 0;
                sys_bus_din <= 0;
                sys_bus_rd_ctrl <= 0;
                sys_bus_wr_ctrl <= 0;
                dram_addr <= alu_result_EXC;
                dram_din <= reg_data2_EXC;
                dram_rd_ctrl <= dm_rd_ctrl_EXC;
                dram_wr_ctrl <= dm_wr_ctrl_EXC;
            end
            else begin //不访问外设或主存，直接锁存信号交付给下一阶段
                sys_bus_din <= 0;
                sys_bus_rd_ctrl <= 0;
                sys_bus_wr_ctrl <= 0;
                dram_din <= 0;
                dram_rd_ctrl <= 0;
                dram_wr_ctrl <= 0;
            end
        end
    end

    // 始终需要进行传递的信号
    always_ff @(posedge clk or negedge reset) begin
        if (reset) begin
            pc_MEMP <= 0;
            rf_wr_sel_MEMP <= 0;
            rf_wr_en_MEMP <= 0;
            alu_result_MEMP <= 0;
            rd_MEMP <= 0;
            is_dram_MEMP <= 0;
        end else if (~stall) begin
            pc_MEMP <= pc_EXC;
            rf_wr_sel_MEMP <= rf_wr_sel_EXC;
            rf_wr_en_MEMP <= rf_wr_en_EXC;
            alu_result_MEMP <= alu_result_EXC;
            rd_MEMP <= rd_EXC;
            is_dram_MEMP <= is_dram;
        end
    end

endmodule
