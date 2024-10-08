# Makefile for RVCPU Project

# Compiler
IVERILOG = iverilog
VVP = vvp

# Directories
SRC_DIR = .
ALU_DIR = $(SRC_DIR)/ALU
BRANCH_DIR = $(SRC_DIR)/Branch
CTRL_DIR = $(SRC_DIR)/Ctrl
IMM_DIR = $(SRC_DIR)/Imm
MEMORY_DIR = $(SRC_DIR)/Memory
PC_DIR = $(SRC_DIR)/PC
REGFILE_DIR = $(SRC_DIR)/RegisterFile
RVCU_DIR = $(SRC_DIR)/RVCPU
OUTPUT_DIR = output

# Source files
ALU_SRC = $(ALU_DIR)/ALU.v
BRANCH_SRC = $(BRANCH_DIR)/branch.v
CTRL_SRC = $(CTRL_DIR)/ctrl.v
IMM_SRC = $(IMM_DIR)/imm.v
MEMORY_SRC = $(MEMORY_DIR)/Memory.v
PC_SRC = $(PC_DIR)/PC.v
REGFILE_SRC = $(REGFILE_DIR)/regfile.v 
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
$(OUTPUT): $(OUTPUT_DIR) $(ALU_SRC) $(BRANCH_SRC) $(CTRL_SRC) $(IMM_SRC) $(MEMORY_SRC) $(PC_SRC) $(REGFILE_SRC) $(RVCU_SRC)
	$(IVERILOG) -o $(OUTPUT) $^

# Run the simulation
run: $(OUTPUT)
	$(VVP) $(OUTPUT)

# Clean up generated files
clean:
	rm -f $(OUTPUT) $(WAVEFORM)

.PHONY: all run clean
