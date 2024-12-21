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

    logic [DATA_BUS_WIDTH-1:0] cache_data[CACHE_LINES-1:0];  // 缓存数据
    logic [TAG_BITS-1:0] cache_tags[CACHE_LINES-1:0];  // 缓存标签
    logic valid_bits[CACHE_LINES-1:0];  // 有效位
    logic dirty_bits[CACHE_LINES-1:0];  // 脏位
    logic [INDEX_BITS-1:0] cache_index;  // 缓存索引
    logic [TAG_BITS-1:0] cache_tag;  // 缓存标签
    logic [OFFSET_BITS-1:0] cache_offset;  // 缓存偏移

    logic [COUNTER_LEN-1:0] counter;  // 计数器

    // 地址解析
    assign cache_offset = addr[OFFSET_BITS-1:0];  // 偏移量：最低位
    assign cache_index = addr[OFFSET_BITS +: INDEX_BITS];  // 索引：偏移量左侧的中间部分
    assign cache_tag = addr[ADDRESS_WIDTH-1:OFFSET_BITS + INDEX_BITS];  // 标签：最高位部分

    logic hit;
    logic dirty;
    logic uncached;  // 地址无效
    assign uncached = addr[31:28] != 4'd8 || addr[63:32] != 32'd0;
    assign hit = valid_bits[cache_index] && cache_tags[cache_index] == cache_tag;
    assign dirty = valid_bits[cache_index] && dirty_bits[cache_index];

    // 定义状态机
    typedef enum logic[1:0] {
        IDLE = 2'b00,         // 空闲状态
        FETCH = 2'b01,        // 数据获取状态
        WRITEBACK = 2'b10,    // 写回状态
        UNCACHED = 2'b11      // 地址无效
    } state_t;

    state_t state, next_state;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            counter <= 0;
            for (int i = 0; i < CACHE_LINES; i++) begin
                valid_bits[i] <= 0;
                dirty_bits[i] <= 0;
                cache_tags[i] <= 0;
                cache_data[i] <= 0;
            end
            data_ready <= 0;
        end else begin
            state <= next_state;
        end
    end

    // 状态机主体
    always_comb begin
        next_state = state;
        data_ready = 0;
        dout = 0;
        dram_rd_ctrl = 3'b000;
        dram_wr_ctrl = 3'b000;
        dram_addr = 0;
        dram_din = 0;
        case (state)
            IDLE: begin
                if (uncached) begin
                    next_state = UNCACHED;
                end else if (hit) begin
                    dout = cache_data[cache_index];
                    if (rd_ctrl) begin
                        case (rd_ctrl)

                        endcase
                    end else if(wr_ctrl) begin
                        case (wr_ctrl)
                            3'b001: begin // 读8位
                                dout = cache_data[cache_index][cache_offset * 8 +: 8];
                            end
                            3'b010: begin // 读16位
                                dout = cache_data[cache_index][cache_offset * 8 +: 16];
                            end
                            3'b011: begin // 读32位
                                dout = cache_data[cache_index][cache_offset * 8 +: 32];
                            end
                            3'b100: begin // 读64位
                                dout = cache_data[cache_index][cache_offset * 8 +: 64];
                            end
                            default: begin
                                dout = 0;
                            end
                        endcase
                    end
                    data_ready = 1;
                    next_state = IDLE;
                end else if (dirty) begin
                    counter = 0;
                    dram_addr = {cache_tags[cache_index], cache_index, {OFFSET_BITS{1'b0}}};
                    dram_din = cache_data[cache_index];
                    dram_wr_ctrl = 3'b100;
                    next_state = WRITEBACK;
                end else begin
                    counter = 0;
                    dram_addr = addr;
                    dram_rd_ctrl = 3'b110;
                    next_state = FETCH;
                end
            end

            FETCH: begin
                if (state == 2'b00) begin // DRAM ready信号
                    cache_data[cache_index][counter * DATA_BUS_WIDTH +: DATA_BUS_WIDTH] = dram_dout;
                    counter = counter + 1;
                    if (counter == CACHE_LINE_SIZE / (DATA_BUS_WIDTH / 8)) begin
                        cache_tags[cache_index] = cache_tag;
                        valid_bits[cache_index] = 1;
                        dirty_bits[cache_index] = 0;
                        dout = dram_dout;
                        data_ready = 1;
                        next_state = IDLE;
                    end
                end
            end

            WRITEBACK: begin
                if (state == 2'b00) begin // DRAM完成信号
                    dram_din = cache_data[cache_index][counter * DATA_BUS_WIDTH +: DATA_BUS_WIDTH];
                    counter = counter + 1;
                    if (counter == CACHE_LINE_SIZE / (DATA_BUS_WIDTH / 8)) begin
                        dram_addr = addr;
                        dram_rd_ctrl = 3'b110;
                        next_state = FETCH;
                    end
                end
            end

            UNCACHED: begin
                dram_addr = addr;
                dram_din = din;
                if (rd_ctrl != 0) begin
                    dram_rd_ctrl = rd_ctrl;
                    dout = dram_dout;
                end else if (wr_ctrl != 0) begin
                    dram_wr_ctrl = wr_ctrl;
                end
                data_ready = 1;
                next_state = IDLE;
            end
        endcase
    end

endmodule
