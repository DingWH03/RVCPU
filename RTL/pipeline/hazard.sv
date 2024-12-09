
module hazard (
  input logic branch_taken_EXB,
  input logic [63:0] branch_target_EXB,

  output logic flush_IDC,
  output logic flush_IDR,
  output logic flush_EXA,
  output logic flush_IFR,
  output logic branch_taken_IF,
  output logic [63:0] branch_target_IF
);

  assign flush_IDC = branch_taken_EXB;
  assign flush_IDR = branch_taken_EXB;
  assign flush_EXA = branch_taken_EXB;
  assign flush_IFR = branch_taken_EXB;
  assign branch_taken_IFP = branch_taken_EXB;
  assign branch_target_IFP = branch_target_EXB;
  

endmodule