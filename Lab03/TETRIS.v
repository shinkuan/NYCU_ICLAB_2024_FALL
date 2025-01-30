/**************************************************************************/
// Copyright (c) 2024, OASIS Lab
// MODULE: TETRIS
// FILE NAME: TETRIS.v
// VERSRION: 1.0
// DATE: August 15, 2024
// AUTHOR: Yu-Hsuan Hsu, NYCU IEE
// DESCRIPTION: ICLAB2024FALL / LAB3 / TETRIS
// MODIFICATION HISTORY:
// Date                 Description
// 
/**************************************************************************/
module TETRIS (
    //INPUT
    rst_n,
    clk,
    in_valid,
    tetrominoes,
    position,
    //OUTPUT
    tetris_valid,
    score_valid,
    fail,
    score,
    tetris
);

//=====================================================================
//  PORT DECLARATION          
//=====================================================================
input                rst_n, clk, in_valid;
input        [2:0]   tetrominoes;
input        [2:0]   position;
output reg           tetris_valid, score_valid, fail;
output reg   [3:0]   score;
output reg   [71:0]  tetris;


//=====================================================================
//  PARAMETER & INTEGER DECLARATION
//=====================================================================
//---------------------------------------------------------------------
//  FOR LOOP
//---------------------------------------------------------------------
integer i, j, k, l, m, n;
//---------------------------------------------------------------------
//  SHAPE
//---------------------------------------------------------------------
/*
██
*/localparam SHAPE_O      = 3'b000;
/*
█
█
*/localparam SHAPE_I      = 3'b001;
/*
▄▄▄▄
*/localparam SHAPE_I_R1   = 3'b010;
/*
▄▄
 █
*/localparam SHAPE_L_R2   = 3'b011;
/*
█▀▀
*/localparam SHAPE_L_R3   = 3'b100;
/*
█
▀▀
*/localparam SHAPE_L      = 3'b101;
/*
▄
▀█
*/localparam SHAPE_S_R1   = 3'b110;
/*
▄█▀
*/localparam SHAPE_S      = 3'b111;

//=====================================================================
//  REG & WIRE DECLARATION
//=====================================================================
reg [5:0] tetris_2d [11:0];
reg [5:0] tetris_2d_r0 [11:0];
reg [5:0] tetris_2d_r1 [11:0];
reg [5:0] tetris_2d_r2 [11:0];
reg [5:0] tetris_2d_r3 [11:0];
reg [3:0] tetrominoes_shape [3:0];
reg can_place [11:0] [5:0];
reg [3:0] place_y_at [5:0];
reg [5:0] tetromino_2d_placed [3:0];
reg row_full [3:0];
reg [3:0] tetromino_cnt;
reg [3:0] _score;

wire [3:0] place_y_r0, place_y_r1, place_y_r2, place_y_r3;
wire can_fail_r0, can_fail_r1, can_fail_r2, can_fail_r3;
wire _fail;
wire [2:0] add_score;

