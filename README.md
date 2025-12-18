# 16bit-mips-like-cpu

This repository contains the design and implementation of a custom **16-bit MIPS-like RISC CPU**, developed as an academic computer architecture project. The processor is described in SystemVerilog, functionally verified using RTL simulation, and implemented on an FPGA.

A detailed technical report explaining the instruction set architecture (ISA), datapath design, control logic, verification strategy, and FPGA synthesis results is provided at the root of this repository.

📄 **Project Report:** `ISA_16bit_Nabin_K_Singh.pdf`

---

## Project Summary
- Custom 16-bit RISC ISA inspired by MIPS
- Single-cycle CPU datapath with centralized control unit
- Implemented entirely in SystemVerilog
- Functional verification using ModelSim
- Instruction memory initialized via `.hex` files
- Synthesized and deployed on an Intel DE2-115 FPGA board

---


## Repository Structure
### `source_files/`
Contains all **synthesizable SystemVerilog RTL modules** that define the hardware implementation of the CPU, including:
- Top-level CPU module
- Datapath and control unit
- ALU
- Register file
- Instruction memory (`imem.sv`)
- Data memory (`dmem.sv`)
- Program counter and supporting logic

These files collectively describe the complete 16-bit processor.

---

### `testbenches_and_program_instructions/`
Contains **RTL testbenches** and their corresponding **instruction memory `.hex` files** used for simulation and functional verification.

Each testbench targets a specific class of instructions, such as:
- R-type instructions
- I-type instructions
- Branch instructions
- Shift operations
- Call/return and control-flow instructions

For every testbench (`.sv`), there is a matching `.hex` file that contains the machine code program executed by the CPU during simulation.

---

## Instruction Memory and `.hex` File Usage

The instruction memory module (`imem.sv`) supports file-based initialization using `$readmemh`.  
A parameter is used to specify which `.hex` file should be loaded into instruction memory.

Example from `imem.sv`:
```systemverilog
parameter INIT_FILE = "tb_cpu_callret.hex";


Author

Nabin Kumar Singh
M.S. Electrical and Computer Engineering
University of Alabama at Huntsville
