`timescale 1ns / 1ns
module PC (
    input              clk,
    input              rst,
    input              JUMP,
    input       [63:0] JUMP_PC,
    input              stall,
    output reg  [63:0] pc
);
    wire [63:0] pc_plus4;

    assign pc_plus4 = pc + 4; // 计算PC + 4

    // 计算PC
    always @(posedge clk or posedge rst) begin
        if (rst) 
            pc <= 64'b0; // 使用非阻塞赋值
        else begin
            if (JUMP) 
                pc <= JUMP_PC; // 使用非阻塞赋值
            else begin
                if (!stall) 
                    pc <= pc_plus4; // 使用非阻塞赋值
            end
        end
    end
endmodule