//=====================================================================
//  DESIGN
//=====================================================================
always @(*) begin
    case (tetrominoes)
        SHAPE_O: begin
            tetrominoes_shape[3][0] = 1'b0; tetrominoes_shape[3][1] = 1'b0; tetrominoes_shape[3][2] = 1'b0; tetrominoes_shape[3][3] = 1'b0;
            tetrominoes_shape[2][0] = 1'b0; tetrominoes_shape[2][1] = 1'b0; tetrominoes_shape[2][2] = 1'b0; tetrominoes_shape[2][3] = 1'b0;
            tetrominoes_shape[1][0] = 1'b1; tetrominoes_shape[1][1] = 1'b1; tetrominoes_shape[1][2] = 1'b0; tetrominoes_shape[1][3] = 1'b0;
            tetrominoes_shape[0][0] = 1'b1; tetrominoes_shape[0][1] = 1'b1; tetrominoes_shape[0][2] = 1'b0; tetrominoes_shape[0][3] = 1'b0;
        end
        SHAPE_I: begin
            tetrominoes_shape[3][0] = 1'b1; tetrominoes_shape[3][1] = 1'b0; tetrominoes_shape[3][2] = 1'b0; tetrominoes_shape[3][3] = 1'b0;
            tetrominoes_shape[2][0] = 1'b1; tetrominoes_shape[2][1] = 1'b0; tetrominoes_shape[2][2] = 1'b0; tetrominoes_shape[2][3] = 1'b0;
            tetrominoes_shape[1][0] = 1'b1; tetrominoes_shape[1][1] = 1'b0; tetrominoes_shape[1][2] = 1'b0; tetrominoes_shape[1][3] = 1'b0;
            tetrominoes_shape[0][0] = 1'b1; tetrominoes_shape[0][1] = 1'b0; tetrominoes_shape[0][2] = 1'b0; tetrominoes_shape[0][3] = 1'b0;
        end
        SHAPE_I_R1: begin
            tetrominoes_shape[3][0] = 1'b0; tetrominoes_shape[3][1] = 1'b0; tetrominoes_shape[3][2] = 1'b0; tetrominoes_shape[3][3] = 1'b0;
            tetrominoes_shape[2][0] = 1'b0; tetrominoes_shape[2][1] = 1'b0; tetrominoes_shape[2][2] = 1'b0; tetrominoes_shape[2][3] = 1'b0;
            tetrominoes_shape[1][0] = 1'b0; tetrominoes_shape[1][1] = 1'b0; tetrominoes_shape[1][2] = 1'b0; tetrominoes_shape[1][3] = 1'b0;
            tetrominoes_shape[0][0] = 1'b1; tetrominoes_shape[0][1] = 1'b1; tetrominoes_shape[0][2] = 1'b1; tetrominoes_shape[0][3] = 1'b1;
        end
        SHAPE_L_R2: begin
            tetrominoes_shape[3][0] = 1'b0; tetrominoes_shape[3][1] = 1'b0; tetrominoes_shape[3][2] = 1'b0; tetrominoes_shape[3][3] = 1'b0;
            tetrominoes_shape[2][0] = 1'b1; tetrominoes_shape[2][1] = 1'b1; tetrominoes_shape[2][2] = 1'b0; tetrominoes_shape[2][3] = 1'b0;
            tetrominoes_shape[1][0] = 1'b0; tetrominoes_shape[1][1] = 1'b1; tetrominoes_shape[1][2] = 1'b0; tetrominoes_shape[1][3] = 1'b0;
            tetrominoes_shape[0][0] = 1'b0; tetrominoes_shape[0][1] = 1'b1; tetrominoes_shape[0][2] = 1'b0; tetrominoes_shape[0][3] = 1'b0;
        end
        SHAPE_L_R3: begin
            tetrominoes_shape[3][0] = 1'b0; tetrominoes_shape[3][1] = 1'b0; tetrominoes_shape[3][2] = 1'b0; tetrominoes_shape[3][3] = 1'b0;
            tetrominoes_shape[2][0] = 1'b0; tetrominoes_shape[2][1] = 1'b0; tetrominoes_shape[2][2] = 1'b0; tetrominoes_shape[2][3] = 1'b0;
            tetrominoes_shape[1][0] = 1'b1; tetrominoes_shape[1][1] = 1'b1; tetrominoes_shape[1][2] = 1'b1; tetrominoes_shape[1][3] = 1'b0;
            tetrominoes_shape[0][0] = 1'b1; tetrominoes_shape[0][1] = 1'b0; tetrominoes_shape[0][2] = 1'b0; tetrominoes_shape[0][3] = 1'b0;
        end
        SHAPE_L: begin
            tetrominoes_shape[3][0] = 1'b0; tetrominoes_shape[3][1] = 1'b0; tetrominoes_shape[3][2] = 1'b0; tetrominoes_shape[3][3] = 1'b0;
            tetrominoes_shape[2][0] = 1'b1; tetrominoes_shape[2][1] = 1'b0; tetrominoes_shape[2][2] = 1'b0; tetrominoes_shape[2][3] = 1'b0;
            tetrominoes_shape[1][0] = 1'b1; tetrominoes_shape[1][1] = 1'b0; tetrominoes_shape[1][2] = 1'b0; tetrominoes_shape[1][3] = 1'b0;
            tetrominoes_shape[0][0] = 1'b1; tetrominoes_shape[0][1] = 1'b1; tetrominoes_shape[0][2] = 1'b0; tetrominoes_shape[0][3] = 1'b0;
        end
        SHAPE_S_R1: begin
            tetrominoes_shape[3][0] = 1'b0; tetrominoes_shape[3][1] = 1'b0; tetrominoes_shape[3][2] = 1'b0; tetrominoes_shape[3][3] = 1'b0;
            tetrominoes_shape[2][0] = 1'b1; tetrominoes_shape[2][1] = 1'b0; tetrominoes_shape[2][2] = 1'b0; tetrominoes_shape[2][3] = 1'b0;
            tetrominoes_shape[1][0] = 1'b1; tetrominoes_shape[1][1] = 1'b1; tetrominoes_shape[1][2] = 1'b0; tetrominoes_shape[1][3] = 1'b0;
            tetrominoes_shape[0][0] = 1'b0; tetrominoes_shape[0][1] = 1'b1; tetrominoes_shape[0][2] = 1'b0; tetrominoes_shape[0][3] = 1'b0;
        end
        SHAPE_S: begin
            tetrominoes_shape[3][0] = 1'b0; tetrominoes_shape[3][1] = 1'b0; tetrominoes_shape[3][2] = 1'b0; tetrominoes_shape[3][3] = 1'b0;
            tetrominoes_shape[2][0] = 1'b0; tetrominoes_shape[2][1] = 1'b0; tetrominoes_shape[2][2] = 1'b0; tetrominoes_shape[2][3] = 1'b0;
            tetrominoes_shape[1][0] = 1'b0; tetrominoes_shape[1][1] = 1'b1; tetrominoes_shape[1][2] = 1'b1; tetrominoes_shape[1][3] = 1'b0;
            tetrominoes_shape[0][0] = 1'b1; tetrominoes_shape[0][1] = 1'b1; tetrominoes_shape[0][2] = 1'b0; tetrominoes_shape[0][3] = 1'b0;
        end
    endcase
