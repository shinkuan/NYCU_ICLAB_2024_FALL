/**************************************************************************/
// Copyright (c) 2024, OASIS Lab
// MODULE: SA
// FILE NAME: SA.v
// VERSRION: 1.0
// DATE: Nov 06, 2024
// AUTHOR: Yen-Ning Tung, NYCU AIG
// CODE TYPE: RTL or Behavioral Level (Verilog)
// DESCRIPTION: 2024 Fall IC Lab / Exersise Lab08 / SA
// MODIFICATION HISTORY:
// Date                 Description
// 
/**************************************************************************/

// synopsys translate_off
`ifdef RTL
	`include "GATED_OR.v"
`else
	`include "Netlist/GATED_OR_SYN.v"
`endif
// synopsys translate_on


module SA(
    //Input signals
    clk,
    rst_n,
    cg_en,
    in_valid,
    T,
    in_data,
    w_Q,
    w_K,
    w_V,

    //Output signals
    out_valid,
    out_data
);

    input clk;
    input rst_n;
    input in_valid;
    input cg_en;
    input [3:0] T;
    input signed [7:0] in_data;
    input signed [7:0] w_Q;
    input signed [7:0] w_K;
    input signed [7:0] w_V;

    output reg out_valid;
    output reg signed [63:0] out_data;

    //==============================================//
    //       parameter & integer declaration        //
    //==============================================//
    localparam [3:0] STATE_IDLE = 4'd0;
    localparam [3:0] STATE_INPT = 4'd1;
    localparam [3:0] STATE_MATS = 4'd2;
    localparam [3:0] STATE_DONE = 4'd3;

    //==============================================//
    //           reg & wire declaration             //
    //==============================================//
    reg [3:0] cs, ns;
    reg [7:0] cnt, cnt_n, cnt_d1;
    
    reg        [ 3:0] in_T_reg;
    reg signed [ 7:0] in_data_reg;
    reg signed [ 7:0] in_w_Q_reg;
    reg signed [ 7:0] in_w_K_reg;
    reg signed [ 7:0] in_w_V_reg;

    reg signed [40:0] matrix_XS  [7:0][7:0];
    reg signed [ 7:0] matrix_W1  [7:0][7:0];
    reg signed [18:0] matrix_W2V [7:0][7:0];
    reg signed [18:0] matrix_Q   [7:0][7:0];
    reg signed [18:0] matrix_K   [7:0][7:0];

    reg signed [62:0] dot_product;
    reg signed [40:0] dot_product_reg;

    reg signed [40:0] dp_a0, dp_a1, dp_a2, dp_a3, dp_a4, dp_a5, dp_a6, dp_a7;
    reg signed [18:0] dp_b0, dp_b1, dp_b2, dp_b3, dp_b4, dp_b5, dp_b6, dp_b7;
    reg signed [59:0] dp0, dp1, dp2, dp3, dp4, dp5, dp6, dp7;
    reg signed [60:0] dp_s0, dp_s1, dp_s2, dp_s3;
    reg signed [61:0] dp_s4, dp_s5; 

    reg signed [39:0] scaled_relu;

    wire       [ 2:0] in_T_reg_sub1;


    localparam TRASH_SIZE = 8;
    reg        [ 1:0] tr;
    reg signed [63:0] trash0 [TRASH_SIZE-1:0];
    wire              sleep_trash0, gated_trash0_clk;
    reg signed [63:0] trash1 [TRASH_SIZE-1:0];
    wire              sleep_trash1, gated_trash1_clk;
    reg signed [63:0] trash2 [TRASH_SIZE-1:0];
    wire              sleep_trash2, gated_trash2_clk;
    reg signed [63:0] trash3 [TRASH_SIZE-1:0];
    wire              sleep_trash3, gated_trash3_clk;

    //==============================================//
    //                 GATED_OR                     //
    //==============================================//
    assign sleep_trash0 = cg_en;
    GATED_OR GATED_TRASH (
        .CLOCK(clk),   .SLEEP_CTRL(sleep_trash0),
        .RST_N(rst_n), .CLOCK_GATED(gated_trash0_clk)
    );
    assign sleep_trash1 = cg_en;
    GATED_OR GATED_TRASH1 (
        .CLOCK(clk),   .SLEEP_CTRL(sleep_trash1),
        .RST_N(rst_n), .CLOCK_GATED(gated_trash1_clk)
    );
    assign sleep_trash2 = cg_en;
    GATED_OR GATED_TRASH2 (
        .CLOCK(clk),   .SLEEP_CTRL(sleep_trash2),
        .RST_N(rst_n), .CLOCK_GATED(gated_trash2_clk)
    );
    assign sleep_trash3 = cg_en;
    GATED_OR GATED_TRASH3 (
        .CLOCK(clk),   .SLEEP_CTRL(sleep_trash3),
        .RST_N(rst_n), .CLOCK_GATED(gated_trash3_clk)
    );

    //==============================================//
    //                  design                      //
    //==============================================//
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            in_T_reg    <= 'd0;
            in_data_reg <= 'd0;
            in_w_Q_reg  <= 'd0;
            in_w_K_reg  <= 'd0;
            in_w_V_reg  <= 'd0;
        end else begin
            in_T_reg    <= cs == STATE_IDLE ? T : in_T_reg;
            in_data_reg <= in_data;
            in_w_Q_reg  <= w_Q;
            in_w_K_reg  <= w_K;
            in_w_V_reg  <= w_V;
        end
    end

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
                ns = in_valid ? STATE_INPT : STATE_IDLE;
            end
            STATE_INPT: begin
                ns = cnt == 8'o377 ? STATE_MATS : STATE_INPT;
            end
            STATE_MATS: begin
                ns = cnt == 8'o100 ? STATE_DONE : STATE_MATS;
            end
            STATE_DONE: begin
                ns = cnt == {2'b0, in_T_reg_sub1, 3'o7} ? STATE_IDLE : STATE_DONE;
            end
            default: begin
                ns = STATE_IDLE;
            end
        endcase
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            cnt <= 'd0;
        end else begin
            cnt <= cnt_n;
        end
    end

    assign in_T_reg_sub1 = in_T_reg - 1;
    always @(*) begin
        case (cs)
            STATE_IDLE: begin
                cnt_n = 'd0;
            end
            STATE_INPT: begin
                cnt_n = cnt + 1;
            end
            STATE_MATS: begin
                if (cnt[7:6]) begin
                    cnt_n = 'd0;
                end else begin
                    if (cnt[2:0] == in_T_reg_sub1) begin
                        cnt_n[2:0] = 'd0;
                        if (cnt[5:3] == in_T_reg_sub1) begin
                            cnt_n[5:3] = 'd0;
                            cnt_n[7:6] = cnt[7:6] + 1;
                        end else begin
                            cnt_n[5:3] = cnt[5:3] + 1;
                            cnt_n[7:6] = cnt[7:6];
                        end
                    end else begin
                        cnt_n = cnt + 1;
                    end
                end
            end
            STATE_DONE: begin
                cnt_n = cnt + 1;
            end
            default: begin
                cnt_n = 'd0;
            end
        endcase
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            cnt_d1 <= 'd0;
        end else begin
            cnt_d1 <= cnt;
        end
    end

    always @(*) begin
        dp0 = dp_a0 * dp_b0;
        dp1 = dp_a1 * dp_b1;
        dp2 = dp_a2 * dp_b2;
        dp3 = dp_a3 * dp_b3;
        dp4 = dp_a4 * dp_b4;
        dp5 = dp_a5 * dp_b5;
        dp6 = dp_a6 * dp_b6;
        dp7 = dp_a7 * dp_b7;

        dp_s0 = dp0 + dp1;
        dp_s1 = dp2 + dp3;
        dp_s2 = dp4 + dp5;
        dp_s3 = dp6 + dp7;

        dp_s4 = dp_s0 + dp_s1;
        dp_s5 = dp_s2 + dp_s3;

        dot_product = dp_s4 + dp_s5;
    end
    
    always @(*) begin
        case (cs)
            STATE_IDLE: begin
                dp_a0 = 'd0;
                dp_a1 = 'd0;
                dp_a2 = 'd0;
                dp_a3 = 'd0;
                dp_a4 = 'd0;
                dp_a5 = 'd0;
                dp_a6 = 'd0;
                dp_a7 = 'd0;
                dp_b0 = 'd0;
                dp_b1 = 'd0;
                dp_b2 = 'd0;
                dp_b3 = 'd0;
                dp_b4 = 'd0;
                dp_b5 = 'd0;
                dp_b6 = 'd0;
                dp_b7 = 'd0;
            end
            STATE_INPT: begin
                case (cnt[7:6])
                    'b00: begin
                        dp_a0 = 'd0;
                        dp_a1 = 'd0;
                        dp_a2 = 'd0;
                        dp_a3 = 'd0;
                        dp_a4 = 'd0;
                        dp_a5 = 'd0;
                        dp_a6 = 'd0;
                        dp_a7 = 'd0;
                        dp_b0 = 'd0;
                        dp_b1 = 'd0;
                        dp_b2 = 'd0;
                        dp_b3 = 'd0;
                        dp_b4 = 'd0;
                        dp_b5 = 'd0;
                        dp_b6 = 'd0;
                        dp_b7 = 'd0;
                    end
                    'b01: begin
                        dp_a0 = matrix_XS[cnt[5:3]][0];
                        dp_a1 = matrix_XS[cnt[5:3]][1];
                        dp_a2 = matrix_XS[cnt[5:3]][2];
                        dp_a3 = matrix_XS[cnt[5:3]][3];
                        dp_a4 = matrix_XS[cnt[5:3]][4];
                        dp_a5 = matrix_XS[cnt[5:3]][5];
                        dp_a6 = matrix_XS[cnt[5:3]][6];
                        dp_a7 = matrix_XS[cnt[5:3]][7];
                        dp_b0 = matrix_W1[0][cnt[2:0]];
                        dp_b1 = matrix_W1[1][cnt[2:0]];
                        dp_b2 = matrix_W1[2][cnt[2:0]];
                        dp_b3 = matrix_W1[3][cnt[2:0]];
                        dp_b4 = matrix_W1[4][cnt[2:0]];
                        dp_b5 = matrix_W1[5][cnt[2:0]];
                        dp_b6 = matrix_W1[6][cnt[2:0]];
                        dp_b7 = matrix_W1[7][cnt[2:0]];
                    end
                    'b10: begin
                        dp_a0 = matrix_XS[cnt[5:3]][0];
                        dp_a1 = matrix_XS[cnt[5:3]][1];
                        dp_a2 = matrix_XS[cnt[5:3]][2];
                        dp_a3 = matrix_XS[cnt[5:3]][3];
                        dp_a4 = matrix_XS[cnt[5:3]][4];
                        dp_a5 = matrix_XS[cnt[5:3]][5];
                        dp_a6 = matrix_XS[cnt[5:3]][6];
                        dp_a7 = matrix_XS[cnt[5:3]][7];
                        dp_b0 = matrix_W2V[0][cnt[2:0]];
                        dp_b1 = matrix_W2V[1][cnt[2:0]];
                        dp_b2 = matrix_W2V[2][cnt[2:0]];
                        dp_b3 = matrix_W2V[3][cnt[2:0]];
                        dp_b4 = matrix_W2V[4][cnt[2:0]];
                        dp_b5 = matrix_W2V[5][cnt[2:0]];
                        dp_b6 = matrix_W2V[6][cnt[2:0]];
                        dp_b7 = matrix_W2V[7][cnt[2:0]];
                    end
                    'b11: begin
                        dp_a0 = matrix_XS[cnt[5:3]][0];
                        dp_a1 = matrix_XS[cnt[5:3]][1];
                        dp_a2 = matrix_XS[cnt[5:3]][2];
                        dp_a3 = matrix_XS[cnt[5:3]][3];
                        dp_a4 = matrix_XS[cnt[5:3]][4];
                        dp_a5 = matrix_XS[cnt[5:3]][5];
                        dp_a6 = matrix_XS[cnt[5:3]][6];
                        dp_a7 = matrix_XS[cnt[5:3]][7];
                        dp_b0 = matrix_W1[0][cnt[2:0]];
                        dp_b1 = matrix_W1[1][cnt[2:0]];
                        dp_b2 = matrix_W1[2][cnt[2:0]];
                        dp_b3 = matrix_W1[3][cnt[2:0]];
                        dp_b4 = matrix_W1[4][cnt[2:0]];
                        dp_b5 = matrix_W1[5][cnt[2:0]];
                        dp_b6 = matrix_W1[6][cnt[2:0]];
                        dp_b7 = matrix_W1[7][cnt[2:0]];
                    end
                    default: begin
                        dp_a0 = 'd0;
                        dp_a1 = 'd0;
                        dp_a2 = 'd0;
                        dp_a3 = 'd0;
                        dp_a4 = 'd0;
                        dp_a5 = 'd0;
                        dp_a6 = 'd0;
                        dp_a7 = 'd0;
                        dp_b0 = 'd0;
                        dp_b1 = 'd0;
                        dp_b2 = 'd0;
                        dp_b3 = 'd0;
                        dp_b4 = 'd0;
                        dp_b5 = 'd0;
                        dp_b6 = 'd0;
                        dp_b7 = 'd0;
                    end
                endcase
            end
            STATE_MATS: begin
                dp_a0 = matrix_Q[cnt[5:3]][0];
                dp_a1 = matrix_Q[cnt[5:3]][1];
                dp_a2 = matrix_Q[cnt[5:3]][2];
                dp_a3 = matrix_Q[cnt[5:3]][3];
                dp_a4 = matrix_Q[cnt[5:3]][4];
                dp_a5 = matrix_Q[cnt[5:3]][5];
                dp_a6 = matrix_Q[cnt[5:3]][6];
                dp_a7 = matrix_Q[cnt[5:3]][7];
                dp_b0 = matrix_K[cnt[2:0]][0];
                dp_b1 = matrix_K[cnt[2:0]][1];
                dp_b2 = matrix_K[cnt[2:0]][2];
                dp_b3 = matrix_K[cnt[2:0]][3];
                dp_b4 = matrix_K[cnt[2:0]][4];
                dp_b5 = matrix_K[cnt[2:0]][5];
                dp_b6 = matrix_K[cnt[2:0]][6];
                dp_b7 = matrix_K[cnt[2:0]][7];
            end
            STATE_DONE: begin
                dp_a0 = matrix_XS[cnt[5:3]][0];
                dp_a1 = matrix_XS[cnt[5:3]][1];
                dp_a2 = matrix_XS[cnt[5:3]][2];
                dp_a3 = matrix_XS[cnt[5:3]][3];
                dp_a4 = matrix_XS[cnt[5:3]][4];
                dp_a5 = matrix_XS[cnt[5:3]][5];
                dp_a6 = matrix_XS[cnt[5:3]][6];
                dp_a7 = matrix_XS[cnt[5:3]][7];
                dp_b0 = matrix_W2V[0][cnt[2:0]];
                dp_b1 = matrix_W2V[1][cnt[2:0]];
                dp_b2 = matrix_W2V[2][cnt[2:0]];
                dp_b3 = matrix_W2V[3][cnt[2:0]];
                dp_b4 = matrix_W2V[4][cnt[2:0]];
                dp_b5 = matrix_W2V[5][cnt[2:0]];
                dp_b6 = matrix_W2V[6][cnt[2:0]];
                dp_b7 = matrix_W2V[7][cnt[2:0]];
            end
            default: begin
                dp_a0 = 'd0;
                dp_a1 = 'd0;
                dp_a2 = 'd0;
                dp_a3 = 'd0;
                dp_a4 = 'd0;
                dp_a5 = 'd0;
                dp_a6 = 'd0;
                dp_a7 = 'd0;
                dp_b0 = 'd0;
                dp_b1 = 'd0;
                dp_b2 = 'd0;
                dp_b3 = 'd0;
                dp_b4 = 'd0;
                dp_b5 = 'd0;
                dp_b6 = 'd0;
                dp_b7 = 'd0;
            end
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            dot_product_reg <= 'd0;
        end else begin
            dot_product_reg <= dot_product;
        end
    end

    always @(*) begin
        scaled_relu = dot_product_reg[40] ? 'd0 : dot_product_reg[39:0];
        scaled_relu = scaled_relu / 3;
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            for (int i = 0; i < 8; i = i+1) begin
                for (int j = 0; j < 8; j = j+1) begin
                    matrix_XS[i][j] <= 'd0;
                end
            end
        end else begin
            case (cs)
                STATE_IDLE: begin
                    for (int i = 0; i < 8; i = i+1) begin
                        for (int j = 0; j < 8; j = j+1) begin
                            matrix_XS[i][j] <= 'd0;
                        end
                    end
                end
                STATE_INPT: begin
                    case (cnt[7:6])
                        'b00: begin
                            matrix_XS[cnt[5:3]][cnt[2:0]] <= in_T_reg > {1'b0, cnt[5:3]} ? in_data_reg : $signed('d0);
                        end
                        default: begin
                            // do nothing
                        end
                    endcase
                end
                STATE_MATS: begin
                    matrix_XS[cnt_d1[5:3]][cnt_d1[2:0]] <= {1'b0, scaled_relu[39:0]};
                end
                default: begin
                    for (int i = 0; i < 8; i = i+1) begin
                        for (int j = 0; j < 8; j = j+1) begin
                            matrix_XS[i][j] <= matrix_XS[i][j];
                        end
                    end
                end
            endcase
        end
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            for (int i = 0; i < 8; i = i+1) begin
                for (int j = 0; j < 8; j = j+1) begin
                    matrix_W1[i][j] <= 'd0;
                end
            end
        end else begin
            case (cs)
                STATE_IDLE: begin
                    for (int i = 0; i < 8; i = i+1) begin
                        for (int j = 0; j < 8; j = j+1) begin
                            matrix_W1[i][j] <= 'd0;
                        end
                    end
                end
                STATE_INPT: begin
                    case (cnt[7:6])
                        'b00: begin
                            matrix_W1[cnt[5:3]][cnt[2:0]] <= in_w_Q_reg;
                        end
                        'b10: begin
                            matrix_W1[cnt[5:3]][cnt[2:0]] <= in_w_V_reg;
                        end
                        default: begin
                            // do nothing
                        end
                    endcase
                end
                default: begin
                    for (int i = 0; i < 8; i = i+1) begin
                        for (int j = 0; j < 8; j = j+1) begin
                            matrix_W1[i][j] <= matrix_W1[i][j];
                        end
                    end
                end
            endcase
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            for (int i = 0; i < 8; i = i+1) begin
                for (int j = 0; j < 8; j = j+1) begin
                    matrix_W2V[i][j] <= 'd0;
                end
            end
        end else begin
            case (cs)
                STATE_IDLE: begin
                    for (int i = 0; i < 8; i = i+1) begin
                        for (int j = 0; j < 8; j = j+1) begin
                            matrix_W2V[i][j] <= 'd0;
                        end
                    end
                end
                STATE_INPT: begin
                    case (cnt[7:6])
                        'b01: begin
                            matrix_W2V[cnt[5:3]][cnt[2:0]] <= in_w_K_reg;
                        end
                        'b11: begin
                            matrix_W2V[cnt[5:3]][cnt[2:0]] <= dot_product;
                        end
                        default: begin
                            // do nothing
                        end
                    endcase
                end
                default: begin
                    for (int i = 0; i < 8; i = i+1) begin
                        for (int j = 0; j < 8; j = j+1) begin
                            matrix_W2V[i][j] <= matrix_W2V[i][j];
                        end
                    end
                end
            endcase
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            for (int i = 0; i < 8; i = i+1) begin
                for (int j = 0; j < 8; j = j+1) begin
                    matrix_Q[i][j] = 'd0;
                end
            end
        end else begin
            case (cs)
                STATE_IDLE: begin
                    for (int i = 0; i < 8; i = i+1) begin
                        for (int j = 0; j < 8; j = j+1) begin
                            matrix_Q[i][j] = 'd0;
                        end
                    end
                end
                STATE_INPT: begin
                    case (cnt[7:6])
                        'b01: begin
                            matrix_Q[cnt[5:3]][cnt[2:0]] = dot_product;
                        end
                        default: begin
                            // do nothing
                        end
                    endcase
                end
                default: begin
                    for (int i = 0; i < 8; i = i+1) begin
                        for (int j = 0; j < 8; j = j+1) begin
                            matrix_Q[i][j] = matrix_Q[i][j];
                        end
                    end
                end
            endcase
        end
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            for (int i = 0; i < 8; i = i+1) begin
                for (int j = 0; j < 8; j = j+1) begin
                    matrix_K[i][j] = 'd0;
                end
            end
        end else begin
            case (cs)
                STATE_IDLE: begin
                    for (int i = 0; i < 8; i = i+1) begin
                        for (int j = 0; j < 8; j = j+1) begin
                            matrix_K[i][j] = 'd0;
                        end
                    end
                end
                STATE_INPT: begin
                    case (cnt[7:6])
                        'b10: begin
                            matrix_K[cnt[5:3]][cnt[2:0]] = dot_product;
                        end
                        default: begin
                            // do nothing
                        end
                    endcase
                end
                default: begin
                    for (int i = 0; i < 8; i = i+1) begin
                        for (int j = 0; j < 8; j = j+1) begin
                            matrix_K[i][j] = matrix_K[i][j];
                        end
                    end
                end
            endcase
        end
    end

    always @(posedge gated_trash0_clk or negedge rst_n) begin
        if (~rst_n) begin
            tr <= 1'b0;
        end else begin
            tr <= tr+1;
        end
    end

    always @(posedge gated_trash0_clk or negedge rst_n) begin
        if (~rst_n) begin
            for (int i = 0; i < TRASH_SIZE; i = i+1) begin
                trash0[i] <= 64'd0;
            end
        end else begin
            for (int i = 0; i < TRASH_SIZE; i = i+1) begin
                trash0[i] <= ~trash0[i];
            end
        end
    end

    always @(posedge gated_trash1_clk or negedge rst_n) begin
        if (~rst_n) begin
            for (int i = 0; i < TRASH_SIZE; i = i+1) begin
                trash1[i] <= 64'hFFFFFFFFFFFFFFFF;
            end
        end else begin
            for (int i = 0; i < TRASH_SIZE; i = i+1) begin
                trash1[i] <= ~trash1[i];
            end
        end
    end

    always @(posedge gated_trash2_clk or negedge rst_n) begin
        if (~rst_n) begin
            for (int i = 0; i < TRASH_SIZE; i = i+1) begin
                trash2[i] <= 64'd0;
            end
        end else begin
            for (int i = 0; i < TRASH_SIZE; i = i+1) begin
                trash2[i] <= ~trash2[i];
            end
        end
    end

    always @(posedge gated_trash3_clk or negedge rst_n) begin
        if (~rst_n) begin
            for (int i = 0; i < TRASH_SIZE; i = i+1) begin
                trash3[i] <= 64'hFFFFFFFFFFFFFFFF;
            end
        end else begin
            for (int i = 0; i < TRASH_SIZE; i = i+1) begin
                trash3[i] <= ~trash3[i];
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out_valid <= 1'b0;
        end else begin
            out_valid <= cs == STATE_DONE ? 1'b1 : 1'b0;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out_data <= 'd0;
        end else begin
            out_data <= cs == STATE_DONE ? dot_product : (in_T_reg == 4'd3 && cs != STATE_IDLE ? (tr[0] ? (tr[1] ? $signed(trash1[cnt[2:0]]) : $signed(trash3[cnt[2:0]])) : (tr[1] ? $signed(trash0[cnt[2:0]]) : $signed(trash2[cnt[2:0]]))) : $signed('d0));
        end
    end

endmodule
