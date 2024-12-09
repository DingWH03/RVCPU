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
    output logic [4:0] rs1_IDC, rs2_IDC,  // 连接源寄存器堆地址
    // --------------wb阶段的输出(与寄存器堆的连线)-----------------
    output logic [63:0] write_data_WB,   // 数据信号
    output logic [4:0] rd_WB,            // 地址信号
    output logic reg_write_WB           // 使能控制信号
    // -------------------------------------------------------------
);
// 各阶段PC值之间的传递
logic [63:0] pc_ifp_to_ifr, pc_ifr_to_idc, pc_idc_to_idr, pc_idr_to_exb;
logic [63:0] pc_exb_to_exa, pc_exa_to_memp, pc_memp_to_memr, pc_memr_to_wb;

// hazard连接信号线定义
logic branch_taken_EXB;
logic [63:0] branch_target_EXB;
logic stall_IDR;
logic stall_IDC;
logic stall_IFR;
logic stall_IFP;
logic nop_IDR;
logic flush_IDC;
logic flush_IDR;
logic flush_IFR;
logic flush_EXB;
logic branch_taken_IFP;
logic [63:0] branch_target_IFP;

// forwarding连接信号线定义
logic no_forwarding_data_IDR;
logic no_forwarding_data_EXB;
logic no_forwarding_data_MEMP;
logic [63:0] forward_rs1_data;
logic [63:0] forward_rs2_data;
logic forward_rs1_sel;
logic forward_rs2_sel;

// ifp连接信号定义
logic if_channel_sel;

// ifr信号定义
logic [31:0] instruction_IF;

// idc信号定义
logic [4:0] rd_ID;
logic [63:0] imm_ID;
logic rf_wr_en;
logic do_jump;
logic is_branch;
logic alu_a_sel;
logic alu_b_sel;
logic is_rs1_used;
logic is_rs2_used;
logic [3:0] alu_ctrl;
logic [2:0] BrType;
logic [1:0] rf_wr_sel;
logic [2:0] dm_rd_ctrl;
logic [2:0] dm_wr_ctrl;

// idr信号定义
logic [63:0] reg_data1_IDR;
logic [63:0] reg_data2_IDR;
logic [4:0] rd_IDR;
logic [63:0] imm_IDR;
logic rf_wr_en_IDR;
logic do_jump_IDR;
logic is_branch_IDR;
logic alu_a_sel_IDR;
logic alu_b_sel_IDR;
logic [3:0] alu_ctrl_IDR;
logic [2:0] BrType_IDR;
logic [1:0] rf_wr_sel_IDR;
logic [2:0] dm_rd_ctrl_IDR;
logic [2:0] dm_wr_ctrl_IDR;

// exb信号定义
logic [63:0] reg_data1_EXB;
logic [63:0] reg_data2_EXB;
logic [63:0] imm_EXB;
logic rf_wr_en_EXB;
logic [1:0] rf_wr_sel_EXB;
logic [3:0] alu_ctrl_EXB;
logic alu_a_sel_EXB;
logic alu_b_sel_EXB;
logic [2:0] dm_rd_ctrl_EXB;
logic [2:0] dm_wr_ctrl_EXB;
logic [4:0] rd_EXB;

// exa信号定义
logic rf_wr_en_EXA;
logic [1:0] rf_wr_sel_EXA;
logic [63:0] alu_result_EXA;
logic [2:0] dm_rd_ctrl_EXA;
logic [2:0] dm_wr_ctrl_EXA;
logic [63:0] reg_data2_EXA;
logic [4:0] rd_EXA;

// memp信号定义
logic is_dram_MEMP;
logic [1:0] rf_wr_sel_MEMP;
logic rf_wr_en_MEMP;
logic [63:0] alu_result_MEMP;
logic [4:0] rd_MEMP;

// memr信号定义
logic [63:0] mem_data_MEM;
logic [1:0] rf_wr_sel_MEMR;
logic rf_wr_en_MEMR;
logic [63:0] alu_result_MEMR;
logic [4:0] rd_MEMR;

