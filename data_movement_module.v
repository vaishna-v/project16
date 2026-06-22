// ============================================================================
// Module: data_movement_module
// Description: Execution unit for SYNTH-16 data movement instructions.
//              Handles MOV (MIRROR), LOADI (ENCHANT), LOAD (SUMMON),
//              and STORE (SEAL).
//              Rewritten as a purely combinational module per updated specs.
// ============================================================================

module data_movement_module (
    input wire [4:0] opcode,
    input wire [15:0] rd_data,
    input wire [15:0] rs_data,
    input wire [15:0] IR_ext,
    input wire [15:0] ram_rd_data,

    output reg reg_wr_en,
    output reg [15:0] reg_wr_data,
    output reg flag_wr_en,
    output reg [1:0] flag_wr_data,

    output reg [14:0] ram_rd_addr,
    output reg ram_wr_en,
    output reg [14:0] ram_wr_addr,
    output reg [15:0] ram_wr_data
);

    always @(*) begin
        // Default output states (all inactive / 0)
        reg_wr_en     = 1'b0;
        reg_wr_data   = 16'h0000;
        flag_wr_en    = 1'b0;
        flag_wr_data  = 2'b00;
        ram_rd_addr   = 15'h0000;
        ram_wr_en     = 1'b0;
        ram_wr_addr   = 15'h0000;
        ram_wr_data   = 16'h0000;

        case (opcode)
            5'b01010: begin // MOV (MIRROR) - 1 Cycle
                // Write Rs value to Rd
                reg_wr_en   = 1'b1;
                reg_wr_data = rs_data;
            end

            5'b01011: begin // LOADI (ENCHANT) - 1 Cycle
                // Write 16-bit immediate IR_ext directly to Rd
                reg_wr_en   = 1'b1;
                reg_wr_data = IR_ext;

                // Update Z flag (bit 1) if immediate is 0, Carry (bit 0) is set to 0
                flag_wr_en   = 1'b1;
                flag_wr_data = {(IR_ext == 16'h0000) ? 1'b1 : 1'b0, 1'b0};
            end

            5'b01000: begin // LOAD (SUMMON) - 1 Cycle (asynchronous RAM read)
                // Read RAM at Rs address combinational value
                ram_rd_addr = rs_data[14:0];
                
                // Write RAM read result to Rd
                reg_wr_en   = 1'b1;
                reg_wr_data = ram_rd_data;
            end

            5'b01001: begin // STORE (SEAL) - 1 Cycle (writes to RAM on clock edge)
                // Store Rs data to RAM at Rd address
                ram_wr_en   = 1'b1;
                ram_wr_addr = rd_data[14:0];
                ram_wr_data = rs_data;
            end
        endcase
    end

endmodule
