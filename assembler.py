import json

OPCODE_FILE = "opcodes.json"
ASM_FILE = "program.asm"

with open(OPCODE_FILE, "r") as f:
    opcode_table = json.load(f)

# Check duplicate opcode values
#values = list(opcode_table.values())
#if len(values) != len(set(values)):
#    raise ValueError("Duplicate opcode values found in opcodes.json")

binary_lines = []
hex_lines = []

with open(ASM_FILE, "r") as f:
    for line_num, line in enumerate(f, start=1):

        line = line.strip()

        if not line:
            continue

        # Split instruction into fields
        fields = [x.strip() for x in line.split(",")]

        opcode = fields[0]
        operands = fields[1:]

        if opcode not in opcode_table:
            raise ValueError(
                f"Line {line_num}: Unknown opcode '{opcode}'"
            )

        opcode_hex = opcode_table[opcode].upper()

        machine_hex = [opcode_hex]

        for operand in operands:

            try:
                int(operand, 16)
            except ValueError:
                raise ValueError(
                    f"Line {line_num}: Invalid hex operand '{operand}'"
                )

            machine_hex.append(operand.upper())

        # Hex output
        hex_instruction = "".join(machine_hex)
        hex_lines.append(hex_instruction)

        # Binary output
        binary_instruction = ""

        for part in machine_hex:

            # preserve leading zeros
            if len(part) % 2:
                part = "0" + part

            for i in range(0, len(part), 2):
                byte = int(part[i:i+2], 16)
                binary_instruction += format(byte, "08b")

        binary_lines.append(binary_instruction)

with open("resulthex.txt", "w") as f:
    f.write("\n".join(hex_lines))

with open("result.txt", "w") as f:
    f.write("\n".join(binary_lines))

print("Assembly successful.")