// hazard模块初始化
hazard hazard0(
    .branch_taken_EXB(branch_taken_EXB),
    .branch_target_EXB(branch_target_EXB),
    .no_forwarding_data_IDR(no_forwarding_data_IDR),
    .no_forwarding_data_EXB(no_forwarding_data_EXB),
    .no_forwarding_data_MEMP(no_forwarding_data_MEMP),
    .stall_IDR(stall_IDR),
    .stall_IDC(stall_IDC),
    .stall_IFR(stall_IFR),
    .stall_IFP(stall_IFP),
    .flush_IDC(flush_IDC),
    .flush_IDR(flush_IDR),
    .flush_IFR(flush_IFR),
    .flush_EXB(flush_EXB),
    .nop_IDR(nop_IDR),
    .branch_taken_IFP(branch_taken_IFP),
    .branch_target_IFP(branch_target_IFP)
);

// forwarding模块初始化
forwarding forwarding0(
    .rs1_IDC(rs1_IDC),           // IDC阶段寄存器读取地址1
    .rs2_IDC(rs2_IDC),           // IDC阶段寄存器读取地址2
    .rd_IDR(rd_IDR),            // EXA阶段目标寄存器地址
    .rf_wr_en_IDR(rf_wr_en_IDR),      // EXA阶段寄存器写使能信号
    .rd_EXB(rd_EXB),            // EXA阶段目标寄存器地址
    .rf_wr_en_EXB(rf_wr_en_EXB),      // EXA阶段寄存器写使能信号
    .rd_EXA(rd_EXA),            // EXA阶段目标寄存器地址
    .rf_wr_en_EXA(rf_wr_en_EXA),      // EXA阶段寄存器写使能信号
    .alu_result_EXA(alu_result_EXA),    // EX阶段ALU结果
    .pc_MEMP(pc_MEMP),           // MEMP阶段时钟到来前PC地址
    .rd_MEMP(rd_MEMP),           // MEMP阶段目标寄存器地址
    .dm_rd_ctrl_MEMP(dm_rd_ctrl_EXA),   // MEMP阶段内存读控制信号
    .rf_wr_sel_MEMP(rf_wr_sel_MEMP),    // MEMP阶段数据选择信号
    .rf_wr_en_MEMP(rf_wr_en_MEMP),     // MEMP阶段寄存器写使能信号
    .alu_result_MEMP(alu_result_MEMP),   // MEMP阶段传递的内存读取结果
    .pc_MEMR(pc_MEMR),           // MEMR阶段时钟到来前PC地址
    .rd_MEMR(rd_MEMR),           // MEMR阶段目标寄存器地址
    .dm_rd_ctrl_MEMR(dram_rd_ctrl),   // MEMR阶段内存读控制信号
    .rf_wr_sel_MEMR(rf_wr_sel_MEMR),    // MEMR阶段数据选择信号
    .rf_wr_en_MEMR(rf_wr_en_MEMR),     // MEMR阶段寄存器写使能信号
    .mem_data_MEMR(mem_data_MEM),     // MEMR阶段内存数据
    .alu_result_MEMR(alu_result_MEMR),   // MEMR阶段传递的内存读取结果
    .rd_WB(rd_WB),             // WB阶段目标寄存器地址
    .reg_write_WB(reg_write_WB),      // WB阶段寄存器写使能信号
    .write_data_WB(write_data_WB),     // WB阶段写入数据
    .no_forwarding_data_IDR(no_forwarding_data_IDR),
    .no_forwarding_data_EXB(no_forwarding_data_EXB),
    .no_forwarding_data_MEMP(no_forwarding_data_MEMP),
    .forward_rs1_data(forward_rs1_data),  // 前递寄存器1数据
    .forward_rs2_data(forward_rs2_data),  // 前递寄存器2数据
    .forward_rs1_sel(forward_rs1_sel),   // 前递寄存器1数据选择信号
    .forward_rs2_sel(forward_rs2_sel)    // 前递寄存器2数据选择信号
);

// 实例化stage1
pipeline_ifp_stage1 stage1(
    .clk(clk),               // 时钟信号
    .reset(rst),             // 复位信号，低电平有效
    .stall(stall_IFP),             // 流水线暂停信号
    .branch_taken(branch_taken_IFP),      // 分支跳转信号
    .branch_target(branch_target_IFP),     // 分支跳转目标地址
    .im_addr(rom_addr),           // 指令存储器地址
    .dram_addr(),         // 可能需要访问数据存储器
    .dm_rd_ctrl(),        // 访问数据存储器控制信号
    .if_channel_sel(if_channel_sel),    // 选择从rom还是dram中读取数据，dram置1
    .pc_IFP(pc_ifp_to_ifr)             // 当前PC值
);

