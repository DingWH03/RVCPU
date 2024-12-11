module forwarding (
    input logic [4:0] rs1_IDC, // IDC阶段寄存器读取地址1
    input logic [4:0] rs2_IDC, // IDC阶段寄存器读取地址2

    input logic [4:0] rd_IDR, // IDR阶段目标寄存器地址
    input logic rf_wr_en_IDR,  // IDR阶段寄存器写使能信号

    input logic [4:0] rd_EXB, // EXA阶段目标寄存器地址
    input logic rf_wr_en_EXB,  // EXA阶段寄存器写使能信号

    input logic [4:0] rd_EXA, // EXA阶段目标寄存器地址
    input logic rf_wr_en_EXA,  // EXA阶段寄存器写使能信号
    input logic [63:0] alu_result_EXA, // EX阶段ALU结果

    // MEM阶段转发的数据有两种，一种是自己从存储器中读取的数据，另一种是从ex转移到wb阶段写回的数据，在memp阶段虽然未完成读写但是仍然可以前递wb需要传递的数据
    // MEMP
    input logic [63:0] pc_MEMP, // MEMP阶段时钟到来前PC地址
    input logic [4:0] rd_MEMP, // MEMP阶段目标寄存器地址
    input logic [2:0] dm_rd_ctrl_MEMP, // MEMP阶段内存读控制信号
    input logic [1:0] rf_wr_sel_MEMP, // MEMP阶段数据选择信号
    input logic rf_wr_en_MEMP,  // MEMP阶段寄存器写使能信号
    input logic [63:0] alu_result_MEMP, // MEMP阶段传递的内存读取结果

    // MEMR
    input logic [63:0] pc_MEMR, // MEMR阶段时钟到来前PC地址
    input logic [4:0] rd_MEMR, // MEMR阶段目标寄存器地址
    input logic [2:0] dm_rd_ctrl_MEMR, // MEMR阶段内存读控制信号
    input logic [1:0] rf_wr_sel_MEMR, // MEMR阶段数据选择信号
    input logic rf_wr_en_MEMR,  // MEMR阶段寄存器写使能信号
    input logic [63:0] mem_data_MEMR, // MEMR阶段内存数据
    input logic [63:0] alu_result_MEMR, // MEMR阶段传递的内存读取结果

    input logic [4:0] rd_WB, // WB阶段目标寄存器地址
    input logic reg_write_WB, // WB阶段寄存器写使能信号
    input logic [63:0] write_data_WB, // WB阶段写入数据

    output logic no_forwarding_data_IDR,  // 没有可转发的数据暂停IDR
    output logic no_forwarding_data_EXB,  // 没有可转发的数据暂停IDR
    output logic no_forwarding_data_MEMP,  // 没有可转发的数据暂停IDR
    output logic [63:0] forward_rs1_data, // 前递寄存器1数据
    output logic [63:0] forward_rs2_data, // 前递寄存器2数据
    output logic forward_rs1_sel, // 前递寄存器1数据选择信号
    output logic forward_rs2_sel  // 前递寄存器2数据选择信号
);
    logic no_forwarding_data1_IDR, no_forwarding_data1_EXB, no_forwarding_data1_MEMP;
    logic no_forwarding_data2_IDR, no_forwarding_data2_EXB, no_forwarding_data2_MEMP;
    assign no_forwarding_data_IDR = no_forwarding_data1_IDR | no_forwarding_data2_IDR;
    assign no_forwarding_data_EXB = no_forwarding_data1_EXB | no_forwarding_data2_EXB;
    assign no_forwarding_data_MEMP = no_forwarding_data1_MEMP | no_forwarding_data2_MEMP;

    logic [63:0] pc_plus4_MEMP;
    logic [63:0] write_data_MEMP;
    assign pc_plus4_MEMP = pc_MEMP + 4;

    // 写回数据选择逻辑(判断寄存器wb写回数据的来源)
    always @(*)
    begin
    case(rf_wr_sel_MEMP)
        2'b00:  write_data_MEMP = 64'h0;
        2'b01:  write_data_MEMP = pc_plus4_MEMP;
        2'b10:  write_data_MEMP = alu_result_MEMP;
        2'b11:  write_data_MEMP = 64'h0;
    default:write_data_MEMP = 64'h0;
    endcase
    end

    logic [63:0] pc_plus4_MEMR;
    logic [63:0] write_data_MEMR;
    assign pc_plus4_MEMR = pc_MEMR + 4;

    // 写回数据选择逻辑(判断寄存器wb写回数据的来源)
    always @(*)
    begin
    case(rf_wr_sel_MEMR)
        2'b00:  write_data_MEMR = 64'h0;
        2'b01:  write_data_MEMR = pc_plus4_MEMR;
        2'b10:  write_data_MEMR = alu_result_MEMR;
        2'b11:  write_data_MEMR = mem_data_MEMR;
    default:write_data_MEMR = 64'h0;
    endcase
    end

    // 前递逻辑：寄存器1数据
    always_comb begin
        if (rf_wr_en_IDR && (rd_IDR != 5'b0) && (rs1_IDC == rd_IDR)) begin
            forward_rs1_data = 0; // EXB阶段数据转发失败暂停流水线
            no_forwarding_data1_IDR = 1;
            no_forwarding_data1_EXB = 0;
            no_forwarding_data1_MEMP = 0;
            forward_rs1_sel = 1'b1;
        end else if (rf_wr_en_EXB && (rd_EXB != 5'b0) && (rs1_IDC == rd_EXB)) begin
            forward_rs1_data = 0; // EXB阶段数据转发失败暂停流水线
            no_forwarding_data1_EXB = 1;
            no_forwarding_data1_IDR = 0;
            no_forwarding_data1_MEMP = 0;
            forward_rs1_sel = 1'b1;
        end else if (rf_wr_en_EXA && (rd_EXA != 5'b0) && (rs1_IDC == rd_EXA)) begin
            forward_rs1_data = alu_result_EXA; // EXA阶段数据转发
            no_forwarding_data1_IDR = 0;
            no_forwarding_data1_EXB = 0;
            no_forwarding_data1_MEMP = 0;
            forward_rs1_sel = 1'b1;
        end else if ((dm_rd_ctrl_MEMP != 4'b0) && (rd_MEMP != 5'b0) && (rs1_IDC == rd_MEMP)) begin
            forward_rs1_data = 0; // MEMP阶段数据转发
            no_forwarding_data1_MEMP = 1;
            no_forwarding_data1_IDR = 0;
            no_forwarding_data1_EXB = 0;
            forward_rs1_sel = 1'b1;
        end else if ((dm_rd_ctrl_MEMP == 4'b0&&rf_wr_en_MEMP) && (rd_MEMP != 5'b0) && (rs1_IDC == rd_MEMP)) begin
            forward_rs1_data = write_data_MEMP; // MEMRR阶段数据转发
            no_forwarding_data1_IDR = 0;
            no_forwarding_data1_EXB = 0;
            no_forwarding_data1_MEMP = 0;
            forward_rs1_sel = 1'b1;
        end else if ((dm_rd_ctrl_MEMR != 4'b0||rf_wr_en_MEMR) && (rd_MEMR != 5'b0) && (rs1_IDC == rd_MEMR)) begin
            forward_rs1_data = write_data_MEMR; // MEMR阶段数据转发
            no_forwarding_data1_IDR = 0;
            no_forwarding_data1_EXB = 0;
            no_forwarding_data1_MEMP = 0;
            forward_rs1_sel = 1'b1;
        end else if (reg_write_WB && (rd_WB != 5'b0) && (rs1_IDC == rd_WB)) begin
            forward_rs1_data = write_data_WB; // WB阶段数据转发
            no_forwarding_data1_IDR = 0;
            no_forwarding_data1_EXB = 0;
            no_forwarding_data1_MEMP = 0;
            forward_rs1_sel = 1'b1;
        end else begin
            forward_rs1_data = 64'b0; // 默认值
            no_forwarding_data1_IDR = 0;
            no_forwarding_data1_EXB = 0;
            no_forwarding_data1_MEMP = 0;
            forward_rs1_sel = 1'b0;  // 不进行前递
        end
    end

    // 前递逻辑：寄存器2数据
    always_comb begin
        if (rf_wr_en_IDR && (rd_IDR != 5'b0) && (rs2_IDC == rd_IDR)) begin
            forward_rs2_data = 0; // EXB阶段数据转发失败暂停流水线
            no_forwarding_data2_IDR = 1;
            no_forwarding_data2_EXB = 0;
            no_forwarding_data2_MEMP = 0;
            forward_rs2_sel = 1'b1;
        end else if (rf_wr_en_EXB && (rd_EXB != 5'b0) && (rs2_IDC == rd_EXB)) begin
            forward_rs2_data = 0; // EXB阶段数据转发失败暂停流水线
            no_forwarding_data2_EXB = 1;
            no_forwarding_data2_IDR = 0;
            no_forwarding_data2_MEMP = 0;
            forward_rs2_sel = 1'b1;
        end else if (rf_wr_en_EXA && (rd_EXA != 5'b0) && (rs2_IDC == rd_EXA)) begin
            forward_rs2_data = alu_result_EXA; // EXA阶段数据转发
            no_forwarding_data2_IDR = 0;
            no_forwarding_data2_EXB = 0;
            no_forwarding_data2_MEMP = 0;
            forward_rs2_sel = 1'b1;
        end else if ((dm_rd_ctrl_MEMP != 4'b0) && (rd_MEMP != 5'b0) && (rs2_IDC == rd_MEMP)) begin
            forward_rs2_data = 0; // MEMP阶段数据转发
            no_forwarding_data2_MEMP = 1;
            no_forwarding_data2_IDR = 0;
            no_forwarding_data2_EXB = 0;
            forward_rs2_sel = 1'b1;
        end else if ((dm_rd_ctrl_MEMP == 4'b0&&rf_wr_en_MEMP) && (rd_MEMP != 5'b0) && (rs2_IDC == rd_MEMP)) begin
            forward_rs2_data = write_data_MEMP; // MEMRR阶段数据转发
            no_forwarding_data2_IDR = 0;
            no_forwarding_data2_EXB = 0;
            no_forwarding_data2_MEMP = 0;
            forward_rs2_sel = 1'b1;
        end else if ((dm_rd_ctrl_MEMR != 4'b0||rf_wr_en_MEMR) && (rd_MEMR != 5'b0) && (rs2_IDC == rd_MEMR)) begin
            forward_rs2_data = write_data_MEMR; // MEMR阶段数据转发
            no_forwarding_data2_IDR = 0;
            no_forwarding_data2_EXB = 0;
            no_forwarding_data2_MEMP = 0;
            forward_rs2_sel = 1'b1;
        end else if (reg_write_WB && (rd_WB != 5'b0) && (rs2_IDC == rd_WB)) begin
            forward_rs2_data = write_data_WB; // WB阶段数据转发
            no_forwarding_data2_IDR = 0;
            no_forwarding_data2_EXB = 0;
            no_forwarding_data2_MEMP = 0;
            forward_rs2_sel = 1'b1;
        end else begin
            forward_rs2_data = 64'b0; // 默认值
            no_forwarding_data2_IDR = 0;
            no_forwarding_data2_EXB = 0;
            no_forwarding_data2_MEMP = 0;
            forward_rs2_sel = 1'b0;  // 不进行前递
        end
    end

endmodule
