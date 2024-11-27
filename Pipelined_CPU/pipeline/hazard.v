
module hazard (
  input branch_taken_EX,
  input [63:0] branch_target_EX,
  input memorying_MEM,  // 结构冒险，MEM阶段占用总线导致无法取指流水线需要暂停
  output stall_IF,
  output stall_ID,
  output stall_EX,
  output wire flush_ID,
  output wire flush_EX,
  output wire branch_taken_IF,
  output wire [63:0] branch_target_IF
);

  assign stall_IF = memorying_MEM;
  assign stall_ID = memorying_MEM;
  assign stall_EX = memorying_MEM;

  assign flush_ID = branch_taken_EX;
  assign flush_EX = branch_taken_EX;
  assign branch_taken_IF = branch_taken_EX;
  assign branch_target_IF = branch_target_EX;
  

endmodule