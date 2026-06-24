module arithmetic_module
(
    input wire [4:0] opcode,

    input wire [15:0] rd_data,
    input wire [15:0] rs_data,

    input wire [3:0] imm,

    output reg reg_wr_en,
    output reg [15:0] reg_wr_data,

    output reg flag_wr_en,
    output reg [1:0] flag_wr_data
);

    always @(*) begin
        reg_wr_en= 0;
        reg_wr_data= 0;
        flag_wr_en= 0;
        flag_wr_data= 0;
        case (opcode)
            5'b00000: begin     //  ADD
                {flag_wr_data[0], reg_wr_data} = {1'b0, rd_data} + {1'b0, rs_data};
                reg_wr_en = 1;
                flag_wr_data[1] = (reg_wr_data == 0);
                flag_wr_en = 1;
            end
            5'b00001: begin     // SUB
                {flag_wr_data[0], reg_wr_data} = {1'b0, rd_data} - {1'b0, rs_data};
                reg_wr_en = 1;
                flag_wr_data[1]= (reg_wr_data == 0);
                flag_wr_en = 1;
            end
            5'b00010: begin     // INC
                {flag_wr_data[0], reg_wr_data} = {1'b0, rd_data} + 1'b1;
                reg_wr_en = 1;
                flag_wr_data[1] = (reg_wr_data == 0);
                flag_wr_en = 1;
            end
            5'b00011: begin     // DEC
                {flag_wr_data[0], reg_wr_data} = {1'b0, rd_data} - 1'b1;
                reg_wr_en = 1;
                flag_wr_data[1] = (reg_wr_data == 0);
                flag_wr_en = 1;
            end
            5'b00100: begin     // CMP
                {flag_wr_data[0], reg_wr_data} = {1'b0, rd_data} - {1'b0, rs_data};
                reg_wr_en = 0;
                flag_wr_data[1] = (reg_wr_data == 0);
                flag_wr_en = 1;
            end
            5'b00101: begin     // AND
                reg_wr_data = rd_data & rs_data;
                reg_wr_en = 1;
                flag_wr_data[0] = 0;
                flag_wr_data[1] = (reg_wr_data == 0);
                flag_wr_en = 1;
            end
            5'b00110: begin     // OR
                reg_wr_data = rd_data | rs_data;
                reg_wr_en = 1;
                flag_wr_data[0] = 0;
                flag_wr_data[1] = (reg_wr_data == 0);
                flag_wr_en = 1;
            end
            5'b00111: begin     // XOR
                reg_wr_data = rd_data ^ rs_data;
                reg_wr_en = 1;
                flag_wr_data[0] = 0;
                flag_wr_data[1] = (reg_wr_data == 0);
                flag_wr_en = 1;
            end
            5'b11000: begin     // NOT
                reg_wr_data = ~rd_data;
                reg_wr_en = 1;
                flag_wr_data[0] = 0;
                flag_wr_data[1] = (reg_wr_data == 0);
                flag_wr_en = 1;
            end
            5'b11001: begin     // SHL
                flag_wr_data[0] = (imm==0) ? 0 : rd_data[16-imm];
                reg_wr_data = rd_data << imm;
                reg_wr_en = 1;
                flag_wr_data[1] = (reg_wr_data == 0);
                flag_wr_en = 1;
            end
            5'b11010: begin     // SHR
                flag_wr_data[0] = (imm==0) ? 0 : rd_data[imm-1];
                reg_wr_data = rd_data >> imm;
                reg_wr_en = 1;
                flag_wr_data[1] = (reg_wr_data == 0);
                flag_wr_en = 1;
            end
            default: begin
            end
        endcase
    end
    
endmodule