module prog22_tb;

reg clk = 0;
reg rst = 1;
wire halt;

cpu_top uut(.clk(clk), .rst(rst), .halt(halt));

always #5 clk = ~clk;

integer i;
initial begin
    #20 rst = 0;

    wait(halt);

    $write("\nARRAY_1: ");

    for(i=0; i<10; i=i+1) begin
        $write("%0d ", uut.ram.mem[14+i]);
    end

    $write("\nARRAY_2: ");

    for(i=0; i<10; i=i+1) begin
        $write("%0d ", uut.ram.mem[24+i]);
    end

    $write("\n");
    
    $finish;
end

initial #100000 $finish;

endmodule