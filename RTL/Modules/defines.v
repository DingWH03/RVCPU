// cpu位宽
`define CPU_WIDTH 64                // CPU 数据宽度
`define INSTRUCTION_WIDTH 32       // 指令宽度
`define SYS_BUS_WIDTH 64          // 数据总线宽度

// 地址范围
`define DRAM_BASE_ADDR 32'h80000000
`define ROM_BASE_ADDR 32'h00000000
`define GPIO_BASE_ADDR 32'h40000000
`define UART_BASE_ADDR 32'h50000000

// cache
`define CACHE_LINE_SIZE 64
`define CACHE_SETS 64
`define CACHE_ASSOCIATIVITY 4

// 中断向量地址
`define INTERRUPT_VECTOR_ADDR 32'h00000100
