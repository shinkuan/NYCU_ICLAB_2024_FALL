//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    (C) Copyright System Integration and Silicon Implementation Laboratory
//    All Right Reserved
//		Date		: 2024/9
//		Version		: v1.0
//   	File Name   : MDC.v
//   	Module Name : MDC
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

//synopsys translate_off
`include "HAMMING_IP.v"
//synopsys translate_on

module MDC(
    // Input signals
    clk,
	rst_n,
	in_valid,
    in_data, 
	in_mode,
    // Output signals
    out_valid, 
	out_data
);

    //================================================================
    // Input & Output Declaration
    //================================================================
    input clk, rst_n, in_valid;
    input [8:0] in_mode;
    input [14:0] in_data;

    output reg out_valid;
    output reg [206:0] out_data;

    //================================================================
    // Parameter & Integer Declaration
    //================================================================
    integer i, j, k, l, m, n; // @suppress

    localparam [3:0] STATE_IDLE = 4'd0;
    localparam [3:0] STATE_M2X2 = 4'd1;
    localparam [3:0] STATE_M3X3 = 4'd2;
    localparam [3:0] STATE_M4X4 = 4'd3;

    //================================================================
    // Wire & Reg Declaration
    //================================================================
    reg  [ 3:0] cs, ns;

    wire [ 4:0] mode_decoded;
    wire [10:0] data_decoded;

    reg  signed [10:0] matrix [3:0][3:0];

    reg  [ 4:0] cnt, cnt_n;

    reg  signed [10:0] mult_0_a, mult_0_b;
    reg  signed [10:0] mult_1_a, mult_1_b;
    wire signed [21:0] mult_0_y, mult_1_y;
    wire signed [21:0] determinant_2x2;

    reg  signed [10:0] mult_2_a;
    reg  signed [33:0] mult_2_b;
    wire signed [44:0] mult_2_y;

    reg                addsub_sel;
    reg  signed [44:0] addsub_a, addsub_b;
    reg  signed [44:0] addsub_y;

    reg  signed [21:0] determinant_2x2_mid_01;
    reg  signed [21:0] determinant_2x2_mid_02;
    reg  signed [21:0] determinant_2x2_mid_03;
    reg  signed [21:0] determinant_2x2_mid_12;
    reg  signed [21:0] determinant_2x2_mid_13;
    reg  signed [21:0] determinant_2x2_mid_23;

    reg  [206:0] out_data_inside;

    //================================================================
    // Design
    //================================================================
    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // Input Register & Decoding
    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    
    //----------------------------------------------------------------
    // Decoding IP
    //----------------------------------------------------------------
    HAMMING_IP #(
        .IP_BIT(5)
    ) HAMMING_IP_mode (
        .IN_code(in_mode),
        .OUT_code(mode_decoded)
    );

    HAMMING_IP #(
        .IP_BIT(11)
    ) HAMMING_IP_data (
        .IN_code(in_data),
        .OUT_code(data_decoded)
    );

    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // State Machine
    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            cs <= STATE_IDLE;
        end else begin
            cs <= ns;
        end
    end

    always @(*) begin
        case (cs)
            STATE_IDLE: begin
                if(in_valid) begin
                    case (mode_decoded)
                        5'b00100: ns = STATE_M2X2;
                        5'b00110: ns = STATE_M3X3;
                        5'b10110: ns = STATE_M4X4;
                        default:  ns = 5'b0;
                    endcase
                end else begin
                    ns = STATE_IDLE;
                end
            end
            STATE_M2X2: begin
                if (cnt[4:0] == 5'h10) begin
                    ns = STATE_IDLE;
                end else begin
                    ns = STATE_M2X2;
                end
            end
            STATE_M3X3: begin
                if (cnt[4:0] == 5'h16) begin
                    ns = STATE_IDLE;
                end else begin
                    ns = STATE_M3X3;
                end
            end
            STATE_M4X4: begin
                if (cnt[4:0] == 5'h1A) begin
                    ns = STATE_IDLE;
                end else begin
                    ns = STATE_M4X4;
                end
            end
            default: begin
                ns = STATE_IDLE;
            end
        endcase
    end

    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // Counter
    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    //----------------------------------------------------------------
    // 5-bit Counter
    //----------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            cnt <= 5'b0;
        end else begin
            cnt <= cnt_n;
        end
    end

    always @(*) begin
        if (cs == STATE_IDLE && !in_valid) begin
            cnt_n = 5'b0;
        end else begin
            cnt_n = cnt + 5'b1;
        end
    end

    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // Matrix
    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    //----------------------------------------------------------------
    // Matrix
    //----------------------------------------------------------------
    always @(posedge clk) begin
        if (~cnt[4]) case (cnt[3:0])
            4'd0: matrix[0][0] <= data_decoded;
            4'd1: matrix[0][1] <= data_decoded;
            4'd2: matrix[0][2] <= data_decoded;
            4'd3: matrix[0][3] <= data_decoded;
            4'd4: matrix[1][0] <= data_decoded;
            4'd5: matrix[1][1] <= data_decoded;
            4'd6: matrix[1][2] <= data_decoded;
            4'd7: matrix[1][3] <= data_decoded;
            4'd8: matrix[2][0] <= data_decoded;
            4'd9: matrix[2][1] <= data_decoded;
            4'd10: matrix[2][2] <= data_decoded;
            4'd11: matrix[2][3] <= data_decoded;
            4'd12: matrix[3][0] <= data_decoded;
            4'd13: matrix[3][1] <= data_decoded;
            4'd14: matrix[3][2] <= data_decoded;
            4'd15: matrix[3][3] <= data_decoded;
            default: /*Impossible*/;
        endcase
    end

    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // Determinant 2x2
    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    assign mult_0_y = mult_0_a * mult_0_b;
    assign mult_1_y = mult_1_a * mult_1_b;
    assign determinant_2x2 = mult_0_y - mult_1_y;

    always @(*) begin
        case (cs)
            STATE_M2X2: begin
                case (cnt[4:0])
                    5'h06: begin
                        mult_0_a = matrix[0][0];
                        mult_0_b = matrix[1][1];
                        mult_1_a = matrix[0][1];
                        mult_1_b = matrix[1][0];
                    end
                    5'h07: begin
                        mult_0_a = matrix[0][1];
                        mult_0_b = matrix[1][2];
                        mult_1_a = matrix[0][2];
                        mult_1_b = matrix[1][1];
                    end
                    5'h08: begin
                        mult_0_a = matrix[0][2];
                        mult_0_b = matrix[1][3];
                        mult_1_a = matrix[0][3];
                        mult_1_b = matrix[1][2];
                    end
                    5'h0A: begin
                        mult_0_a = matrix[1][0];
                        mult_0_b = matrix[2][1];
                        mult_1_a = matrix[1][1];
                        mult_1_b = matrix[2][0];
                    end
                    5'h0B: begin
                        mult_0_a = matrix[1][1];
                        mult_0_b = matrix[2][2];
                        mult_1_a = matrix[1][2];
                        mult_1_b = matrix[2][1];
                    end
                    5'h0C: begin
                        mult_0_a = matrix[1][2];
                        mult_0_b = matrix[2][3];
                        mult_1_a = matrix[1][3];
                        mult_1_b = matrix[2][2];
                    end
                    5'h0E: begin
                        mult_0_a = matrix[2][0];
                        mult_0_b = matrix[3][1];
                        mult_1_a = matrix[2][1];
                        mult_1_b = matrix[3][0];
                    end
                    5'h0F: begin
                        mult_0_a = matrix[2][1];
                        mult_0_b = matrix[3][2];
                        mult_1_a = matrix[2][2];
                        mult_1_b = matrix[3][1];
                    end
                    5'h10: begin
                        mult_0_a = matrix[2][2];
                        mult_0_b = matrix[3][3];
                        mult_1_a = matrix[2][3];
                        mult_1_b = matrix[3][2];
                    end
                    default: begin
                        mult_0_a = 11'b0;
                        mult_0_b = 11'b0;
                        mult_1_a = 11'b0;
                        mult_1_b = 11'b0;
                    end
                endcase
            end
            STATE_M3X3,
            STATE_M4X4: begin
                case (cnt[4:0])
                    5'h0A: begin
                        mult_0_a = matrix[1][0];
                        mult_0_b = matrix[2][1];
                        mult_1_a = matrix[1][1];
                        mult_1_b = matrix[2][0];
                    end
                    5'h0B: begin
                        mult_0_a = matrix[1][0];
                        mult_0_b = matrix[2][2];
                        mult_1_a = matrix[1][2];
                        mult_1_b = matrix[2][0];
                    end
                    5'h0C: begin
                        mult_0_a = matrix[1][1];
                        mult_0_b = matrix[2][2];
                        mult_1_a = matrix[1][2];
                        mult_1_b = matrix[2][1];
                    end
                    5'h0D: begin
                        mult_0_a = matrix[1][1];
                        mult_0_b = matrix[2][3];
                        mult_1_a = matrix[1][3];
                        mult_1_b = matrix[2][1];
                    end
                    5'h0E: begin
                        mult_0_a = matrix[1][2];
                        mult_0_b = matrix[2][3];
                        mult_1_a = matrix[1][3];
                        mult_1_b = matrix[2][2];
                    end
                    5'h0F: begin
                        mult_0_a = matrix[1][0];
                        mult_0_b = matrix[2][3];
                        mult_1_a = matrix[1][3];
                        mult_1_b = matrix[2][0];
                    end
                    default: begin
                        mult_0_a = 11'b0;
                        mult_0_b = 11'b0;
                        mult_1_a = 11'b0;
                        mult_1_b = 11'b0;
                    end
                endcase
            end
            default: begin
                mult_0_a = 11'b0;
                mult_0_b = 11'b0;
                mult_1_a = 11'b0;
                mult_1_b = 11'b0;
            end
        endcase
    end

    always @(posedge clk) begin
        case (cs)
            STATE_M3X3,
            STATE_M4X4: begin
                case (cnt[4:0])
                    5'h0A: determinant_2x2_mid_01 <= determinant_2x2;
                    5'h0B: determinant_2x2_mid_02 <= determinant_2x2;
                    5'h0C: determinant_2x2_mid_12 <= determinant_2x2;
                    5'h0D: determinant_2x2_mid_13 <= determinant_2x2;
                    5'h0E: determinant_2x2_mid_23 <= determinant_2x2;
                    5'h0F: determinant_2x2_mid_03 <= determinant_2x2;
                    default: /*Ignore*/;
                endcase
            end
            default: begin
                determinant_2x2_mid_01 <= 22'b0;
                determinant_2x2_mid_02 <= 22'b0;
                determinant_2x2_mid_03 <= 22'b0;
                determinant_2x2_mid_12 <= 22'b0;
                determinant_2x2_mid_13 <= 22'b0;
                determinant_2x2_mid_23 <= 22'b0;
            end
        endcase
    end

    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // Determinant 3x3, 4x4
    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    assign mult_2_y = mult_2_a * mult_2_b;

    always @(*) begin
        // This inferences DW01_addsub
        if (addsub_sel == 0) addsub_y = addsub_a + addsub_b;
        else                 addsub_y = addsub_a - addsub_b;
    end
    
    always @(*) begin
        case (cs)
            STATE_M3X3: begin
                case (cnt[4:0])
                    //====================================
                    // Det(M00_22)
                    5'h0B: begin
                        addsub_sel = 0;
                        mult_2_a = matrix[0][2];
                        mult_2_b = determinant_2x2_mid_01;
                    end
                    5'h0C: begin
                        addsub_sel = 1;
                        mult_2_a = matrix[0][1];
                        mult_2_b = determinant_2x2_mid_02;
                    end
                    5'h0D: begin
                        addsub_sel = 0;
                        mult_2_a = matrix[0][0];
                        mult_2_b = determinant_2x2_mid_12;
                    end
                    //====================================
                    // Det(M01_23)
                    5'h0E: begin
                        addsub_sel = 0;
                        mult_2_a = matrix[0][3];
                        mult_2_b = determinant_2x2_mid_12;
                    end
                    5'h0F: begin
                        addsub_sel = 1;
                        mult_2_a = matrix[0][2];
                        mult_2_b = determinant_2x2_mid_13;
                    end
                    5'h10: begin
                        addsub_sel = 0;
                        mult_2_a = matrix[0][1];
                        mult_2_b = determinant_2x2_mid_23;
                    end
                    //====================================
                    // Det(M10_32)
                    5'h11: begin
                        addsub_sel = 0;
                        mult_2_a = matrix[3][2];
                        mult_2_b = determinant_2x2_mid_01;
                    end
                    5'h12: begin
                        addsub_sel = 1;
                        mult_2_a = matrix[3][1];
                        mult_2_b = determinant_2x2_mid_02;
                    end
                    5'h13: begin
                        addsub_sel = 0;
                        mult_2_a = matrix[3][0];
                        mult_2_b = determinant_2x2_mid_12;
                    end
                    //====================================
                    // Det(M11_33)
                    5'h14: begin
                        addsub_sel = 0;
                        mult_2_a = matrix[3][3];
                        mult_2_b = determinant_2x2_mid_12;
                    end
                    5'h15: begin
                        addsub_sel = 1;
                        mult_2_a = matrix[3][2];
                        mult_2_b = determinant_2x2_mid_13;
                    end
                    5'h16: begin
                        addsub_sel = 0;
                        mult_2_a = matrix[3][1];
                        mult_2_b = determinant_2x2_mid_23;
                    end
                    //====================================
                    default: begin
                        addsub_sel = 1'b0;
                        mult_2_a = 11'b0;
                        mult_2_b = 34'b0;
                    end
                endcase
            end
            STATE_M4X4: begin
                case (cnt[4:0])
                    //====================================
                    // Det(M012)
                    5'h0B: begin
                        addsub_sel = 0;
                        mult_2_a = matrix[0][2];
                        mult_2_b = determinant_2x2_mid_01;
                    end
                    5'h0C: begin
                        addsub_sel = 1;
                        mult_2_a = matrix[0][1];
                        mult_2_b = determinant_2x2_mid_02;
                    end
                    5'h0D: begin
                        addsub_sel = 0;
                        mult_2_a = matrix[0][0];
                        mult_2_b = determinant_2x2_mid_12;
                    end
                    //====================================
                    // Det(M123)
                    5'h0E: begin
                        addsub_sel = 0;
                        mult_2_a = matrix[0][3];
                        mult_2_b = determinant_2x2_mid_12;
                    end
                    5'h0F: begin
                        addsub_sel = 1;
                        mult_2_a = matrix[0][2];
                        mult_2_b = determinant_2x2_mid_13;
                    end
                    5'h10: begin
                        addsub_sel = 0;
                        mult_2_a = matrix[0][1];
                        mult_2_b = determinant_2x2_mid_23;
                    end
                    //====================================
                    // Det(M023)
                    5'h11: begin
                        addsub_sel = 0;
                        mult_2_a = matrix[0][3];
                        mult_2_b = determinant_2x2_mid_02;
                    end
                    5'h12: begin
                        addsub_sel = 1;
                        mult_2_a = matrix[0][2];
                        mult_2_b = determinant_2x2_mid_03;
                    end
                    5'h13: begin
                        addsub_sel = 0;
                        mult_2_a = matrix[0][0];
                        mult_2_b = determinant_2x2_mid_23;
                    end
                    //====================================
                    // Det(M013)
                    5'h14: begin
                        addsub_sel = 0;
                        mult_2_a = matrix[0][3];
                        mult_2_b = determinant_2x2_mid_01;
                    end
                    5'h15: begin
                        addsub_sel = 1;
                        mult_2_a = matrix[0][1];
                        mult_2_b = determinant_2x2_mid_03;
                    end
                    5'h16: begin
                        addsub_sel = 0;
                        mult_2_a = matrix[0][0];
                        mult_2_b = determinant_2x2_mid_13;
                    end
                    //====================================
                    // Det(M013) * M[3][2]
                    5'h17: begin
                        addsub_sel = 1;
                        mult_2_a = matrix[3][2];
                        mult_2_b = out_data_inside[ 33:  0];
                    end
                    //====================================
                    // Det(M023) * M[3][1]
                    5'h18: begin
                        addsub_sel = 0;
                        mult_2_a = matrix[3][1];
                        mult_2_b = out_data_inside[ 84: 51];
                    end
                    //====================================
                    // Det(M123) * M[3][0]
                    5'h19: begin
                        addsub_sel = 1;
                        mult_2_a = matrix[3][0];
                        mult_2_b = out_data_inside[135:102];
                    end
                    //====================================
                    // Det(M012) * M[3][3]
                    5'h1A: begin
                        addsub_sel = 0;
                        mult_2_a = matrix[3][3];
                        mult_2_b = out_data_inside[186:153];
                    end
                    //====================================
                    default: begin
                        addsub_sel = 1'b0;
                        mult_2_a = 11'b0;
                        mult_2_b = 34'b0;
                    end
                endcase
            end
            default: begin
                addsub_sel = 1'b0;
                mult_2_a = 11'b0;
                mult_2_b = 34'b0;
            end
        endcase
    end

    always @(*) begin
        case (cs)
            STATE_M3X3: begin
                case (cnt[4:0])
                    //====================================
                    // Det(M00_22)
                    5'h0B,
                    5'h0C,
                    5'h0D: begin
                        addsub_a = $signed(out_data_inside[186:153]);
                        addsub_b = mult_2_y;
                    end
                    //====================================
                    // Det(M01_23)
                    5'h0E,
                    5'h0F,
                    5'h10: begin
                        addsub_a = $signed(out_data_inside[135:102]);
                        addsub_b = mult_2_y;
                    end
                    //====================================
                    // Det(M10_32)
                    5'h11,
                    5'h12,
                    5'h13: begin
                        addsub_a = $signed(out_data_inside[ 84: 51]);
                        addsub_b = mult_2_y;
                    end
                    //====================================
                    // Det(M11_33)
                    5'h14,
                    5'h15,
                    5'h16: begin
                        addsub_a = $signed(out_data_inside[ 33:  0]);
                        addsub_b = mult_2_y;
                    end
                    //====================================
                    default: begin
                        addsub_a = 45'b0;
                        addsub_b = 45'b0;
                    end
                endcase
            end
            STATE_M4X4: begin
                case (cnt[4:0])
                    //====================================
                    // Det(M012)
                    5'h0B,
                    5'h0C,
                    5'h0D: begin
                        addsub_a = $signed(out_data_inside[186:153]);
                        addsub_b = mult_2_y;
                    end
                    //====================================
                    // Det(M123)
                    5'h0E,
                    5'h0F,
                    5'h10: begin
                        addsub_a = $signed(out_data_inside[135:102]);
                        addsub_b = mult_2_y;
                    end
                    //====================================
                    // Det(M023)
                    5'h11,
                    5'h12,
                    5'h13: begin
                        addsub_a = $signed(out_data_inside[ 84: 51]);
                        addsub_b = mult_2_y;
                    end
                    //====================================
                    // Det(M013)
                    5'h14,
                    5'h15,
                    5'h16: begin
                        addsub_a = $signed(out_data_inside[ 33:  0]);
                        addsub_b = mult_2_y;
                    end
                    //====================================
                    // Det(M013) * M[3][2]
                    5'h17: begin
                        addsub_a = 45'd0;
                        addsub_b = mult_2_y;
                    end
                    //====================================
                    // Det(M023) * M[3][1]
                    5'h18: begin
                        addsub_a = $signed(out_data_inside[ 44: 0]);
                        addsub_b = mult_2_y;
                    end
                    //====================================
                    // Det(M123) * M[3][0]
                    5'h19: begin
                        addsub_a = $signed(out_data_inside[ 44: 0]);
                        addsub_b = mult_2_y;
                    end
                    //====================================
                    // Det(M012) * M[3][3]
                    5'h1A: begin
                        addsub_a = $signed(out_data_inside[ 44: 0]);
                        addsub_b = mult_2_y;
                    end
                    //====================================
                    default: begin
                        addsub_a = 45'b0;
                        addsub_b = 45'b0;
                    end
                endcase
            end
            default: begin
                addsub_a = 45'b0;
                addsub_b = 45'b0;
            end
        endcase
    end
    

    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // Output Register
    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out_valid <= 1'b0;
        end else begin
            case (cs)
                STATE_M2X2: out_valid <= (cnt[4:0] == 5'h10);
                STATE_M3X3: out_valid <= (cnt[4:0] == 5'h16);
                STATE_M4X4: out_valid <= (cnt[4:0] == 5'h1A);
                default:    out_valid <= 1'b0;
            endcase
        end
    end

    always @(*) begin
        // if (out_valid)  out_data = out_data_inside;
        // else            out_data = 207'b0;
        out_data = out_data_inside;
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out_data_inside <= 207'b0;
        end else begin
            case (cs)
                STATE_IDLE: out_data_inside <= 207'b0;
                STATE_M2X2: begin
                    case (cnt[4:0])
                        5'h06: out_data_inside[206:184] <= determinant_2x2;
                        5'h07: out_data_inside[183:161] <= determinant_2x2;
                        5'h08: out_data_inside[160:138] <= determinant_2x2;
                        5'h0A: out_data_inside[137:115] <= determinant_2x2;
                        5'h0B: out_data_inside[114: 92] <= determinant_2x2;
                        5'h0C: out_data_inside[ 91: 69] <= determinant_2x2;
                        5'h0E: out_data_inside[ 68: 46] <= determinant_2x2;
                        5'h0F: out_data_inside[ 45: 23] <= determinant_2x2;
                        5'h10: out_data_inside[ 22:  0] <= determinant_2x2;
                        default: /*Ignore*/;
                    endcase
                end
                STATE_M3X3: begin
                    case (cnt[4:0])
                        5'h0B,
                        5'h0C,
                        5'h0D: out_data_inside[203:153] <= addsub_y;
                        5'h0E,
                        5'h0F,
                        5'h10: out_data_inside[152:102] <= addsub_y;
                        5'h11,
                        5'h12,
                        5'h13: out_data_inside[101: 51] <= addsub_y;
                        5'h14,
                        5'h15,
                        5'h16: out_data_inside[ 50:  0] <= addsub_y;
                        default: /*Ignore*/;
                    endcase
                end
                STATE_M4X4: begin
                    case (cnt[4:0])
                        5'h0B,
                        5'h0C,
                        5'h0D: out_data_inside[203:153] <= addsub_y;
                        5'h0E,
                        5'h0F,
                        5'h10: out_data_inside[152:102] <= addsub_y;
                        5'h11,
                        5'h12,
                        5'h13: out_data_inside[101: 51] <= addsub_y;
                        5'h14,
                        5'h15,
                        5'h16: out_data_inside[ 50:  0] <= addsub_y;
                        5'h17,
                        5'h18,
                        5'h19: out_data_inside[ 50:  0] <= addsub_y;
                        5'h1A: out_data_inside[206:  0] <= addsub_y;
                        default: /*Ignore*/;
                    endcase
                end
                default: out_data_inside <= 207'b0;
            endcase
        end
    end

endmodule
