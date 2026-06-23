# SYNTH-16 Data Movement Module Documentation

This document describes the design, port interfaces, internal states, and instruction-by-instruction execution flow of the **Data Movement Module** (`data_movement_module`) for the SYNTH-16 custom 16-bit processor, referencing the updated combinational microarchitecture specifications.

---

## 1. Module Overview

The [data_movement_module](./data_movement_module.v) is a dedicated execution unit within the SYNTH-16 CPU. It is responsible for transferring data between registers, loading immediate values, and performing read/write operations to external RAM.

Unlike the previous multi-cycle design, **all instructions are completed in a single execution cycle** because:
* Register reads are performed asynchronously (combinational) in the top-level FSM, meaning source and destination register data are directly supplied to this module as inputs.
* The external RAM has asynchronous read capabilities, allowing memory loads to complete in the same clock cycle.
* There are **no clock, reset, or phase registers** in this module. It is a **purely combinational block**.

It implements the following instructions:
* **MOV (MIRROR)** (Opcode `01010`): Copies the value of the source register (`Rs`) to the destination register (`Rd`).
* **LOADI (ENCHANT)** (Opcode `01011`): Loads a 16-bit immediate value (`IR_ext` from the second instruction word) into the destination register (`Rd`). Updates flags.
* **LOAD (SUMMON)** (Opcode `01000`): Loads a 16-bit word from memory address stored in `Rs` into destination register `Rd`.
* **STORE (SEAL)** (Opcode `01001`): Stores a 16-bit word from source register `Rs` into memory address stored in `Rd`.

---

## 2. Port Configuration

Below is the interface of the [data_movement_module](./data_movement_module.v). It is connected as a sub-module of the `execution_unit`.

| Port Name | Width | Direction | Description |
| :--- | :---: | :---: | :--- |
| `opcode` | 5 | Input | The 5-bit instruction opcode from `IR[15:11]`. |
| `rd_data` | 16 | Input | The current 16-bit value of the destination register (`Rd`) from the register file. |
| `rs_data` | 16 | Input | The current 16-bit value of the source register (`Rs`) from the register file. |
| `IR_ext` | 16 | Input | The 16-bit immediate value fetched during `FETCH_EXT` (mode_bit = 1). |
| `ram_rd_data` | 16 | Input | The 16-bit data read back asynchronously from external RAM. |
| `reg_wr_en` | 1 | Output | Asserted high when writing data to the destination register (`Rd`). |
| `reg_wr_data` | 16 | Output | The data to write into the destination register (`Rd`). |
| `flag_wr_en` | 1 | Output | Asserted high to write new flag values. |
| `flag_wr_data` | 2 | Output | New flag values `{Zero, Carry}` to write. For LOADI, updates Zero flag (Z) and clears Carry (C). |
| `ram_rd_addr` | 15 | Output | 15-bit address sent to RAM to request an asynchronous read. |
| `ram_wr_en` | 1 | Output | Asserted high to request a memory write (writes on the clock edge). |
| `ram_wr_addr` | 15 | Output | 15-bit address sent to RAM for writing. |
| `ram_wr_data` | 16 | Output | Data to write to memory. |

---

## 3. Instruction Execution Flow

Since the module is combinational, all outputs are driven instantaneously from the inputs in a single cycle.

### 3.1 MOV (MIRROR)
Copies `rs_data` directly to `rd_data`.
* `reg_wr_en = 1'b1`
* `reg_wr_data = rs_data`

### 3.2 LOADI (ENCHANT)
Copies `IR_ext` to `rd_data` and evaluates the Zero flag.
* `reg_wr_en = 1'b1`
* `reg_wr_data = IR_ext`
* `flag_wr_en = 1'b1`
* `flag_wr_data = {(IR_ext == 16'h0000) ? 1'b1 : 1'b0, 1'b0}` (Carry flag is cleared to 0)

### 3.3 LOAD (SUMMON)
Drives the memory address using `rs_data` and routes the returned RAM data to register write lines.
* `ram_rd_addr = rs_data[14:0]`
* `reg_wr_en = 1'b1`
* `reg_wr_data = ram_rd_data` (read asynchronously from RAM in the same cycle)

### 3.4 STORE (SEAL)
Drives the RAM write address and data. Writing occurs at the rising clock edge at the end of the `EXECUTE` cycle.
* `ram_wr_en = 1'b1`
* `ram_wr_addr = rd_data[14:0]`
* `ram_wr_data = rs_data`

---

## 4. CPU Integration

To connect the [data_movement_module](./data_movement_module.v) inside [execution_unit.v](./execution_unit.v):

1. **Instantiation**: Instantiate the module inside `execution_unit.v`, mapping inputs like `opcode`, `rd_data`, `rs_data`, `IR_ext`, and `ram_rd_data` to its outputs.
2. **CPU-Level Writes**: The CPU FSM (`cpu_top.v`) receives the write requests and writes data to `regfile[rd_addr]` (if `reg_wr_en` is high) or `FLAGS` (if `flag_wr_en` is high) on the positive clock edge at the end of the `EXECUTE` state.
3. **RAM Multiplexing**: If `dm_active` is asserted, the `execution_unit` routes `ram_rd_addr`, `ram_wr_en`, `ram_wr_addr`, and `ram_wr_data` from this module to the top-level RAM ports.
