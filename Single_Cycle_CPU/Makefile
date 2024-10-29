# Makefile for RVCPU Project

# Compiler
IVERILOG = iverilog
VVP = vvp

# Directories
SRC_DIR = ..
COMPONENTS_DIR = $(SRC_DIR)/Components
ALU_DIR = $(COMPONENTS_DIR)/ALU
BRANCH_DIR = $(COMPONENTS_DIR)/Branch
CTRL_DIR = $(COMPONENTS_DIR)/Ctrl
IMM_DIR = $(COMPONENTS_DIR)/Imm
DRAM_DIR = $(COMPONENTS_DIR)/Dram
ROM_DIR = $(COMPONENTS_DIR)/Rom
PC_DIR = $(COMPONENTS_DIR)/PC
REGFILE_DIR = $(COMPONENTS_DIR)/RegisterFile
RVCU_DIR = $(SRC_DIR)/Single_Cycle_CPU
OUTPUT_DIR = output

# Source files
ALU_SRC = $(ALU_DIR)/ALU64.v
BRANCH_SRC = $(BRANCH_DIR)/branch64.v
CTRL_SRC = $(CTRL_DIR)/ctrl64.v \
			$(CTRL_DIR)/dram_ctrl.v
IMM_SRC = $(IMM_DIR)/imm64.v
DRAM_SRC = $(DRAM_DIR)/dram.v
ROM_SRC = $(ROM_DIR)/rom.v
PC_SRC = $(PC_DIR)/PC.v
REGFILE_SRC = $(REGFILE_DIR)/regfileI64.v 
RVCU_SRC = $(RVCU_DIR)/RVCPU.v \
			$(RVCU_DIR)/RVCPU_tb.v

# Output files
OUTPUT = $(OUTPUT_DIR)/RVCPU_tb.vvp
WAVEFORM = $(OUTPUT_DIR)/waveform.vcd

# Default target
all: $(OUTPUT)

# Create output directory if it doesn't exist
$(OUTPUT_DIR):
	mkdir -p $(OUTPUT_DIR)

# Compile the design
$(OUTPUT): $(OUTPUT_DIR) $(ALU_SRC) $(BRANCH_SRC) $(CTRL_SRC) $(IMM_SRC) $(DRAM_SRC) $(ROM_SRC) $(PC_SRC) $(REGFILE_SRC) $(RVCU_SRC)
	$(IVERILOG) -o $(OUTPUT) $^

# Run the simulation
run: $(OUTPUT)
	$(VVP) $(OUTPUT)

# Clean up generated files
clean:
	rm -f $(OUTPUT) $(WAVEFORM)

.PHONY: all run clean
