module InstructionMemory (
    input wire clk,            // 时钟输入
    input wire rw_enable,      // 读写使能，低电平有效
    input wire [7:0] address,  // 8位地址
    input wire [15:0] data_in, // 写入数据
    output wire [15:0] data_out // 读出数据
);

reg [15:0] data_out_r;
assign data_out = data_out_r;
// 存储器数组，512字节，每个存储位置16位
reg [15:0] memory [0:255];

// 初始化存储器的前几个位置
initial begin
    memory[0] = 16'h0000;  // 地址0
    memory[1] = 16'h0001;  // 地址1
    memory[2] = 16'h0002;  // 地址2
    // 可以添加更多的初始化...

    // 其余位置默认为全零
end


// 读写操作
always @(posedge clk)
begin
    if (rw_enable) begin  // 读操作，低电平有效
        data_out_r <= memory[address];
    end
    else begin  // 写操作
        memory[address] <= data_in;
    end
end

endmodule
