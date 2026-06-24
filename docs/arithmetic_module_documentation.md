# SYNTH-16 Arithmetic Module Documentation

This document describes the design, port interfaces, internal states, and instruction-by-instruction execution flow of the **Arithmetic Module** (`arithmetic_module`) for the SYNTH-16 custom 16-bit processor, referencing the updated combinational microarchitecture specifications.

---

## 1. Module Overview

The [arithmetic_module](arithmetic_module.v) is a dedicated execution unit within the SYNTH-16 CPU. It executes arithmetic and bitwise operations and is responsible for computing register write data and CPU flags.

Unlike the previous multi-cycle design, **all instructions are completed in a single execution cycle** because:
* input operands are supplied directly from the register file as combinational inputs.
* outputs are computed combinationally with no internal state updates required.
* there are **no clock, reset, or phase registers** in this module; it is a **purely combinational block**.

It implements the following instructions:
* `FUSE` (ADD)
* `DRAIN` (SUB)
* `RISE` (INC)
* `FALL` (DEC)
* `JUDGE` (CMP)
* `AND`
* `OR`
* `XOR`
* `NOT`
* `SHL`
* `SHR`

The module does not manage state or memory. It only outputs:
* a destination register write enable and data
* flag updates for zero and carry

---

## 2. Port Interface

| Port Name | Width | Direction | Description |
| :--- | :---: | :---: | :--- |
| `opcode` | 5 | Input | The current instruction opcode. |
| `rd_data` | 16 | Input | The current value of the destination register `Rd`. |
| `rs_data` | 16 | Input | The current value of the source register `Rs`. |
| `imm` | 4 | Input | The immediate field from the instruction word used for shift amount. |
| `reg_wr_en` | 1 | Output | Enable signal to write the arithmetic result back to the destination register. |
| `reg_wr_data` | 16 | Output | The value to write into the destination register. |
| `flag_wr_en` | 1 | Output | Enable signal to update CPU flags. |
| `flag_wr_data` | 2 | Output | Updated flags: `flag_wr_data[1]` = Zero, `flag_wr_data[0]` = Carry. |

---

## 3. Instruction Behavior

### 3.1 `FUSE` (ADD)
Opcode: `5'b00000`

* Computes `Rd + Rs`.
* Sets the carry flag based on overflow from the 16-bit addition.
* Sets the zero flag if the result is zero.
* Writes the result to `Rd`.

### 3.2 `DRAIN` (SUB)
Opcode: `5'b00001`

* Computes `Rd - Rs`.
* Sets the carry flag from the subtraction result.
* Sets the zero flag if the result is zero.
* Writes the result to `Rd`.

### 3.3 `RISE` (INC)
Opcode: `5'b00010`

* Computes `Rd + 1`.
* Sets carry from the increment result.
* Sets zero if the result becomes zero.
* Writes the result to `Rd`.

### 3.4 `FALL` (DEC)
Opcode: `5'b00011`

* Computes `Rd - 1`.
* Sets carry from the decrement result.
* Sets zero if the result becomes zero.
* Writes the result to `Rd`.

### 3.5 `JUDGE` (CMP)
Opcode: `5'b00100`

* Computes `Rd - Rs`.
* Does not write a register result.
* Sets the zero flag if `Rd == Rs`.
* Sets the carry flag according to the subtraction result.

### 3.6 `AND`
Opcode: `5'b00101`

* Computes bitwise `Rd & Rs`.
* Writes the result to `Rd`.
* Sets the zero flag if the result is zero.
* Clears the carry flag.

### 3.7 `OR`
Opcode: `5'b00110`

* Computes bitwise `Rd | Rs`.
* Writes the result to `Rd`.
* Sets zero if the result is zero.
* Clears the carry flag.

### 3.8 `XOR`
Opcode: `5'b00111`

* Computes bitwise `Rd ^ Rs`.
* Writes the result to `Rd`.
* Sets zero if the result is zero.
* Clears the carry flag.

### 3.9 `NOT`
Opcode: `5'b11000`

* Computes bitwise complement of `Rd`.
* Writes the result to `Rd`.
* Sets zero if the result is zero.
* Clears the carry flag.

### 3.10 `SHL`
Opcode: `5'b11001`

* Shifts `Rd` left by `imm` bits.
* The carry flag is set to the bit shifted out from `Rd`.
* Writes the shifted result to `Rd`.
* Sets the zero flag if the result is zero.

### 3.11 `SHR`
Opcode: `5'b11010`

* Shifts `Rd` right by `imm` bits.
* The carry flag is set to the bit shifted out from `Rd`.
* Writes the shifted result to `Rd`.
* Sets the zero flag if the result is zero.

---

## 4. Integration Notes

* The `arithmetic_module` is instantiated inside `execution_unit.v`.
* Its outputs are selected when the current opcode falls into the arithmetic category.
* The CPU relies on `reg_wr_en` and `flag_wr_en` to update register and flag state during the `EXECUTE` stage.
* This module does not require any clock or reset signals because it is pure combinational logic.
