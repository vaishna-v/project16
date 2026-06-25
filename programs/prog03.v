module prog03_tb;

reg clk = 0;
reg rst = 1;
wire halt;

cpu_top uut(.clk(clk), .rst(rst), .halt(halt));

always #5 clk = ~clk;

initial begin

    #20 rst = 0;

    wait(halt);

    $display("VALUE  : %0d", uut.ram.mem[8]);
    $display("RESULT : %0d", uut.ram.mem[9]);

    $finish;
end

initial #100000 $finish;

endmodule