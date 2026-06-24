module execution_unit (
    input [4:0] opcode,
    input mode_bit,
    input [2:0] rd_addr,
    input [2:0] rs_addr,
    input [15:0] rd_data,
    input [15:0] rs_data,
    input [3:0] imm,
    input [15:0] IR_ext,
    input [14:0] PC_in,
    input [14:0] SP_in,
    input [1:0] FLAGS_in,


    output reg_wr_en,
    output [15:0] reg_wr_data,
    output flag_wr_en,
    output [1:0] flag_wr_data,
    output PC_wr_en,
    output [14:0] PC_wr_data,
    output SP_wr_en,
    output [14:0] SP_wr_data,

    input [15:0] ram_rd_data,
    output [14:0] ram_rd_addr,
    output ram_wr_en,
    output [14:0] ram_wr_addr,
    output [15:0] ram_wr_data,
    output halt
);


    // ---------------------------------------------------------- Module Select ----------------------------------------------------------

    wire arith_active;
    wire dm_active;
    wire cf_active;
    wire sys_active;

    assign arith_active = ((opcode[4:3] == 2'b00) || (opcode[4:2] == 3'b110));

    assign dm_active = (opcode[4:3] == 2'b01);

    assign cf_active = (opcode[4:3] == 2'b10);

    assign sys_active = (opcode[4:2] == 3'b111);


    // ---------------------------------------------------------- Arithmetic Module ----------------------------------------------------------

    wire a_reg_wr_en;
    wire [15:0] a_reg_wr_data;

    wire a_flag_wr_en;
    wire [1:0] a_flag_wr_data;
    
    arithmetic_module arithmetic_unit
    (
        .opcode(opcode),

        .rd_data(rd_data),
        .rs_data(rs_data),

        .imm(imm),

        .reg_wr_en(a_reg_wr_en),
        .reg_wr_data(a_reg_wr_data),

        .flag_wr_en(a_flag_wr_en),
        .flag_wr_data(a_flag_wr_data)
    );

    // ---------------------------------------------------------- Data Movement Module ----------------------------------------------------------

    wire d_reg_wr_en;
    wire [15:0] d_reg_wr_data;

    wire d_flag_wr_en;
    wire [1:0] d_flag_wr_data;

    wire [14:0] d_ram_rd_addr;

    wire d_ram_wr_en;
    wire [14:0] d_ram_wr_addr;
    wire [15:0] d_ram_wr_data;

    data_movement_module data_movement_unit
    (
        .opcode(opcode),

        .rd_data(rd_data),
        .rs_data(rs_data),

        .IR_ext(IR_ext),

        .ram_rd_data(ram_rd_data),

        .reg_wr_en(d_reg_wr_en),
        .reg_wr_data(d_reg_wr_data),

        .flag_wr_en(d_flag_wr_en),
        .flag_wr_data(d_flag_wr_data),

        .ram_rd_addr(d_ram_rd_addr),

        .ram_wr_en(d_ram_wr_en),
        .ram_wr_addr(d_ram_wr_addr),
        .ram_wr_data(d_ram_wr_data)
    );


    // ---------------------------------------------------------- Control Flow Module ----------------------------------------------------------

    wire c_PC_wr_en;
    wire [14:0] c_PC_wr_data;

    wire c_SP_wr_en;
    wire [14:0] c_SP_wr_data;

    wire c_ram_wr_en;
    wire [14:0] c_ram_wr_addr;
    wire [15:0] c_ram_wr_data;

    wire [14:0] c_ram_rd_addr;

    control_flow_module control_flow_unit
    (
        .opcode(opcode),

        .PC_in(PC_in),
        .SP_in(SP_in),

        .FLAGS_in(FLAGS_in),

        .IR_ext(IR_ext),

        .ram_rd_data(ram_rd_data),

        .PC_wr_en(c_PC_wr_en),
        .PC_wr_data(c_PC_wr_data),

        .SP_wr_en(c_SP_wr_en),
        .SP_wr_data(c_SP_wr_data),

        .ram_wr_en(c_ram_wr_en),
        .ram_wr_addr(c_ram_wr_addr),
        .ram_wr_data(c_ram_wr_data),

        .ram_rd_addr(c_ram_rd_addr)
    );


    // ---------------------------------------------------------- System Module ----------------------------------------------------------

    wire s_halt;
    
    system_module system_unit
    (
        .opcode(opcode),
        .halt(s_halt)
    );
    

    // ---------------------------------------------------------- Register Write ----------------------------------------------------------

    assign reg_wr_en =
        (arith_active && a_reg_wr_en) ||
        (dm_active    && d_reg_wr_en);

    assign reg_wr_data =
        arith_active ? a_reg_wr_data :
        dm_active    ? d_reg_wr_data :
        16'h0000;


    // ---------------------------------------------------------- Flag Write ----------------------------------------------------------

    assign flag_wr_en = (arith_active && a_flag_wr_en) || (dm_active    && d_flag_wr_en);

    assign flag_wr_data =
        arith_active ? a_flag_wr_data :
        dm_active    ? d_flag_wr_data :
        2'b00;


    // ---------------------------------------------------------- PC Write ----------------------------------------------------------

    assign PC_wr_en = cf_active && c_PC_wr_en;
    assign PC_wr_data = c_PC_wr_data;


    // ---------------------------------------------------------- SP Write ----------------------------------------------------------

    assign SP_wr_en = cf_active && c_SP_wr_en;
    assign SP_wr_data = c_SP_wr_data;

    // ---------------------------------------------------------- RAM Read ----------------------------------------------------------

    assign ram_rd_addr =
        dm_active ? d_ram_rd_addr :
        cf_active ? c_ram_rd_addr :
        15'h0000;


    // ---------------------------------------------------------- RAM Write ----------------------------------------------------------

    assign ram_wr_en =
        (dm_active && d_ram_wr_en) ||
        (cf_active && c_ram_wr_en);

    assign ram_wr_addr =
        dm_active ? d_ram_wr_addr :
        cf_active ? c_ram_wr_addr :
        15'h0000;

    assign ram_wr_data =
        dm_active ? d_ram_wr_data :
        cf_active ? c_ram_wr_data :
        16'h0000;


    // ---------------------------------------------------------- HALT ----------------------------------------------------------

    assign halt = sys_active && s_halt;


endmodule