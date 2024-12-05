# Compiler
VERILATOR = verilator
CXX = g++

# Directories
SRC_DIR = ..
COMPONENTS_DIR = $(SRC_DIR)/Components
ALU_DIR = $(COMPONENTS_DIR)/ALU
BRANCH_DIR = $(COMPONENTS_DIR)/Branch
CTRL_DIR = $(COMPONENTS_DIR)/Ctrl
IMM_DIR = $(COMPONENTS_DIR)/Imm
DRAM_DIR = $(COMPONENTS_DIR)/Dram
ROM_DIR = $(COMPONENTS_DIR)/Rom
REGFILE_DIR = $(COMPONENTS_DIR)/RegisterFile
UART_DIR = $(COMPONENTS_DIR)/UART
GPIO_DIR = $(COMPONENTS_DIR)/GPIO
SYS_BUS_DIR = $(COMPONENTS_DIR)/Sys_bus
RVCU_DIR = $(SRC_DIR)/Pipelined_CPU
PIPELINE_DIR = $(RVCU_DIR)/pipeline
OUTPUT_DIR = output
BUILD_DIR = $(OUTPUT_DIR)/build

# Source files
ALU_SRC = $(ALU_DIR)/ALU64.v
BRANCH_SRC = $(BRANCH_DIR)/branch64.v
CTRL_SRC = $(CTRL_DIR)/ctrl64.v \
            $(CTRL_DIR)/dram_ctrl.v
IMM_SRC = $(IMM_DIR)/imm64.v
DRAM_SRC = $(DRAM_DIR)/dram.v
ROM_SRC = $(ROM_DIR)/rom.v
REGFILE_SRC = $(REGFILE_DIR)/regfileI64.v 
UART_SRC = $(UART_DIR)/uart.v \
            $(UART_DIR)/uart_rx.v \
            $(UART_DIR)/uart_tx.v
GPIO_SRC = $(GPIO_DIR)/gpio.v 
SYS_BUS_SRC = $(SYS_BUS_DIR)/sys_bus.v 
PIPELINE_SRC = $(PIPELINE_DIR)/pipeline_if_stage.v \
                $(PIPELINE_DIR)/pipeline_id_stage.v \
                $(PIPELINE_DIR)/pipeline_ex_stage.v \
                $(PIPELINE_DIR)/pipeline_mem_stage.v \
                $(PIPELINE_DIR)/pipeline_wb_stage.v  \
                $(PIPELINE_DIR)/hazard.v             \
                $(PIPELINE_DIR)/forwarding.v 
RVCU_SRC = $(RVCU_DIR)/RV64CPU.v \
            $(RVCU_DIR)/data_path.v

# Verilator output and executable
VOBJ = $(BUILD_DIR)/VRVCPU
EXE = $(OUTPUT_DIR)/RVCPU_tb_sim
WAVEFORM_VCD = $(OUTPUT_DIR)//waveform.vcd

# C++ testbench
TB_CPP_CP = $(RVCU_DIR)/tb_main.cpp
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
$(VOBJ): $(TB_CPP) $(BUILD_DIR) $(ALU_SRC) $(BRANCH_SRC) $(CTRL_SRC) $(IMM_SRC) $(DRAM_SRC) $(ROM_SRC) $(REGFILE_SRC) $(GPIO_SRC) $(UART_SRC) $(SYS_BUS_SRC) $(PIPELINE_SRC) $(RVCU_SRC)
	$(VERILATOR) --cc --exe --build --trace --Wno-lint -timescale 1ns/1ns \
		-Mdir $(BUILD_DIR) \
		--top-module RVCPU $(ALU_SRC) $(BRANCH_SRC) $(CTRL_SRC) $(IMM_SRC) $(DRAM_SRC) $(ROM_SRC) $(REGFILE_SRC) $(GPIO_SRC) $(UART_SRC) $(SYS_BUS_SRC) $(PIPELINE_SRC)  $(RVCU_SRC) $(TB_CPP)


# Build simulation executable
$(EXE): $(VOBJ)
	cp $(VOBJ) $(EXE)

# Run the simulation
run: $(EXE)
	$(EXE)

# Clean up generated files
clean:
	rm -rf $(BUILD_DIR) $(OUTPUT_DIR)/tb_main.cpp $(EXE) $(WAVEFORM_VCD)

.PHONY: all run clean
