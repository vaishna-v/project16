module prog23_tb;

reg clk = 0;
reg rst = 1;
wire halt;

cpu_top uut(.clk(clk), .rst(rst), .halt(halt));

always #5 clk = ~clk;

integer i;
initial begin
    #20 rst = 0;

    $write("\nARRAY : ");

    for(i=0; i<10; i=i+1) begin
        $write("%0d ", uut.ram.mem[30+i]);
    end

    wait(halt);

    $write("\nARRAY (sorted) : ");

    for(i=0; i<10; i=i+1) begin
        $write("%0d ", uut.ram.mem[30+i]);
    end

    $write("\n");
    
    $finish;
end

initial #100000 $finish;

endmodule