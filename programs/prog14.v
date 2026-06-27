module prog01_tb;

reg clk = 0;
reg rst = 1;
wire halt;

cpu_top uut(.clk(clk), .rst(rst), .halt(halt));

always #5 clk = ~clk;

initial begin
    #20 rst = 0;

    wait(halt);

    $display("NUM1   : %0d", uut.ram.mem[23]);
    $display("NUM2   : %0d", uut.ram.mem[24]);
    $display("RESULT : %0d", uut.ram.mem[25]);

    $finish;
end

initial #100000 $finish;

endmodule