module icache(
    input logic clk,
    input logic reset,
    input logic[31:0] address,
    input logic[31:0] write_data,
    input logic write_enable,
    output logic[31:0] read_data,
    output logic hit,
    input logic[31:0] mem_data,  // 来自主存的数据
    output logic[31:0] mem_address,  // 主存的地址
    output logic mem_read  // 读取主存的控制信号
);

// 参数定义
localparam ADDR_WIDTH = 32;      // 地址宽度
localparam DATA_WIDTH = 32;      // 数据宽度
localparam CACHE_SIZE = 256;     // 缓存大小，例如256个字
localparam BLOCK_SIZE = 4;       // 块大小（字数），这里每个块4个字
localparam INDEX_BITS = 8;       // 索引位数
localparam OFFSET_BITS = 2;      // 偏移位数，4个字，每个字4字节

// 计算块内偏移
localparam OFFSET_MASK = (1 << OFFSET_BITS) - 1;
// 索引掩码
localparam INDEX_MASK = ((1 << INDEX_BITS) - 1) << OFFSET_BITS;

// 标签位数
localparam TAG_BITS = ADDR_WIDTH - INDEX_BITS - OFFSET_BITS;

// 数据和标签存储
logic[DATA_WIDTH-1:0] cache_data[CACHE_SIZE-1:0];
logic[TAG_BITS-1:0] cache_tags[CACHE_SIZE-1:0];
logic valid_bits[CACHE_SIZE-1:0];  // 有效位数组

// 地址解析
wire[TAG_BITS-1:0] tag = address[ADDR_WIDTH-1:INDEX_BITS+OFFSET_BITS];
wire[INDEX_BITS-1:0] index = (address & INDEX_MASK) >> OFFSET_BITS;

// 缓存访问逻辑
always_ff @(posedge clk) begin
    if (reset) begin
        // 初始化缓存
        for (int i = 0; i < CACHE_SIZE; i++) begin
            valid_bits[i] <= 0;
        end
    end else begin
        if (write_enable) begin
            // 写入缓存
            cache_data[index] <= write_data;
            cache_tags[index] <= tag;
            valid_bits[index] <= 1;
        end else begin
            // 读取缓存
            if (valid_bits[index] && cache_tags[index] == tag) begin
                read_data <= cache_data[index];
                hit <= 1;
            end else begin
                hit <= 0;
            end
        end
    end
end

// 定义状态机
typedef enum logic[1:0] {
    IDLE,
    FETCH,
    WRITEBACK,
    UNCACHED
} state_t;

state_t state, next_state;

// 状态转换逻辑
always_ff @(posedge clk) begin
    if (reset) begin
        state <= IDLE;
    end else begin
        state <= next_state;
    end
end

// 状态机主体
always_comb begin
    case (state)
        IDLE: begin
            if (!write_enable && !valid_bits[index] || cache_tags[index] != tag) begin
                mem_address = address;
                mem_read = 1;
                next_state = FETCH;
            end else begin
                next_state = IDLE;
            end
        end
        FETCH: begin
            mem_read = 0;
            next_state = WRITEBACK;
        end
        WRITEBACK: begin
            if (mem_read == 0) begin
                cache_data[index] = mem_data;
                cache_tags[index] = tag;
                valid_bits[index] = 1;
                read_data = mem_data;  // 输出读取的数据
                hit = 0;  // 表示这是填充数据，不是缓存命中
                next_state = IDLE;
            end else begin
                next_state = WRITEBACK;
            end
        end
        default: next_state = IDLE;
    endcase
end



endmodule
