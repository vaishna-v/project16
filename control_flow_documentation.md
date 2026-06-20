# SYNTH-16 Control Flow Module Documentation

This document describes the design, port interfaces, internal states, and instruction-by-instruction execution flow of the **Control Flow Module** (`control_flow_module`) for the SYNTH-16 custom 16-bit processor, referencing the SYNTH-16 Microarchitecture Specification.

---

## 1. Module Overview

The [control_flow_module](./control_flow_module.v) is responsible for executing instructions that change the sequential program flow, such as unconditional jumps, conditional jumps, subroutine calls, and returns.

All branching target addresses are 16-bit words fetched as the second word of a variable-length instruction (mode_bit = 1). This module does not interact with the general-purpose register file, and only accesses external RAM for stack operations during `CALL` and `RET`.

It implements the following instructions:
* **WARP (JMP)** (Opcode `10000`): Jumps unconditionally to target address in `IR_ext`.
* **WARPZ (JZ)** (Opcode `10001`): Jumps to target if the Zero (Z) flag is set.
* **WARPNZ (JNZ)** (Opcode `10010`): Jumps to target if the Zero (Z) flag is clear.
* **WARPC (JC)** (Opcode `10011`): Jumps to target if the Carry (C) flag is set.
* **WARPNC (JNC)** (Opcode `10100`): Jumps to target if the Carry (C) flag is clear.
* **INVOKE (CALL)** (Opcode `10101`): Calls a subroutine, saving the return address onto the stack.
* **RETURN (RET)** (Opcode `10110`): Returns from a subroutine by restoring the return address from the stack.

---

## 2. Port Configuration

Below is the port structure for [control_flow_module](./control_flow_module.v).

> [!NOTE]
> In the official SYNTH-16 Microarchitecture Specification, the Control Flow Module is described as outputting GPR and flag interfaces (e.g. `cf_reg_enable`, `cf_flag_enable`, etc.) that are hardwired to 0. In the implemented RTL code, these unused ports have been optimized away for clarity.

### 2.1 Implemented Verilog Ports

| Port Name | Width | Direction | Description |
| :--- | :---: | :---: | :--- |
| `clk` | 1 | Input | System clock (active-high). |
| `rst` | 1 | Input | Synchronous system reset (active-high). |
| `cf_en` | 1 | Input | Enable signal asserted by the Execute module when a control flow instruction is active. |
| `opcode` | 5 | Input | The 5-bit instruction opcode from `IR[15:11]`. |
| `IR_ext` | 16 | Input | The 16-bit target branch address from the second instruction word. |
| `FLAGS_in` | 2 | Input | The current CPU flags: `FLAGS_in[1]` = Zero (Z), `FLAGS_in[0]` = Carry (C). |
| `PC_in` | 16 | Input | The current Program Counter (`PC`) from `cpu_top`. |
| `SP_in` | 16 | Input | The current Stack Pointer (`SP`) from `cpu_top`. |
| `ram_rd_data` | 16 | Input | Data read back from external RAM (used by RET). |
| `cf_ram_enable` | 1 | Output | Asserted high to request RAM access for stack operations. |
| `cf_ram_addr` | 15 | Output | 15-bit address sent to RAM (derived from `SP_in`). |
| `cf_ram_read` | 1 | Output | Asserted high to read the return address from the stack during RET. |
| `cf_ram_write` | 1 | Output | Asserted high to push the return address onto the stack during CALL. |
| `cf_ram_data` | 16 | Output | Return address data (current `PC_in`) to write to memory. |
| `cf_pc_write` | 1 | Output | Asserted high to update the Program Counter. |
| `cf_pc_data` | 16 | Output | New Program Counter value to load into `PC`. |
| `cf_sp_write` | 1 | Output | Asserted high to update the Stack Pointer. |
| `cf_sp_data` | 16 | Output | New Stack Pointer value to load into `SP`. |

---

## 3. Internal Wires & Registers

