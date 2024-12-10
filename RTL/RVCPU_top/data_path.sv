`timescale 1ns / 1ns

module data_path(
    input logic rst,
    input logic clk,
    // -------------到sys_bus的连线---------------------------------
    output logic [2:0] bus_rd_ctrl,
    output logic [2:0] bus_wr_ctrl,
    output logic [63:0] bus_addr,
    output logic [63:0] bus_din,
    input logic [63:0] bus_dout,
    
    // -------------到dram的连线---------------------------------
    output logic [2:0] dram_rd_ctrl,
    output logic [2:0] dram_wr_ctrl,
    output logic [63:0] dram_addr,
    output logic [63:0] dram_din,
    input logic [63:0] dram_dout,

    //--------------到rom的连线------------------------------
    output logic [63:0] rom_addr,
    input logic [31:0] rom_dout,

    // ------------id阶段与寄存器堆的连接信号----------------------
    input logic [63:0] data_reg_read_1, data_reg_read_2, // 寄存器堆返回的数据信号
    output logic [4:0] addr_reg_read_1, addr_reg_read_2,  // 连接源寄存器堆地址
    // --------------wb阶段的输出(与寄存器堆的连线)-----------------
    output logic [63:0] write_data_WB,   // 数据信号
    output logic [4:0] rd_WB,            // 地址信号
    output logic reg_write_WB           // 使能控制信号
    // -------------------------------------------------------------
);
// 各阶段PC值之间的传递
logic [63:0] pc_ifp_to_ifr, pc_ifr_to_idc, pc_idc_to_idr, pc_idr_to_exb;
logic [63:0] pc_exb_to_exa, pc_exa_to_memp, pc_memp_to_memr, pc_memr_to_wb;

// hazard模块初始化
hazard hazard0(
    .branch_taken_EXB(branch_taken_EXB),
    .branch_target_EXB(branch_target_EXB),
    .no_forwarding_data(no_forwarding_data),
    .stall_IDR(stall_IDR),
    .stall_IDP(stall_IDP),
    .stall_IFR(stall_IFR),
    .stall_IFP(stall_IFP),
    .flush_IDC(flush_IDC),
    .flush_IDR(flush_IDR),
    .flush_EXA(flush_EXA),
    .flush_IFR(flush_IFR),
    .branch_taken_IFP(branch_taken_IFP),
    .branch_target_IFP(branch_target_IFP)
);

// forwarding模块初始化
forwarding forwarding0(
    .rs1_IDC(),           // IDC阶段寄存器读取地址1
    .rs2_IDC(),           // IDC阶段寄存器读取地址2
    .rd_EXB(),            // EXA阶段目标寄存器地址
    .rf_wr_en_EXB(),      // EXA阶段寄存器写使能信号
    .rd_EXA(),            // EXA阶段目标寄存器地址
    .rf_wr_en_EXA(),      // EXA阶段寄存器写使能信号
    .alu_result_EXA(),    // EX阶段ALU结果
    .pc_MEMP(),           // MEMP阶段时钟到来前PC地址
    .rd_MEMP(),           // MEMP阶段目标寄存器地址
    .dm_rd_ctrl_MEMP(),   // MEMP阶段内存读控制信号
    .rf_wr_sel_MEMP(),    // MEMP阶段数据选择信号
    .rf_wr_en_MEMP(),     // MEMP阶段寄存器写使能信号
    .alu_result_MEMP(),   // MEMP阶段传递的内存读取结果
    .pc_MEMR(),           // MEMR阶段时钟到来前PC地址
    .rd_MEMR(),           // MEMR阶段目标寄存器地址
    .dm_rd_ctrl_MEMR(),   // MEMR阶段内存读控制信号
    .rf_wr_sel_MEMR(),    // MEMR阶段数据选择信号
    .rf_wr_en_MEMR(),     // MEMR阶段寄存器写使能信号
    .mem_data_MEMR(),     // MEMR阶段内存数据
    .alu_result_MEMR(),   // MEMR阶段传递的内存读取结果
    .rd_WB(),             // WB阶段目标寄存器地址
    .reg_write_WB(),      // WB阶段寄存器写使能信号
    .write_data_WB(),     // WB阶段写入数据
    .no_forwarding_data(),// 没有可转发的数据暂停IDR
    .forward_rs1_data(),  // 前递寄存器1数据
    .forward_rs2_data(),  // 前递寄存器2数据
    .forward_rs1_sel(),   // 前递寄存器1数据选择信号
    .forward_rs2_sel()    // 前递寄存器2数据选择信号
);

// 实例化stage1
pipeline_ifp_stage1 stage1(
    .clk(),               // 时钟信号
    .reset(),             // 复位信号，低电平有效
    .stall(),             // 流水线暂停信号
    .branch_taken(),      // 分支跳转信号
    .branch_target(),     // 分支跳转目标地址
    .im_addr(),           // 指令存储器地址
    .dram_addr(),         // 可能需要访问数据存储器
    .dm_rd_ctrl(),        // 访问数据存储器控制信号
    .if_channel_sel(),    // 选择从rom还是dram中读取数据，dram置1
    .pc_IFP()             // 当前PC值
);

// 实例化stage2
pipeline_ifr_stage2 stage2(
    .clk(),               // 时钟信号
    .reset(),             // 复位信号，低电平有效
    .stall(),             // 流水线暂停信号
    .flush(),             // 流水线冲刷信号
    .pc_IFP(),           // 上一阶段传来的PC地址
    .if_channel_sel(),    // 选择从rom还是dram中读取数据，dram置1
    .dram_dout(),        // 从dram读取的内存数据(指令)
    .dram_data_ready(),  // dram或cache发出的数据准备完毕信号
    .rom_dout(),         // 从rom读取的内存数据(指令)
    .data_reading(),     // 正在进行内存读取，需要阻塞流水线
    .pc_IFR(),           // 当前PC值
    .Instruction()       // 当前读取的指令
);

// 实例化stage3
pipeline_idc_stage3 stage3(
    .clk(),                       // 时钟信号
    .reset(),                     // 复位信号，低电平有效
    .stall(),                     // 流水线暂停信号
    .flush(),                     // 流水线冲刷信号
    .instruction_IF(),            // 从IF阶段传来的指令
    .pc_IFR(),                    // 从IF阶段传来的PC值
    .rd_ID(),                     // 目的寄存器地址
    .imm_ID(),                     // 解码出的立即数
    .pc_IDC(),                    // 输出到下一阶段的PC
    .rf_wr_en(),                  // 寄存器写使能信号
    .do_jump(),                   // 跳转控制信号
    .is_branch(),                 // 是否b_type
    .is_debug(),                  // 调试信号
    .alu_a_sel(),                 // ALU 输入A选择信号
    .alu_b_sel(),                 // ALU 输入B选择信号
    .alu_ctrl(),                  // ALU 控制信号
    .BrType(),                    // 分支类型控制信号
    .rf_wr_sel(),                 // 寄存器写回数据来源选择
    .dm_rd_ctrl(),                // 数据存储器读取控制信号
    .dm_wr_ctrl(),                // 数据存储器写入控制信号
    .rs1_IDC(),                   // 读取寄存器堆数据的地址1
    .rs2_IDC()                    // 读取寄存器堆数据的地址2
);

// 实例化stage4
pipeline_idr_stage4 stage4(
    .clk(),                       // 时钟信号
    .reset(),                     // 复位信号，低电平有效
    .stall(),                     // 流水线暂停信号
    .flush(),                     // 流水线冲刷信号
    .pc_IDC(),                    // 从IDC阶段传来的PC值
    .rs1_IDC(),                   // 读取寄存器地址1
    .rs2_IDC(),                   // 读取寄存器地址2
    .rd_ID(),                     // 目的寄存器地址
    .imm_ID(),                     // 解码出的立即数
    .rf_wr_en(),                  // 寄存器写使能信号
    .do_jump(),                   // 跳转控制信号
    .is_branch(),                 // 是否b_type
    .alu_a_sel(),                 // ALU 输入A选择信号
    .alu_b_sel(),                 // ALU 输入B选择信号
    .alu_ctrl(),                  // ALU 控制信号
    .BrType(),                    // 分支类型控制信号
    .rf_wr_sel(),                 // 寄存器写回数据来源选择
    .dm_rd_ctrl(),                // 数据存储器读取控制信号
    .dm_wr_ctrl(),                // 数据存储器写入控制信号
    .forward_rs1_data(),         // 前递寄存器1数据
    .forward_rs2_data(),         // 前递寄存器2数据
    .forward_rs1_sel(),          // 前递寄存器1数据选择信号
    .forward_rs2_sel(),          // 前递寄存器2数据选择信号
    .data_reg_read_1(),          // 从寄存器堆读取的数据1
    .data_reg_read_2(),          // 从寄存器堆读取的数据2
    .pc_IDR(),                   // IDR阶段的PC值
    .reg_data1_IDR(),            // 解码出的源操作数1
    .reg_data2_IDR(),            // 解码出的源操作数2
    .rd_IDR(),                   // 目的寄存器地址
    .imm_IDR(),                  // 解码出的立即数
    .rf_wr_en_IDR(),             // 寄存器写使能信号
    .do_jump_IDR(),              // 跳转控制信号
    .is_branch_IDR(),            // 是否b_type
    .alu_a_sel_IDR(),            // ALU 输入A选择信号
    .alu_b_sel_IDR(),            // ALU 输入B选择信号
    .alu_ctrl_IDR(),             // ALU 控制信号
    .BrType_IDR(),               // 分支类型控制信号
    .rf_wr_sel_IDR(),            // 寄存器写回数据来源选择
    .dm_rd_ctrl_IDR(),           // 数据存储器读取控制信号
    .dm_wr_ctrl_IDR()            // 数据存储器写入控制信号
);

// 实例化stage5
pipeline_exb_stage5 stage5(
    .clk(),                       // 时钟信号
    .reset(),                     // 复位信号，低电平有效
    .flush(),                     // 流水线冲刷信号
    .stall(),                     // 流水线暂停信号

    // 传递的信号
    .pc_IDR(),                    // 从IDR阶段传递的PC值
    .reg_data1_IDR(),             // 从IDR阶段传递的源操作数1
    .reg_data2_IDR(),             // 从IDR阶段传递的源操作数2
    .imm_IDR(),                   // 从IDR阶段传递的立即数
    .rd_IDR(),                     // 目的寄存器地址
    .rf_wr_en_IDR(),               // 从IDR阶段传递的寄存器写使能信号
    .rf_wr_sel_IDR(),              // 从IDR阶段传递的寄存器写数据选择信号
    .alu_ctrl_IDR(),               // 用于选择ALU操作的控制信号
    .alu_a_sel_IDR(),              // ALU选择信号
    .alu_b_sel_IDR(),              // ALU选择信号
    .dm_rd_ctrl_IDR(),             // 接收idr阶段数据存储器读取控制信号
    .dm_wr_ctrl_IDR(),             // 接收idr阶段数据存储器写入控制信号

    // 分支跳转输入信号
    .do_jump_IDR(),                // idr阶段传来的jump信号
    .is_branch_IDR(),              // idr阶段传来的branch信号
    .BrType_IDR(),                 // idr阶段传来的Brtype信号

    // 分支跳转处理信号
    .branch_taken_EXB(),           // 分支跳转信号
    .branch_target_EXB(),          // 分支跳转目标地址

    // 输出到下一阶段的信号
    .pc_EXB(),                     // exb阶段输入pc
    .reg_data1_EXB(),              // 转发到exa阶段的源操作数1
    .reg_data2_EXB(),              // 转发到exa阶段的源操作数2
    .imm_EXB(),                    // 转发给alu的立即数
    .rf_wr_en_EXB(),               // 寄存器写使能信号
    .rf_wr_sel_EXB(),              // 转发寄存器写数据选择信号
    .alu_ctrl_EXB(),               // 转发到exa阶段的alu控制信号
    .alu_a_sel_EXB(),              // 转发到exa阶段的ALU选择信号
    .alu_b_sel_EXB(),              // 转发到exa阶段的ALU选择信号
    .dm_rd_ctrl_EXB(),             // 转发读取控制信号
    .dm_wr_ctrl_EXB(),             // 转发写入控制信号
    .rd_EXB()                       // 转发到exa阶段的目的寄存器地址
);

// 实例化stage6
pipeline_exa_stage6 stage6(
    .clk(),                         // 时钟信号
    .reset(),                       // 复位信号，低电平有效
    .stall(),                       // 流水线暂停信号

    // 接收来自EXB阶段的信号
    .reg_data1_EXB(),              // 从ID阶段传递的源操作数1
    .reg_data2_EXB(),              // 从ID阶段传递的源操作数2
    .imm_EXB(),                    // 从ID阶段传递的立即数
    .rd_EXB(),                     // 目的寄存器地址
    .pc_EXB(),                     // 从ID阶段传递的PC值
    .rf_wr_en_EXB(),               // 从ID阶段传递的寄存器写使能信号
    .rf_wr_sel_EXB(),              // 从ID阶段传递的寄存器写数据选择信号
    .alu_ctrl_EXB(),               // 用于选择ALU操作的控制信号
    .alu_a_sel_EXB(),              // ALU选择信号
    .alu_b_sel_EXB(),              // ALU选择信号
    .dm_rd_ctrl_EXB(),             // 接收id阶段数据存储器读取控制信号
    .dm_wr_ctrl_EXB(),             // 接收id阶段数据存储器写入控制信号

    // 输出到下一阶段
    .pc_EXA(),                     // mem阶段输入pc
    .rf_wr_en_EXA(),               // 从ID阶段传递的寄存器写使能信号
    .rf_wr_sel_EXA(),              // 转发寄存器写数据选择信号
    .alu_result_EXA(),             // ALU执行的结果
    .dm_rd_ctrl_EXA(),             // 转发读取控制信号
    .dm_wr_ctrl_EXA(),             // 转发写入控制信号
    .reg_data2_EXA(),              // 转发到mem阶段
    .rd_EXA()                       // 转发到mem阶段的目的寄存器地址
);

// 实例化 MEMP 阶段
pipeline_memp_stage7 memp_stage7(
    .clk(),                          // 时钟信号
    .reset(),                        // 复位信号，低电平有效
    .stall(),                        // 流水线暂停信号

    // 接收来自EX阶段的信号
    .pc_EXA(),                       // 从EX阶段传递的PC值
    .rf_wr_en_EXA(),                 // EX阶段传递的寄存器写使能信号
    .rf_wr_sel_EXA(),                // EX阶段传递的寄存器写数据选择信号
    .alu_result_EXA(),               // 从EX阶段传递的ALU计算结果
    .dm_rd_ctrl_EXA(),               // 内存读控制信号
    .dm_wr_ctrl_EXA(),               // 内存写控制信号
    .reg_data2_EXA(),                // EX阶段传递的寄存器数据2
    .rd_EXA(),                       // EX阶段传递的目的寄存器地址

    // 外设接口相关信号
    .sys_bus_din(),                  // 写入总线的数据
    .sys_bus_rd_ctrl(),              // 外设接口读控制信号
    .sys_bus_wr_ctrl(),              // 外设接口写控制信号

    // 与DRAM接口相关信号
    .dram_din(),                     // 写入DRAM的数据
    .dram_rd_ctrl(),                 // DRAM读控制信号
    .dram_wr_ctrl(),                 // DRAM写控制信号

    // 传递给 MEMD 阶段的信号
    .is_dram_MEMP(),                 // 标志是否需要访问DRAM
    .pc_MEMP(),                      // MEMD阶段的PC输入
    .rf_wr_sel_MEMP(),               // 写回寄存器数据选择信号
    .rf_wr_en_MEMP(),                 // 写回寄存器写使能信号
    .alu_result_MEMP(),              // 直接传递的ALU结果
    .rd_MEMP()                       // 下一级阶段传递的目标寄存器地址
);

// 实例化 MEMR 阶段
pipeline_memr_stage8 memr_stage8(
    .clk(),                          // 时钟信号
    .reset(),                        // 复位信号，低电平有效
    .stall(),                        // 流水线暂停信号

    // 接收外设和内存读取数据
    .sys_bus_dout(),                 // 从外设读取的数据
    .dram_dout(),                    // 从DRAM读取的数据
    .dram_done(),                    // 内存操作完成信号

    // 接收来自 MEMP 阶段传递的信号
    .is_dram_MEMP(),                 // 标志是否需要DRAM访问
    .pc_MEMP(),                      // MEMP 阶段传递的PC值
    .rf_wr_sel_MEMP(),               // MEMP 阶段传递的寄存器写数据选择信号
    .rf_wr_en_MEMP(),                 // MEMP 阶段传递的寄存器写使能信号
    .alu_result_MEMP(),              // ALU运算结果
    .rd_MEMP(),                      // MEMP 阶段传递的目标寄存器地址

    // 向下一阶段传递的信号
    .mem_data_MEM(),                  // 内存读取的数据
    .pc_MEMR(),                       // MEMR 阶段的 PC 地址
    .rf_wr_sel_MEMR(),                // 写回阶段的寄存器写数据选择信号
    .rf_wr_en_MEMR(),                 // 写回阶段的寄存器写使能信号
    .alu_result_MEMR(),               // 传递的 ALU 运算结果
    .rd_MEMR()                         // 写回阶段的目标寄存器地址
);

// 实例化 WB 阶段
pipeline_wb_stage9 wb_stage9 (
    .clk(),                          // 时钟信号
    .reset(),                        // 复位信号
    .stall(),                        // 流水线暂停信号

    // 控制信号和数据输入
    .rf_wr_sel(),                    // 写回数据源选择信号
    .alu_result_MEM(),               // ALU结果
    .mem_data_MEM(),                 // 内存数据
    .rd_MEM(),                       // 目的寄存器地址
    .reg_write_MEM(),                // 写寄存器控制信号
    .pc_WB(),                        // 当前阶段的PC值

    // 输出信号
    .write_data_WB(),                // 写回寄存器数据
    .rd_WB(),                        // 写回的目的寄存器地址
    .reg_write_WB()                  // 写回寄存器控制信号
);


endmodule