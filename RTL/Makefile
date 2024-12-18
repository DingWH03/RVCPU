# Compiler
VERILATOR = verilator
CXX = g++

# Directories
SRC_DIR = .
INCLUDE_DIR = $(SRC_DIR)/include
MODULES_DIR = $(SRC_DIR)/Modules
PERIPS_DIR = $(MODULES_DIR)/Perips
CORE_DIR = $(MODULES_DIR)/Core
ALU_DIR = $(CORE_DIR)/ALU
BRANCH_DIR = $(CORE_DIR)/Branch
CTRL_DIR = $(CORE_DIR)/Ctrl
IMM_DIR = $(CORE_DIR)/Imm
DRAM_DIR = $(PERIPS_DIR)/Dram
ROM_DIR = $(PERIPS_DIR)/Rom
REGFILE_DIR = $(CORE_DIR)/RegisterFile
UART_DIR = $(PERIPS_DIR)/UART
GPIO_DIR = $(PERIPS_DIR)/GPIO
SYS_BUS_DIR = $(MODULES_DIR)/Sys_bus
RVCU_DIR = $(SRC_DIR)/top
PIPELINE_DIR = $(SRC_DIR)/pipeline
TB_CPP_DIR = $(SRC_DIR)/tb_cpp
OUTPUT_DIR = output
BUILD_DIR = $(OUTPUT_DIR)/build

# Source files
DEFINES_SRC = $(INCLUDE_DIR)/defines.sv
ALU_SRC = $(ALU_DIR)/ALU.v
BRANCH_SRC = $(BRANCH_DIR)/branch.v
CTRL_SRC = $(CTRL_DIR)/ctrl.sv \
            $(CTRL_DIR)/dram_ctrl.sv
IMM_SRC = $(IMM_DIR)/imm.v
DRAM_SRC = $(DRAM_DIR)/dram16.sv
ROM_SRC = $(ROM_DIR)/rom.v
REGFILE_SRC = $(REGFILE_DIR)/regfileI.v 
UART_SRC = $(UART_DIR)/uart.v \
            $(UART_DIR)/uart_rx.v \
            $(UART_DIR)/uart_tx.v
GPIO_SRC = $(GPIO_DIR)/gpio.v 
SYS_BUS_SRC = $(SYS_BUS_DIR)/sys_bus.sv 
PIPELINE_SRC = $(PIPELINE_DIR)/pipeline_ifp_stage1.sv \
                $(PIPELINE_DIR)/pipeline_ifr_stage2.sv \
                $(PIPELINE_DIR)/pipeline_idc_stage3.sv \
                $(PIPELINE_DIR)/pipeline_idr_stage4.sv \
                $(PIPELINE_DIR)/pipeline_exb_stage5.sv \
                $(PIPELINE_DIR)/pipeline_exa_stage6.sv \
                $(PIPELINE_DIR)/pipeline_exc_stage7.sv \
                $(PIPELINE_DIR)/pipeline_memp_stage8.sv \
                $(PIPELINE_DIR)/pipeline_memr_stage9.sv \
                $(PIPELINE_DIR)/pipeline_wb_stage10.sv  \
                $(PIPELINE_DIR)/hazard.sv             \
                $(PIPELINE_DIR)/forwarding.sv 
RVCU_SRC = $(RVCU_DIR)/RVCPU.sv \
            $(RVCU_DIR)/data_path.sv

# Verilator output and executable
VOBJ = $(BUILD_DIR)/VRVCPU
EXE = $(OUTPUT_DIR)/RVCPU_tb_sim
WAVEFORM_VCD = $(OUTPUT_DIR)//waveform.vcd

# C++ testbench
TB_CPP_CP = $(TB_CPP_DIR)/tb_main.cpp
TB_CPP = $(OUTPUT_DIR)/tb_main.cpp

# Default target
all: $(EXE)

# Create build and output directories
$(OUTPUT_DIR) $(BUILD_DIR):
	mkdir -p $@

# Copy tb_main.cpp to the output directory
$(TB_CPP): $(TB_CPP_CP) $(OUTPUT_DIR)
	cp $(TB_CPP_CP) $(TB_CPP)

# Verilator model generation
$(VOBJ): $(TB_CPP) $(BUILD_DIR) $(DEFINES_SRC) $(ALU_SRC) $(BRANCH_SRC) $(CTRL_SRC) $(IMM_SRC) $(DRAM_SRC) $(ROM_SRC) $(REGFILE_SRC) $(GPIO_SRC) $(UART_SRC) $(SYS_BUS_SRC) $(PIPELINE_SRC) $(RVCU_SRC)
	$(VERILATOR) --cc --exe --build --trace --Wno-lint -timescale 1ns/1ns \
		-Mdir $(BUILD_DIR) \
		--top-module RVCPU $(DEFINES_SRC) $(ALU_SRC) $(BRANCH_SRC) $(CTRL_SRC) $(IMM_SRC) $(DRAM_SRC) $(ROM_SRC) $(REGFILE_SRC) $(GPIO_SRC) $(UART_SRC) $(SYS_BUS_SRC) $(PIPELINE_SRC)  $(RVCU_SRC) $(TB_CPP)


# Build simulation executable
$(EXE): $(VOBJ)
	cp $(VOBJ) $(EXE)

# Run the simulation
run: $(EXE)
	$(EXE)

# Clean up generated files
clean:
	rm -rf $(OUTPUT_DIR)

.PHONY: all run clean
