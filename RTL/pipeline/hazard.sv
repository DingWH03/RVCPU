
module hazard (
  input logic branch_taken_EXB,
  input logic [63:0] branch_target_EXB,

  input logic no_forwarding_data,  // 没有可转发的数据暂停IDR

  output logic stall_IDR, stall_IDC, stall_IFR, stall_IFP,
  output logic nop_IDR,

  output logic flush_IDC,
  output logic flush_IDR,
  output logic flush_IFR,
  output logic flush_EXB,
  output logic branch_taken_IFP,
  output logic [63:0] branch_target_IFP
);
  assign flush_IDC = branch_taken_EXB;
  assign flush_IDR = branch_taken_EXB;
  assign flush_IFR = branch_taken_EXB;
  assign flush_EXB = 0;
  assign branch_taken_IFP = branch_taken_EXB;
  assign branch_target_IFP = branch_target_EXB;
  
  assign stall_IDR = 0;
  assign nop_IDR = no_forwarding_data;
  assign stall_IDC = no_forwarding_data;
  assign stall_IFR = no_forwarding_data;
  assign stall_IFP = no_forwarding_data;
  

endmodule