module imm(
input 	    [31:0] inst,
output reg	[31:0] out
);
wire	[6:0] opcode;
assign	opcode= inst[6:0];
//立即数扩展
    initial out = 32'b0;
always@(*)
begin
	case(opcode)
        7'b0010111: begin out[31:12] = inst[31:12]; end	//auipc
        7'b0110111: begin out[31:12] = inst[31:12]; end	//lui
        7'b1100011: begin 	//B type
        	out[12] = inst[31];
            out[11] = inst[7];
            out[10:5] = inst[30:25];
            out[4:1] = inst[11:8];
            out[31:13] = {19{out[12]}};
        end
        7'b1101111: begin	//jal
            out[20] = inst[31];
            out[19:12] = inst[19:12];
            out[11] = inst[20];
            out[10:1] = inst[30:21];
            out[31:21] = {10{out[20]}};
        end
        7'b1100111: begin	//jalr->I type
            out[11:0] = inst[31:20];
            out[31:12] = {20{out[11]}};
        end
        7'b0000011: begin	//I type
            out[11:0] = inst[31:20];
            out[31:12] = {20{out[11]}};
        end
        7'b0100011: begin	//S type
            out[11:5] = inst[31:25];
            out[4:0] = inst[11:7];
        end
        7'b0010011: begin	//I type
             out[11:0] = inst[31:20];
            out[31:12] = {20{out[11]}};
        end
        default: out = 32'b0;        
                                     
	endcase
end 
endmodule
