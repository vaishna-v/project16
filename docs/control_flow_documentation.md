# SYNTH-16 Control Flow Module Documentation

This document describes the design, port interfaces, internal states, and instruction-by-instruction execution flow of the **Control Flow Module** (`control_flow_module`) for the SYNTH-16 custom 16-bit processor, referencing the updated combinational microarchitecture specifications.

---

## 1. Module Overview

The [control_flow_module](./control_flow_module.v) is responsible for executing instructions that change the sequential program flow, such as unconditional jumps, conditional jumps, subroutine calls, and returns.

Unlike the previous multi-cycle design, **all instructions are completed in a single execution cycle** because:
* Stack reading during `RET` is executed asynchronously via the RAM's combinational output `ram_rd_data` when `ram_rd_addr` is set to the current stack pointer `SP_in`.
* Stack writing during `CALL` is executed in a single cycle where the decremented stack pointer (`SP_in - 1`) and return address (`PC_in`) are output combinationally, writing to RAM on the positive clock edge at the end of the `EXECUTE` state.
* The module has **no clock, reset, or phase registers**. It is a **purely combinational block**.

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

Below is the port structure for [control_flow_module](./control_flow_module.v). It is connected as a sub-module of the `execution_unit`.

| Port Name | Width | Direction | Description |
| :--- | :---: | :---: | :--- |
| `opcode` | 5 | Input | The 5-bit instruction opcode from `IR[15:11]`. |
| `PC_in` | 15 | Input | The current Program Counter (`PC`) from `cpu_top`. |
| `SP_in` | 15 | Input | The current Stack Pointer (`SP`) from `cpu_top`. |
| `FLAGS_in` | 2 | Input | The current CPU flags: `FLAGS_in[1]` = Zero (Z), `FLAGS_in[0]` = Carry (C). |
| `IR_ext` | 16 | Input | The 16-bit target branch address from the second instruction word. |
| `ram_rd_data` | 16 | Input | Data read back asynchronously from external RAM (used by RET). |
| `PC_wr_en` | 1 | Output | Asserted high to write a new value into the Program Counter. |
| `PC_wr_data` | 15 | Output | New Program Counter value to load into `PC` on the rising clock edge. |
| `SP_wr_en` | 1 | Output | Asserted high to write a new value into the Stack Pointer. |
| `SP_wr_data` | 15 | Output | New Stack Pointer value to load into `SP` on the rising clock edge. |
| `ram_wr_en` | 1 | Output | Asserted high to request RAM write (writes on the clock edge). |
| `ram_wr_addr` | 15 | Output | 15-bit address sent to RAM for stack push operations (CALL). |
| `ram_wr_data` | 16 | Output | Return address data (current `PC_in`) to write to memory. |
| `ram_rd_addr` | 15 | Output | 15-bit address sent to RAM to pop the return address asynchronously (RET). |

---

## 3. Instruction Execution Flow

Since the module is combinational, all outputs are driven instantaneously from the inputs in a single cycle.

### 3.1 Jumps (JMP/JZ/JNZ/JC/JNC)
Checks flags combinational:
* Unconditional `JMP` is always taken.
* Conditional jumps are taken if their flag condition is met.
* If taken: `PC_wr_en = 1'b1` and `PC_wr_data = IR_ext[14:0]`.

### 3.2 CALL (INVOKE)
Branches the Program Counter and pushes the return address (`PC_in`) onto the stack in the same clock cycle:
* `SP_wr_en = 1'b1` and `SP_wr_data = SP_in - 15'd1`
* `ram_wr_en = 1'b1`, `ram_wr_addr = SP_in - 15'd1`, and `ram_wr_data = {1'b0, PC_in}`
* `PC_wr_en = 1'b1` and `PC_wr_data = IR_ext[14:0]`

### 3.3 RET (RETURN)
Pops the return address from the top of the stack asynchronously and updates the Program Counter and Stack Pointer:
* `ram_rd_addr = SP_in`
* `PC_wr_en = 1'b1` and `PC_wr_data = ram_rd_data[14:0]` (fetched asynchronously in the same cycle)
* `SP_wr_en = 1'b1` and `SP_wr_data = SP_in + 15'd1`

---

## 4. CPU Integration

To connect the [control_flow_module](./control_flow_module.v) inside [execution_unit.v](./execution_unit.v):

1. **Instantiation**: Instantiate the module inside `execution_unit.v`, mapping its control and status signals.
2. **CPU-Level Writes**: The CPU FSM (`cpu_top.v`) receives the write requests and writes data to `PC` (if `PC_wr_en` is high) or `SP` (if `SP_wr_en` is high) on the positive clock edge at the end of the `EXECUTE` state.
3. **RAM Interface Multiplexing**: If `cf_active` is asserted, the `execution_unit` routes `ram_rd_addr`, `ram_wr_en`, `ram_wr_addr`, and `ram_wr_data` from this module to the top-level RAM ports.