end
always @(*) begin
    for (i = 0; i < 12; i = i + 1) begin
        for (j = 0; j < 6; j = j + 1) begin
            if (i == 11) begin
                if (j == 5) begin
                    can_place[i][j] = ~( tetris_2d[i][j]     & tetrominoes_shape[0][0]);
                end else
                if (j == 4) begin
                    can_place[i][j] = ~|{tetris_2d[i][j]     & tetrominoes_shape[0][0], tetris_2d[i][j+1]   & tetrominoes_shape[0][1]};
                end else
                if (j == 3) begin
                    can_place[i][j] = ~|{tetris_2d[i][j]     & tetrominoes_shape[0][0], tetris_2d[i][j+1]   & tetrominoes_shape[0][1], tetris_2d[i][j+2]   & tetrominoes_shape[0][2]};
                end else begin
                    can_place[i][j] = ~|{tetris_2d[i][j]     & tetrominoes_shape[0][0], tetris_2d[i][j+1]   & tetrominoes_shape[0][1], tetris_2d[i][j+2]   & tetrominoes_shape[0][2], tetris_2d[i][j+3]   & tetrominoes_shape[0][3]};
                end
            end else
            if (i == 10) begin
                if (j == 5) begin
                    can_place[i][j] = ~|{tetris_2d[i][j]     & tetrominoes_shape[0][0], 
                                         tetris_2d[i+1][j]   & tetrominoes_shape[1][0]};
                end else
                if (j == 4) begin
                    can_place[i][j] = ~|{tetris_2d[i][j]     & tetrominoes_shape[0][0], tetris_2d[i][j+1]   & tetrominoes_shape[0][1], 
                                         tetris_2d[i+1][j]   & tetrominoes_shape[1][0], tetris_2d[i+1][j+1] & tetrominoes_shape[1][1]};
                end else
                if (j == 3) begin
                    can_place[i][j] = ~|{tetris_2d[i][j]     & tetrominoes_shape[0][0], tetris_2d[i][j+1]   & tetrominoes_shape[0][1], tetris_2d[i][j+2]   & tetrominoes_shape[0][2], 
                                         tetris_2d[i+1][j]   & tetrominoes_shape[1][0], tetris_2d[i+1][j+1] & tetrominoes_shape[1][1], tetris_2d[i+1][j+2] & tetrominoes_shape[1][2]};
                end else begin
                    can_place[i][j] = ~|{tetris_2d[i][j]     & tetrominoes_shape[0][0], tetris_2d[i][j+1]   & tetrominoes_shape[0][1], tetris_2d[i][j+2]   & tetrominoes_shape[0][2], tetris_2d[i][j+3]   & tetrominoes_shape[0][3], 
                                         tetris_2d[i+1][j]   & tetrominoes_shape[1][0], tetris_2d[i+1][j+1] & tetrominoes_shape[1][1], tetris_2d[i+1][j+2] & tetrominoes_shape[1][2], tetris_2d[i+1][j+3] & tetrominoes_shape[1][3]};
                end
            end else
            if (i == 9) begin
                if (j == 5) begin
                    can_place[i][j] = ~|{tetris_2d[i][j]     & tetrominoes_shape[0][0], 
                                         tetris_2d[i+1][j]   & tetrominoes_shape[1][0], 
                                         tetris_2d[i+2][j]   & tetrominoes_shape[2][0]};
                end else
                if (j == 4) begin
                    can_place[i][j] = ~|{tetris_2d[i][j]     & tetrominoes_shape[0][0], tetris_2d[i][j+1]   & tetrominoes_shape[0][1], 
                                         tetris_2d[i+1][j]   & tetrominoes_shape[1][0], tetris_2d[i+1][j+1] & tetrominoes_shape[1][1], 
                                         tetris_2d[i+2][j]   & tetrominoes_shape[2][0], tetris_2d[i+2][j+1] & tetrominoes_shape[2][1]};
                end else
                if (j == 3) begin
                    can_place[i][j] = ~|{tetris_2d[i][j]     & tetrominoes_shape[0][0], tetris_2d[i][j+1]   & tetrominoes_shape[0][1], tetris_2d[i][j+2]   & tetrominoes_shape[0][2], 
                                         tetris_2d[i+1][j]   & tetrominoes_shape[1][0], tetris_2d[i+1][j+1] & tetrominoes_shape[1][1], tetris_2d[i+1][j+2] & tetrominoes_shape[1][2], 
                                         tetris_2d[i+2][j]   & tetrominoes_shape[2][0], tetris_2d[i+2][j+1] & tetrominoes_shape[2][1], tetris_2d[i+2][j+2] & tetrominoes_shape[2][2]};
                end else begin
                    can_place[i][j] = ~|{tetris_2d[i][j]     & tetrominoes_shape[0][0], tetris_2d[i][j+1]   & tetrominoes_shape[0][1], tetris_2d[i][j+2]   & tetrominoes_shape[0][2], tetris_2d[i][j+3]   & tetrominoes_shape[0][3], 
                                         tetris_2d[i+1][j]   & tetrominoes_shape[1][0], tetris_2d[i+1][j+1] & tetrominoes_shape[1][1], tetris_2d[i+1][j+2] & tetrominoes_shape[1][2], tetris_2d[i+1][j+3] & tetrominoes_shape[1][3], 
                                         tetris_2d[i+2][j]   & tetrominoes_shape[2][0], tetris_2d[i+2][j+1] & tetrominoes_shape[2][1], tetris_2d[i+2][j+2] & tetrominoes_shape[2][2], tetris_2d[i+2][j+3] & tetrominoes_shape[2][3]};
                end
            end else begin
                if (j == 5) begin
                    can_place[i][j] = ~|{tetris_2d[i][j]     & tetrominoes_shape[0][0], 
                                         tetris_2d[i+1][j]   & tetrominoes_shape[1][0], 
                                         tetris_2d[i+2][j]   & tetrominoes_shape[2][0], 
                                         tetris_2d[i+3][j]   & tetrominoes_shape[3][0]};
                end else
                if (j == 4) begin
                    can_place[i][j] = ~|{tetris_2d[i][j]     & tetrominoes_shape[0][0], tetris_2d[i][j+1]   & tetrominoes_shape[0][1], 
                                         tetris_2d[i+1][j]   & tetrominoes_shape[1][0], tetris_2d[i+1][j+1] & tetrominoes_shape[1][1], 
                                         tetris_2d[i+2][j]   & tetrominoes_shape[2][0], tetris_2d[i+2][j+1] & tetrominoes_shape[2][1], 
                                         tetris_2d[i+3][j]   & tetrominoes_shape[3][0], tetris_2d[i+3][j+1] & tetrominoes_shape[3][1]};
                end else
                if (j == 3) begin
                    can_place[i][j] = ~|{tetris_2d[i][j]     & tetrominoes_shape[0][0], tetris_2d[i][j+1]   & tetrominoes_shape[0][1], tetris_2d[i][j+2]   & tetrominoes_shape[0][2], 
                                         tetris_2d[i+1][j]   & tetrominoes_shape[1][0], tetris_2d[i+1][j+1] & tetrominoes_shape[1][1], tetris_2d[i+1][j+2] & tetrominoes_shape[1][2],
                                         tetris_2d[i+2][j]   & tetrominoes_shape[2][0], tetris_2d[i+2][j+1] & tetrominoes_shape[2][1], tetris_2d[i+2][j+2] & tetrominoes_shape[2][2],
                                         tetris_2d[i+3][j]   & tetrominoes_shape[3][0], tetris_2d[i+3][j+1] & tetrominoes_shape[3][1], tetris_2d[i+3][j+2] & tetrominoes_shape[3][2]};
                end else begin
                    can_place[i][j] = ~|{tetris_2d[i][j]     & tetrominoes_shape[0][0], tetris_2d[i][j+1]   & tetrominoes_shape[0][1], tetris_2d[i][j+2]   & tetrominoes_shape[0][2], tetris_2d[i][j+3]   & tetrominoes_shape[0][3], 
                                         tetris_2d[i+1][j]   & tetrominoes_shape[1][0], tetris_2d[i+1][j+1] & tetrominoes_shape[1][1], tetris_2d[i+1][j+2] & tetrominoes_shape[1][2], tetris_2d[i+1][j+3] & tetrominoes_shape[1][3],
                                         tetris_2d[i+2][j]   & tetrominoes_shape[2][0], tetris_2d[i+2][j+1] & tetrominoes_shape[2][1], tetris_2d[i+2][j+2] & tetrominoes_shape[2][2], tetris_2d[i+2][j+3] & tetrominoes_shape[2][3],
                                         tetris_2d[i+3][j]   & tetrominoes_shape[3][0], tetris_2d[i+3][j+1] & tetrominoes_shape[3][1], tetris_2d[i+3][j+2] & tetrominoes_shape[3][2], tetris_2d[i+3][j+3] & tetrominoes_shape[3][3]};
                end
            end
        end
    end
