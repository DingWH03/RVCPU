module dcache(
    input logic clk,
    input logic rst,
    // 缓存数据准备就绪信号
    output logic data_ready,
    // 连接到mem阶段的信号
    input logic [63:0] addr,
    input logic [63:0] din,
    output logic [63:0] dout,
    input logic [2:0] rd_ctrl,
    input logic [2:0] wr_ctrl,
    // 连接到dram_ctrl的信号
    input logic [1:0] state, // 存储器状态
    output logic [63:0] dram_addr,
    output logic [63:0] dram_din,
    input logic [63:0] dram_dout,
    output logic [2:0] dram_rd_ctrl,
    output logic [2:0] dram_wr_ctrl
);
    // Parameters
    parameter int ADDRESS_WIDTH = 64;     // 地址总线宽度
    parameter int DATA_BUS_WIDTH = 64;   // 数据总线宽度
    parameter int CACHE_LINE_SIZE = 64;  // 缓存行大小（单位：字节）
    parameter int CACHE_LINES = 256;     // 缓存行数量

    // Derived parameters
    parameter int OFFSET_BITS = $clog2(CACHE_LINE_SIZE);  // 偏移长度
    parameter int INDEX_BITS = $clog2(CACHE_LINES);       // 索引长度
    parameter int COUNTER_LEN = $clog2(CACHE_LINE_SIZE / (DATA_BUS_WIDTH / 8));     // 计数器长度
    parameter int TAG_BITS = ADDRESS_WIDTH - OFFSET_BITS - INDEX_BITS;  // 标签长度

    logic [CACHE_LINE_SIZE*8-1:0] cache_data[CACHE_LINES-1:0];  // 缓存数据
    logic [TAG_BITS-1:0] cache_tags[CACHE_LINES-1:0];  // 缓存标签
    logic valid_bits[CACHE_LINES-1:0];  // 有效位
    logic dirty_bits[CACHE_LINES-1:0];  // 脏位
    logic [INDEX_BITS-1:0] cache_index;  // 缓存索引
    logic [TAG_BITS-1:0] cache_tag;  // 缓存标签
    logic [OFFSET_BITS-1:0] cache_offset;  // 缓存偏移

    logic [COUNTER_LEN-1:0] counter;  // 计数器
    logic [OFFSET_BITS-1:0] counter2offset;  // 计数器转偏移
    assign counter2offset = counter * (DATA_BUS_WIDTH / 8);  // 计数器转偏移

    initial begin
        valid_bits = '{default: 0};
        dirty_bits = '{default: 0};
        cache_tags = '{default: 0};
        cache_data = '{default: 0};
    end


    // 地址解析
    assign cache_offset = addr[OFFSET_BITS-1:0];  // 偏移量：最低位
    assign cache_index = addr[OFFSET_BITS +: INDEX_BITS];  // 索引：偏移量左侧的中间部分
    assign cache_tag = addr[ADDRESS_WIDTH-1:OFFSET_BITS + INDEX_BITS];  // 标签：最高位部分

    logic hit;
    logic valid;
    logic dirty;
    logic uncached;  // 地址无效
    assign uncached = addr[31:28] != 4'd8 || addr[63:32] != 32'd0;
    assign hit = valid_bits[cache_index] && cache_tags[cache_index] == cache_tag;
    assign valid = valid_bits[cache_index];
    assign dirty = valid_bits[cache_index] && dirty_bits[cache_index];

    logic [CACHE_LINE_SIZE*8-1:0] x0 = cache_data[0];
    logic [1:0] write_cache_done;

    logic [DATA_BUS_WIDTH-1:0] temp_cache_data; // 缓存数据暂存

    // 定义状态机
    typedef enum logic[1:0] {
        IDLE = 2'b00,         // 空闲状态
        FETCH = 2'b01,        // 数据获取状态
        WRITEBACK = 2'b10,    // 写回状态
        UNCACHED = 2'b11      // 地址无效
    } state_t;

    state_t current_cstate, next_cstate;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            current_cstate <= IDLE;
            counter <= 0;
            write_cache_done <= 0;
            temp_cache_data <= 0;
        end else begin
            case(current_cstate)
                IDLE: begin
                    counter <= 0;
                    current_cstate <= next_cstate;
                    if (hit && wr_ctrl) begin
                        temp_cache_data <= din;
                        write_cache_done <= write_cache_done + 1;
                        dirty_bits[cache_index] <= 1;
                        case (wr_ctrl)
                            3'b001: begin // 写8位
                                cache_data[cache_index][cache_offset * 8 +: 8] = temp_cache_data[7:0];
                            end
                            3'b010: begin // 写16位
                                cache_data[cache_index][cache_offset * 8 +: 16] = temp_cache_data[15:0];
                            end
                            3'b011: begin // 写32位
                                cache_data[cache_index][cache_offset * 8 +: 32] = temp_cache_data[31:0];
                            end
                            3'b100: begin // 写64位
                                cache_data[cache_index][cache_offset * 8 +: 64] = temp_cache_data;
                            end
                        endcase
                    end else begin
                        temp_cache_data <= 0;
                        write_cache_done <= 0;
                    end
                end
                FETCH: begin
                    if ((counter < (CACHE_LINE_SIZE / (DATA_BUS_WIDTH / 8) - 1))&&state==2'b00) begin
                        counter <= counter + 1;
                    end else if((counter == (CACHE_LINE_SIZE / (DATA_BUS_WIDTH / 8) - 1))&&state==2'b00) begin
                        current_cstate <= next_cstate;
                    end
                    if (state == 2'b00) begin
                        temp_cache_data <= dram_dout;
                        cache_data[cache_index][counter * DATA_BUS_WIDTH +: DATA_BUS_WIDTH] <= temp_cache_data;
                        cache_tags[cache_index] <= cache_tag;
                    end else begin
                        temp_cache_data <= 0;
                        write_cache_done <= 0;
                    end
                end
                WRITEBACK: begin
                    if ((counter < (CACHE_LINE_SIZE / (DATA_BUS_WIDTH / 8) - 1))&&state==2'b00) begin
                        counter <= counter + 1;
                    end else if((counter == (CACHE_LINE_SIZE / (DATA_BUS_WIDTH / 8) - 1))&&state==2'b00) begin
                        current_cstate <= next_cstate;
                    end
                end
                default: begin
                    counter <= counter;
                end
            endcase
        end
    end

    // 状态机主体
    always_comb begin
        data_ready = 0;
        dout = 0;
        dram_rd_ctrl = 3'b000;
        dram_wr_ctrl = 3'b000;
        dram_addr = 0;
        dram_din = 0;
        case (current_cstate)
            IDLE: begin
                if (rd_ctrl||wr_ctrl) begin
                    if (uncached) begin
                        next_cstate = UNCACHED;
                    end else if(!valid) begin
                        next_cstate = FETCH;
                    end else if (hit) begin
                        if (rd_ctrl) begin
                            case (rd_ctrl)
                                3'b001: begin // 读8位
                                    dout = cache_data[cache_index][cache_offset * 8 +: 8];
                                end
                                3'b010: begin // 读8位(unsigned)
                                    dout = cache_data[cache_index][cache_offset * 8 +: 8];
                                end
                                3'b011: begin // 读16位
                                    dout = cache_data[cache_index][cache_offset * 8 +: 16];
                                end
                                3'b100: begin // 读16位(unsigned)
                                    dout = cache_data[cache_index][cache_offset * 8 +: 16];
                                end
                                3'b101: begin // 读32位
                                    dout = cache_data[cache_index][cache_offset * 8 +: 32];
                                end
                                3'b110: begin // 读64位
                                    dout = cache_data[cache_index][cache_offset * 8 +: 64];
                                end
                            endcase
                            data_ready = 1;
                            next_cstate = IDLE;
                        end else if (wr_ctrl) begin
                            next_cstate = IDLE;
                            data_ready = ((write_cache_done==2'b11) ? 1 : 0);
                        end else begin
                        data_ready = 1;
                        next_cstate = IDLE;
                        end
                    end else if (dirty) begin
                        next_cstate = WRITEBACK;
                    end else begin
                        next_cstate = FETCH;
                    end
                end else begin
                    data_ready = 0;
                    next_cstate = IDLE;
                end
            end

            FETCH: begin
                dram_rd_ctrl = 3'b110; // 读64位
                dram_addr = {cache_tags[cache_index], cache_index, counter2offset};
                if (counter == (CACHE_LINE_SIZE / (DATA_BUS_WIDTH / 8) - 1)) begin
                    valid_bits[cache_index] = 1;
                    dirty_bits[cache_index] = 0;
                    next_cstate = IDLE;
                end
            end

            WRITEBACK: begin
                dram_wr_ctrl = 3'b100; // 写64位
                dram_addr = {cache_tags[cache_index], cache_index, counter2offset};
                dram_din = cache_data[cache_index][counter * DATA_BUS_WIDTH +: DATA_BUS_WIDTH];
                if (counter == CACHE_LINE_SIZE / (DATA_BUS_WIDTH / 8) - 1) begin
                    next_cstate = IDLE;
                    dirty_bits[cache_index] = 0;
                    valid_bits[cache_index] = 1;
                end
                else begin
                    next_cstate = WRITEBACK;
                end
            end

            UNCACHED: begin
                data_ready = 1;
                next_cstate = IDLE;
            end
        endcase
    end

endmodule
