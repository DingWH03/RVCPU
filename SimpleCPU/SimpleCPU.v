module SimpleCPU (
    input wire clk,              // 时钟输入
    input wire reset,            // 复位输入
    input wire [15:0] data_out,  // 读取内存中的数据
    output wire rw_enable,       // 读写内存使能，低电平有效
    output wire [7:0] address,   // 存储器地址
    output wire [15:0] data_in   // 写入数据到内存
);

    wire [15:0] instruction;  // 从指令内存读取的指令
    wire [15:0] ALU_result;   // ALU 计算结果
    wire [3:0] ALU_op;        // ALU 操作码
    wire [2:0] reg_read1, reg_read2, reg_write;  // 寄存器读写地址
    wire reg_write_enable;    // 寄存器写使能

    assign instruction = data_out;

    // PC 模块实例化
    PC pc_inst (
        .clk(clk),
        .reset(reset),
        .pc(address)  // PC 输出地址
    );

    // CU 模块实例化
    CU cu_inst (
        .Ins(instruction),
        .Register_write_enable(reg_write_enable),
        .ALU_opcode(ALU_op),
        .r1(reg_read1),
        .r2(reg_read2),
        .r3(reg_write)
    );

    // RegisterFile 模块实例化
    RegisterFile rf_inst (
        .clk(clk),
        .readAddr1(reg_read1),
        .readAddr2(reg_read2),
        .writeAddr(reg_write),
        .writeEnable(reg_write_enable),
        .writeData(ALU_result),  // 写入 ALU 计算结果到寄存器
        .readData1(),  // 读端口1的读数据
        .readData2()   // 读端口2的读数据
    );

    // ALU 模块实例化
    ALU alu_inst (
        .A(rf_inst.readData1),  // 从寄存器读取数据作为 ALU 输入 A
        .B(rf_inst.readData2),  // 从寄存器读取数据作为 ALU 输入 B
        .opcode(ALU_op),
        .result(ALU_result)     // ALU 计算结果输出
    );

endmodule
