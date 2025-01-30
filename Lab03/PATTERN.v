/**************************************************************************/
// Copyright (c) 2024, OASIS Lab
// MODULE: PATTERN
// FILE NAME: PATTERN.v
// VERSRION: 1.0
// DATE: August 15, 2024
// AUTHOR: Yu-Hsuan Hsu, NYCU IEE
// DESCRIPTION: ICLAB2024FALL / LAB3 / PATTERN
// MODIFICATION HISTORY:
// Date                 Description
// 
/**************************************************************************/

`ifdef RTL
    `define CYCLE_TIME 12.2
`endif
`ifdef GATE
    `define CYCLE_TIME 12.2
`endif

module PATTERN(
    //OUTPUT
    rst_n,
    clk,
    in_valid,
    tetrominoes,
    position,
    //INPUT
    tetris_valid,
    score_valid,
    fail,
    score,
    tetris
);

    //=====================================================================
    //   PORT DECLARATION          
    //=====================================================================
    output reg          rst_n, clk, in_valid;
    output reg [2:0]    tetrominoes;
    output reg [2:0]    position;
    input               tetris_valid, score_valid, fail;
    input      [ 3:0]   score;
    input      [71:0]   tetris;

    //=====================================================================
    //   PARAMETER & INTEGER DECLARATION
    //=====================================================================
    integer total_latency;
    real CYCLE = `CYCLE_TIME;
    integer pattern_id;
    //---------------------------------------------------------------------
    //  TETROMINOES
    //---------------------------------------------------------------------
    //  TYPE 0:         TYPE 4:
    //      23              123
    //      01              0
    //  TYPE 1:         TYPE 5:
    //      3               3
    //      2               2
    //      1               01
    //      0           TYPE 6:
    //  TYPE 2:             3
    //      0123            12
    //  TYPE 3:              0
    //      23          TYPE 7:
    //       1                23
    //       0               01

    // tetrominoes_block_x[type][block]
    reg [1:0] tetrominoes_blocks_x [0:7][0:3] = '{
        '{2'b00, 2'b01, 2'b00, 2'b01},
        '{2'b00, 2'b00, 2'b00, 2'b00},
        '{2'b00, 2'b01, 2'b10, 2'b11},
        '{2'b01, 2'b01, 2'b00, 2'b01},
        '{2'b00, 2'b00, 2'b01, 2'b10},
        '{2'b00, 2'b01, 2'b00, 2'b00},
        '{2'b01, 2'b00, 2'b01, 2'b00},
        '{2'b00, 2'b01, 2'b01, 2'b10}
    };
    // tetrominoes_block_y[type][block]
    reg [1:0] tetrominoes_blocks_y [0:7][0:3] = '{
        '{2'b00, 2'b00, 2'b01, 2'b01},
        '{2'b00, 2'b01, 2'b10, 2'b11},
        '{2'b00, 2'b00, 2'b00, 2'b00},
        '{2'b00, 2'b01, 2'b10, 2'b10},
        '{2'b00, 2'b01, 2'b01, 2'b01},
        '{2'b00, 2'b00, 2'b01, 2'b10},
        '{2'b00, 2'b01, 2'b01, 2'b10},
        '{2'b00, 2'b00, 2'b01, 2'b01}
    };
    
    //---------------------------------------------------------------------
    //  COUNTER
    //---------------------------------------------------------------------
    integer   tetrominoes_counter;
    integer   pattern_total;
    integer   pattern_counter;

    //---------------------------------------------------------------------
    //  FILE
    //---------------------------------------------------------------------
    integer f_input;
    
    //---------------------------------------------------------------------
    //  LATENCY
    //---------------------------------------------------------------------
    integer score_latency;

    //=====================================================================
    //   REG & WIRE DECLARATION
    //=====================================================================
    //---------------------------------------------------------------------
    //  GOLDEN
    //---------------------------------------------------------------------
    reg        fail_golden          = 1'd0;
    reg [ 3:0] score_golden         = 4'd0000;
    reg [ 5:0] tetris_golden [0:15] = '{
        6'b000000, 6'b000000, 6'b000000, 6'b000000,
        6'b000000, 6'b000000, 6'b000000, 6'b000000,
        6'b000000, 6'b000000, 6'b000000, 6'b000000,
        6'b000000, 6'b000000, 6'b000000, 6'b000000
    };

    //---------------------------------------------------------------------
    //  PATTERNS
    //---------------------------------------------------------------------
    reg [ 3:0] tetrominoes_pattern;
    reg [ 2:0] position_pattern;

    reg spec_5_fail = 1'b0;
    reg spec_6_fail = 1'b0;
    reg spec_7_fail = 1'b0;
    reg spec_8_fail = 1'b0;

    //=====================================================================
    //  CLOCK
    //=====================================================================
    initial clk = 0;
    always #(CYCLE/2) clk = ~clk;

    //=====================================================================
    //  SIMULATION
    //=====================================================================
    //---------------------------------------------------------------------
    //  MAIN
    //---------------------------------------------------------------------
    always @(negedge clk) begin
        task_spec5;
        task_check_fail;
    end
    initial begin
        `ifdef SHINKUAN
            $display("**************************************************");
            $display("            PATTERN MADE BY SHIN-KUAN             ");
            $display("**************************************************");
        `else
        `endif
        
        task_f_input;
        task_reset;
        task_read_pattern_num;
        #(CYCLE*5);
        for (pattern_counter = 0; pattern_counter < pattern_total; pattern_counter = pattern_counter + 1) begin
            $fscanf(f_input, "%d", pattern_id);
            task_reset_golden;
            #(CYCLE);
            for (tetrominoes_counter = 0; tetrominoes_counter < 16; tetrominoes_counter = tetrominoes_counter + 1) begin
                $fscanf(f_input, "%d %d", tetrominoes_pattern, position_pattern);
                if (!fail_golden) begin
                    task_place_tetromino;
                    @(negedge clk); 
                    task_send_pattern;
                    task_wait_score_valid;
                    task_spec7;
                    // Wait for 1 or 4 cycles`
                    repeat (1+(tetrominoes_counter%2)*3) @(negedge clk)
                        task_spec8;
                end
            end
        end
        task_success;
        $fclose(f_input);
        #(CYCLE*10);
        $finish;
    end

    
    
    //---------------------------------------------------------------------
    //  INPUT FILE
    //---------------------------------------------------------------------
    task task_f_input; begin
        f_input = $fopen("../00_TESTBED/input.txt", "r");
        if (f_input == 0) begin
            $display("**************************************************");
            $display("                    FILE ERROR                    ");
            $display("**************************************************");
            $display("Cannot open input.txt");
            $display("--------------------------------------------------");
            $finish;
        end
    end endtask

    //---------------------------------------------------------------------
    //  RESET
    //---------------------------------------------------------------------
    task task_reset; begin
        rst_n           = 1'b1;
        in_valid        = 1'b0;
        tetrominoes     = 3'bxx;
        position        = 3'bxxx;
        total_latency   = 0;

        force clk = 0;

        // Apply reset
        #CYCLE; rst_n = 1'b0; 
        #CYCLE; rst_n = 1'b1;
        
        // Check initial conditions
        #(100-CYCLE); task_spec4;
        #(CYCLE); release clk;  // TODO: Check timing
    end endtask

    //---------------------------------------------------------------------
    //  READ PATTERN NUM
    //---------------------------------------------------------------------
    task task_read_pattern_num; begin
        if ($feof(f_input)) begin
            $display("**************************************************");
            $display("                    FILE ERROR                    ");
            $display("**************************************************");
            $display("Cannot read pattern number");
            $display("--------------------------------------------------");
            $finish;
        end
        $fscanf(f_input, "%d", pattern_total);
    end endtask

    //---------------------------------------------------------------------
    //  RESET GOLDEN
    //---------------------------------------------------------------------
    task task_reset_golden; begin
        fail_golden = 1'b0;
        score_golden = 4'd0;
        tetris_golden = '{
            6'b000000, 6'b000000, 6'b000000, 6'b000000,
            6'b000000, 6'b000000, 6'b000000, 6'b000000,
            6'b000000, 6'b000000, 6'b000000, 6'b000000,
            6'b000000, 6'b000000, 6'b000000, 6'b000000
        };
    end endtask

    //---------------------------------------------------------------------
    //  SEND PATTERN
    //---------------------------------------------------------------------
    task task_send_pattern; begin
        in_valid = 1'b1;
        tetrominoes = tetrominoes_pattern;
        position = position_pattern;
    end endtask

    //---------------------------------------------------------------------
    //  WAIT FOR SCORE VALID
    //---------------------------------------------------------------------
    task task_wait_score_valid; begin
        score_latency = 0;
        while (score_valid !== 1'b1) begin
            score_latency = score_latency + 1;
            task_spec6;
            @(negedge clk);
            in_valid = 1'b0;
            tetrominoes = 3'bxxx;
            position = 3'bxxx;
        end
        total_latency = total_latency + score_latency;
    end endtask
    
    //---------------------------------------------------------------------
    //  SPEC-4:
    //      The reset signal (rst_n) would be given only once at the 
    //      beginning of simulation. All output signals should be reset. 
    //      The pattern will check the output signal 100ns after the reset 
    //      signal is pulled low.
    //---------------------------------------------------------------------
    task task_spec4; begin 
        if (  // 100ns after reset
            tetris_valid    !== 1'b0    ||
            score_valid     !== 1'b0    ||
            fail            !== 1'b0    ||
            score           !== 4'b0000 ||
            tetris          !== 72'b0
        ) begin
            $display("**************************************************");
            $display("                    SPEC-4 FAIL                   ");
            $display("**************************************************");
            $display("Output signals should be 0 after initial RESET at %8t", $time);
            $display("tetris_valid = %b, score_valid = %b, fail = %b, score = %b, tetris = %b", tetris_valid, score_valid, fail, score, tetris);
            $display("--------------------------------------------------");
            task_display_fail;
            $finish;
        end
    end endtask

    //---------------------------------------------------------------------
    //  SPEC-5:
    //      The signals score, fail, and tetris_valid must be 0 When the 
    //      score valid is low. And the tetris must be reset when tetris 
    //      valid is low.
    //---------------------------------------------------------------------
    task task_spec5; begin
        if (score_valid === 1'b0) begin
            if (
                score           !== 4'b0000 ||
                fail            !== 1'b0    ||
                tetris_valid    !== 1'b0    ||
                tetris          !== 72'b0   
            ) begin
                spec_5_fail = 1'b1;
                // $display("**************************************************");
                // $display("                    SPEC-5 FAIL                   ");
                // $display("**************************************************");
                // $display("score and fail should be 0 when score_valid is 0 at %8t", $time);
                // $display("score = %b, fail = %b, score_valid = %b", score, fail, score_valid);
                // $display("--------------------------------------------------");
                // task_display_fail;
                // $finish;
            end
        end else
        if (tetris_valid === 1'b0) begin
            if (tetris !== 72'b0) begin
                spec_5_fail = 1'b1;
                // $display("**************************************************");
                // $display("                    SPEC-5 FAIL                   ");
                // $display("**************************************************");
                // $display("tetris should be 0 when tetris_valid is 0 at %8t", $time);
                // $display("tetris = %b, tetris_valid = %b", tetris, tetris_valid);
                // $display("--------------------------------------------------");
                // task_display_fail;
                // $finish;
            end
        end
    end endtask

    //---------------------------------------------------------------------
    //  SPEC-6:
    //      The latency of each inputs set is limited in 1000 cycles. The 
    //      latency is the time of the clock cycles between the falling 
    //      edge of the in valid and the rising edge of the score_valid.
    //---------------------------------------------------------------------
    task task_spec6; begin
        if (score_latency >= 1000) begin
            spec_6_fail = 1'b1;
            // $display("**************************************************");
            // $display("                    SPEC-6 FAIL                   ");
            // $display("**************************************************");
            // $display("The latency of each inputs set is limited in 1000 cycles at %8t", $time);
            // $display("score_latency = %d", score_latency);
            // $display("--------------------------------------------------");
            // task_display_fail;
            // $finish;
        end
    end endtask

    //---------------------------------------------------------------------
    //  SPEC-7:
    //      The score and fail should be correct when score valid is high. 
    //      The tetris must be correct when the tetris_valid is high.
    //---------------------------------------------------------------------
    task task_spec7; begin
        // Pattern Finished
        // Both score_valid and tetris_valid are high
        if (fail_golden || tetrominoes_counter === 15) begin
            if (
                tetris_valid    !== 1'b1            ||
                score_valid     !== 1'b1            ||
                fail            !== fail_golden     ||
                score           !== score_golden    ||
                tetris          !== {tetris_golden[11], tetris_golden[10], tetris_golden[9], tetris_golden[8], tetris_golden[7], tetris_golden[6], tetris_golden[5], tetris_golden[4], tetris_golden[3], tetris_golden[2], tetris_golden[1], tetris_golden[0]}
            ) begin
                spec_7_fail = 1'b1;
                // $display("**************************************************");
                // $display("                    SPEC-7 FAIL                   ");
                // $display("**************************************************");
                // $display("tetris_valid: %b", tetris_valid);
                // $display("score_valid: %b", score_valid);
                // $display("fail: %b, fail_golden: %b", fail, fail_golden);
                // $display("score: %b, score_golden: %b", score, score_golden);
                // $display("tetris[71:66]: %b, tetris_golden[71:66]: %b", tetris[71:66], tetris_golden[11]);
                // $display("tetris[65:60]: %b, tetris_golden[65:60]: %b", tetris[65:60], tetris_golden[10]);
                // $display("tetris[59:54]: %b, tetris_golden[59:54]: %b", tetris[59:54], tetris_golden[9]);
                // $display("tetris[53:48]: %b, tetris_golden[53:48]: %b", tetris[53:48], tetris_golden[8]);
                // $display("tetris[47:42]: %b, tetris_golden[47:42]: %b", tetris[47:42], tetris_golden[7]);
                // $display("tetris[41:36]: %b, tetris_golden[41:36]: %b", tetris[41:36], tetris_golden[6]);
                // $display("tetris[35:30]: %b, tetris_golden[35:30]: %b", tetris[35:30], tetris_golden[5]);
                // $display("tetris[29:24]: %b, tetris_golden[29:24]: %b", tetris[29:24], tetris_golden[4]);
                // $display("tetris[23:18]: %b, tetris_golden[23:18]: %b", tetris[23:18], tetris_golden[3]);
                // $display("tetris[17:12]: %b, tetris_golden[17:12]: %b", tetris[17:12], tetris_golden[2]);
                // $display("tetris[11: 6]: %b, tetris_golden[11: 6]: %b", tetris[11: 6], tetris_golden[1]);
                // $display("tetris[ 5: 0]: %b, tetris_golden[ 5: 0]: %b", tetris[ 5: 0], tetris_golden[0]);
                // $display("--------------------------------------------------");
                // task_display_fail;
                // $finish;
            end
        end else
        // Set Finished
        // score_valid is high
        begin
            if (
                score_valid     !== 1'b1            ||
                fail            !== 1'b0            ||
                score           !== score_golden    ||
                (
                    tetris_valid    === 1'b0        &&
                    tetris          !== 72'b0
                )                                   ||
                (
                    tetris_valid    === 1'b1        &&
                    tetris          !== {tetris_golden[11], tetris_golden[10], tetris_golden[9], tetris_golden[8], tetris_golden[7], tetris_golden[6], tetris_golden[5], tetris_golden[4], tetris_golden[3], tetris_golden[2], tetris_golden[1], tetris_golden[0]}
                )
            ) begin
                spec_7_fail = 1'b1;
                // $display("**************************************************");
                // $display("                    SPEC-7 FAIL                   ");
                // $display("**************************************************");
                // $display("tetris_valid: %b, tetris_valid_golden: 0", tetris_valid);
                // $display("score_valid: %b, score_valid_golden: 1", score_valid);
                // $display("fail: %b, fail_golden: 0", fail, fail_golden);
                // $display("score: %d, score_golden: %d", score, score_golden);
                // $display("tetris[71:66]: %b, tetris_golden[71:66]: %b", tetris[71:66], tetris_golden[11]);
                // $display("tetris[65:60]: %b, tetris_golden[65:60]: %b", tetris[65:60], tetris_golden[10]);
                // $display("tetris[59:54]: %b, tetris_golden[59:54]: %b", tetris[59:54], tetris_golden[9]);
                // $display("tetris[53:48]: %b, tetris_golden[53:48]: %b", tetris[53:48], tetris_golden[8]);
                // $display("tetris[47:42]: %b, tetris_golden[47:42]: %b", tetris[47:42], tetris_golden[7]);
                // $display("tetris[41:36]: %b, tetris_golden[41:36]: %b", tetris[41:36], tetris_golden[6]);
                // $display("tetris[35:30]: %b, tetris_golden[35:30]: %b", tetris[35:30], tetris_golden[5]);
                // $display("tetris[29:24]: %b, tetris_golden[29:24]: %b", tetris[29:24], tetris_golden[4]);
                // $display("tetris[23:18]: %b, tetris_golden[23:18]: %b", tetris[23:18], tetris_golden[3]);
                // $display("tetris[17:12]: %b, tetris_golden[17:12]: %b", tetris[17:12], tetris_golden[2]);
                // $display("tetris[11: 6]: %b, tetris_golden[11: 6]: %b", tetris[11: 6], tetris_golden[1]);
                // $display("tetris[ 5: 0]: %b, tetris_golden[ 5: 0]: %b", tetris[ 5: 0], tetris_golden[0]);
                // $display("--------------------------------------------------");
                // task_display_fail;
                // $finish;
            end
        end
    end endtask

    //---------------------------------------------------------------------
    //  SPEC-8:
    //      The score_valid and the tetris_valid cannot be high for more 
    //      than 1 cycle. They must be pulled down immediately in the next 
    //      cycle.
    //---------------------------------------------------------------------
    task task_spec8; begin
        if (score_valid === 1'b1 || tetris_valid === 1'b1) begin
            spec_8_fail = 1'b1;
            // $display("**************************************************");
            // $display("                    SPEC-8 FAIL                   ");
            // $display("**************************************************");
            // $display("score_valid and tetris_valid should be 0 in the next cycle at %8t", $time);
            // $display("score_valid = %b, tetris_valid = %b", score_valid, tetris_valid);
            // $display("--------------------------------------------------");
            // task_display_fail;
            // $finish;
        end
    end endtask

    //---------------------------------------------------------------------
    //  FAIL PATTERN INFO
    //---------------------------------------------------------------------
    task task_check_fail; begin
        if (spec_5_fail || spec_6_fail || spec_7_fail || spec_8_fail) begin
            $display("**************************************************");
            $display("                    FAIL PATTERN                  ");
            $display("**************************************************");
            $display("Pattern ID: %d", pattern_id);
            $display("Tetrominoes_counter: %d", tetrominoes_counter);
            $display("Tetrominoes: %d", tetrominoes_pattern);
            $display("Position: %d", position_pattern);
            $display("--------------------------------------------------");
            if (spec_5_fail) begin
                $display("                    SPEC-5 FAIL                   ");
            end
            else if (spec_6_fail) begin
                $display("                    SPEC-6 FAIL                   ");
            end
            else if (spec_7_fail) begin
                $display("                    SPEC-7 FAIL                   ");
            end
            else if (spec_8_fail) begin
                $display("                    SPEC-8 FAIL                   ");
            end
            $display("--------------------------------------------------");
            $finish;
        end
    end endtask
    task task_display_fail; begin
        $display("**************************************************");
        $display("                    FAIL PATTERN                  ");
        $display("**************************************************");
        $display("Pattern ID: %d", pattern_id);
        $display("Tetrominoes_counter: %d", tetrominoes_counter);
        $display("Tetrominoes: %d", tetrominoes_pattern);
        $display("Position: %d", position_pattern);
        $display("--------------------------------------------------");
    end endtask

    //---------------------------------------------------------------------
    //  SUCCESS
    //---------------------------------------------------------------------
    task task_success; begin
        $display("**************************************************");
        $display("                  Congratulations!               ");
        $display("              execution cycles = %7d", total_latency);
        $display("              clock period = %4fns", CYCLE);
        $display("**************************************************");
    end endtask

    //---------------------------------------------------------------------
    //  GOLDEN GENERATION
    //---------------------------------------------------------------------
    task task_place_tetromino; begin
        integer y, x;
        integer j, k;

        fail_golden = 1'b1;
        for (y = 12; y >= 0; y = y - 1) begin
            if (
                tetris_golden[y+tetrominoes_blocks_y[tetrominoes_pattern][0]][position_pattern+tetrominoes_blocks_x[tetrominoes_pattern][0]] === 1'b0 &&
                tetris_golden[y+tetrominoes_blocks_y[tetrominoes_pattern][1]][position_pattern+tetrominoes_blocks_x[tetrominoes_pattern][1]] === 1'b0 &&
                tetris_golden[y+tetrominoes_blocks_y[tetrominoes_pattern][2]][position_pattern+tetrominoes_blocks_x[tetrominoes_pattern][2]] === 1'b0 &&
                tetris_golden[y+tetrominoes_blocks_y[tetrominoes_pattern][3]][position_pattern+tetrominoes_blocks_x[tetrominoes_pattern][3]] === 1'b0
            ) begin
                fail_golden = 1'b0;
                j = y;
            end else if (fail_golden === 1'b0) begin
                break;
            end
        end
        if (fail_golden === 1'b0) begin
            for (k = 0; k < 4; k = k + 1) begin
                tetris_golden[j+tetrominoes_blocks_y[tetrominoes_pattern][k]][position_pattern+tetrominoes_blocks_x[tetrominoes_pattern][k]] = 1'b1;
            end
        end
        for (y = 0; y < 12; y = y + 1 ) begin
            if (tetris_golden[y] === 6'b111111) begin
                score_golden = score_golden + 1;
                for (j = y; j < 15; j = j + 1) begin
                    tetris_golden[j] = tetris_golden[j+1];
                end
                tetris_golden[15] = 6'b000000;
                y=y-1;
            end
        end
        for (y = 12; y < 16; y = y + 1) begin
            if (tetris_golden[y] !== 6'b000000) begin
                fail_golden = 1'b1;
            end
        end
    end endtask

endmodule
// for spec check
// $display("                    SPEC-4 FAIL                   ");
// $display("                    SPEC-5 FAIL                   ");
// $display("                    SPEC-6 FAIL                   ");
// $display("                    SPEC-7 FAIL                   ");
// $display("                    SPEC-8 FAIL                   ");
// for successful design
// $display("                  Congratulations!               ");
// $display("              execution cycles = %7d", total_latency);
// $display("              clock period = %4fns", CYCLE);