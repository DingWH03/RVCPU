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
)
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
    cache_index <= addr[INDEX_BITS + OFFSET_BITS +: INDEX_BITS];
    cache_tag <= addr[INDEX_BITS + OFFSET_BITS + INDEX_BITS +: TAG_BITS];
    cache_offset <= addr[OFFSET_BITS-1:0];

    logic hit;
    logic dirty;
    logic uncached;  // 地址无效
    assign uncached = addr[31:28] != 4'd8 || addr[63:32] != 32'd0;
    assign hit = valid_bits[cache_index] && cache_tags[cache_index] == cache_tag && ~dirty_bits[cache_index];
    assign dirty = valid_bits[cache_index] && dirty_bits[cache_index];

    // 定义状态机
    typedef enum logic[1:0] {
        IDLE,
        FETCH,
        WRITEBACK,
        UNCACHED    // 地址无效
    } state_t;

    state_t state, next_state;

    always_ff @(posedge clk) begin
        if (rst) begin
            // 初始化缓存
            for (int i = 0; i < CACHE_LINES; i++) begin
                valid_bits[i] <= 0;
                dirty_bits[i] <= 0;
            end
        end else begin
           

            // 读写控制
            case (rd_ctrl)
                
            endcase
        end
    end

    // 状态转换逻辑
    always_ff @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    // 状态机主体
    always_comb begin
        case (state)
            IDLE: begin
                if (uncached) begin
                    next_state = UNCACHED;
                end else if (dirty) begin
                    dram_addr = addr;
                    dram_din = cache_data[cache_index];  // 需要改
                    dram_wr_ctrl = 3'b100;
                    next_state = WRITEBACK;
                end else if(hit) begin
                    dout = cache_data[cache_index][DATA_BUS_WIDTH-1:0];
                    next_state = IDLE;
                end else begin
                    dram_addr = addr;
                    dram_rd_ctrl = 3'b110;
                    next_state = FETCH;
                end
            end
            FETCH: begin
                if (!state) begin
					
				end
            end
            WRITEBACK: begin
                if (!state) begin
					
				end
            end
            UNCACHED: begin     // 访问到地址无效的存储地址
				state_nxt = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end

endmodule