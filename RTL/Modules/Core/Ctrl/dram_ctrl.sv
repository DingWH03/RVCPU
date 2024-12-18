`timescale 1ns / 1ns
`include "../defines.sv"

module dram_ctrl(
    input  logic         clk,
    input  logic         rst,
    input  logic [2:0]   dm_rd_ctrl,
    input  logic [2:0]   dm_wr_ctrl,
    input  logic [63:0]  dm_addr,
    input  logic [63:0]  dm_din,
    output logic [63:0]  dm_dout,
    output logic [1:0]   state,  // 状态输出
    // 连接存储芯片
    inout  logic [15:0]  data,
    output logic         write_en,
    output logic [18:0]  addr
);

// 内部信号
typedef enum logic [1:0] {
    IDLE    = 2'b00, // 空闲
    READ    = 2'b01, // 读数据
    WRITE   = 2'b10  // 写数据
} state_t;

state_t curr_state, next_state;
logic [1:0] write_count;  // 写操作计数器
logic [1:0] read_count;   // 读操作计数器
logic [15:0] wr_data;     // 当前写入的数据
logic [63:0] data_buffer; // 数据缓冲区
logic [63:0] rd_data;     // 读出的数据

// 地址转换
assign addr = (dm_addr >= 64'h80000000) ? (dm_addr - 64'h80000000) : 64'b0;

// 数据总线双向控制
assign data = (curr_state == WRITE) ? wr_data : 16'bz;

// 状态机逻辑
always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        curr_state  <= IDLE;
        write_count <= 2'b00;
        read_count  <= 2'b00;
        rd_data     <= 64'b0;
    end else begin
        curr_state <= next_state;

        case (curr_state)
            IDLE: begin
                write_count <= 2'b00;
                read_count  <= 2'b00;
            end
            WRITE: begin
                if (write_count < dm_wr_ctrl) begin
                    write_count <= write_count + 2'b01;
                end
            end
            READ: begin
                if (read_count < dm_rd_ctrl) begin
                    read_count <= read_count + 2'b01;
                    rd_data <= {rd_data[47:0], data}; // 拼接16位数据
                end
            end
        endcase
    end
end

// 状态转移逻辑
always_comb begin
    next_state = curr_state;
    write_en = 1'b0;

    case (curr_state)
        IDLE: begin
            if (dm_wr_ctrl != 0) begin
                next_state = WRITE;
            end else if (dm_rd_ctrl != 0) begin
                next_state = READ;
            end
        end
        WRITE: begin
            if (write_count < dm_wr_ctrl) begin
                write_en = 1'b1; // 写使能
            end else begin
                next_state = IDLE;
            end
        end
        READ: begin
            if (read_count >= dm_rd_ctrl) begin
                next_state = IDLE;
            end
        end
    endcase
end

// 写数据输出逻辑
always_comb begin
    case (write_count)
        2'b00: wr_data = dm_din[63:48];
        2'b01: wr_data = dm_din[47:32];
        2'b10: wr_data = dm_din[31:16];
        2'b11: wr_data = dm_din[15:0];
        default: wr_data = 16'b0;
    endcase
end

// 读数据输出逻辑
assign dm_dout = rd_data;

// 状态输出
assign state = curr_state;

endmodule
