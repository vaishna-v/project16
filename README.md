# SYNTH-16 Assembler

A two-pass assembler for the **SYNTH-16** custom 16-bit ISA. Reads a `.asm` source file and produces hex and binary machine code output files, ready to be loaded into a SYNTH-16 CPU implementation or simulator.

---

## Table of Contents

- [Project Structure](#project-structure)
- [ISA Overview](#isa-overview)
- [Instruction Encoding](#instruction-encoding)
- [Instruction Formats](#instruction-formats)
- [Instruction Set](#instruction-set)
- [Aliases](#aliases-conventional-names)
- [Assembly Syntax](#assembly-syntax)
- [Usage](#usage)
- [Output Files](#output-files)
- [Example Program](#example-program)
- [How the Assembler Works](#how-the-assembler-works)
- [Error Handling](#error-handling)

---

## Project Structure

```
project16/
├── assembler.py      # Main assembler — two-pass, label-aware
├── opcodes.json      # Instruction definitions (opcode bits + format)
├── aliases.json      # Friendly aliases for native mnemonics
├── program.asm       # Sample program: first 10 Fibonacci numbers
├── program.hex       # Output: one 16-bit word per line, hex
├── program.bin       # Output: one 16-bit word per line, binary
├── result.txt        # Debug / scratch binary output
└── resulthex.txt     # Debug / scratch hex output
```

---

## ISA Overview

SYNTH-16 is a custom 16-bit architecture with:

- **8 general-purpose registers** — `R0` through `R7`
- **16-bit instruction words** — most instructions fit in a single word; two-word instructions handle full 16-bit immediates and branch addresses
- **5-bit opcode space** — supports up to 32 distinct instructions
- **Themed native mnemonics** with conventional aliases (e.g. `FUSE` / `ADD`, `WARP` / `JMP`)

---

## Instruction Encoding

Every instruction is encoded as a **16-bit word**:

```
 15      11  10   9     7   6     4   3     0
┌──────────┬────┬───────┬───────┬───────────┐
│  opcode  │mode│  Rd   │  Rs   │    imm    │
│ (5 bits) │(1b)│(3 bit)│(3 bit)│  (4 bit)  │
└──────────┴────┴───────┴───────┴───────────┘
```

| Field    | Bits  | Description                                              |
|----------|-------|----------------------------------------------------------|
| `opcode` | 15–11 | Identifies the instruction (5 bits → 32 possible opcodes)|
| `mode`   | 10    | Extended flag: `1` = a second 16-bit word follows        |
| `Rd`     | 9–7   | Destination register (`R0`–`R7`)                         |
| `Rs`     | 6–4   | Source register (`R0`–`R7`)                              |
| `imm`    | 3–0   | 4-bit immediate (shift amount or small constant)         |

When `mode = 1`, the **next word** holds a full 16-bit value (immediate or branch address).

---

## Instruction Formats

| Format   | Operands          | Words | Description                                       |
|----------|-------------------|-------|---------------------------------------------------|
| `RR`     | `Rd, Rs`          | 1     | Two-register operation                            |
| `R`      | `Rd`              | 1     | Single-register operation                         |
| `SHIFT`  | `Rd, imm4`        | 1     | Register + 4-bit shift amount                     |
| `EXT`    | `Rd, imm16`       | 2     | Load full 16-bit immediate into register           |
| `BRANCH` | `label` / `addr`  | 2     | Jump or call — 16-bit target in the second word   |
| `NONE`   | *(none)*          | 1     | No operands                                       |

---

## Instruction Set

### Arithmetic

| Mnemonic | Format | Opcode    | Operation              |
|----------|--------|-----------|------------------------|
| `FUSE`   | RR     | `00000`   | `Rd = Rd + Rs`         |
| `DRAIN`  | RR     | `00001`   | `Rd = Rd - Rs`         |
| `RISE`   | R      | `00010`   | `Rd = Rd + 1`          |
| `FALL`   | R      | `00011`   | `Rd = Rd - 1`          |

### Logic

| Mnemonic | Format | Opcode    | Operation              |
|----------|--------|-----------|------------------------|
| `JUDGE`  | RR     | `00100`   | Sets flags for `Rd - Rs` (compare, no writeback) |
| `AND`    | RR     | `00101`   | `Rd = Rd & Rs`         |
| `OR`     | RR     | `00110`   | `Rd = Rd \| Rs`        |
| `XOR`    | RR     | `00111`   | `Rd = Rd ^ Rs`         |
| `NOT`    | R      | `11000`   | `Rd = ~Rd`             |

### Shift

| Mnemonic | Format | Opcode    | Operation              |
|----------|--------|-----------|------------------------|
| `SHL`    | SHIFT  | `11001`   | `Rd = Rd << imm4`      |
| `SHR`    | SHIFT  | `11010`   | `Rd = Rd >> imm4`      |

### Memory

| Mnemonic  | Format | Opcode  | Operation              |
|-----------|--------|---------|------------------------|
| `SUMMON`  | RR     | `01000` | `Rd = Mem[Rs]` (load)  |
| `SEAL`    | RR     | `01001` | `Mem[Rs] = Rd` (store) |
| `MIRROR`  | RR     | `01010` | `Rd = Rs` (move/copy)  |
| `ENCHANT` | EXT    | `01011` | `Rd = imm16` (load immediate) |

### Control Flow

| Mnemonic  | Format | Opcode  | Condition                   |
|-----------|--------|---------|-----------------------------|
| `WARP`    | BRANCH | `10000` | Unconditional jump          |
| `WARPZ`   | BRANCH | `10001` | Jump if Zero flag set       |
| `WARPNZ`  | BRANCH | `10010` | Jump if Zero flag not set   |
| `WARPC`   | BRANCH | `10011` | Jump if Carry flag set      |
| `WARPNC`  | BRANCH | `10100` | Jump if Carry flag not set  |
| `INVOKE`  | BRANCH | `10101` | Call subroutine             |
| `RETURN`  | NONE   | `10110` | Return from subroutine      |

### Miscellaneous

| Mnemonic | Format | Opcode  | Description       |
|----------|--------|---------|-------------------|
| `IDLE`   | NONE   | `11100` | No operation      |
| `FREEZE` | NONE   | `11101` | Halt execution    |

---

## Aliases (Conventional Names)

The assembler accepts standard mnemonics and maps them to native SYNTH-16 ones transparently. Use whichever style you prefer — they produce identical output.

| Alias    | Native    | Alias   | Native    |
|----------|-----------|---------|-----------|
| `ADD`    | `FUSE`    | `LOAD`  | `SUMMON`  |
| `SUB`    | `DRAIN`   | `STORE` | `SEAL`    |
| `INC`    | `RISE`    | `MOV`   | `MIRROR`  |
| `DEC`    | `FALL`    | `LOADI` | `ENCHANT` |
| `CMP`    | `JUDGE`   | `JMP`   | `WARP`    |
| `NOP`    | `IDLE`    | `JZ`    | `WARPZ`   |
| `HALT`   | `FREEZE`  | `JNZ`   | `WARPNZ`  |
| `CALL`   | `INVOKE`  | `JC`    | `WARPC`   |
| `RET`    | `RETURN`  | `JNC`   | `WARPNC`  |

---

## Assembly Syntax

```asm
; This is a comment — everything after ; is ignored

label:
    INSTRUCTION Rd, Rs         ; RR format
    INSTRUCTION Rd, imm        ; SHIFT or EXT format
    INSTRUCTION label_name     ; BRANCH format (label or address)
    INSTRUCTION                ; NONE format (no operands)

inline_label: INSTRUCTION Rd, Rs   ; label and instruction on same line
```

### Rules

- **Comments** begin with `;` — rest of the line is ignored
- **Labels** end with `:` — can be on their own line or before an instruction on the same line
- **Registers** are written as `R0`–`R7`, case-insensitive
- **Immediates** are decimal (`10`) or hex (`0xFF` / `0xff`)
- **Mnemonics** are case-insensitive — `FUSE`, `fuse`, `Fuse` all work
- **Branch targets** can be a label name or a numeric address

---

## Usage

**Requirements:** Python 3.x (no external dependencies)

```bash
python assembler.py
```

By default the assembler reads `program.asm`. To use a different source file, edit the constant at the top of `assembler.py`:

```python
ASM_FILE = "your_program.asm"
```

On success:

```
Assembly successful
Generated N words
Wrote program.hex
Wrote program.bin
```

---

## Output Files

### `program.hex`

One 16-bit word per line, encoded as 4 uppercase hex digits:

```
5C00
0000
5C80
0000
...
```

### `program.bin`

One 16-bit word per line, encoded as 16 binary digits:

```
0101110000000000
0000000000000000
0101110010000000
0000000000000000
...
```

Both files use word addresses — each line corresponds to one 16-bit memory word.

---

## Example Program

`program.asm` computes the first 10 Fibonacci numbers using registers as scratch storage.

**Register map:**

| Register | Role              |
|----------|-------------------|
| `R0`     | Constant zero     |
| `R1`     | `a` (current)     |
| `R2`     | `b` (next)        |
| `R3`     | Temp              |
| `R4`     | Loop counter      |
| `R5`     | Constant one      |

```asm
; Generate first 10 Fibonacci numbers

start:
    ENCHANT R0, 0         ; R0 = 0
    ENCHANT R1, 0         ; a  = 0
    ENCHANT R2, 1         ; b  = 1
    ENCHANT R4, 10        ; counter = 10
    ENCHANT R5, 1         ; constant 1

fib_loop:
    MIRROR  R3, R1        ; temp = a
    FUSE    R3, R2        ; temp = a + b
    MIRROR  R1, R2        ; a = b
    MIRROR  R2, R3        ; b = temp
    FALL    R4            ; counter--
    JUDGE   R4, R0        ; compare counter to 0
    WARPNZ  fib_loop      ; loop if counter != 0

    FREEZE                ; halt
```

**Assembled output (`program.hex`):**

```
5C00  ; ENCHANT R0 (EXT word 1)
0000  ; imm16 = 0
5C80  ; ENCHANT R1 (EXT word 1)
0000  ; imm16 = 0
5D00  ; ENCHANT R2
0001  ; imm16 = 1
5E00  ; ENCHANT R4
000A  ; imm16 = 10
5E80  ; ENCHANT R5
0001  ; imm16 = 1
5190  ; MIRROR R3, R1
01A0  ; FUSE R3, R2
50A0  ; MIRROR R1, R2
5130  ; MIRROR R2, R3
1A00  ; FALL R4
2200  ; JUDGE R4, R0
9400  ; WARPNZ (EXT word 1)
000A  ; target address = 10 (fib_loop)
E800  ; FREEZE
```

---

## How the Assembler Works

The assembler operates in two passes over the source file.

**Pass 1 — Label resolution**

Scans every line without emitting code. Tracks the current program counter (in words), increments it by 1 for single-word instructions and by 2 for `EXT` and `BRANCH` format instructions. Records the word address of each label in a symbol table.

**Pass 2 — Code generation**

Parses each instruction line, looks up the opcode and format in `opcodes.json`, resolves any alias via `aliases.json`, and encodes the instruction into one or two 16-bit words using the field layout described above. Branch targets are resolved against the symbol table from Pass 1; numeric literals are also accepted directly.

**Encoding function:**

```
word = (opcode & 0x1F) << 11
     | (mode   & 0x01) << 10
     | (Rd     & 0x07) << 7
     | (Rs     & 0x07) << 4
     | (imm    & 0x0F)
```

---

## Error Handling

The assembler raises a descriptive `ValueError` and halts on:

| Error                            | Example                                |
|----------------------------------|----------------------------------------|
| Unknown mnemonic                 | `Line 5: Unknown instruction 'BLORP'`  |
| Wrong number of operands         | `Line 7: FUSE requires Rd, Rs`         |
| Invalid register name            | `Invalid register 'R9'`               |
| Shift amount out of range        | `Shift amount must be 0-15`            |
| 16-bit immediate out of range    | `Immediate out of range`               |
| Duplicate label                  | `Line 12: Duplicate label 'start'`     |
| Undefined label in branch        | `Line 9: Undefined label 'loop_end'`   |

---

## Part of the SYNTH-16 Project

This assembler is part of a larger effort to design and implement a custom 16-bit CPU architecture from scratch — including ISA design, Verilog RTL, and FPGA synthesis targeting the **Sipeed Tang Primer 20K** (Gowin GW2A).
