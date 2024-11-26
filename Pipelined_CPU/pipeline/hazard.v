
module hazard (
  input branch_taken_EX,
  input [63:0] branch_target_EX,
  output wire flush_ID,
  output wire flush_EX,
  output wire branch_taken_IF,
  output wire [63:0] branch_target_IF
);

  assign flush_ID = branch_taken_EX;
  assign flush_EX = branch_taken_EX;
  assign branch_taken_IF = branch_taken_EX;
  assign branch_target_IF = branch_target_EX;
  

endmodule