# Project16: SYNTH-16 Custom 16-Bit Processor

Project16 is a custom 16-bit processor (designated **SYNTH-16**) implemented in Verilog. It features a unique, thematic assembly language ("Magical Mnemonic" ISA), a multi-stage FSM control architecture, combinational execution units, and an automated simulation test suite.

---

## 🌟 Architecture & Microarchitecture

The SYNTH-16 processor is designed around a word-addressable memory layout with 15-bit address lines (handling up to 32,768 words of RAM).

### 1. Instruction Pipeline (FSM States)
The top-level CPU state machine controls instructions through four primary phases:
* **FETCH**: Fetches the instruction word from RAM into the Instruction Register (`IR`) and increments the PC.
* **DECODE**: Decodes the opcode and determines whether a 16-bit immediate extension word is required.
* **FETCH_EXT**: Fetches the second instruction word containing the 16-bit immediate operand (e.g. for label offsets or full immediates) and increments the PC.
* **EXECUTE**: Executes the instruction combinationally in a single cycle and updates flags and registers.

### 2. Register & Flag File
* **GPRs**: 8 General Purpose Registers (`R0` through `R7`).
* **PC & SP**: 15-bit Program Counter and 15-bit Stack Pointer (initialized to `0x7FFF`).
* **FLAGS**: 2 Status Flags:
  * **Zero (Z)**: Set if the result of an arithmetic or logical operation is 0.
  * **Carry/Borrow (C)**: Set on arithmetic overflow or subtraction underflow (borrow).

---

## 🧙‍♂️ The SYNTH-16 "Magical" ISA

The processor features a unique vocabulary of mnemonics mapped to standard operations:

| Standard Operation | Magical Mnemonic | Description |
| :--- | :--- | :--- |
| **ADD** | `FUSE` | Adds Rs to Rd |
| **SUB** | `DRAIN` | Subtracts Rs from Rd |
| **INC** | `RISE` | Increments Rd by 1 |
| **DEC** | `FALL` | Decrements Rd by 1 |
| **CMP** | `JUDGE` | Compares Rd and Rs (updates flags without writing back) |
| **MOV** | `MIRROR` | Copies Rs to Rd |
| **LOADI** | `ENCHANT` | Loads 16-bit immediate value into Rd |
| **LOAD** | `SUMMON` | Loads value from RAM address in Rs into Rd |
| **STORE** | `SEAL` | Stores Rs into RAM address in Rd |
| **JMP** | `WARP` | Unconditional jump |
| **JZ** | `WARPZ` | Jump if Zero (Z == 1) |
| **JNZ** | `WARPNZ` | Jump if Not Zero (Z == 0) |
| **JC** | `WARPC` | Jump if Carry / Borrow (C == 1) |
| **JNC** | `WARPNC` | Jump if Not Carry / Borrow (C == 0) |
| **CALL** | `INVOKE` | Pushes return PC to stack and jumps |
| **RET** | `RETURN` | Pops return address from stack to PC |
| **HALT** | `FREEZE` | Stops CPU execution |

---

## 📂 Project Structure

* **`cpu_top.v`**: Main FSM state machine routing instruction execution.
* **`ram.v`**: Word-addressable 32,768 word memory unit featuring asynchronous reads and synchronous writes.
* **`execution_unit.v`**: Routes control signals and operands between CPU registers and specialized modules.
* **`arithmetic_module.v`**: ALU module implementing arithmetic and logic (`FUSE`, `DRAIN`, `RISE`, `FALL`, `JUDGE`, `AND`, `OR`, `XOR`, `SHL`, `SHR`).
* **`data_movement_module.v`**: Registers and RAM data transfer module (`MIRROR`, `ENCHANT`, `SUMMON`, `SEAL`).
* **`control_flow_module.v`**: Jump, Branch, Subroutine call, and return logic (`WARP`, `WARPZ`, `WARPNZ`, `WARPC`, `WARPNC`, `INVOKE`, `RETURN`).
* **`assembler.py`**: A custom assembler written in Python that translates SYNTH-16 assembly (`.asm`) into binary machine codes (`program.hex`/`program.bin`).

---

## 📋 Catalog of Test Programs (`/programs`)

* **`prog01.asm` - `prog08.asm`**: Standard functional checks for arithmetic operations, conditional jumps, logical expressions, and basic data movements.
* **`prog09.asm`**: Factorial calculation using multiplication via repeated addition.
* **`prog10.asm`**: Fibonacci sequence computation (calculates the N-th Fibonacci number).
* **`prog11.asm`**: Primality test for two separate numbers sequentially using an elegant loop-over-array approach.
* **`prog12.asm`**: Greatest Common Divisor (GCD) using the Euclidean subtraction algorithm.
* **`prog13.asm`**: Least Common Multiple (LCM) using running multiples (repeated addition).

---

## 🚀 How to Run Simulations

### Automated Suite
You can execute any test program by running the automated script at the root:
```bash
python tester.py
```
*Enter the program number when prompted (e.g. `11` or `12`).*

### Manual Execution
1. Copy the target files to root name:
   ```bash
   cp programs/prog12.asm test.asm
   cp programs/prog12.v testbench.v
   ```
2. Assemble the program:
   ```bash
   python assembler.py
   ```
3. Compile with Icarus Verilog:
   ```bash
   iverilog testbench.v cpu_top.v ram.v execution_unit.v arithmetic_module.v data_movement_module.v control_flow_module.v system_module.v
   ```
4. Run the simulator:
   ```bash
   vvp a.out
   ```
