
module hazard (
  input logic branch_taken_EXB,
  input logic [63:0] branch_target_EXB,

  input logic no_forwarding_data,  // 没有可转发的数据暂停IDR

  input logic data_ready, // 存储器状态信号

  input logic mALU_runing,

  input logic [2:0] dm_rd_ctrl,
  input logic [2:0] dm_wr_ctrl,

  output logic stall_IDR, stall_IDC, stall_IFR, stall_IFP,
  output logic stall_EXB, stall_EXA, stall_EXC, stall_MEMP, stall_MEMR,
  output logic nop_IDR,

  output logic flush_IDC,
  output logic flush_IDR,
  output logic flush_IFR,
  output logic flush_EXB,
  output logic branch_taken_IFP,
  output logic [63:0] branch_target_IFP
);
  logic mem_busy;
  assign mem_busy = !data_ready&&(dm_rd_ctrl!=3'b000||dm_wr_ctrl!=3'b000); 
  assign flush_IDC = branch_taken_EXB;
  assign flush_IDR = branch_taken_EXB;
  assign flush_IFR = branch_taken_EXB;
  assign flush_EXB = 0;
  assign branch_taken_IFP = branch_taken_EXB;
  assign branch_target_IFP = branch_target_EXB;
  
  assign stall_IDR = mem_busy | mALU_runing;
  assign nop_IDR = no_forwarding_data;
  assign stall_IDC = no_forwarding_data|mem_busy | mALU_runing;
  assign stall_IFR = no_forwarding_data|mem_busy | mALU_runing;
  assign stall_IFP = no_forwarding_data|mem_busy | mALU_runing;

  assign stall_EXB = mem_busy | mALU_runing;
  assign stall_EXA = mem_busy | mALU_runing;
  assign stall_EXC = mem_busy | mALU_runing;
  assign stall_MEMP = mem_busy;
  assign stall_MEMR = mem_busy;
  

endmodule