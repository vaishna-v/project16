module system_module(
    input wire[4:0] opcode,
    output reg halt
);
    always @(*) begin
        halt=0;
        case(opcode)
            5'b11100: begin     // NOP
                // no operation
            end
            5'b11101: begin     // HALT
                halt = 1;
            end
            default: begin
            end
        endcase
    end

endmodule