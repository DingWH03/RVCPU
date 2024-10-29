`timescale 1ns / 1ns
module rom(
    input           clk,
    input   [63:0]  im_addr,
    output  reg [31:0]  im_dout
);

reg     [31:0]  inst_mem[0:4095];   // 修改为32位宽度的数据存储
integer i;

initial
begin
    for(i=0;i<4095;i=i+1) inst_mem[i] = 0;
end

initial
begin
   $readmemb("/home/dwh/code/RVCPU/meminit/inst.dat",inst_mem);
   // 打印内存前10个地址的值
   for(i=0; i<10; i=i+1) begin
       $display("inst_mem[%0d] = %h", i, inst_mem[i]);
   end
end

// 读取指令存储（IM）
always @(*) begin
    if (im_addr[63:14] == 0) begin
        im_dout = inst_mem[im_addr[13:2]];  // 按字地址读取32位数据
    end else begin
        im_dout = 32'b0;  // 地址不在有效范围内，返回0
    end
end

endmodule
