// ============================================================================
// Module: data_movement_module
// Description: Execution unit for SYNTH-16 data movement instructions.
//              Handles MOV (MIRROR), LOADI (ENCHANT), LOAD (SUMMON),
//              and STORE (SEAL).
// ============================================================================

module data_movement_module (
    input wire clk,
    input wire rst,
    input wire dmov_en,
    input wire [4:0] opcode,
    input wire [2:0] rd_addr,
    input wire [2:0] rs_addr,
    input wire [15:0] IR_ext,
    input wire [15:0] reg_rd_data,
    input wire [15:0] ram_rd_data,

    output reg dmov_reg_enable,
    output reg [2:0] dmov_reg_addr,
    output reg dmov_reg_read,
    output reg dmov_reg_write,
    output reg [15:0] dmov_reg_data,

    output reg dmov_flag_enable,
    output reg dmov_flag_write,
    output reg [1:0] dmov_flag_data,

    output reg dmov_ram_enable,
    output reg [14:0] dmov_ram_addr,
    output reg dmov_ram_read,
    output reg dmov_ram_write,
    output reg [15:0] dmov_ram_data
);

    // op_sel derived from opcode:
    // 00 = LOAD  (SUMMON: 01000)
    // 01 = STORE (SEAL:   01001)
    // 10 = MOV   (MIRROR: 01010)
    // 11 = LOADI (ENCHANT: 01011)
    wire [1:0] op_sel = opcode[1:0];

    reg phase;
    reg [15:0] addr_latch;

    // ------------------------------------------------------------------------
    // Phase control logic (2-cycle operations for LOAD and STORE)
    // ------------------------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            phase <= 1'b0;
        end else if (dmov_en) begin
            if (op_sel == 2'b00 || op_sel == 2'b01) begin // LOAD or STORE
                phase <= ~phase;
            end else begin
                phase <= 1'b0;
            end
        end else begin
            phase <= 1'b0;
        end
    end

    // ------------------------------------------------------------------------
    // Address latching (stores Rd value during phase 0 for STORE, or Rs value for LOAD)
    // ------------------------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            addr_latch <= 16'h0000;
        end else if (dmov_en && phase == 1'b0) begin
            if (op_sel == 2'b00 || op_sel == 2'b01) begin
                addr_latch <= reg_rd_data;
            end
        end
    end

    // ------------------------------------------------------------------------
    // Output Generation logic
    // ------------------------------------------------------------------------
    always @(*) begin
        // Default output states (all inactive / 0)
        dmov_reg_enable  = 1'b0;
        dmov_reg_addr    = 3'b000;
        dmov_reg_read    = 1'b0;
        dmov_reg_write   = 1'b0;
        dmov_reg_data    = 16'h0000;

        dmov_flag_enable = 1'b0;
        dmov_flag_write  = 1'b0;
        dmov_flag_data   = 2'b00;

        dmov_ram_enable  = 1'b0;
        dmov_ram_addr    = 15'h0000;
        dmov_ram_read    = 1'b0;
        dmov_ram_write   = 1'b0;
        dmov_ram_data    = 16'h0000;

        if (dmov_en) begin
            case (op_sel)
                2'b10: begin // MOV (MIRROR) - 1 Cycle
                    // Reads Rs, writes to Rd (write_addr is hardwired to rd_addr in cpu_top)
                    dmov_reg_enable = 1'b1;
                    dmov_reg_addr   = rs_addr;
                    dmov_reg_read   = 1'b1;
                    dmov_reg_write  = 1'b1;
                    dmov_reg_data   = reg_rd_data;
                end

                2'b11: begin // LOADI (ENCHANT) - 1 Cycle
                    // Writes IR_ext directly to Rd
                    dmov_reg_enable  = 1'b1;
                    dmov_reg_write   = 1'b1;
                    dmov_reg_data    = IR_ext;

                    // Updates Z flag if immediate is 0, Carry is set to 0
                    dmov_flag_enable = 1'b1;
                    dmov_flag_write  = 1'b1;
                    dmov_flag_data   = {(IR_ext == 16'h0000) ? 1'b1 : 1'b0, 1'b0};
                end

                2'b00: begin // LOAD (SUMMON) - 2 Cycles
                    if (phase == 1'b0) begin
                        // Cycle 1: Read Rs combinational value (address) and request RAM read
                        dmov_reg_enable = 1'b1;
                        dmov_reg_addr   = rs_addr;
                        dmov_reg_read   = 1'b1;

                        dmov_ram_enable = 1'b1;
                        dmov_ram_read   = 1'b1;
                        dmov_ram_addr   = reg_rd_data[14:0];
                    end else begin
                        // Cycle 2: Write RAM read result to Rd
                        dmov_reg_enable = 1'b1;
                        dmov_reg_write  = 1'b1;
                        dmov_reg_data   = ram_rd_data;
                    end
                end

                2'b01: begin // STORE (SEAL) - 2 Cycles
                    if (phase == 1'b0) begin
                        // Cycle 1: Read Rd to get the RAM write address, latched on clock edge
                        dmov_reg_enable = 1'b1;
                        dmov_reg_addr   = rd_addr;
                        dmov_reg_read   = 1'b1;
                    end else begin
                        // Cycle 2: Read Rs (source data) and write Rs value to RAM[addr_latch]
                        dmov_reg_enable = 1'b1;
                        dmov_reg_addr   = rs_addr;
                        dmov_reg_read   = 1'b1;

                        dmov_ram_enable = 1'b1;
                        dmov_ram_write  = 1'b1;
                        dmov_ram_addr   = addr_latch[14:0];
                        dmov_ram_data   = reg_rd_data;
                    end
                end
            endcase
        end
    end

endmodule
