# SYNTH-16 System Module Documentation

This document describes the design, port interfaces, internal states, and instruction-by-instruction execution flow of the **System Module** (`system_module`) for the SYNTH-16 custom 16-bit processor, referencing the updated combinational microarchitecture specifications.

---

## 1. Module Overview

The [system_module](system_module.v) is responsible for executing system-level instructions that control CPU halting and no-op behavior.

The module is purely combinational and contains no internal state registers, clock, or reset logic. It generates a single control signal based on the current opcode.

It implements the following instructions:
* **NOP** (Opcode `11100`): No operation, does not change CPU state.
* **HALT** (Opcode `11101`): Asserts the `halt` signal to stop CPU state progression.

---

## 2. Port Configuration

Below is the interface of the [system_module](./system_module.v). It is connected as a sub-module of the `execution_unit`.

| Port Name | Width | Direction | Description |
| :--- | :---: | :---: | :--- |
| `opcode` | 5 | Input | The 5-bit instruction opcode decoded from `IR[15:11]`. |
| `halt` | 1 | Output | Asserted high when the system instruction requests CPU halt. |

---

## 3. Instruction Behavior

### 3.1 `NOP`
Opcode: `5'b11100`

* No operation is performed.
* `halt` remains `0`.
* This instruction allows the processor to continue fetching and executing subsequent instructions normally.

### 3.2 `HALT`
Opcode: `5'b11101`

* Sets `halt = 1`.
* Signals the CPU to stop advancing the state machine.
* The processor remains halted until reset is asserted.

---

## 4. Integration Notes

* The `system_module` is instantiated inside `execution_unit.v`.
* Its output is only meaningful when `sys_active` is true; otherwise the `halt` signal remains low.
* In `execution_unit.v`, `halt` is computed as `sys_active && s_halt`.
* The top-level CPU (`cpu_top.v`) uses this `halt` signal to prevent state transitions when asserted.

---

## 5. Important Implementation Details

* The module is purely combinational and has no clock or reset inputs.
* It only evaluates the current opcode and produces a single output.
* `NOP` is implemented as a default no-op case.
* `HALT` is the only instruction that asserts the halt signal.
