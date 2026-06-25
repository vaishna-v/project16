import json
import re

ASM_FILE = "test.asm"
OPCODE_FILE = "opcodes.json"
ALIAS_FILE = "aliases.json"

HEX_OUT = "program.hex"
BIN_OUT = "program.bin"


with open(OPCODE_FILE, "r") as f:
    OPCODES = json.load(f)

with open(ALIAS_FILE, "r") as f:
    ALIASES = json.load(f)


constants = {}


def normalize_mnemonic(name):

    name = name.upper()

    return ALIASES.get(name, name)


def parse_register(token):

    token = token.strip().upper()

    match = re.fullmatch(r"R([0-7])", token)

    if not match:
        raise ValueError(
            f"Invalid register '{token}'"
        )

    return int(match.group(1))


def parse_number(token):

    token = token.strip()

    if token.lower() in constants:

        return constants[token.lower()]

    if token.lower().startswith("0x"):

        return int(token, 16)

    if token.lower().startswith("0b"):

        return int(token, 2)

    return int(token)


def encode_word(opcode, mode=0, rd=0, rs=0, imm=0):

    return (
        ((opcode & 0x1F) << 11)
        | ((mode & 1) << 10)
        | ((rd & 0x7) << 7)
        | ((rs & 0x7) << 4)
        | (imm & 0xF)
    )


def instruction_size(fmt):

    if fmt in ("EXT", "BRANCH"):

        return 2

    return 1


# Read source

source_lines = []

with open(ASM_FILE, "r") as f:

    for line_number, raw_line in enumerate(f, start=1):

        line = raw_line.split(";")[0].strip()

        if line:

            source_lines.append(
                (line_number, line)
            )


# Pass 1

labels = {}

pc = 0

for line_number, line in source_lines:

    while ":" in line:

        label, remainder = line.split(":", 1)

        label = label.strip().lower()

        if label in labels:

            raise ValueError(
                f"Line {line_number}: Duplicate label '{label}'"
            )

        labels[label] = pc

        line = remainder.strip()

        if not line:

            break

    if not line:

        continue

    tokens = [
        token.strip()
        for token in re.split(r"[,\s]+", line)
        if token.strip()
    ]

    # EQU

    if len(tokens) >= 3 and tokens[1].upper() == "EQU":

        constants[tokens[0].lower()] = parse_number(
            tokens[2]
        )

        continue

    mnemonic = normalize_mnemonic(
        tokens[0]
    )

    # ORG

    if mnemonic == "ORG":

        if len(tokens) != 2:

            raise ValueError(
                f"Line {line_number}: ORG requires one address"
            )

        pc = parse_number(
            tokens[1]
        )

        continue

    # DW

    if mnemonic == "DW":

        if len(tokens) != 2:

            raise ValueError(
                f"Line {line_number}: DW requires one value"
            )

        pc += 1

        continue

    if mnemonic not in OPCODES:

        raise ValueError(
            f"Line {line_number}: Unknown instruction '{mnemonic}'"
        )

    fmt = OPCODES[mnemonic]["format"]

    pc += instruction_size(fmt)
    # Pass 2

output_words = []

pc = 0

