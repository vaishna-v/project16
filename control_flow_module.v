// ============================================================================
// Module: control_flow_module
// Description: Execution unit for SYNTH-16 control flow instructions.
//              Handles WARP (JMP), WARPZ (JZ), WARPNZ (JNZ), WARPC (JC),
//              WARPNC (JNC), INVOKE (CALL), and RETURN (RET).
//              Outputs that are always set to 0 have been omitted as requested.
// ============================================================================

module control_flow_module (
    input wire clk,
    input wire rst,
    input wire cf_en,
    input wire [4:0] opcode,
    input wire [15:0] IR_ext,
    input wire [1:0] FLAGS_in, // FLAGS_in[1] = Zero flag (Z), FLAGS_in[0] = Carry flag (C)
    input wire [15:0] PC_in,
    input wire [15:0] SP_in,
    input wire [15:0] ram_rd_data,

    output reg cf_ram_enable,
    output reg [14:0] cf_ram_addr,
    output reg cf_ram_read,
    output reg cf_ram_write,
    output reg [15:0] cf_ram_data,

    output reg cf_pc_write,
    output reg [15:0] cf_pc_data,
    output reg cf_sp_write,
    output reg [15:0] cf_sp_data
);

    reg phase;
    reg branch_taken;

    // ------------------------------------------------------------------------
    // Condition Evaluator (Section 6.2)
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
    // Phase control logic (2-cycle operations for CALL and RET)
    // ------------------------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            phase <= 1'b0;
        end else if (cf_en) begin
            if (opcode == 5'b10101 || opcode == 5'b10110) begin // CALL or RET
                phase <= ~phase;
            end else begin
                phase <= 1'b0;
            end
        end else begin
            phase <= 1'b0;
        end
    end

    // ------------------------------------------------------------------------
    // Output Generation logic
    // ------------------------------------------------------------------------
    always @(*) begin
        // Default output states (all inactive / 0)
        cf_ram_enable = 1'b0;
        cf_ram_addr   = 15'h0000;
        cf_ram_read   = 1'b0;
        cf_ram_write  = 1'b0;
        cf_ram_data   = 16'h0000;

        cf_pc_write   = 1'b0;
        cf_pc_data    = 16'h0000;
        cf_sp_write   = 1'b0;
        cf_sp_data    = 16'h0000;

        if (cf_en) begin
            case (opcode)
                5'b10000, 5'b10001, 5'b10010, 5'b10011, 5'b10100: begin // Jumps (unconditional & conditional)
                    if (branch_taken) begin
                        cf_pc_write = 1'b1;
                        cf_pc_data  = IR_ext;
                    end
                end

                5'b10101: begin // CALL (INVOKE) - 2 Cycles
                    if (phase == 1'b0) begin
                        // Cycle 1: Decrement SP and push return address (PC_in) onto stack
                        cf_sp_write   = 1'b1;
                        cf_sp_data    = SP_in - 16'd1;

                        cf_ram_enable = 1'b1;
                        cf_ram_write  = 1'b1;
                        cf_ram_addr   = SP_in[14:0] - 15'd1;
                        cf_ram_data   = PC_in;
                    end else begin
                        // Cycle 2: Update PC to destination address (IR_ext)
                        cf_pc_write = 1'b1;
                        cf_pc_data  = IR_ext;
                    end
                end

                5'b10110: begin // RET (RETURN) - 2 Cycles
                    if (phase == 1'b0) begin
                        // Cycle 1: Read return address from top of stack MEM[SP]
                        cf_ram_enable = 1'b1;
                        cf_ram_read   = 1'b1;
                        cf_ram_addr   = SP_in[14:0];
                    end else begin
                        // Cycle 2: Update PC to return address (ram_rd_data), increment SP
                        cf_pc_write = 1'b1;
                        cf_pc_data  = ram_rd_data;

                        cf_sp_write = 1'b1;
                        cf_sp_data  = SP_in + 16'd1;
                    end
                end
            endcase
        end
    end

endmodule
