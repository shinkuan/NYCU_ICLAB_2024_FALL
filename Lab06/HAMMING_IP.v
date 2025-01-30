//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    (C) Copyright System Integration and Silicon Implementation Laboratory
//    All Right Reserved
//		Date		: 2024/10
//		Version		: v1.0
//   	File Name   : HAMMING_IP.v
//   	Module Name : HAMMING_IP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
module HAMMING_IP #(parameter IP_BIT = 8) (
    // Input signals
    IN_code,
    // Output signals
    OUT_code
);

    // ===============================================================
    // Input & Output
    // ===============================================================
    input [IP_BIT+4-1:0]  IN_code;

    output reg [IP_BIT-1:0] OUT_code;

    // ===============================================================
    // Design
    // ===============================================================
    wire [1:IP_BIT+4] code;
    reg  [1:IP_BIT+4] code_fix;
    reg  [3:0] parity;

    assign code[1:IP_BIT+4] = IN_code[IP_BIT+4-1:0];

    always @(*) begin
        case (IP_BIT)
            11: begin
                parity[0] = code[1] ^ code[3] ^ code[5] ^ code[7] ^ code[9] ^ code[11] ^ code[13] ^ code[15];
                parity[1] = code[2] ^ code[3] ^ code[6] ^ code[7] ^ code[10] ^ code[11] ^ code[14] ^ code[15];
                parity[2] = code[4] ^ code[5] ^ code[6] ^ code[7] ^ code[12] ^ code[13] ^ code[14] ^ code[15];
                parity[3] = code[8] ^ code[9] ^ code[10] ^ code[11] ^ code[12] ^ code[13] ^ code[14] ^ code[15];
            end
            10: begin
                parity[0] = code[1] ^ code[3] ^ code[5] ^ code[7] ^ code[9] ^ code[11] ^ code[13];
                parity[1] = code[2] ^ code[3] ^ code[6] ^ code[7] ^ code[10] ^ code[11] ^ code[14];
                parity[2] = code[4] ^ code[5] ^ code[6] ^ code[7] ^ code[12] ^ code[13] ^ code[14];
                parity[3] = code[8] ^ code[9] ^ code[10] ^ code[11] ^ code[12] ^ code[13] ^ code[14];
            end
            9: begin
                parity[0] = code[1] ^ code[3] ^ code[5] ^ code[7] ^ code[9] ^ code[11] ^ code[13];
                parity[1] = code[2] ^ code[3] ^ code[6] ^ code[7] ^ code[10] ^ code[11];
                parity[2] = code[4] ^ code[5] ^ code[6] ^ code[7] ^ code[12] ^ code[13];
                parity[3] = code[8] ^ code[9] ^ code[10] ^ code[11] ^ code[12] ^ code[13];
            end
            8: begin
                parity[0] = code[1] ^ code[3] ^ code[5] ^ code[7] ^ code[9] ^ code[11];
                parity[1] = code[2] ^ code[3] ^ code[6] ^ code[7] ^ code[10] ^ code[11];
                parity[2] = code[4] ^ code[5] ^ code[6] ^ code[7] ^ code[12];
                parity[3] = code[8] ^ code[9] ^ code[10] ^ code[11] ^ code[12];
            end
            7: begin
                parity[0] = code[1] ^ code[3] ^ code[5] ^ code[7] ^ code[9] ^ code[11];
                parity[1] = code[2] ^ code[3] ^ code[6] ^ code[7] ^ code[10] ^ code[11];
                parity[2] = code[4] ^ code[5] ^ code[6] ^ code[7];
                parity[3] = code[8] ^ code[9] ^ code[10] ^ code[11];
            end
            6: begin
                parity[0] = code[1] ^ code[3] ^ code[5] ^ code[7] ^ code[9];
                parity[1] = code[2] ^ code[3] ^ code[6] ^ code[7] ^ code[10];
                parity[2] = code[4] ^ code[5] ^ code[6] ^ code[7];
                parity[3] = code[8] ^ code[9] ^ code[10];
            end
            5: begin
                parity[0] = code[1] ^ code[3] ^ code[5] ^ code[7] ^ code[9];
                parity[1] = code[2] ^ code[3] ^ code[6] ^ code[7];
                parity[2] = code[4] ^ code[5] ^ code[6] ^ code[7];
                parity[3] = code[8] ^ code[9];
            end
            default: /* Impossible */;
        endcase
    end
    
    always @(*) begin
        code_fix = code;
        code_fix[parity] = ~code_fix[parity];
    end

    always @(*) begin
        case (IP_BIT)
            11: begin
                OUT_code = {code_fix[3], code_fix[5], code_fix[6], code_fix[7], 
                            code_fix[9], code_fix[10], code_fix[11], code_fix[12], 
                            code_fix[13], code_fix[14], code_fix[15]};
            end
            10: begin
                OUT_code = {code_fix[3], code_fix[5], code_fix[6], code_fix[7], 
                            code_fix[9], code_fix[10], code_fix[11], code_fix[12], 
                            code_fix[13], code_fix[14]};
            end
            9: begin
                OUT_code = {code_fix[3], code_fix[5], code_fix[6], code_fix[7], 
                            code_fix[9], code_fix[10], code_fix[11], code_fix[12], 
                            code_fix[13]};
            end
            8: begin
                OUT_code = {code_fix[3], code_fix[5], code_fix[6], code_fix[7], 
                            code_fix[9], code_fix[10], code_fix[11], code_fix[12]};
            end
            7: begin
                OUT_code = {code_fix[3], code_fix[5], code_fix[6], code_fix[7], 
                            code_fix[9], code_fix[10], code_fix[11]};
            end
            6: begin
                OUT_code = {code_fix[3], code_fix[5], code_fix[6], code_fix[7], 
                            code_fix[9], code_fix[10]};
            end
            5: begin
                OUT_code = {code_fix[3], code_fix[5], code_fix[6], code_fix[7], 
                            code_fix[9]};
            end
            default: /* Impossible */;
        endcase
    end

endmodule