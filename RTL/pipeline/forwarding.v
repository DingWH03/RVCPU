module forwarding (
    input [4:0] addr_reg_read_1_ID, // ID阶段寄存器读取地址1
    input [4:0] addr_reg_read_2_ID, // ID阶段寄存器读取地址2

    input [4:0] rd_EX, // EX阶段目标寄存器地址
    input rf_wr_en_EX,  // EX阶段寄存器写使能信号
    input [63:0] alu_result_EX, // EX阶段ALU结果

    input [63:0] pc_MEM, // MEM阶段时钟到来前PC地址
    input [4:0] rd_MEM, // MEM阶段目标寄存器地址
    input [2:0] dm_rd_ctrl_MEM, // MEM阶段内存读控制信号
    input [1:0] rf_wr_sel_MEM, // MEM阶段数据选择信号
    input rf_wr_en_MEM,  // MEM阶段寄存器写使能信号
    input [63:0] mem_data_MEM, // MEM阶段内存数据
    input [63:0] alu_result_MEM, // MEM阶段传递的内存读取结果

    input [4:0] rd_WB, // WB阶段目标寄存器地址
    input reg_write_WB, // WB阶段寄存器写使能信号
    input [63:0] write_data_WB, // WB阶段写入数据

    output reg [63:0] forward_rs1_data, // 前递寄存器1数据
    output reg [63:0] forward_rs2_data, // 前递寄存器2数据
    output reg forward_rs1_sel, // 前递寄存器1数据选择信号
    output reg forward_rs2_sel  // 前递寄存器2数据选择信号
);

    wire [63:0] pc_plus4_MEM;
    reg [63:0] write_data_MEM;
    assign pc_plus4_MEM = pc_MEM + 4;

    // 写回数据选择逻辑
    always @(*)
    begin
    case(rf_wr_sel_MEM)
        2'b00:  write_data_MEM = 64'h0;
        2'b01:  write_data_MEM = pc_plus4_MEM;
        2'b10:  write_data_MEM = alu_result_MEM;
        2'b11:  write_data_MEM = mem_data_MEM;
    default:write_data_MEM = 64'h0;
    endcase
    end

    // 前递逻辑：寄存器1数据
    always @(*) begin
        if (rf_wr_en_EX && (rd_EX != 5'b0) && (addr_reg_read_1_ID == rd_EX)) begin
            forward_rs1_data = alu_result_EX; // EX阶段数据转发
            forward_rs1_sel = 1'b1;
        end else if ((dm_rd_ctrl_MEM != 4'b0||rf_wr_en_MEM) && (rd_MEM != 5'b0) && (addr_reg_read_1_ID == rd_MEM)) begin
            forward_rs1_data = write_data_MEM; // MEM阶段数据转发
            forward_rs1_sel = 1'b1;
        end else if (reg_write_WB && (rd_WB != 5'b0) && (addr_reg_read_1_ID == rd_WB)) begin
            forward_rs1_data = write_data_WB; // WB阶段数据转发
            forward_rs1_sel = 1'b1;
        end else begin
            forward_rs1_data = 64'b0; // 默认值
            forward_rs1_sel = 1'b0;  // 不进行前递
        end
    end

    // 前递逻辑：寄存器2数据
    always @(*) begin
        if (rf_wr_en_EX && (rd_EX != 5'b0) && (addr_reg_read_2_ID == rd_EX)) begin
            forward_rs2_data = alu_result_EX; // EX阶段数据转发
            forward_rs2_sel = 1'b1;
        end else if ((dm_rd_ctrl_MEM != 4'b0||rf_wr_en_MEM) && (rd_MEM != 5'b0) && (addr_reg_read_2_ID == rd_MEM)) begin
            forward_rs2_data = write_data_MEM; // MEM阶段数据转发
            forward_rs2_sel = 1'b1;
        end else if (reg_write_WB && (rd_WB != 5'b0) && (addr_reg_read_2_ID == rd_WB)) begin
            forward_rs2_data = write_data_WB; // WB阶段数据转发
            forward_rs2_sel = 1'b1;
        end else begin
            forward_rs2_data = 64'b0; // 默认值
            forward_rs2_sel = 1'b0;  // 不进行前递
        end
    end

endmodule