* **`branch_taken`** (1-bit wire): Combinational evaluation of condition flags against the instruction type:
  * `JMP` (`10000`), `CALL` (`10101`), `RET` (`10110`): Always taken (`1'b1`).
  * `JZ` (`10001`): Evaluates to `FLAGS_in[1]` (True if Zero flag set).
  * `JNZ` (`10010`): Evaluates to `~FLAGS_in[1]` (True if Zero flag clear).
  * `JC` (`10011`): Evaluates to `FLAGS_in[0]` (True if Carry flag set).
  * `JNC` (`10100`): Evaluates to `~FLAGS_in[0]` (True if Carry flag clear).
* **`phase`** (1-bit register): Manages sequencing for 2-cycle instructions (`CALL` and `RET`).
  * `phase = 1'b0`: Cycle 1 (memory stack access).
  * `phase = 1'b1`: Cycle 2 (register update for `PC` and `SP`).

---

## 4. Instruction Execution Flow

### 4.1 Jumps (JMP/JZ/JNZ/JC/JNC) — 1 Cycle
Jump instructions complete in a single execution cycle.
* **Cycle 1**:
  * The module combinationally evaluates `branch_taken`.
  * If `branch_taken == 1'b1`: Assert `cf_pc_write = 1'b1` and set `cf_pc_data = IR_ext` to overwrite the PC.
  * If `branch_taken == 0'b0`: No signals are asserted. The CPU FSM resumes sequential execution.

### 4.2 CALL (INVOKE) — 2 Cycles
Subroutine calls execute in two cycles to allow stack modification and PC branching.
* **Cycle 1 (Phase 0)**:
  * Decrement Stack Pointer: Set `cf_sp_write = 1'b1` and `cf_sp_data = SP_in - 16'd1`.
  * Push Return Address: Assert `cf_ram_enable = 1'b1` and `cf_ram_write = 1'b1`.
  * Set RAM write address to `cf_ram_addr = SP_in[14:0] - 15'd1` and write data to `cf_ram_data = PC_in` (points to the instruction following the CALL).
  * At the rising clock edge, `phase` toggles to `1'b1`.
* **Cycle 2 (Phase 1)**:
  * Overwrite Program Counter: Assert `cf_pc_write = 1'b1` and set `cf_pc_data = IR_ext` to branch to the target subroutine.
  * At the rising clock edge, `phase` returns to `1'b0`.

### 4.3 RET (RETURN) — 2 Cycles
Subroutine returns execute in two cycles to read the return address from RAM and restore the caller's context.
* **Cycle 1 (Phase 0)**:
  * Pop Return Address request: Assert `cf_ram_enable = 1'b1` and `cf_ram_read = 1'b1`.
  * Set RAM address to the top of the stack: `cf_ram_addr = SP_in[14:0]`.
  * At the rising clock edge, `phase` toggles to `1'b1`.
* **Cycle 2 (Phase 1)**:
  * Overwrite Program Counter: Assert `cf_pc_write = 1'b1` and set `cf_pc_data = ram_rd_data` (the return address fetched from RAM).
  * Increment Stack Pointer: Assert `cf_sp_write = 1'b1` and set `cf_sp_data = SP_in + 16'd1`.
  * At the rising clock edge, `phase` returns to `1'b0`.

---

## 5. CPU Integration

To connect the [control_flow_module](./control_flow_module.v) inside [cpu_top.v](./cpu_top.v):

1. **Instantiation**: Instantiate the module, routing control lines like `cf_en`, `opcode`, `IR_ext`, `FLAGS_in`, `PC_in`, `SP_in`, and `ram_rd_data`.
2. **FSM Phase Stalling**: The FSM in `cpu_top` must be updated to remain in the `EXECUTE` state for two cycles during `CALL` or `RET` instructions. `cf_en` must remain high during both execution cycles.
3. **RAM Interface Multiplexing**: When `cf_en` is high, route `cf_ram_addr`, `cf_ram_read`, `cf_ram_write`, and `cf_ram_data` to the external RAM interface.
4. **PC/SP Multiplexing**: Integrate `cf_pc_write` and `cf_sp_write` to overwrite `PC` and `SP` registers in the root module:
   * `PC <= (cf_en && cf_pc_write) ? cf_pc_data[14:0] : PC;`
   * `SP <= (cf_en && cf_sp_write) ? cf_sp_data[14:0] : SP;`
