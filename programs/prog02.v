module prog01_tb;

reg clk = 0;
reg rst = 1;
wire halt;

cpu_top uut(.clk(clk), .rst(rst), .halt(halt));

always #5 clk = ~clk;

initial begin   
    #20 rst = 0;
    wait(halt);

    $monitor("NUM1   : %0d\nNUM2   : %0d\nRESULT : %0d", uut.ram.mem[11], uut.ram.mem[12], uut.ram.mem[13]);
    $finish;
end

initial #100000 $finish;

endmodule