end
always @(*) begin
    for (i = 0; i < 6; i = i + 1) begin
        case (1'b0)
            can_place[11][i]: place_y_at[i] = 4'd12;
            can_place[10][i]: place_y_at[i] = 4'd11;
            can_place[9][i]:  place_y_at[i] = 4'd10;
            can_place[8][i]:  place_y_at[i] = 4'd9;
            can_place[7][i]:  place_y_at[i] = 4'd8;
            can_place[6][i]:  place_y_at[i] = 4'd7;
            can_place[5][i]:  place_y_at[i] = 4'd6;
            can_place[4][i]:  place_y_at[i] = 4'd5;
            can_place[3][i]:  place_y_at[i] = 4'd4;
            can_place[2][i]:  place_y_at[i] = 4'd3;
            can_place[1][i]:  place_y_at[i] = 4'd2;
            can_place[0][i]:  place_y_at[i] = 4'd1;
            default:          place_y_at[i] = 4'd0;
        endcase
    end
end
assign place_y_r0 = place_y_at[position];
assign place_y_r1 = row_full[0] ? place_y_r0 : place_y_r0 + 1;
assign place_y_r2 = row_full[1] ? place_y_r1 : place_y_r1 + 1;
assign place_y_r3 = row_full[2] ? place_y_r2 : place_y_r2 + 1;
assign can_fail_r0 = place_y_r0 >= 12;
assign can_fail_r1 = place_y_r1 >= 12 && (|tetromino_2d_placed[1]);
assign can_fail_r2 = place_y_r2 >= 12 && (|tetromino_2d_placed[2]);
assign can_fail_r3 = place_y_r3 >= 12 && (|tetromino_2d_placed[3]);
assign _fail = can_fail_r0 || can_fail_r1 || can_fail_r2 || can_fail_r3;
assign add_score = row_full[0] + row_full[1] + row_full[2] + row_full[3];
always @(*) begin
    for (i = 0; i < 4; i = i + 1) begin
        // TODO: Let tetris_2d be 16x6, set 12~15 to 0 constant
        if (place_y_r0+i < 12) begin
            tetromino_2d_placed[i] = ({2'b00, tetrominoes_shape[i]} << position) | (tetris_2d[place_y_r0+i]);
        end else begin
            tetromino_2d_placed[i] = ({2'b00, tetrominoes_shape[i]} << position);
        end
    end
end
always @(*) begin
    for (i = 0; i < 4; i = i + 1) begin
        row_full[i] = &tetromino_2d_placed[i];
    end
end
always @(*) begin
    for (i = 0; i < 11; i = i + 1) begin
        if (i < place_y_r0) begin
            tetris_2d_r0[i] = tetris_2d[i];
        end else
        if (i == place_y_r0) begin
            tetris_2d_r0[i] = row_full[0] ? tetris_2d[i+1] : tetromino_2d_placed[0];
        end else begin
            tetris_2d_r0[i] = row_full[0] ? tetris_2d[i+1] : tetris_2d[i];
        end
    end
    tetris_2d_r0[11] = row_full[0] ? 6'd0 : (place_y_r0 == 11 ? tetromino_2d_placed[0] : tetris_2d[11]); 
end
always @(*) begin
    for (i = 0; i < 11; i = i + 1) begin
        if (i < place_y_r1) begin
            tetris_2d_r1[i] = tetris_2d_r0[i];
        end else
        if (i == place_y_r1) begin
            tetris_2d_r1[i] = row_full[1] ? tetris_2d_r0[i+1] : tetromino_2d_placed[1];
        end else begin
            tetris_2d_r1[i] = row_full[1] ? tetris_2d_r0[i+1] : tetris_2d_r0[i];
        end
    end
    tetris_2d_r1[11] = row_full[1] ? 6'd0 : (place_y_r1 == 11 ? tetromino_2d_placed[1] : tetris_2d_r0[11]); 
end
always @(*) begin
    for (i = 0; i < 11; i = i + 1) begin
        if (i < place_y_r2) begin
            tetris_2d_r2[i] = tetris_2d_r1[i];
        end else
        if (i == place_y_r2) begin
            tetris_2d_r2[i] = row_full[2] ? tetris_2d_r1[i+1] : tetromino_2d_placed[2];
        end else begin
            tetris_2d_r2[i] = row_full[2] ? tetris_2d_r1[i+1] : tetris_2d_r1[i];
        end
    end
    tetris_2d_r2[11] = row_full[2] ? 6'd0 : (place_y_r2 == 11 ? tetromino_2d_placed[2] : tetris_2d_r1[11]); 
end
always @(*) begin
    for (i = 0; i < 11; i = i + 1) begin
        if (i < place_y_r3) begin
            tetris_2d_r3[i] = tetris_2d_r2[i];
        end else
        if (i == place_y_r3) begin
            tetris_2d_r3[i] = row_full[3] ? tetris_2d_r2[i+1] : tetromino_2d_placed[3];
        end else begin
            tetris_2d_r3[i] = row_full[3] ? tetris_2d_r2[i+1] : tetris_2d_r2[i];
        end
    end
    tetris_2d_r3[11] = row_full[3] ? 6'd0 : (place_y_r3 == 11 ? tetromino_2d_placed[3] : tetris_2d_r2[11]); 
end
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        for (i = 0; i < 12; i = i + 1) begin
            tetris_2d[i] <= 6'd0;
        end
    end else begin
        if (in_valid) begin
            for (i = 0; i < 12; i = i + 1) begin
                tetris_2d[i] <= tetris_2d_r3[i];
            end
        end else begin
            if (fail || tetromino_cnt == 4'd0) begin
                for (i = 0; i < 12; i = i + 1) begin
                    tetris_2d[i] <= 6'd0;
                end
            end
        end
    end
end
always @(*) begin
    tetris = {tetris_2d[11], tetris_2d[10], tetris_2d[9], tetris_2d[8], tetris_2d[7], tetris_2d[6], tetris_2d[5], tetris_2d[4], tetris_2d[3], tetris_2d[2], tetris_2d[1], tetris_2d[0]}
            &{72{tetris_valid}};
end
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        score_valid <= 1'b0;
    end else begin
        if (in_valid) begin
            score_valid <= 1'b1;
        end else begin
            score_valid <= 1'b0;
        end
    end
end
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        _score <= 4'd0;
    end else begin
        if (in_valid) begin
            _score <= _score + add_score;
        end else begin
            if (fail || tetromino_cnt == 4'd0) begin
                _score <= 4'd0;
            end else begin
                _score <= _score;
            end
        end
    end
end
always @(*) begin
    score = _score & {4{score_valid}};
end
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        tetris_valid <= 1'b0;
    end else begin
        if (in_valid && (_fail || tetromino_cnt == 4'd15)) begin
            tetris_valid <= 1'b1;
        end else begin
            tetris_valid <= 1'b0;
        end
    end
end
// always @(*) begin
//     tetris_valid = score_valid;
// end
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        fail <= 1'b0;
    end else begin
        if (in_valid) begin
            fail <= _fail;
        end else begin
            fail <= 1'b0;
        end
    end
end
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        tetromino_cnt <= 4'd0;
    end else begin
        if (in_valid) begin
            tetromino_cnt <= tetromino_cnt + 1;
        end else begin
            if (fail) begin
                tetromino_cnt <= 4'd0;
            end else begin
                tetromino_cnt <= tetromino_cnt;
            end
        end
    end
end

endmodule
