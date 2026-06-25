module prog08_tb;

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

    $display("ARRAY[0] : %0d", uut.ram.mem[30]);
    $display("ARRAY[1] : %0d", uut.ram.mem[31]);
    $display("ARRAY[2] : %0d", uut.ram.mem[32]);
    $display("ARRAY[3] : %0d", uut.ram.mem[33]);
    $display("ARRAY[4] : %0d", uut.ram.mem[34]);
    $display("RESULT   : %0d", uut.ram.mem[35]);

    $finish;

end

initial begin

    #100000;
    $finish;

end

endmodule