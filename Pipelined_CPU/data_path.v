`timescale 1ns / 1ns
module data_path(
    input rst,
    input clk,
    // -------------到sys_bus的连线---------------------------------
    output [2:0] bus_rd_ctrl,
    output [2:0] bus_wr_ctrl,
    output [63:0] bus_addr,
    output [63:0] bus_din,
    input [63:0] bus_dout,
    
    // ------------id阶段与寄存器堆的连接信号----------------------
    input [63:0] data_reg_read_1, data_reg_read_2, // 寄存器堆返回的数据信号
    output [4:0] addr_reg_read_1, addr_reg_read_2,  // 连接源寄存器堆地址
    // --------------wb阶段的输出(与寄存器堆的连线)-----------------
    output [63:0] write_data_WB,   // 数据信号
    output [4:0] rd_WB,            // 地址信号
    output reg_write_WB           // 使能控制信号
    // -------------------------------------------------------------
);

wire [63:0] pc_if_to_id, pc_id_to_ex, pc_ex_to_mem, pc_mem_to_wb; // 各阶段PC值之间的传递

// -----------------------if阶段-------------------------------
wire [31:0] instruction_IF; // if阶段取出的指令连接到id阶段
wire [63:0] im_addr_mem0;
// ---------------------------------------------------------------

// ------------id阶段的输出，连接到ex阶段----------------------
// wire [6:0] opcode_ID; 
// wire [2:0] funct3_ID;  
// wire [6:0] funct7_ID;  
wire [63:0] imm_ID;   

wire [63:0] reg_data1_ID;  // 源操作数1
wire [63:0] reg_data2_ID;  // 源操作数2
wire [4:0] rd_ID;          // 目的寄存器地址
wire [1:0] rf_wr_sel;      // 寄存器写回数据选择
wire rf_wr_en_ID;             // 传递寄存器写使能信号

// 传递内存相关的控制信号到后续阶段
wire [2:0] dm_rd_ctrl_ID;  // 内存读控制信号
wire [2:0] dm_wr_ctrl_ID;  // 内存写控制信号
// ---------------------------------------------------------

// ------------ex阶段的输出，连接到mem阶段----------------------
wire [63:0] alu_result_EX; // ALU执行的结果

// 将ID阶段传递来的控制信号继续传递给MEM阶段
wire [2:0] dm_rd_ctrl_EX;  // 内存读控制信号
wire [2:0] dm_wr_ctrl_EX;  // 内存写控制信号

wire rf_wr_en_EX;             // 传递寄存器写使能信号
wire [1:0] rf_wr_sel_EX;      // 传递寄存器数据选择信号

wire [63:0] reg_data2_EX;
wire [4:0] rs2_EX;
wire [4:0] rd_EX;
// --------------------------------------------------------------

// --------------与hazard模块的连线-----------------------
wire branch_taken_EX;
wire [63:0] branch_target_EX;
wire branch_taken_IF;
wire [63:0] branch_target_IF;
wire flush_ID;
// --------------------------------------------------------------

// ----------------id阶段的输出接入到ex阶段----------------------
wire alu_a_sel_ID;
wire alu_b_sel_ID;
wire [3:0] alu_ctrl_ID;
wire do_jump;
wire is_branch;
wire [2:0] BrType;
// -------------------------------------------------------------

// -----------------mem阶段的输出接入到wb阶段--------------------
wire [63:0] mem_data_MEM;   // 内存读取的数据
wire [63:0] alu_result_MEM; // 传递过来的alu计算数据
wire [4:0] rd_MEM;          // 传递过来的寄存器号
wire rf_wr_en_MEM;          // 从id阶段传递过来的寄存器写使能信号
wire [1:0] rf_wr_sel_MEM;   // 从id阶段传递过来的寄存器写入数据选择信号
// --------------------------------------------------------------

// -----------------mem阶段总线占用信号------------------------
wire memorying;
assign bus_addr = memorying?dm_addr_mem:im_addr_mem0;
wire [63:0] dm_addr_mem;
// -----------------------------------------------------------

// ----------------hazard模块信号定义----------------------------
wire pcFromTaken;
wire IF_ID_stall;
wire ID_EX_stall;
wire ID_EX_flush;
wire EX_MEM_flush;
wire IF_ID_flush;
// ------------------------------------------------------------

// 控制冒险模块
// module hazard (
//   input branch_taken_EX,
//   input [63:0] branch_target_EX,
//   output flush_ID,
//   output branch_taken_IF,
//   output [63:0] branch_target_IF
// );
hazard hazard0(
    .branch_taken_EX(branch_taken_EX),
    .branch_target_EX(branch_target_EX),
    .flush_ID(flush_ID),
    .branch_taken_IF(branch_taken_IF),
    .branch_target_IF(branch_target_IF)
);

// stage1
// module pipeline_if_stage (
//     input wire clk,              // 时钟信号
//     input wire reset,            // 复位信号，低电平有效
//     input wire stall,            // 流水线暂停信号
//     input wire branch_taken,     // 分支跳转信号
//     input wire [63:0] branch_target, // 分支跳转目标地址
    
//     input wire [31:0] im_dout,   // 连接到顶层模块中的指令存储器输出数据
//     output reg [63:0] im_addr,   // 连接到顶层模块中的指令存储器地址
    
//     output reg [63:0] pc_IF,     // 当前PC值
//     output reg [31:0] instruction_IF  // 取到的指令
// );

pipeline_if_stage stage1(
    .clk(clk),
    .reset(rst),
    .stall(memorying),
    .branch_taken(branch_taken_IF),
    .branch_target(branch_target_IF),
    .im_dout(bus_dout[31:0]),
    .im_addr(im_addr_mem0),
    .pc_IF(pc_if_to_id), // 传入下一周期的PC值(等于当前阶段指令位置)
    .instruction_IF(instruction_IF)
);


//stage2
// module pipeline_id_stage (
//     input wire clk,                   // 时钟信号
//     input wire reset,                 // 复位信号，低电平有效
//     input wire [31:0] instruction_ID, // 从IF阶段传来的指令
//     input wire [63:0] pc_ID,          // 从IF阶段传来的PC值

//     input wire [63:0] data_reg_read_1, data_reg_read_2, // 从寄存器堆读取的数据
    
//     output reg [63:0] reg_data1_ID,  // 解码出的源操作数1
//     output reg [63:0] reg_data2_ID,  // 解码出的源操作数2
//     output reg [4:0] rs1_ID,         // 源寄存器1地址
//     output reg [4:0] rs2_ID,         // 源寄存器2地址
//     output reg [4:0] rd_ID,          // 目的寄存器地址
//     output reg [6:0] opcode_ID,      // 解码出的操作码
//     output reg [2:0] funct3_ID,      // 解码出的功能码 funct3
//     output reg [6:0] funct7_ID,      // 解码出的功能码 funct7
//     output reg [63:0] imm_ID,        // 解码出的立即数

//     output reg pc_out,               // 输出到下一阶段的PC

//     // 控制信号
//     output reg rf_wr_en,             // 寄存器写使能信号
//     output reg do_jump,              // 跳转控制信号
//     output reg alu_a_sel,            // ALU 输入A选择信号
//     output reg alu_b_sel,            // ALU 输入B选择信号
//     output reg [3:0] alu_ctrl,       // ALU 控制信号
//     output reg [2:0] BrType,         // 分支类型控制信号
//     output reg [1:0] rf_wr_sel,      // 寄存器写回数据来源选择

//     // 与内存模块连接的信号
//     output reg [2:0] dm_rd_ctrl,     // 数据存储器读取控制信号
//     output reg [1:0] dm_wr_ctrl,     // 数据存储器写入控制信号

//     output reg [4:0] addr_reg_read_1, addr_reg_read_2 // 连接源寄存器堆地址
// );

pipeline_id_stage stage2(
    .clk(clk),
    .reset(rst),
    .flush(flush_ID),
    .stall(1'b0),
    .instruction_IF(instruction_IF),
    .pc_IF(pc_if_to_id),
    .data_reg_read_1(data_reg_read_1),
    .data_reg_read_2(data_reg_read_2),
    .reg_data1_ID(reg_data1_ID),
    .reg_data2_ID(reg_data2_ID),
    .rd_ID(rd_ID),
    .imm_ID(imm_ID),
    .pc_ID(pc_id_to_ex),
    .rf_wr_en(rf_wr_en_ID), // 寄存器写使能信号，需要传递至wb阶段
    .do_jump(do_jump), // jump控制信号，接入ex阶段（BrE || do_jump）
    .is_branch(is_branch),
    .alu_a_sel(alu_a_sel_ID),
    .alu_b_sel(alu_b_sel_ID),
    .alu_ctrl(alu_ctrl_ID),
    .BrType(BrType),
    .rf_wr_sel(rf_wr_sel),
    .dm_rd_ctrl(dm_rd_ctrl_ID),  // 新增信号
    .dm_wr_ctrl(dm_wr_ctrl_ID),  // 新增信号
    .addr_reg_read_1(addr_reg_read_1),
    .addr_reg_read_2(addr_reg_read_2)
);


// stage3
// module pipeline_ex_stage (
//     input wire clk,                  // 时钟信号
//     input wire reset,                // 复位信号，低电平有效
//     input wire [63:0] reg_data1_EX,  // 从ID阶段传递的源操作数1
//     input wire [63:0] reg_data2_EX,  // 从ID阶段传递的源操作数2
//     input wire [63:0] imm_EX,        // 从ID阶段传递的立即数
//     input wire [4:0] rs1_EX,         // 源寄存器1地址
//     input wire [4:0] rs2_EX,         // 源寄存器2地址
//     input wire [4:0] rd_EX,          // 目的寄存器地址
//     input wire [6:0] opcode_EX,      // 操作码
//     input wire [2:0] funct3_EX,      // 功能码 funct3
//     input wire [6:0] funct7_EX,      // 功能码 funct7
//     input wire [63:0] pc_EX,         // 从ID阶段传递的PC值
//     input wire rf_wr_en_ID,          // 从ID阶段传递的寄存器写使能信号，需要传递到wb阶段
//     input wire [1:0] rf_wr_sel_ID,         // 从ID阶段传递的寄存器写数据选择信号，需要传递到wb阶段

//     input wire [3:0] alu_ctrl,       // 用于选择ALU操作的控制信号(来自ctrl)
//     input wire alu_a_sel, alu_b_sel, // ALU选择信号（来自ctrl）

//     input wire [2:0] dm_rd_ctrl_ID,  // 接受id阶段数据存储器读取控制信号
//     input wire [1:0] dm_wr_ctrl_ID,  // 接受id阶段数据存储器写入控制信号

//     input wire do_jump,              // id阶段传来的jump信号
//     input wire [2:0] BrType,         // id阶段传来的Brtype信号

//     output reg [63:0] pc_out,               // mem阶段输入pc
//     output reg rf_wr_en_EX,          // 从ID阶段传递的寄存器写使能信号，需要传递到wb阶段
//     output reg [1:0] rf_wr_sel_EX,        // 从ID阶段传递的寄存器写数据选择信号，需要传递到wb阶段

//     output reg [63:0] alu_result_EX, // ALU执行的结果
//     output reg branch_taken_EX,      // 分支跳转信号
//     output reg [63:0] branch_target_EX, // 分支跳转目标地址
//     output reg [2:0] dm_rd_ctrl_EX, // 转发读取控制信号
//     output reg [1:0] dm_wr_ctrl_EX, // 转发写入控制信号
//     output reg [63:0] reg_data2_MEM,// 转发到mem阶段
//     output reg [4:0] rd_MEM        // 转发到mem阶段
// );

pipeline_ex_stage stage3(
    .clk(clk),
    .reset(rst),
    .stall(1'b0),
    .reg_data1_EX(reg_data1_ID),
    .reg_data2_EX(reg_data2_ID),
    .imm_EX(imm_ID),
    .rd_EX(rd_ID),
    // .opcode_EX(opcode_ID),
    .pc_EX(pc_id_to_ex),
    .rf_wr_en_ID(rf_wr_en_ID),             // 传递寄存器写使能信号
    .rf_wr_sel_ID(rf_wr_sel),
    .alu_ctrl(alu_ctrl_ID),
    .alu_a_sel(alu_a_sel_ID),
    .alu_b_sel(alu_b_sel_ID),
    .dm_rd_ctrl_ID(dm_rd_ctrl_ID), // 转发id信号
    .dm_wr_ctrl_ID(dm_wr_ctrl_ID), // 转发id信号
    .do_jump(do_jump),
    .is_branch(is_branch),
    .BrType(BrType),
    .pc_MEM(pc_ex_to_mem),
    .rf_wr_en_EX(rf_wr_en_EX),             // 传递寄存器写使能信号
    .rf_wr_sel_EX(rf_wr_sel_EX),
    .alu_result_EX(alu_result_EX),
    .branch_taken_EX(branch_taken_EX),
    .branch_target_EX(branch_target_EX),
    .dm_rd_ctrl_EX(dm_rd_ctrl_EX),  // 新增信号传递
    .dm_wr_ctrl_EX(dm_wr_ctrl_EX),   // 新增信号传递
    .reg_data2_MEM(reg_data2_EX),
    .rd_MEM(rd_EX)
);



// stage4
// module pipeline_mem_stage (
//     input wire clk,                     // 时钟信号
//     input wire reset,                   // 复位信号，低电平有效

//     // 上一阶段或id阶段的信号
//     input wire [63:0] alu_result_EX,    // 从EX阶段传递的ALU计算结果，作为地址
//     input wire [63:0] reg_data2_EX,     // 从EX阶段传递的源寄存器2的值 (用于存储数据)
//     input wire [4:0] rd_EX,             // 从EX阶段传递的目的寄存器地址
//     input wire [63:0] pc_MEM,           // 从EX阶段传递的PC值
//     input wire [2:0] dm_rd_ctrl_id,     // 内存读控制信号
//     input wire [1:0] dm_wr_ctrl_id,     // 内存写控制信号
//     input wire rf_wr_en_EX,             // id阶段传来的寄存器写使能信号
//     input wire [1:0] rf_wr_sel_EX,         // 从ID阶段传递的寄存器写数据选择信号，需要传递到wb阶段

//     // 与内存接口的信号
//     output reg [63:0] dm_addr,          // 传递给内存的地址信号
//     output reg [63:0] dm_din,           // 传递给内存的数据（写入）
//     input wire [63:0] dm_dout,          // 从内存读取的数据
//     output reg [2:0] dm_rd_ctrl,        // 内存读控制信号
//     output reg [1:0] dm_wr_ctrl,        // 内存写控制信号

//     // 传递给下一个阶段的信号
//     output reg [63:0] pc_out,           // 下一阶段的输入pc
//     output reg [1:0] rf_wr_sel_MEM,        // 从ID阶段传递的寄存器写数据选择信号，需要传递到wb阶段
//     output reg rf_wr_en_MEM,            // 传入到wb阶段的寄存器写使能信号
//     output reg [63:0] mem_data_MEM,     // 内存读取的数据
//     output reg [63:0] alu_result_MEM,   // 直接传递的ALU结果（用于不需要内存操作的指令）
//     output reg [4:0] rd_MEM,            // 传递给下一个阶段的目的寄存器地址
//     output reg mem_read_done_MEM        // 内存读取完成信号
// );

pipeline_mem_stage stage4(
    .clk(clk),
    .reset(rst),
    .alu_result_EX(alu_result_EX),
    .reg_data2_EX(reg_data2_EX),
    .rd_EX(rd_EX),
    .pc_MEM(pc_ex_to_mem),
    .rf_wr_en_EX(rf_wr_en_EX),
    .rf_wr_sel_EX(rf_wr_sel_EX),
    .dm_rd_ctrl_id(dm_rd_ctrl_EX),  // 修改为从EX阶段传入
    .dm_wr_ctrl_id(dm_wr_ctrl_EX),  // 修改为从EX阶段传入
    .dm_addr(dm_addr_mem),
    .dm_din(bus_din),
    .dm_dout(bus_dout),
    .dm_rd_ctrl(bus_rd_ctrl),
    .dm_wr_ctrl(bus_wr_ctrl),
    .memorying(memorying),
    .rf_wr_sel_MEM(rf_wr_sel_MEM),
    .pc_WB(pc_mem_to_wb),
    .rf_wr_en_MEM(rf_wr_en_MEM),
    .mem_data_MEM(mem_data_MEM),
    .alu_result_MEM(alu_result_MEM),
    .rd_MEM(rd_MEM),
    .mem_read_done_MEM()
);

// stage5
// module pipeline_wb_stage (
//     input wire clk,                    // 时钟信号
//     input wire reset,                  // 复位信号，低电平有效
//     input wire [1:0] rf_wr_sel,              // 控制信号，选择从内存还是ALU写回
//     input wire [63:0] alu_result_MEM,  // 从MEM阶段传递的ALU结果
//     input wire [63:0] mem_data_MEM,    // 从MEM阶段传递的内存数据
//     input wire [4:0] rd_MEM,           // 从MEM阶段传递的目的寄存器地址
//     input wire reg_write_MEM,          // 来自MEM阶段的写寄存器信号
//     input wire [63:0] pc_in,           // 该阶段的pc值

//     output reg [63:0] write_data_WB,   // 写回寄存器的数据
//     output reg [4:0] rd_WB,            // 写回的目的寄存器地址
//     output reg reg_write_WB            // 写回寄存器的控制信号
// );

pipeline_wb_stage stage5(
    .clk(clk),
    .reset(rst),
    .rf_wr_sel(rf_wr_sel_MEM),
    .alu_result_MEM(alu_result_MEM),
    .mem_data_MEM(mem_data_MEM),
    .rd_MEM(rd_MEM),
    .reg_write_MEM(rf_wr_en_MEM),
    .pc_WB(pc_mem_to_wb),
    .write_data_WB(write_data_WB),
    .rd_WB(rd_WB),
    .reg_write_WB(reg_write_WB)
);

endmodule