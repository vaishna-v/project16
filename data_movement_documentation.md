# SYNTH-16 Data Movement Module Documentation

This document describes the design, port interfaces, internal states, and instruction-by-instruction execution flow of the **Data Movement Module** (`data_movement_module`) for the SYNTH-16 custom 16-bit processor, referencing the SYNTH-16 Microarchitecture Specification.

---

## 1. Module Overview

The [data_movement_module](./data_movement_module.v) is a dedicated execution unit within the SYNTH-16 CPU. It is responsible for transferring data between registers, loading immediate values, and performing read/write operations to external RAM.

It implements the following instructions:
* **MOV (MIRROR)** (Opcode `01010`): Copies the value of the source register (`Rs`) to the destination register (`Rd`).
* **LOADI (ENCHANT)** (Opcode `01011`): Loads a 16-bit immediate value (`IR_ext` from the second instruction word) into the destination register (`Rd`). Updates flags.
* **LOAD (SUMMON)** (Opcode `01000`): Loads a 16-bit word from memory address stored in `Rs` into destination register `Rd`.
* **STORE (SEAL)** (Opcode `01001`): Stores a 16-bit word from source register `Rs` into memory address stored in `Rd`.

---

## 2. Port Configuration

Below is the interface of the [data_movement_module](./data_movement_module.v). It connects to the CPU FSM and requests operations to be carried out by the CPU's Read/Write (RW) module.

| Port Name | Width | Direction | Description |
| :--- | :---: | :---: | :--- |
| `clk` | 1 | Input | System clock (active-high). |
| `rst` | 1 | Input | Synchronous system reset (active-high). |
| `dmov_en` | 1 | Input | Enable signal asserted by the Execute module when a data movement instruction is decoded. |
| `opcode` | 5 | Input | The 5-bit instruction opcode from `IR[15:11]`. |
| `rd_addr` | 3 | Input | Destination register index from `IR[9:7]`. |
| `rs_addr` | 3 | Input | Source register index from `IR[6:4]`. |
| `IR_ext` | 16 | Input | The 16-bit immediate value fetched during `FETCH_EXT` (mode_bit = 1). |
| `reg_rd_data` | 16 | Input | The 16-bit data read back from the register file (GPR). |
| `ram_rd_data` | 16 | Input | The 16-bit data read back from external RAM. |
| `dmov_reg_enable` | 1 | Output | Asserted high to request register file read/write access. |
| `dmov_reg_addr` | 3 | Output | The register index to access (either for reading `Rs` or `Rd`). |
| `dmov_reg_read` | 1 | Output | Asserted high to read from the register file at address `dmov_reg_addr`. |
| `dmov_reg_write` | 1 | Output | Asserted high to write data to the destination register (`Rd`). |
| `dmov_reg_data` | 16 | Output | The data to write into the destination register (`Rd`). |
| `dmov_flag_enable` | 1 | Output | Asserted high to request updates to the processor flags. |
| `dmov_flag_write` | 1 | Output | Asserted high to write new flag values. |
| `dmov_flag_data` | 2 | Output | New flag values `{Zero, Carry}` to write. For LOADI, updates Zero flag (Z) and clears Carry (C). |
| `dmov_ram_enable` | 1 | Output | Asserted high to request external RAM read/write access. |
| `dmov_ram_addr` | 15 | Output | 15-bit address sent to RAM. |
| `dmov_ram_read` | 1 | Output | Asserted high to request a memory read. |
| `dmov_ram_write` | 1 | Output | Asserted high to request a memory write. |
| `dmov_ram_data` | 16 | Output | Data to write to memory. |

---

## 3. Internal Wires & Registers

The module maintains internal registers to manage multi-cycle memory instructions:

* **`op_sel`** (2-bit wire): Decoded internally from `opcode[1:0]` to simplify instruction routing:
  * `00` = `LOAD` (SUMMON)
  * `01` = `STORE` (SEAL)
  * `10` = `MOV` (MIRROR)
  * `11` = `LOADI` (ENCHANT)
* **`phase`** (1-bit register): Used for `LOAD` and `STORE` instructions.
  * `phase = 1'b0`: Represents Cycle 1 (address decoding and memory request).
  * `phase = 1'b1`: Represents Cycle 2 (register write-back or RAM writing).
