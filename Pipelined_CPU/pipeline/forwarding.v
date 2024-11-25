module forwarding (
    input [4:0] addr_reg_read_1_IF, // ID阶段寄存器读取地址1
    input [4:0] addr_reg_read_2_IF, // ID阶段寄存器读取地址2

    input [4:0] rd_ID, // EX阶段目标寄存器地址
    input rf_wr_en_ID,  // EX阶段寄存器写使能信号
    input [63:0] alu_result_EX, // EX阶段ALU结果

    input [4:0] rd_EX, // MEM阶段目标寄存器地址
    input [2:0] dm_rd_ctrl_EX, // MEM阶段内存读控制信号
    input [63:0] mem_data_MEM, // MEM阶段内存数据

    input [4:0] rd_MEM, // WB阶段目标寄存器地址
    input reg_write_MEM, // WB阶段寄存器写使能信号
    input [63:0] write_data_WB, // WB阶段写入数据

    output reg [63:0] forward_rs1_data, // 前递寄存器1数据
    output reg [63:0] forward_rs2_data, // 前递寄存器2数据
    output reg forward_rs1_sel, // 前递寄存器1数据选择信号
    output reg forward_rs2_sel  // 前递寄存器2数据选择信号
);

    // 前递逻辑：寄存器1数据
    always @(*) begin
        if (rf_wr_en_ID && (rd_ID != 5'b0) && (addr_reg_read_1_IF == rd_ID)) begin
            forward_rs1_data = alu_result_EX; // EX阶段数据转发
            forward_rs1_sel = 1'b1;
        end else if ((dm_rd_ctrl_EX != 4'b0) && (rd_EX != 5'b0) && (addr_reg_read_1_IF == rd_EX)) begin
            forward_rs1_data = mem_data_MEM; // MEM阶段数据转发
            forward_rs1_sel = 1'b1;
        end else if (reg_write_MEM && (rd_MEM != 5'b0) && (addr_reg_read_1_IF == rd_MEM)) begin
            forward_rs1_data = write_data_WB; // WB阶段数据转发
            forward_rs1_sel = 1'b1;
        end else begin
            forward_rs1_data = 64'b0; // 默认值
            forward_rs1_sel = 1'b0;  // 不进行前递
        end
    end

    // 前递逻辑：寄存器2数据
    always @(*) begin
        if (rf_wr_en_ID && (rd_ID != 5'b0) && (addr_reg_read_2_IF == rd_ID)) begin
            forward_rs2_data = alu_result_EX; // EX阶段数据转发
            forward_rs2_sel = 1'b1;
        end else if ((dm_rd_ctrl_EX != 4'b0) && (rd_EX != 5'b0) && (addr_reg_read_2_IF == rd_EX)) begin
            forward_rs2_data = mem_data_MEM; // MEM阶段数据转发
            forward_rs2_sel = 1'b1;
        end else if (reg_write_MEM && (rd_MEM != 5'b0) && (addr_reg_read_2_IF == rd_MEM)) begin
            forward_rs2_data = write_data_WB; // WB阶段数据转发
            forward_rs2_sel = 1'b1;
        end else begin
            forward_rs2_data = 64'b0; // 默认值
            forward_rs2_sel = 1'b0;  // 不进行前递
        end
    end

endmodule
