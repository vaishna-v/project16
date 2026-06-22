module cpu_top
(
    input clk,
    input rst,
    output halt
);



    // --------------------------------------------------------Definin some important registers and wire for cpu working -----------------------------------


    // CPU MEMORY-
    reg[14:0] PC = 15'h0000;       // Program Counter is 15 bit 
    reg[14:0] SP = 15'h7FFF;
    reg[15:0] IR;
    reg[15:0] IR_ext;
    reg[1:0] FLAGS;
    reg[15:0] regfile[7:0];
    


    // Required by Execution Module and for working of FSM
    reg[1:0] state;
    wire[4:0] opcode;
    wire[2:0] rd_addr;
    wire[2:0] rs_addr;
    wire mode_bit;
    wire [3:0] imm;
    reg[1:0] next_state;        // This was not defined in microarch spec


    




    // ---------------------------------------------------------- FSM ------------------------------------------------------------------
    // some constants enum-
    localparam FETCH = 2'd0;
    localparam DECODE = 2'd1;
    localparam FETCH_ext = 2'd2;
    localparam EXECUTE = 2'd3;



    // Assign some constant flow to wires
    assign opcode = IR[15:11];
    assign mode_bit = IR[10];
    assign rd_addr = IR[9:7];
    assign rs_addr = IR[6:4];
    assign imm = IR[3:0];
    
    
     

    
    //  THis block is responsible for changing "state" at every pos edge
    always @(posedge clk or posedge rst)
    begin
        if(rst)
            state <= FETCH;
        else if(!halt)
            state <= next_state;
    end



    // THis block writes to PC (depending on reset condition) and also updates PC to jump to next address
    wire[15:0] ram_rd_data; 
    always @(posedge clk or posedge rst)
    begin
        if(rst)
        begin
            PC <= 15'h0000;
        end

        else if(PC_wr_enable)
        begin
            PC <= PC_wr_data;
        end

        else
        begin
            case(state)

                FETCH:
                begin
                    IR <= ram_rd_data;
                    PC <= PC + 1;
                end

                FETCH_ext:
                begin
                    IR_ext <= ram_rd_data;
                    PC <= PC + 1;
                end

            endcase
        end
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
                next_state = FETCH;

            default:
                next_state = FETCH;
        endcase
    end
    















    // ------------------------------------------------------- RW MODULE -------------------------------------------------------------------------------



                    //                  1. For RAM-


    // Update 1: Ram is being instansiated by cpu instead of other way round
    // To be connected with ports of RAM-
    wire ram_wr_enable;                      // is defined here depedning on whether EU is enabled and is requesting for ram write
    wire[14:0] ram_wr_addr;              // is being driven by EU, no need to define this
    wire[15:0] ram_wr_data;               // is being driven by EU
    wire[14:0] ram_rd_addr;             // is defined here depending on state, whether PC address or EU address
    //wire[15:0] ram_rd_data;              is defined above as its required to read data in ram
    

    wire ram_wr_en;             // will be driven by EU module
    assign ram_wr_enable = (state == EXECUTE) && (ram_wr_en);

    wire[14:0] exec_ram_rd_addr; // will be driven by EU module
    assign ram_rd_addr = (state == FETCH || state == FETCH_ext) ? PC : exec_ram_rd_addr;

    ram myRam
    (
        .clk(clk), 
        .we(ram_wr_enable), 
        .rd_addr(ram_rd_addr), 
        .wr_addr(ram_wr_addr), 
        .din(ram_wr_data), 
        .dout(ram_rd_data)
    );



                //                      2. For Registers, Flags, PC, SP-

    
    // i. READ REGISTER-
    // rd_addr and rs_addr is driven by IR and is assigned above.
    wire[15:0] rs_data;
    wire[15:0] rd_data;       
    assign rs_data = regfile[rs_addr];          // constantly reading register data
    assign rd_data = regfile[rd_addr];          // constantly reading register data


    // ii. Write Register-
    wire reg_wr_en;                         // driven by EU
    wire reg_wr_enable;                     // assigned here ensure that EU is active, and register wants to wrte data   
    assign reg_wr_enable =  (state == EXECUTE) & (reg_wr_en);
                                            // wire reg_wr_addr;  is not required as it is same as rd_addr, (destination register)s
    wire[15:0] reg_wr_data;                            // driven by EU

    // iii. Reading of Flags, SP, PC is being done constantly

    //  iv. Write Flags, SP, PC-
    wire flag_wr_en, SP_wr_en, PC_wr_en;            // driven by EU
    wire flag_wr_enable, SP_wr_enable, PC_wr_enable;        // defined here

    assign flag_wr_enable = (state == EXECUTE) & (flag_wr_en);
    assign SP_wr_enable = (state == EXECUTE) & (SP_wr_en);
    assign PC_wr_enable = (state == EXECUTE) & (PC_wr_en);

    wire[1:0] flag_wr_data;
    wire[14:0] PC_wr_data;
    wire[14:0] SP_wr_data;          // driven by EU


    always @(posedge clk or posedge rst)
    begin
        if(rst)
        begin
            SP <= 15'h7FFF;
            FLAGS <= 2'b00;
        end

        else
        begin
            if(reg_wr_enable)
            begin
                regfile[rd_addr] <= reg_wr_data;
            end

            if(flag_wr_enable)
            begin
                FLAGS <= flag_wr_data;
            end

            if(SP_wr_enable)
            begin
                SP <= SP_wr_data;
            end
        end
    end




    











    // --------------------------------------------------- EU MODULE INSTANSIATION ------------------------------------------------------------    

    // I made few changes in execution module
    // instead of passing whether the request is from arithmetic register, or control flow register
    // it will just pass the "request", and will recieve response, cpu will just look at the response and ensure that execution module is enabled


    

    
    // Instatitate Execution MODULE-
    execution_unit eu(
        .opcode(opcode), 
        .mode_bit(mode_bit), 
        .rd_addr(rd_addr), 
        .rs_addr(rs_addr), 
        .rd_data(rd_data),
        .rs_data(rs_data),
        .imm(imm), 
        .IR_ext(IR_ext), 
        .PC_in(PC), 
        .SP_in(SP), 
        .FLAGS_in(FLAGS), 

        .reg_wr_en(reg_wr_en),
        .reg_wr_data(reg_wr_data),
        .flag_wr_en(flag_wr_en),
        .flag_wr_data(flag_wr_data),
        .PC_wr_en(PC_wr_en),
        .PC_wr_data(PC_wr_data),
        .SP_wr_en(SP_wr_en),
        .SP_wr_data(SP_wr_data),
    
        
        .ram_rd_data(ram_rd_data), 
        .ram_rd_addr(exec_ram_rd_addr),
        .ram_wr_en(ram_wr_en),
        .ram_wr_addr(ram_wr_addr),
        .ram_wr_data(ram_wr_data),

        .halt(halt)
    );
    




    





endmodule




// Things wrong in processor architecture specification for CPU_FSM-

/*

2. No mention of next_state
3. NO mention of exec_ram_rd_addr --> Used to ensure that ram_rd_addr = 
*/