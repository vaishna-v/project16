
module tb_cpu;

    reg clk;
    reg rst;
    wire halt;

    cpu_top dut (
        .clk(clk),
        .rst(rst),
        .halt(halt)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Dump waves
    initial begin
        $dumpfile("cpu.vcd");
        $dumpvars(0, tb_cpu);
    end




    initial begin
        rst = 0;
        #1;
        rst = 1;
        #1;
        rst = 0;

        // ------------------------ Run --------------------------------

        #2000;

        // ----------------------------- Display state--------------------------

        $display("\n==== CPU STATE ====");
        $display("PC    = %h", dut.PC);
        $display("SP    = %h", dut.SP);
        $display("IR    = %h", dut.IR);
        $display("IRext = %h", dut.IR_ext);
        $display("FLAGS = %b", dut.FLAGS);

        $display("\n==== REGISTERS ====");
        $display("R0 = %h", dut.regfile[0]);
        $display("R1 = %h", dut.regfile[1]);
        $display("R2 = %h", dut.regfile[2]);
        $display("R3 = %h", dut.regfile[3]);
        $display("R4 = %h", dut.regfile[4]);
        $display("R5 = %h", dut.regfile[5]);
        $display("R6 = %h", dut.regfile[6]);
        $display("R7 = %h", dut.regfile[7]);

        $display("\n==== MEMORY ====");
        $display("mem[4000] = %h",
                 dut.myRam.mem[15'h4000]);

        $display("mem[4001] = %h",
                 dut.myRam.mem[15'h4001]);

        $finish;
    end




    // ------------------------- Live monitor ---------------------------

    always @(posedge clk) 
    begin
        $display
        (
            "T=%0t | ST=%0d NX=%0d | PC=%h | IR=%h IR_EXT=%h | OPC=%b M=%b RD=%0d RS=%0d IMM=%h | RAM_ADDR=%h RAM_DATA=%h",
                $time,
            dut.state,
            dut.next_state,
            dut.PC,
            dut.IR,
            dut.IR_ext,

            dut.opcode,
            dut.mode_bit,
            dut.rd_addr,
            dut.rs_addr,
            dut.imm,

            dut.ram_rd_addr,
            dut.ram_rd_data
        );
    end

endmodule