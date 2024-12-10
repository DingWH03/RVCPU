
module hazard (
  input logic branch_taken_EXB,
  input logic [63:0] branch_target_EXB,

  input logic no_forwarding_data,  // 无法数据前递时需要暂停IDR、IDP、IFR、IFP

  output logic stall_IDR, stall_IDP, stall_IFR, stall_IFP,

  output logic flush_IDC,
  output logic flush_IDR,
  output logic flush_EXA,
  output logic flush_IFR,
  output logic branch_taken_IFP,
  output logic [63:0] branch_target_IFP
);

  assign flush_IDC = branch_taken_EXB;
  assign flush_IDR = branch_taken_EXB;
  assign flush_EXA = branch_taken_EXB;
  assign flush_IFR = branch_taken_EXB;
  assign branch_taken_IFP = branch_taken_EXB;
  assign branch_target_IFP = branch_target_EXB;
  
  assign stall_IDR = no_forwarding_data;
  assign stall_IDP = no_forwarding_data;
  assign stall_IFR = no_forwarding_data;
  assign stall_IFP = no_forwarding_data;
  

endmodule