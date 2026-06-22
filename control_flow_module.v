// ============================================================================
// Module: control_flow_module
// Description: Execution unit for SYNTH-16 control flow instructions.
//              Handles WARP (JMP), WARPZ (JZ), WARPNZ (JNZ), WARPC (JC),
//              WARPNC (JNC), INVOKE (CALL), and RETURN (RET).
//              Rewritten as a purely combinational module per updated specs.
// ============================================================================

module control_flow_module (
    input wire [4:0] opcode,
    input wire [14:0] PC_in,
    input wire [14:0] SP_in,
    input wire [1:0] FLAGS_in, // FLAGS_in[1] = Zero flag (Z), FLAGS_in[0] = Carry flag (C)
    input wire [15:0] IR_ext,
    input wire [15:0] ram_rd_data,

    output reg PC_wr_en,
    output reg [14:0] PC_wr_data,
    output reg SP_wr_en,
    output reg [14:0] SP_wr_data,

    output reg ram_wr_en,
    output reg [14:0] ram_wr_addr,
    output reg [15:0] ram_wr_data,
    output reg [14:0] ram_rd_addr
);

    reg branch_taken;

    // ------------------------------------------------------------------------
    // Condition Evaluator
    // ------------------------------------------------------------------------
    always @(*) begin
        case (opcode)
            5'b10000: branch_taken = 1'b1;                  // JMP (WARP)
            5'b10001: branch_taken = FLAGS_in[1];           // JZ (WARPZ) - Z == 1
            5'b10010: branch_taken = ~FLAGS_in[1];          // JNZ (WARPNZ) - Z == 0
            5'b10011: branch_taken = FLAGS_in[0];           // JC (WARPC) - C == 1
            5'b10100: branch_taken = ~FLAGS_in[0];          // JNC (WARPNC) - C == 0
            5'b10101: branch_taken = 1'b1;                  // CALL (INVOKE)
            5'b10110: branch_taken = 1'b1;                  // RET (RETURN)
            default:  branch_taken = 1'b0;
        endcase
    end

    // ------------------------------------------------------------------------
    // Output Generation logic (combinational single-cycle)
    // ------------------------------------------------------------------------
    always @(*) begin
        // Default output states (all inactive / 0)
        PC_wr_en     = 1'b0;
        PC_wr_data   = 15'h0000;
        SP_wr_en     = 1'b0;
        SP_wr_data   = 15'h0000;
        ram_wr_en    = 1'b0;
        ram_wr_addr  = 15'h0000;
        ram_wr_data  = 16'h0000;
        ram_rd_addr  = 15'h0000;

        case (opcode)
            5'b10000, 5'b10001, 5'b10010, 5'b10011, 5'b10100: begin // Jumps (unconditional & conditional)
                if (branch_taken) begin
                    PC_wr_en   = 1'b1;
                    PC_wr_data = IR_ext[14:0];
                end
            end

            5'b10101: begin // CALL (INVOKE) - 1 Cycle (pushes PC to stack, jumps PC to target)
                // Decrement SP and push PC_in onto stack
                SP_wr_en    = 1'b1;
                SP_wr_data  = SP_in - 15'd1;

                ram_wr_en   = 1'b1;
                ram_wr_addr = SP_in - 15'd1;
                ram_wr_data = {1'b0, PC_in}; // Pad 15-bit PC to 16-bit word

                // Jump to subroutine target address
                PC_wr_en    = 1'b1;
                PC_wr_data  = IR_ext[14:0];
            end

            5'b10110: begin // RET (RETURN) - 1 Cycle (pops PC from stack, increments SP)
                // Request read from top of the stack
                ram_rd_addr = SP_in;

                // Load popped address into PC
                PC_wr_en    = 1'b1;
                PC_wr_data  = ram_rd_data[14:0];

                // Increment SP
                SP_wr_en    = 1'b1;
                SP_wr_data  = SP_in + 15'd1;
            end
        endcase
    end

endmodule
