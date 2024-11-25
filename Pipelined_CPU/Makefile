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
REGFILE_DIR = $(COMPONENTS_DIR)/RegisterFile
UART_DIR = $(COMPONENTS_DIR)/UART
GPIO_DIR = $(COMPONENTS_DIR)/GPIO
SYS_BUS_DIR = $(COMPONENTS_DIR)/Sys_bus
RVCU_DIR = $(SRC_DIR)/Pipelined_CPU
PIPELINE_DIR = $(RVCU_DIR)/pipeline
OUTPUT_DIR = output

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
				$(PIPELINE_DIR)/hazard.v 
RVCU_SRC = $(RVCU_DIR)/RV64CPU.v \
			$(RVCU_DIR)/RVCPU_tb.v \
			$(RVCU_DIR)/data_path.v

# Output files
OUTPUT = $(OUTPUT_DIR)/RVCPU_tb.vvp
WAVEFORM = $(OUTPUT_DIR)/waveform.vcd

# Default target
all: $(OUTPUT)

# Create output directory if it doesn't exist
$(OUTPUT_DIR):
	mkdir -p $(OUTPUT_DIR)

# Compile the design
$(OUTPUT): $(OUTPUT_DIR) $(ALU_SRC) $(BRANCH_SRC) $(CTRL_SRC) $(IMM_SRC) $(DRAM_SRC) $(ROM_SRC) $(REGFILE_SRC) $(GPIO_SRC) $(UART_SRC) $(SYS_BUS_SRC) $(PIPELINE_SRC) $(RVCU_SRC)
	$(IVERILOG) -o $(OUTPUT) $^

# Run the simulation
run: $(OUTPUT)
	$(VVP) $(OUTPUT)

# Clean up generated files
clean:
	rm -f $(OUTPUT) $(WAVEFORM)

.PHONY: all run clean
