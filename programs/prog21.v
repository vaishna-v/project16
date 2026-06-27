module prog21_tb;

reg clk = 0;
reg rst = 1;
wire halt;

cpu_top uut(.clk(clk), .rst(rst), .halt(halt));

always #5 clk = ~clk;

integer i;
initial begin
    #20 rst = 0;

    wait(halt);

    $write("\nARRAY     : ");

    for(i=0; i<10; i=i+1) begin
        $write("%0d ", uut.ram.mem[31+i]);
    end

    $write("\n");

    $display("KEY    : %0d", uut.ram.mem[30]);

    $display("FOUND    : %0d", uut.ram.mem[41]);
    if(uut.ram.mem[41]==1)
        $display("INDEX    : %0d", uut.ram.mem[42]);
    
    $finish;
end

initial #100000 $finish;

endmodule