* **`addr_latch`** (16-bit register): Holds the RAM address captured in Phase 0 so it is preserved during Phase 1.
  * For `LOAD`: Latches the base address read from register `Rs`.
  * For `STORE`: Latches the destination address read from register `Rd`.

---

## 4. Instruction Execution Flow

### 4.1 MOV (MIRROR) — 1 Cycle
Executes in a single cycle. Copies data from `Rs` directly to `Rd`.
* **Cycle 1**:
  * Set `dmov_reg_enable = 1'b1`, `dmov_reg_addr = rs_addr`, and `dmov_reg_read = 1'b1` to read the value of `Rs`.
  * Set `dmov_reg_write = 1'b1` and `dmov_reg_data = reg_rd_data` (the read value) to write it into `Rd`.

### 4.2 LOADI (ENCHANT) — 1 Cycle
Executes in a single cycle. Copies the 16-bit immediate `IR_ext` to `Rd` and updates flags.
* **Cycle 1**:
  * Set `dmov_reg_enable = 1'b1`, `dmov_reg_write = 1'b1`, and `dmov_reg_data = IR_ext`.
  * Set `dmov_flag_enable = 1'b1`, `dmov_flag_write = 1'b1`, and `dmov_flag_data = {Z, 1'b0}` where `Z = (IR_ext == 16'h0000)`.

### 4.3 LOAD (SUMMON) — 2 Cycles
Requires two cycles due to sequential register reading and memory fetching.
* **Cycle 1 (Phase 0)**:
  * Set `dmov_reg_enable = 1'b1`, `dmov_reg_addr = rs_addr`, and `dmov_reg_read = 1'b1` to read the target memory address from register `Rs`.
  * Set `dmov_ram_enable = 1'b1`, `dmov_ram_read = 1'b1`, and drive `dmov_ram_addr = reg_rd_data[14:0]` combinational value to launch the memory read request.
  * At the rising clock edge, `reg_rd_data` (address) is stored in `addr_latch` and `phase` toggles to `1'b1`.
* **Cycle 2 (Phase 1)**:
  * RAM returns data on `ram_rd_data`.
  * Set `dmov_reg_enable = 1'b1`, `dmov_reg_write = 1'b1`, and `dmov_reg_data = ram_rd_data` to write the fetched data to `Rd`.
  * At the rising clock edge, `phase` returns to `1'b0`.

### 4.4 STORE (SEAL) — 2 Cycles
Requires two cycles to read the target address in Cycle 1 and write data to RAM in Cycle 2.
* **Cycle 1 (Phase 0)**:
  * Set `dmov_reg_enable = 1'b1`, `dmov_reg_addr = rd_addr` (destination register contains target address), and `dmov_reg_read = 1'b1`.
  * At the rising clock edge, this address is latched into `addr_latch` and `phase` toggles to `1'b1`.
* **Cycle 2 (Phase 1)**:
  * Set `dmov_reg_enable = 1'b1`, `dmov_reg_addr = rs_addr` (source register contains data to write), and `dmov_reg_read = 1'b1`.
  * Set `dmov_ram_enable = 1'b1`, `dmov_ram_write = 1'b1`, `dmov_ram_addr = addr_latch[14:0]`, and `dmov_ram_data = reg_rd_data`.
  * At the rising clock edge, memory is written and `phase` returns to `1'b0`.

---

## 5. CPU Integration

To connect the [data_movement_module](./data_movement_module.v) inside [cpu_top.v](./cpu_top.v):

1. **Instantiation**: Instantiate the module, passing `clk`, `rst`, `dmov_en`, `opcode`, `rd_addr`, `rs_addr`, `IR_ext`, register read lines, and RAM read data.
2. **FSM Phase Stalling**: Ensure the FSM stays in the `EXECUTE` state for two cycles when `opcode` indicates `LOAD` or `STORE` (holding `dmov_en` high until `phase` completes cycle 1).
3. **RAM Multiplexing**: If `dmov_en` is high, route `dmov_ram_addr`, `dmov_ram_read`, `dmov_ram_write`, and `dmov_ram_data` to the external RAM interface.
4. **Register Write Multiplexing**: If `dmov_en` and `dmov_reg_write` are high, update the register file `regfile[rd_addr] <= dmov_reg_data` on the clock edge.