// 实例化stage2
pipeline_ifr_stage2 stage2(
    .clk(clk),               // 时钟信号
    .reset(rst),             // 复位信号，低电平有效
    .stall(stall_IFR),             // 流水线暂停信号
    .flush(flush_IFR),             // 流水线冲刷信号
    .pc_IFP(pc_ifp_to_ifr),           // 上一阶段传来的PC地址
    .if_channel_sel(if_channel_sel),    // 选择从rom还是dram中读取数据，dram置1
    .dram_dout(),        // 从dram读取的内存数据(指令)
    .dram_data_ready(1'b1),  // dram或cache发出的数据准备完毕信号
    .rom_dout(rom_dout),         // 从rom读取的内存数据(指令)
    .pc_IFR(pc_ifr_to_idc),           // 当前PC值
    .Instruction(instruction_IF)       // 当前读取的指令
);

// 实例化stage3
pipeline_idc_stage3 stage3(
    .clk(clk),                       // 时钟信号
    .reset(rst),                     // 复位信号，低电平有效
    .stall(stall_IDC),                     // 流水线暂停信号
    .flush(flush_IDC),                     // 流水线冲刷信号
    .instruction_IF(instruction_IF),            // 从IF阶段传来的指令
    .pc_IFR(pc_ifr_to_idc),                    // 从IF阶段传来的PC值
    .rd_ID(rd_ID),                     // 目的寄存器地址
    .imm_ID(imm_ID),                     // 解码出的立即数
    .pc_IDC(pc_idc_to_idr),                    // 输出到下一阶段的PC
    .rf_wr_en(rf_wr_en),                  // 寄存器写使能信号
    .is_rs1_used(is_rs1_used),
    .is_rs2_used(is_rs2_used),
    .do_jump(do_jump),                   // 跳转控制信号
    .is_branch(is_branch),                 // 是否b_type
    .is_debug(),                  // 调试信号
    .alu_a_sel(alu_a_sel),                 // ALU 输入A选择信号
    .alu_b_sel(alu_b_sel),                 // ALU 输入B选择信号
    .alu_ctrl(alu_ctrl),                  // ALU 控制信号
    .BrType(BrType),                    // 分支类型控制信号
    .rf_wr_sel(rf_wr_sel),                 // 寄存器写回数据来源选择
    .dm_rd_ctrl(dm_rd_ctrl),                // 数据存储器读取控制信号
    .dm_wr_ctrl(dm_wr_ctrl),                // 数据存储器写入控制信号
    .rs1_IDC(rs1_IDC),                   // 读取寄存器堆数据的地址1
    .rs2_IDC(rs2_IDC)                    // 读取寄存器堆数据的地址2
);

// 实例化stage4
pipeline_idr_stage4 stage4(
    .clk(clk),                       // 时钟信号
    .reset(rst),                     // 复位信号，低电平有效
    .stall(stall_IDR),                     // 流水线暂停信号
    .flush(flush_IDR),                     // 流水线冲刷信号
    .nop(nop_IDR),
    .pc_IDC(pc_idc_to_idr),                    // 从IDC阶段传来的PC值
    .rs1_IDC(rs1_IDC),                   // 读取寄存器地址1
    .rs2_IDC(rs2_IDC),                   // 读取寄存器地址2
    .rd_ID(rd_ID),                     // 目的寄存器地址
    .imm_ID(imm_ID),                     // 解码出的立即数
    .rf_wr_en(rf_wr_en),                  // 寄存器写使能信号
    .do_jump(do_jump),                   // 跳转控制信号
    .is_branch(is_branch),                 // 是否b_type
    .alu_a_sel(alu_a_sel),                 // ALU 输入A选择信号
    .alu_b_sel(alu_b_sel),                 // ALU 输入B选择信号
    .alu_ctrl(alu_ctrl),                  // ALU 控制信号
    .BrType(BrType),                    // 分支类型控制信号
    .rf_wr_sel(rf_wr_sel),                 // 寄存器写回数据来源选择
    .dm_rd_ctrl(dm_rd_ctrl),                // 数据存储器读取控制信号
    .dm_wr_ctrl(dm_wr_ctrl),                // 数据存储器写入控制信号
    .forward_rs1_data(forward_rs1_data),         // 前递寄存器1数据
    .forward_rs2_data(forward_rs2_data),         // 前递寄存器2数据
    .forward_rs1_sel(forward_rs1_sel),          // 前递寄存器1数据选择信号
    .forward_rs2_sel(forward_rs2_sel),          // 前递寄存器2数据选择信号
    .data_reg_read_1(data_reg_read_1),          // 从寄存器堆读取的数据1
    .data_reg_read_2(data_reg_read_2),          // 从寄存器堆读取的数据2
    .pc_IDR(pc_idr_to_exb),                   // IDR阶段的PC值
    .reg_data1_IDR(reg_data1_IDR),            // 解码出的源操作数1
    .reg_data2_IDR(reg_data2_IDR),            // 解码出的源操作数2
    .rd_IDR(rd_IDR),                   // 目的寄存器地址
    .imm_IDR(imm_IDR),                  // 解码出的立即数
    .rf_wr_en_IDR(rf_wr_en_IDR),             // 寄存器写使能信号
    .do_jump_IDR(do_jump_IDR),              // 跳转控制信号
    .is_branch_IDR(is_branch_IDR),            // 是否b_type
    .alu_a_sel_IDR(alu_a_sel_IDR),            // ALU 输入A选择信号
    .alu_b_sel_IDR(alu_b_sel_IDR),            // ALU 输入B选择信号
    .alu_ctrl_IDR(alu_ctrl_IDR),             // ALU 控制信号
    .BrType_IDR(BrType_IDR),               // 分支类型控制信号
    .rf_wr_sel_IDR(rf_wr_sel_IDR),            // 寄存器写回数据来源选择
    .rs1_IDR(rs1_IDR),
    .rs2_IDR(rs2_IDR),
    .dm_rd_ctrl_IDR(dm_rd_ctrl_IDR),           // 数据存储器读取控制信号
    .dm_wr_ctrl_IDR(dm_wr_ctrl_IDR)            // 数据存储器写入控制信号
);

// 实例化stage5
pipeline_exb_stage5 stage5(
    .clk(clk),                       // 时钟信号
    .reset(rst),                     // 复位信号，低电平有效
    .flush(flush_EXB),                     // 流水线冲刷信号
    .stall(1'b0),                     // 流水线暂停信号

    // 传递的信号
    .pc_IDR(pc_idr_to_exb),                    // 从IDR阶段传递的PC值
    .reg_data1_IDR(reg_data1_IDR),             // 从IDR阶段传递的源操作数1
    .reg_data2_IDR(reg_data2_IDR),             // 从IDR阶段传递的源操作数2
    .imm_IDR(imm_IDR),                   // 从IDR阶段传递的立即数
    .rd_IDR(rd_IDR),                     // 目的寄存器地址
    .rf_wr_en_IDR(rf_wr_en_IDR),               // 从IDR阶段传递的寄存器写使能信号
    .rf_wr_sel_IDR(rf_wr_sel_IDR),              // 从IDR阶段传递的寄存器写数据选择信号
    .alu_ctrl_IDR(alu_ctrl_IDR),               // 用于选择ALU操作的控制信号
    .alu_a_sel_IDR(alu_a_sel_IDR),              // ALU选择信号
    .alu_b_sel_IDR(alu_b_sel_IDR),              // ALU选择信号
    .dm_rd_ctrl_IDR(dm_rd_ctrl_IDR),             // 接收idr阶段数据存储器读取控制信号
    .dm_wr_ctrl_IDR(dm_wr_ctrl_IDR),             // 接收idr阶段数据存储器写入控制信号

    // 分支跳转输入信号
    .do_jump_IDR(do_jump_IDR),                // idr阶段传来的jump信号
    .is_branch_IDR(is_branch_IDR),              // idr阶段传来的branch信号
    .BrType_IDR(BrType_IDR),                 // idr阶段传来的Brtype信号

    // 分支跳转处理信号
    .branch_taken_EXB(branch_taken_EXB),           // 分支跳转信号
    .branch_target_EXB(branch_target_EXB),          // 分支跳转目标地址

    // 输出到下一阶段的信号
    .pc_EXB(pc_exb_to_exa),                     // exb阶段输入pc
    .reg_data1_EXB(reg_data1_EXB),              // 转发到exa阶段的源操作数1
    .reg_data2_EXB(reg_data2_EXB),              // 转发到exa阶段的源操作数2
    .imm_EXB(imm_EXB),                    // 转发给alu的立即数
    .rf_wr_en_EXB(rf_wr_en_EXB),               // 寄存器写使能信号
    .rf_wr_sel_EXB(rf_wr_sel_EXB),              // 转发寄存器写数据选择信号
    .alu_ctrl_EXB(alu_ctrl_EXB),               // 转发到exa阶段的alu控制信号
    .alu_a_sel_EXB(alu_a_sel_EXB),              // 转发到exa阶段的ALU选择信号
    .alu_b_sel_EXB(alu_b_sel_EXB),              // 转发到exa阶段的ALU选择信号
    .dm_rd_ctrl_EXB(dm_rd_ctrl_EXB),             // 转发读取控制信号
    .dm_wr_ctrl_EXB(dm_wr_ctrl_EXB),             // 转发写入控制信号
    .rd_EXB(rd_EXB)                       // 转发到exa阶段的目的寄存器地址
);

// 实例化stage6
pipeline_exa_stage6 stage6(
    .clk(clk),                         // 时钟信号
    .reset(rst),                       // 复位信号，低电平有效
    .stall(1'b0),                       // 流水线暂停信号

    // 接收来自EXB阶段的信号
    .reg_data1_EXB(reg_data1_EXB),              // 从ID阶段传递的源操作数1
    .reg_data2_EXB(reg_data2_EXB),              // 从ID阶段传递的源操作数2
    .imm_EXB(imm_EXB),                    // 从ID阶段传递的立即数
    .rd_EXB(rd_EXB),                     // 目的寄存器地址
    .pc_EXB(pc_exb_to_exa),                     // 从ID阶段传递的PC值
    .rf_wr_en_EXB(rf_wr_en_EXB),               // 从ID阶段传递的寄存器写使能信号
    .rf_wr_sel_EXB(rf_wr_sel_EXB),              // 从ID阶段传递的寄存器写数据选择信号
    .alu_ctrl_EXB(alu_ctrl_EXB),               // 用于选择ALU操作的控制信号
    .alu_a_sel_EXB(alu_a_sel_EXB),              // ALU选择信号
    .alu_b_sel_EXB(alu_b_sel_EXB),              // ALU选择信号
    .dm_rd_ctrl_EXB(dm_rd_ctrl_EXB),             // 接收id阶段数据存储器读取控制信号
    .dm_wr_ctrl_EXB(dm_wr_ctrl_EXB),             // 接收id阶段数据存储器写入控制信号

    // 输出到下一阶段
    .pc_EXA(pc_exa_to_memp),                     // mem阶段输入pc
    .rf_wr_en_EXA(rf_wr_en_EXA),               // 从ID阶段传递的寄存器写使能信号
    .rf_wr_sel_EXA(rf_wr_sel_EXA),              // 转发寄存器写数据选择信号
    .alu_result_EXA(alu_result_EXA),             // ALU执行的结果
    .dm_rd_ctrl_EXA(dm_rd_ctrl_EXA),             // 转发读取控制信号
    .dm_wr_ctrl_EXA(dm_wr_ctrl_EXA),             // 转发写入控制信号
    .reg_data2_EXA(reg_data2_EXA),              // 转发到mem阶段
    .rd_EXA(rd_EXA)                       // 转发到mem阶段的目的寄存器地址
);

// 实例化 MEMP 阶段
pipeline_memp_stage7 stage7(
    .clk(clk),                          // 时钟信号
    .reset(rst),                        // 复位信号，低电平有效
    .stall(1'b0),                        // 流水线暂停信号

    // 接收来自EX阶段的信号
    .pc_EXA(pc_exa_to_memp),                       // 从EX阶段传递的PC值
    .rf_wr_en_EXA(rf_wr_en_EXA),                 // EX阶段传递的寄存器写使能信号
    .rf_wr_sel_EXA(rf_wr_sel_EXA),                // EX阶段传递的寄存器写数据选择信号
    .alu_result_EXA(alu_result_EXA),               // 从EX阶段传递的ALU计算结果
    .dm_rd_ctrl_EXA(dm_rd_ctrl_EXA),               // 内存读控制信号
    .dm_wr_ctrl_EXA(dm_wr_ctrl_EXA),               // 内存写控制信号
    .reg_data2_EXA(reg_data2_EXA),                // EX阶段传递的寄存器数据2
    .rd_EXA(rd_EXA),                       // EX阶段传递的目的寄存器地址

    // 外设接口相关信号
    .sys_bus_addr(bus_addr),
    .sys_bus_din(bus_din),                  // 写入总线的数据
    .sys_bus_rd_ctrl(bus_rd_ctrl),              // 外设接口读控制信号
    .sys_bus_wr_ctrl(bus_wr_ctrl),              // 外设接口写控制信号

    // 与DRAM接口相关信号
    .dram_addr(dram_addr),
    .dram_din(dram_din),                     // 写入DRAM的数据
    .dram_rd_ctrl(dram_rd_ctrl),                 // DRAM读控制信号
    .dram_wr_ctrl(dram_wr_ctrl),                 // DRAM写控制信号

    // 传递给 MEMD 阶段的信号
    .is_dram_MEMP(is_dram_MEMP),                 // 标志是否需要访问DRAM
    .pc_MEMP(pc_memp_to_memr),                      // MEMD阶段的PC输入
    .rf_wr_sel_MEMP(rf_wr_sel_MEMP),               // 写回寄存器数据选择信号
    .rf_wr_en_MEMP(rf_wr_en_MEMP),                 // 写回寄存器写使能信号
    .alu_result_MEMP(alu_result_MEMP),              // 直接传递的ALU结果
    .rd_MEMP(rd_MEMP)                       // 下一级阶段传递的目标寄存器地址
);

// 实例化 MEMR 阶段
pipeline_memr_stage8 stage8(
    .clk(clk),                          // 时钟信号
    .reset(rst),                        // 复位信号，低电平有效
    .stall(1'b0),                        // 流水线暂停信号

    // 接收外设和内存读取数据
    .sys_bus_dout(bus_dout),                 // 从外设读取的数据
    .dram_dout(dram_dout),                    // 从DRAM读取的数据
    .dram_done(1'b1),                    // 内存操作完成信号

    // 接收来自 MEMP 阶段传递的信号
    .is_dram_MEMP(is_dram_MEMP),                 // 标志是否需要DRAM访问
    .pc_MEMP(pc_memp_to_memr),                      // MEMP 阶段传递的PC值
    .rf_wr_sel_MEMP(rf_wr_sel_MEMP),               // MEMP 阶段传递的寄存器写数据选择信号
    .rf_wr_en_MEMP(rf_wr_en_MEMP),                 // MEMP 阶段传递的寄存器写使能信号
    .alu_result_MEMP(alu_result_MEMP),              // ALU运算结果
    .rd_MEMP(rd_MEMP),                      // MEMP 阶段传递的目标寄存器地址

    // 向下一阶段传递的信号
    .mem_data_MEM(mem_data_MEM),                  // 内存读取的数据
    .pc_MEMR(pc_memr_to_wb),                       // MEMR 阶段的 PC 地址
    .rf_wr_sel_MEMR(rf_wr_sel_MEMR),                // 写回阶段的寄存器写数据选择信号
    .rf_wr_en_MEMR(rf_wr_en_MEMR),                 // 写回阶段的寄存器写使能信号
    .alu_result_MEMR(alu_result_MEMR),               // 传递的 ALU 运算结果
    .rd_MEMR(rd_MEMR)                         // 写回阶段的目标寄存器地址
);

// 实例化 WB 阶段
pipeline_wb_stage9 stage9 (
    .clk(clk),                          // 时钟信号
    .reset(rst),                        // 复位信号
    .stall(1'b0),                        // 流水线暂停信号

    // 控制信号和数据输入
    .rf_wr_sel(rf_wr_sel_MEMR),                    // 写回数据源选择信号
    .alu_result_MEM(alu_result_MEMR),               // ALU结果
    .mem_data_MEM(mem_data_MEM),                 // 内存数据
    .rd_MEM(rd_MEMR),                       // 目的寄存器地址
    .reg_write_MEM(rf_wr_en_MEMR),                // 写寄存器控制信号
    .pc_WB(pc_memr_to_wb),                        // 当前阶段的PC值

    // 输出信号
    .write_data_WB(write_data_WB),                // 写回寄存器数据
    .rd_WB(rd_WB),                        // 写回的目的寄存器地址
    .reg_write_WB(reg_write_WB)                  // 写回寄存器控制信号
);


endmodule