for line_number, line in source_lines:

    while ":" in line:

        _, line = line.split(":", 1)

        line = line.strip()

        if not line:

            break

    if not line:

        continue

    tokens = [
        token.strip()
        for token in re.split(r"[,\s]+", line)
        if token.strip()
    ]

    # EQU

    if len(tokens) >= 3 and tokens[1].upper() == "EQU":

        continue

    mnemonic = normalize_mnemonic(
        tokens[0]
    )

    # ORG

    if mnemonic == "ORG":

        if len(tokens) != 2:

            raise ValueError(
                f"Line {line_number}: ORG requires one address"
            )

        target = parse_number(
            tokens[1]
        )

        while pc < target:

            output_words.append(
                0
            )

            pc += 1

        continue

    # DW

    if mnemonic == "DW":

        if len(tokens) != 2:

            raise ValueError(
                f"Line {line_number}: DW requires one value"
            )

        value = parse_number(
            tokens[1]
        )

        if not (0 <= value <= 0xFFFF):

            raise ValueError(
                f"Line {line_number}: Word out of range"
            )

        output_words.append(
            value
        )

        pc += 1

        continue

    if mnemonic not in OPCODES:

        raise ValueError(
            f"Line {line_number}: Unknown instruction '{mnemonic}'"
        )

    info = OPCODES[mnemonic]

    opcode = int(
        info["opcode"],
        2
    )

    fmt = info["format"]

    if fmt == "RR":

        if len(tokens) != 3:

            raise ValueError(
                f"Line {line_number}: {mnemonic} requires Rd, Rs"
            )

        rd = parse_register(
            tokens[1]
        )

        rs = parse_register(
            tokens[2]
        )

        output_words.append(

            encode_word(
                opcode,
                rd=rd,
                rs=rs
            )

        )

        pc += 1

    elif fmt == "R":

        if len(tokens) != 2:

            raise ValueError(
                f"Line {line_number}: {mnemonic} requires Rd"
            )

        rd = parse_register(
            tokens[1]
        )

        output_words.append(

            encode_word(
                opcode,
                rd=rd
            )

        )

        pc += 1

    elif fmt == "SHIFT":

        if len(tokens) != 3:

            raise ValueError(
                f"Line {line_number}: {mnemonic} requires Rd, Imm"
            )

        rd = parse_register(
            tokens[1]
        )

        imm = parse_number(
            tokens[2]
        )

        if not (0 <= imm <= 15):

            raise ValueError(
                f"Line {line_number}: Shift amount must be 0-15"
            )

        output_words.append(

            encode_word(
                opcode,
                rd=rd,
                imm=imm
            )

        )

        pc += 1

    elif fmt == "EXT":

        if len(tokens) != 3:

            raise ValueError(
                f"Line {line_number}: {mnemonic} requires Rd, Imm16"
            )

        rd = parse_register(
            tokens[1]
        )

        operand = tokens[2]

        if operand.lower() in labels:

            imm16 = labels[
                operand.lower()
            ]

        else:

            imm16 = parse_number(
                operand
            )

        if not (0 <= imm16 <= 0xFFFF):

            raise ValueError(
                f"Line {line_number}: Immediate out of range"
            )

        output_words.append(

            encode_word(
                opcode,
                mode=1,
                rd=rd
            )

        )

        output_words.append(
            imm16
        )

        pc += 2

    elif fmt == "BRANCH":

        if len(tokens) != 2:

            raise ValueError(
                f"Line {line_number}: {mnemonic} requires address"
            )

        operand = tokens[1]

        if operand.lower() in labels:

            address = labels[
                operand.lower()
            ]

        else:

            address = parse_number(
                operand
            )

        output_words.append(

            encode_word(
                opcode,
                mode=1
            )

        )

        output_words.append(
            address
        )

        pc += 2

    elif fmt == "NONE":

        if len(tokens) != 1:

            raise ValueError(
                f"Line {line_number}: {mnemonic} takes no operands"
            )

        output_words.append(

            encode_word(
                opcode
            )

        )

        pc += 1

    else:

        raise ValueError(
            f"Line {line_number}: Unknown format '{fmt}'"
        )


# Hex output

with open(HEX_OUT, "w") as f:

    for word in output_words:

        f.write(
            f"{word:04X}\n"
        )


# Binary output

with open(BIN_OUT, "w") as f:

    for word in output_words:

        f.write(
            f"{word:016b}\n"
        )


print("\n\nAssembly successful")
print(f"Generated {len(output_words)} words")
print(f"Wrote {HEX_OUT}")
print(f"Wrote {BIN_OUT}\n\n\n")