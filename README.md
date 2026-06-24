# Project16

Project16 is a custom 16-bit processor implemented in Verilog.

The processor uses a multi-cycle architecture consisting of the following stages:

```text
FETCH → DECODE → FETCH_EXT → EXECUTE
```

Instructions are organized into independent execution modules:

* Arithmetic
* Data Movement
* Control Flow
* System

An accompanying Python assembler converts assembly programs into machine code that can be loaded into RAM during simulation.

## Current Progress

Implemented:

* CPU Top Level
* Register File
* RAM
* Data Movement Module
* Control Flow Module
* Instruction Fetch / Decode Logic
* Assembler
* Arithmetic Module
* System Module

In Progress:

* refinement and optimization
* FPGA implementation and testing (upcoming)

## Documentation

Detailed documentation for individual modules:

* [Data Movement Module](docs/data_movement_documentation.md)
* [Control Flow Module](docs/control_flow_documentation.md)
* [Arithmetic Module](docs/arithmetic_module_documentation.md)
* [System Module](docs/system_module_documentation.md)

## Running

Compile:

```bash
iverilog testbench.v cpu_top.v ram.v execution_unit.v arithmetic_module.v data_movement_module.v control_flow_module.v system_module.v
```

Run:

```bash
vvp a.out
```

View waveforms:

```bash
gtkwave cpu.vcd
```

## Example Program

```asm
ENCHANT R1, 0x0032
ENCHANT R2, 0x005C
FUSE R1, R2
ENCHANT R3, 0x4000
SEAL R3, R1

ENCHANT R4, 0x4001
SUMMON R5, R3
SEAL R4, R5

FREEZE
```

This program adds two immediate values (0x0032 and 0x005C) using the ALU, stores the result in memory at address 0x4000, loads it back into a register using SUMMON, and copies it to address 0x4001 before halting the CPU with FREEZE.
