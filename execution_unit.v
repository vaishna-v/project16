module execution_unit
(
    input clk,        
    input[4:0] opcode,
        
    input mode_bit, 
    input[2:0] rd_addr,
    input[2:0] rs_addr,
    input[15:0] rd_data,
    input[15:0] rs_data,
    input[4:0] imm, 
    input[15:0] IR_ext, 
    input[14:0] PC_in, 
    input[14:0] SP_in, 
    input[2:0] FLAGS_in, 

    output reg_wr_en,
    output[15:0] reg_wr_data,
    output flag_wr_en,
    output[1:0] flag_wr_data,
    output PC_wr_en,
    output[14:0] PC_wr_data,
    output SP_wr_en,
    output[14:0] SP_wr_data,    


    input[15:0] ram_rd_data, 
    output[14:0] ram_rd_addr,
    output ram_wr_en, 
    output[14:0] ram_wr_addr,
    output[15:0] ram_wr_data
        
);

    // --------------------------------------------------------------- Defining important wires --------------------------------------------------------------------
    
            // wires to denote which wire is enable-
    wire arith_enable;
    wire cf_enable;
    wire dm_enable;
    wire sys_enable;


            // 1. For arith module-
    wire arith_reg_enable;
    wire arith_reg_read;
    wire arith_;


endmodule