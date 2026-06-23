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

In Progress:

* Arithmetic Module
* System Module

## Documentation

Detailed documentation for individual modules:

* [Data Movement Module](docs/data_movement_documentation.md)
* [Control Flow Module](docs/control_flow_documentation.md)
* [Arithmetic Module](docs/arithmetic_documentation.md)
* [System Module](docs/system_documentation.md)

## Running

Compile:

```bash
iverilog testbench.v cpu_top.v ram.v execution_unit.v data_movement_module.v control_flow_module.v dummy_system_module.v
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
ENCHANT R1, 0x4000
ENCHANT R2, 0x4001

SUMMON R3, R1
SEAL   R2, R3

FREEZE
```

This program copies the value stored at address `0x4000` to address `0x4001`.
