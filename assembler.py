import json
import re

ASM_FILE = "program.asm"
OPCODE_FILE = "opcodes.json"
ALIAS_FILE = "aliases.json"

HEX_OUT = "program.hex"
BIN_OUT = "program.bin"


with open(OPCODE_FILE, "r") as f:
    OPCODES = json.load(f)

with open(ALIAS_FILE, "r") as f:
    ALIASES = json.load(f)


def normalize_mnemonic(name):

    name = name.upper()

    return ALIASES.get(name, name)


def parse_register(token):

    token = token.strip().upper()

    match = re.fullmatch(r"R([0-7])", token)

    if not match:
        raise ValueError(f"Invalid register '{token}'")

    return int(match.group(1))


def parse_number(token):

    token = token.strip()

    if token.lower().startswith("0x"):
        return int(token, 16)

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
            source_lines.append((line_number, line))


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

    mnemonic = normalize_mnemonic(
        line.split()[0]
    )

    if mnemonic not in OPCODES:
        raise ValueError(
            f"Line {line_number}: Unknown instruction '{mnemonic}'"
        )

    fmt = OPCODES[mnemonic]["format"]

    pc += instruction_size(fmt)


# Pass 2

output_words = []

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

    mnemonic = normalize_mnemonic(tokens[0])

    if mnemonic not in OPCODES:
        raise ValueError(
            f"Line {line_number}: Unknown instruction '{mnemonic}'"
        )

    info = OPCODES[mnemonic]

    opcode = int(info["opcode"], 2)
    fmt = info["format"]

    if fmt == "RR":

        if len(tokens) != 3:
            raise ValueError(
                f"Line {line_number}: {mnemonic} requires Rd, Rs"
            )

        rd = parse_register(tokens[1])
        rs = parse_register(tokens[2])

        output_words.append(
            encode_word(
                opcode,
                rd=rd,
                rs=rs
            )
        )

    elif fmt == "R":

        if len(tokens) != 2:
            raise ValueError(
                f"Line {line_number}: {mnemonic} requires Rd"
            )

        rd = parse_register(tokens[1])

        output_words.append(
            encode_word(
                opcode,
                rd=rd
            )
        )

    elif fmt == "SHIFT":

        if len(tokens) != 3:
            raise ValueError(
                f"Line {line_number}: {mnemonic} requires Rd, Imm"
            )

        rd = parse_register(tokens[1])

        imm = parse_number(tokens[2])

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

    elif fmt == "EXT":

        if len(tokens) != 3:
            raise ValueError(
                f"Line {line_number}: {mnemonic} requires Rd, Imm16"
            )

        rd = parse_register(tokens[1])

        imm16 = parse_number(tokens[2])

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

    elif fmt == "BRANCH":

        if len(tokens) != 2:
            raise ValueError(
                f"Line {line_number}: {mnemonic} requires address"
            )

        target = tokens[1]

        if target.lower() in labels:

            address = labels[target.lower()]

        else:

            try:
                address = parse_number(target)

            except ValueError:

                raise ValueError(
                    f"Line {line_number}: Undefined label '{target}'"
                )

        output_words.append(
            encode_word(
                opcode,
                mode=1
            )
        )

        output_words.append(
            address & 0xFFFF
        )

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

    else:

        raise ValueError(
            f"Line {line_number}: Unknown format '{fmt}'"
        )


# Hex output

with open(HEX_OUT, "w") as f:

    for word in output_words:

        f.write(f"{word:04X}\n")


# Binary output

with open(BIN_OUT, "w") as f:

    for word in output_words:

        f.write(f"{word:016b}\n")


print("Assembly successful")
print(f"Generated {len(output_words)} words")
print(f"Wrote {HEX_OUT}")
print(f"Wrote {BIN_OUT}")