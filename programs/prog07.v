module prog07_tb;

reg clk = 0;
reg rst = 1;

wire halt;

cpu_top uut(
    .clk(clk),
    .rst(rst),
    .halt(halt)
);

always #5 clk = ~clk;

initial begin

    #20 rst = 0;

    wait(halt);

    $display("DIVIDEND : %0d", uut.ram.mem[19]);
    $display("DIVISOR  : %0d", uut.ram.mem[20]);
    $display("QUOTIENT : %0d", uut.ram.mem[21]);

    $finish;

end

initial begin

    #100000;
    $finish;

end

endmodule