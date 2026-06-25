# is used to test files without rewriting compile command again and again
import os
import shutil
import subprocess
import sys

PROGRAMS_DIR = "programs"

ASM_DEST = "test.asm"
TB_DEST = "testbench.v"


def print_header(asm_file):

    print()

    with open(asm_file, "r") as f:

        for line in f:

            if line.startswith(";"):

                print(line[2:].rstrip())

            else:

                break

    print()


def main():

    program = input("Program: ").strip()

    if program.isdigit():

        program = f"prog{int(program):02d}"

    asm_src = os.path.join(
        PROGRAMS_DIR,
        f"{program}.asm"
    )

    tb_src = os.path.join(
        PROGRAMS_DIR,
        f"{program}.v"
    )

    if not os.path.isfile(asm_src):

        print(f"Error: '{asm_src}' not found.")
        return

    if not os.path.isfile(tb_src):

        print(f"Error: '{tb_src}' not found.")
        return

    print_header(asm_src)

    if os.path.exists(ASM_DEST):

        os.remove(ASM_DEST)

    if os.path.exists(TB_DEST):

        os.remove(TB_DEST)

    shutil.copy2(
        asm_src,
        ASM_DEST
    )

    shutil.copy2(
        tb_src,
        TB_DEST
    )

    result = subprocess.run(
        [sys.executable, "assembler.py"]
    )

    if result.returncode != 0:

        return

    compile_cmd = [

        "iverilog",

        "testbench.v",
        "cpu_top.v",
        "ram.v",
        "execution_unit.v",
        "arithmetic_module.v",
        "data_movement_module.v",
        "control_flow_module.v",
        "system_module.v"

    ]

    result = subprocess.run(
        compile_cmd
    )

    if result.returncode != 0:

        return

    subprocess.run(
        ["vvp", "a.out"]
    )


if __name__ == "__main__":

    main()