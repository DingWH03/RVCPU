`timescale 1ns / 1ns
`include "Modules/defines.sv"

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
logic [63:0] dm_addr_reg;
logic [63:0] dm_din_reg;
logic [19:0] state_addr;

// 地址转换
assign state_addr = (dm_addr_reg >= 64'h80000000) ? ((dm_addr_reg - 64'h80000000)>>1) : 19'b0;
assign addr = state_addr + (2'b11 - write_count);

// 数据总线双向控制
assign data = (curr_state == WRITE) ? wr_data : 16'bz;

// 状态机逻辑
always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        curr_state  <= IDLE;
        write_count <= 2'b00;
        read_count  <= 2'b00;
        write_en <= 1'b0; // 写使能
        dm_addr_reg <= 0;
        dm_din_reg <= 0;
    end else begin
        curr_state <= next_state;
        if (next_state != WRITE) write_en <= 1'b0;
        else write_en <= 1'b1; 
        if (curr_state == IDLE && next_state != IDLE) begin
            if (next_state == WRITE)begin // 先检查写
                dm_din_reg <= dm_din;
                dm_addr_reg <= dm_addr;
                case (dm_wr_ctrl)
                    3'b001:write_count <= 2'b11;
                    3'b010:write_count <= 2'b11;
                    3'b011:write_count <= 2'b10;
                    3'b100:write_count <= 2'b00;
                endcase
            end else begin
                dm_addr_reg <= dm_addr;
                case (dm_rd_ctrl)
                    3'b001:read_count <= 2'b11;
                    3'b010:read_count <= 2'b11;
                    3'b011:read_count <= 2'b11;
                    3'b100:read_count <= 2'b11;
                    3'b101:read_count <= 2'b10;
                    3'b110:read_count <= 2'b00;
                endcase
            end
        end else begin
            case (curr_state)
                IDLE: begin
                    write_count <= 2'b00;
                    read_count  <= 2'b00;
                    dm_addr_reg <= 0;
                    dm_din_reg <= 0;
                end
                WRITE: begin
                    write_count <= write_count + 2'b01;
                end
                READ: begin
                    read_count <= read_count + 2'b01;
                end
            endcase
        end
    end
end

// 状态转移逻辑
always_comb begin
    next_state = curr_state;
    case (curr_state)
        IDLE: begin
            if (dm_wr_ctrl != 0) begin
                next_state = WRITE;
            end else if (dm_rd_ctrl != 0) begin
                next_state = READ;
            end
        end
        WRITE: begin
            if (write_count == 2'b11) begin
                next_state = IDLE;
            end
        end
        READ: begin
            if (read_count == 2'b11) begin
                next_state = IDLE;
            end
        end
    endcase
end

// 写数据输出逻辑
always_comb begin
    case (write_count)
        2'b00: wr_data = dm_din_reg[63:48];
        2'b01: wr_data = dm_din_reg[47:32];
        2'b10: wr_data = dm_din_reg[31:16];
        2'b11: wr_data = dm_din_reg[15:0];
        default: wr_data = 16'b0;
    endcase
end

// 读数据输出逻辑
always_comb begin
    case (read_count)
        2'b00: rd_data[63:48] = data;
        2'b01: rd_data[47:32] = data;
        2'b10: rd_data[31:16] = data;
        2'b11: rd_data[15:0] = data;
        default: rd_data = 64'b0;
    endcase
end

// 读数据输出逻辑
assign dm_dout = rd_data;

// 状态输出
assign state = next_state;

endmodule
