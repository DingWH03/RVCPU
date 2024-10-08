module PC(
input              clk,
input              rst,
input              JUMP,
input       [31:0] JUMP_PC,
output reg  [31:0] pc);
wire [31:0] pc_plus4;
assign pc_plus4 = pc + 32'h4;
//计算PC
always@(posedge clk or posedge rst)
begin
    if (rst) pc = 0;
    else begin
        if (JUMP) pc = JUMP_PC;
        else pc = pc_plus4;
    end
end
endmodule