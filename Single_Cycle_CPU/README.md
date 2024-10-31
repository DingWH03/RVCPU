# Single-Cycle RV64I CPU

This repository contains the design of a single-cycle RISC-V 64-bit (RV64I) CPU written in Verilog. This CPU supports basic instruction execution, memory handling, debugging, and basic control flow for single-cycle operation.

## Table of Contents

- [Overview](#overview)
- [Components](#components)
- [Top Module](#top-module)
- [Debugging](#debugging)
- [Memory Management](#memory-management)
- [How to Use](#how-to-use)
- [License](#license)

## Overview

This project implements a basic RV64I single-cycle CPU with a pause-and-continue debugging feature, connected memory controllers for RAM and ROM, and an Arithmetic Logic Unit (ALU). The CPU reads instructions from the ROM, executes them, and interfaces with memory using a custom memory controller.

## Components

The CPU includes the following main components:

1. **Program Counter (PC)**: Manages the address of the next instruction.
2. **Instruction Memory (ROM)**: Stores program instructions.
3. **Register File**: Contains 64-bit general-purpose registers for data storage.
4. **ALU (Arithmetic Logic Unit)**: Performs arithmetic and logic operations.
5. **Memory Controller (DRAM Controller)**: Manages data access to and from DRAM.
6. **Immediate Generator**: Generates immediate values for certain instruction types.
7. **Control Unit**: Decodes instructions, generates control signals, and determines execution flow.
8. **Branch Logic**: Determines conditional branch outcomes.

## Top Module

The top module `RVCPU` contains all the necessary input and output ports:

- `clk` (input): The clock signal for timing.
- `rst` (input): Resets the CPU state.
- `continue_key` (input): A debug key for controlling pause and continue functionality.
- `led` (output): Displays the current ALU output on LEDs.
- `led_addr` (output): Displays the current instruction address.

### Signals in the Top Module

- **`im_addr`**: Instruction memory address, linked to the program counter.
- **`inst`**: Current instruction to be executed.
- **`dm_addr` and `dm_din`**: Data memory address and data input for memory write operations.
- **`cpu_paused`**: Indicates if the CPU is in a paused state during debugging.

## Debugging

This CPU includes a debugging feature that pauses execution on specific conditions. When `is_debug` is active:

- `continue_key` can toggle the `cpu_paused` state.
- Pressing `continue_key` enables the CPU to resume and execute the next instruction.

## Memory Management

The CPU interacts with memory via the `dram_ctrl` memory controller, which interfaces with the `dram` and `rom` modules:

- **DRAM**: Serves as main memory.
- **ROM**: Contains the instruction set for execution.

### Memory Connections

- **`dm_din`** and **`dm_dout`**: Handle data inputs and outputs.
- **`addr_dram_ctrl`**: Memory address for DRAM access.
- **`write_en`**: Enables memory write operations.

## How to Use

1. **Clone the repository** and open the project in a Verilog-compatible development environment.
2. **Load the required instruction set** into the ROM module.
3. **Run the simulation** and monitor `led` and `led_addr` outputs to observe the current ALU output and instruction addresses.
4. **Use `continue_key`** to manually step through instructions in debug mode.

## License

This project is licensed under the GPL-3.0 License.
