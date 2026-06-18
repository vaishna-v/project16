module cpu_top
(
    input clk,
    input rst,

    output ram_wr_en,
    output[14:0] ram_wr_addr,               // driven by execution module directly
    output[15:0] ram_wr_data,

    output[14:0] ram_rd_addr,               // will change depending on state, PC for (fetch) otherwise driven by exec module   
    input[15:0] ram_rd_data,

    output halt
);


    reg[14:0] PC = 15'h0000;       // Program Counter is 15 bit 
    reg[14:0] SP = 15'h7FFF;
    reg[15:0] IR;
    reg[15:0] IR_ext;
    reg[2:0] FLAGS;
    reg[15:0] regfile[7:0];
    reg[2:0] state;
    wire[4:0] opcode;
    wire mode_bit;
    wire [2:0] rd_addr;
    wire [2:0] rs_addr;
    wire [4:0] imm;
    wire ex_en;                 // wasn't define in spec
    reg[2:0] next_state;        // This was not defined in microarch spec
    

    // some constants enum-
    localparam FETCH = 2'd1;
    localparam DECODE = 2'd2;
    localparam FETCH_EXT = 2'd3;
    localparam EXECUTE = 2'4;



    // Assign some constant flow to wires
    assign opcode = IR[15:11];
    assign mode_bit = IR[10];
    assign rd_addr = IR[9:7];
    assign rs_addr = IR[6:4];
    assign imm = IR[3:0];
    assign ex_en = state == EXECUTE;
    
    
     

    
    //  THis block is responsible for changing "state" at every pos edge
    always @(posedge clk or posedge rst)
    begin
        if(rst)
            begin
            state <= FETCH;
            PC <= 15'h0000;
            SP <= 15'h7FFF;
            end
        else
            state <= next_state;
    end


    // This block is responsible for defininng the change-
    always @(*)
    begin
        case(state)
            FETCH:
                next_state = DECODE;

            // FOR Decode, if mode bit is 1, then decode_ext, otherwise execute
            DECODE:
                next_state = mode_bit == 0 ? EXECUTE : FETCH_ext;

            FETCH_ext:
                next_state = EXECUTE;
            
            EXECUTE:
                next_state = DECODE;
        endcase
    end
    



    // WHenever I have state = FETCH, i need to fetch value at [PC] and so on
    always @(posedge clk)
    begin
        case(state)
            FETCH:
                IR <= ram_rd_data;
                PC <= PC+1;
            FETCH_ext:
                IR_ext <= ram_rd_data;
                PC <= PC+1;
        endcase
    end
    

    // I need to define some more modules which definitely were not present in the original specification
    // As of now, I am sure that there is some easy way with writing less code however i will just go with what i am thinking

    // Issue 1: ram_rd_addr will be equal to PC? Or will it be equal whatever execution model wants to read???
    // SOlution 1: depending on (state) i will let ram_rd_addr to be eq ual to either PC or execution model request ( call it exec_ram_rd_addr ), and ram_wr_addr can always be driven by exec

    wire exec_ram_rd_addr[14:0];
    assign ram_rd_addr = (state == FETCH) ? PC : exec_rd_addr;




    // ISSUE 2: In architecture, RW Module is defined to be a separate module, but i believe it should exist directly inside cpu fsm
    // .... to be defined






endmodule




// Things wrong in processor architecture specification for CPU_FSM-

/*

1. No mention of ex_en --> Used to ensure that execution module can only write to ram when it is active
2. No mention of next_state
3. NO mention of exec_ram_rd_addr --> Used to ensure that ram_rd_addr = 
*/