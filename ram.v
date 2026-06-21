module ram
(
    input clk,
    input we,   // write enable

    input[14:0] rd_addr,      // 15 bit selection line for reading ram
    input[14:0] wr_addr,      // 15 bit selection line for writing ram
    input[15:0] din,          // 16-bit input data 
    output[15:0] dout          // 16-bit output data
);

    reg [15:0] mem [0:32767];      // each register of size 16-bit, total registers:  32768

    always @(posedge clk)
    begin
        if(we)
            mem[wr_addr] <= din;
    end

    assign dout = mem[rd_addr];

endmodule
