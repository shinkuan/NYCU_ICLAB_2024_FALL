/**************************************************************************/
// Copyright (c) 2024, OASIS Lab
// MODULE: SA
// FILE NAME: PATTERN.v
// VERSRION: 1.0
// DATE: Nov 06, 2024
// AUTHOR: Yen-Ning Tung, NYCU AIG
// CODE TYPE: RTL or Behavioral Level (Verilog)
// DESCRIPTION: 2024 Fall IC Lab / Exersise Lab08 / PATTERN
// MODIFICATION HISTORY:
// Date                 Description
// 
/**************************************************************************/

`define CYCLE_TIME 50
`define RANDOM_SEED     // Comment this line to use fixed seed
`define SEED_NUMBER     1165092499
`define PAT_NUM         20

module PATTERN(
    // Output signals
    clk,
    rst_n,
    cg_en,
    in_valid,
    T,
    in_data,
    w_Q,
    w_K,
    w_V,

    // Input signals
    out_valid,
    out_data
);

    output reg clk;
    output reg rst_n;
    output reg cg_en;
    output reg in_valid;
    output reg [3:0] T;
    output reg signed [7:0] in_data;
    output reg signed [7:0] w_Q;
    output reg signed [7:0] w_K;
    output reg signed [7:0] w_V;

    input out_valid;
    input signed [63:0] out_data;

    //================================================================
    // Clock
    //================================================================
    real CYCLE = `CYCLE_TIME;
    always #(CYCLE/2.0) clk = ~clk; // @suppress

    `ifdef RANDOM_SEED
    int  SEED           = get_time(); // @suppress
    `else
    int  SEED           = `SEED_NUMBER;
    `endif
    real PAT_NUM = `PAT_NUM;

    //================================================================
    // parameters & integer
    //================================================================
    integer i, j, k; // @suppress
    integer pat_idx;
    integer latency;
    integer total_latency;

    //================================================================
    // Wire & Reg Declaration
    //================================================================
    reg        [ 3:0] T_pattern;
    
    reg signed [ 7:0] matrix_X  [7:0][7:0];
    reg signed [ 7:0] matrix_WQ [7:0][7:0];
    reg signed [ 7:0] matrix_WK [7:0][7:0];
    reg signed [ 7:0] matrix_WV [7:0][7:0];
    reg signed [18:0] matrix_Q  [7:0][7:0];
    reg signed [18:0] matrix_K  [7:0][7:0];
    reg signed [18:0] matrix_V  [7:0][7:0];
    reg signed [40:0] matrix_A  [7:0][7:0];
    reg signed [40:0] matrix_S  [7:0][7:0];
    reg signed [63:0] matrix_P  [7:0][7:0];

    reg signed [63:0] out_datar [7:0][7:0];

    //================================================================
    // Design
    //================================================================
    initial begin
        `ifdef SHINKUAN
        $display("**************************************************");
        $display("            PATTERN MADE BY SHIN-KUAN             ");
        $display("**************************************************");
        `endif
        $write("\033[33m");                                             
        $display("██╗      █████╗ ██████╗  ██████╗  █████╗ ");
        $display("██║     ██╔══██╗██╔══██╗██╔═████╗██╔══██╗");
        $display("██║     ███████║██████╔╝██║██╔██║╚█████╔╝");
        $display("██║     ██╔══██║██╔══██╗████╔╝██║██╔══██╗");
        $display("███████╗██║  ██║██████╔╝╚██████╔╝╚█████╔╝");
        $display("╚══════╝╚═╝  ╚═╝╚═════╝  ╚═════╝  ╚════╝ ");
        $write("\033[0m");
        $write("\033[36m");
        $display("Seed: %d", SEED);
        $display("Pattern Number: %d", PAT_NUM);
        $write("\033[0m");
        $display("==================================================");
        reset;
        for (pat_idx = 0; pat_idx < PAT_NUM; pat_idx++) begin
            generate_stimulus;
            send_input;
            wait_output;
            check_output;
            $write("\033[32m");
            $display("Pattern %d Pass. Latency: %d", pat_idx, latency);
            $write("\033[0m");
            wait_next_pattern;
        end
        $display("\033[32m");
        $display("**************************************************");
        $display("                 ALL PATTERN PASS                 ");
        $display("**************************************************");
        $display("               SEED: %d", SEED);
        $display("         Total Latency: %d cycles", total_latency);
        $display("\033[33m /| ､\033[0m");
        $display("\033[33m(°､ ｡ 7\033[0m");
        $display("\033[33m |､  ~ヽ\033[0m");
        $display("\033[33m じしf_,)〳\033[0m");
        $finish;
    end

    function integer get_time();
        int    file_pointer;
        int    t;

        void'($system("date +%N > sys_time"));
        file_pointer = $fopen("sys_time","r");
        void'($fscanf(file_pointer,"%d",t));
        $fclose(file_pointer);
        void'($system("rm sys_time"));
        return t;
    endfunction

    task reset; begin
        latency       = 0;
        total_latency = 0;
        T_pattern     = 8;

        force clk   = 0;
        rst_n       = 1;
        cg_en       = 0;
        in_valid    = 0;
        T           = 'bX;
        in_data     = 'bX;
        w_Q         = 'bX;
        w_K         = 'bX;
        w_V         = 'bX;
        #CYCLE;
        rst_n       = 0;
        #(3*CYCLE);
        rst_n       = 1;
        outrst_checker;
        #CYCLE;
        release clk;
        repeat(2) @(negedge clk);
    end endtask

    task generate_stimulus; begin
        integer i, j, k;

        // Generate input
        case ({$random(SEED)}%3)
            0: T_pattern = 4'd1;
            1: T_pattern = 4'd4;
            2: T_pattern = 4'd8;
            default: T_pattern = 4'd1;
        endcase

        for (i = 0; i < T_pattern; i++) begin
            for (j = 0; j < 8; j++) begin
                matrix_X[i][j]  = {$random(SEED)}%256;
            end
        end

        for (i = 0; i < 8; i++) begin
            for (j = 0; j < 8; j++) begin
                matrix_WQ[i][j] = {$random(SEED)}%256;
                matrix_WK[i][j] = {$random(SEED)}%256;
                matrix_WV[i][j] = {$random(SEED)}%256;
            end
        end

        for (i = 0; i < T_pattern; i++) begin
            for (j = 0; j < 8; j++) begin
                matrix_Q[i][j] = 0;
                matrix_K[i][j] = 0;
                matrix_V[i][j] = 0;
                for (k = 0; k < 8; k++) begin
                    matrix_Q[i][j] += matrix_X[i][k] * matrix_WQ[k][j];
                    matrix_K[i][j] += matrix_X[i][k] * matrix_WK[k][j];
                    matrix_V[i][j] += matrix_X[i][k] * matrix_WV[k][j];
                end
            end
        end

        for (i = 0; i < T_pattern; i++) begin
            for (j = 0; j < T_pattern; j++) begin
                matrix_A[i][j] = 0;
                for (k = 0; k < 8; k++) begin
                    matrix_A[i][j] += matrix_Q[i][k] * matrix_K[j][k];
                end
            end
        end

        for (i = 0; i < T_pattern; i++) begin
            for (j = 0; j < T_pattern; j++) begin
                matrix_S[i][j] = matrix_A[i][j] / 3;
                matrix_S[i][j] = matrix_S[i][j] < 0 ? 0 : matrix_S[i][j];
            end
        end

        for (i = 0; i < T_pattern; i++) begin
            for (j = 0; j < 8; j++) begin
                matrix_P[i][j] = 0;
                for (k = 0; k < T_pattern; k++) begin
                    matrix_P[i][j] += matrix_S[i][k] * matrix_V[k][j];
                end
            end
        end
    end endtask

    task send_input; begin
        in_valid = 1;
        fork
            begin
                T = T_pattern;
                @(negedge clk);
                T = 'bX;
            end
            begin
                for (int i = 0; i < T_pattern; i++) begin
                    for (int j = 0; j < 8; j++) begin
                        in_data = matrix_X[i][j];
                        @(negedge clk);
                    end
                end
                in_data = 'bX;
            end
            begin
                for (int i = 0; i < 8; i++) begin
                    for (int j = 0; j < 8; j++) begin
                        w_Q = matrix_WQ[i][j];
                        @(negedge clk);
                    end
                end
                w_Q = 'bX;
                for (int i = 0; i < 8; i++) begin
                    for (int j = 0; j < 8; j++) begin
                        w_K = matrix_WK[i][j];
                        @(negedge clk);
                    end
                end
                w_K = 'bX;
                for (int i = 0; i < 8; i++) begin
                    for (int j = 0; j < 8; j++) begin
                        w_V = matrix_WV[i][j];
                        @(negedge clk);
                    end
                end
                w_V = 'bX;
            end
        join
        in_valid = 0;
    end endtask

    task wait_output; begin
        latency = 0;

        while (out_valid === 0) begin
            @(negedge clk);
            latency++;
        end
        total_latency += latency;
    end endtask

    task check_output; begin
        integer out_count;

        out_count = 0;

        if (out_valid !== 1) begin
            $write("\033[31m");
            $display("**************************************************");
            $display("               OUTPUT VALID FAILED                ");
            $display("**************************************************");
            $display("          out_valid did not assert to 1");
            $display("--------------------------------------------------");
            $display("               time: %d", $time);
            $display("--------------------------------------------------");
            $display("Output Valid: %b", out_valid);
            $display("Output Data:  %d", out_data);
            $display("**************************************************");
            $write("\033[0m");
            print_debug;
            $finish;
        end
        while (out_valid === 1) begin
            if (out_data !== matrix_P[out_count/8][out_count%8]) begin
                $write("\033[31m");
                $display("**************************************************");
                $display("                OUTPUT DATA WRONG                 ");
                $display("**************************************************");
                $display("        out_data is not equal to matrix_P");
                $display("--------------------------------------------------");
                $display("               time: %d", $time);
                $display("--------------------------------------------------");
                $display("Output Valid: %b", out_valid);
                $display("Output Data:  %d", out_data);
                $display("**************************************************");
                $write("\033[0m");
                print_debug;
                $finish;
            end
            out_datar[out_count/8][out_count%8] = out_data;
            out_count++;
            @(negedge clk);
        end
        if (out_count != T_pattern*8) begin
            $write("\033[31m");
            $display("**************************************************");
            $display("                OUTPUT DATA WRONG                 ");
            $display("**************************************************");
            $display("        out_data length is not equal to T*8");
            $display("--------------------------------------------------");
            $display("               time: %d", $time);
            $display("--------------------------------------------------");
            $display("Output Valid: %b", out_valid);
            $display("Output Data:  %d", out_data);
            $display("**************************************************");
            $write("\033[0m");
            print_debug;
            $finish;
        end
    end endtask

    task wait_next_pattern; begin
        latency = 0;
        repeat (1+({$random(SEED)}%4)) @(negedge clk);
    end endtask

    task outrst_checker; begin
        // Check the output
        if ( out_valid!==1'b0 || out_data!==64'b0 ) begin
            $write("\033[31m");
            $display("**************************************************");
            $display("               OUTPUT RESET FAILED                ");
            $display("**************************************************");
            $display("     out_valid or out_data did not reset to 0");
            $display("--------------------------------------------------");
            $display("               time: %d", $time);
            $display("--------------------------------------------------");
            $display("Output Valid: %b", out_valid);
            $display("Output Data:  %b", out_data);
            $display("**************************************************");
            $write("\033[0m");
            print_debug;
            $finish;
        end
    end endtask

    always @(in_valid or out_valid) inout_overlap_checker;
    task inout_overlap_checker; begin
        if (in_valid === 1 && out_valid === 1) begin
            $write("\033[31m");
            $display("**************************************************");
            $display("               INPUT OUTPUT OVERLAP               ");
            $display("**************************************************");
            $display("       in_valid and out_valid are both 1");
            $display("--------------------------------------------------");
            $display("               time: %d", $time);
            $display("--------------------------------------------------");
            $display("Input Valid:  %b", in_valid);
            $display("Output Valid: %b", out_valid);
            $display("**************************************************");
            $write("\033[0m");
            print_debug;
            $finish;
        end
    end endtask
    
    always @(negedge clk) out_data_rst_checker;
    task out_data_rst_checker; begin
        if (out_valid === 0 && out_data !== 64'b0) begin
            $write("\033[31m");
            $display("**************************************************");
            $display("             OUTPUT DATA RESET FAILED             ");
            $display("**************************************************");
            $display("  out_data did not reset to 0 when out_valid is 0");
            $display("--------------------------------------------------");
            $display("               time: %d", $time);
            $display("--------------------------------------------------");
            $display("Output Valid: %b", out_valid);
            $display("Output Data:  %b", out_data);
            $display("**************************************************");
            $write("\033[0m");
            print_debug;
            $finish;
        end
    end endtask

    always @(latency) lantency_limit_exceed_checker;
    task lantency_limit_exceed_checker; begin
        if (latency > 2000) begin
            $write("\033[31m");
            $display("**************************************************");
            $display("              LATENCY LIMIT EXCEED                ");
            $display("**************************************************");
            $display("           Latency exceed 2000 cycles");
            $display("--------------------------------------------------");
            $display("               time: %d", $time);
            $display("--------------------------------------------------");
            $display("Latency: %d", latency);
            $display("**************************************************");
            $write("\033[0m");
            print_debug;
            $finish;
        end
    end endtask

    task print_debug; begin
        $write("\033[33m");
        $display("==================================================");
        $display("                   DEBUG INFO                     ");
        $display("==================================================");
        $display("Seed: %d", SEED);
        $display("Pattern Index: %d", pat_idx);
        $display("--------------------------------------------------");
        $display("T: %d", T_pattern);
        $display("");
        $display("Matrix X:");
        $display("       |   0   |   1   |   2   |   3   |   4   |   5   |   6   |   7   |");
        $display("    ---+-------+-------+-------+-------+-------+-------+-------+-------+");
        for (i = 0; i < T_pattern; i++) begin
            $display("     %1d | %5d | %5d | %5d | %5d | %5d | %5d | %5d | %5d |", i, matrix_X[i][0], matrix_X[i][1], matrix_X[i][2], matrix_X[i][3], matrix_X[i][4], matrix_X[i][5], matrix_X[i][6], matrix_X[i][7]);
            $display("    ---+-------+-------+-------+-------+-------+-------+-------+-------+");
        end
        $display("");
        $display("==================================================");
        $display("Matrix WQ:");
        $display("       |   0   |   1   |   2   |   3   |   4   |   5   |   6   |   7   |");
        $display("    ---+-------+-------+-------+-------+-------+-------+-------+-------+");
        for (i = 0; i < 8; i++) begin
            $display("     %1d | %5d | %5d | %5d | %5d | %5d | %5d | %5d | %5d |", i, matrix_WQ[i][0], matrix_WQ[i][1], matrix_WQ[i][2], matrix_WQ[i][3], matrix_WQ[i][4], matrix_WQ[i][5], matrix_WQ[i][6], matrix_WQ[i][7]);
            $display("    ---+-------+-------+-------+-------+-------+-------+-------+-------+");
        end
        $display("");
        $display("==================================================");
        $display("Matrix WK:");
        $display("       |   0   |   1   |   2   |   3   |   4   |   5   |   6   |   7   |");
        $display("    ---+-------+-------+-------+-------+-------+-------+-------+-------+");
        for (i = 0; i < 8; i++) begin
            $display("     %1d | %5d | %5d | %5d | %5d | %5d | %5d | %5d | %5d |", i, matrix_WK[i][0], matrix_WK[i][1], matrix_WK[i][2], matrix_WK[i][3], matrix_WK[i][4], matrix_WK[i][5], matrix_WK[i][6], matrix_WK[i][7]);
            $display("    ---+-------+-------+-------+-------+-------+-------+-------+-------+");
        end
        $display("");
        $display("==================================================");
        $display("Matrix WV:");
        $display("       |   0   |   1   |   2   |   3   |   4   |   5   |   6   |   7   |");
        $display("    ---+-------+-------+-------+-------+-------+-------+-------+-------+");
        for (i = 0; i < 8; i++) begin
            $display("     %1d | %5d | %5d | %5d | %5d | %5d | %5d | %5d | %5d |", i, matrix_WV[i][0], matrix_WV[i][1], matrix_WV[i][2], matrix_WV[i][3], matrix_WV[i][4], matrix_WV[i][5], matrix_WV[i][6], matrix_WV[i][7]);
            $display("    ---+-------+-------+-------+-------+-------+-------+-------+-------+");
        end
        $display("");
        $display("==================================================");
        $display("Matrix Q:");
        $display("       |    0    |    1    |    2    |    3    |    4    |    5    |    6    |    7    |");
        $display("    ---+---------+---------+---------+---------+---------+---------+---------+---------+");
        for (i = 0; i < T_pattern; i++) begin
            $display("     %1d | %7d | %7d | %7d | %7d | %7d | %7d | %7d | %7d |", i, matrix_Q[i][0], matrix_Q[i][1], matrix_Q[i][2], matrix_Q[i][3], matrix_Q[i][4], matrix_Q[i][5], matrix_Q[i][6], matrix_Q[i][7]);
            $display("    ---+---------+---------+---------+---------+---------+---------+---------+---------+");
        end
        $display("");
        $display("==================================================");
        $display("Matrix K:");
        $display("       |    0    |    1    |    2    |    3    |    4    |    5    |    6    |    7    |");
        $display("    ---+---------+---------+---------+---------+---------+---------+---------+---------+");
        for (i = 0; i < T_pattern; i++) begin
            $display("     %1d | %7d | %7d | %7d | %7d | %7d | %7d | %7d | %7d |", i, matrix_K[i][0], matrix_K[i][1], matrix_K[i][2], matrix_K[i][3], matrix_K[i][4], matrix_K[i][5], matrix_K[i][6], matrix_K[i][7]);
            $display("    ---+---------+---------+---------+---------+---------+---------+---------+---------+");
        end
        $display("");
        $display("==================================================");
        $display("Matrix V:");
        $display("       |    0    |    1    |    2    |    3    |    4    |    5    |    6    |    7    |");
        $display("    ---+---------+---------+---------+---------+---------+---------+---------+---------+");
        for (i = 0; i < T_pattern; i++) begin
            $display("     %1d | %7d | %7d | %7d | %7d | %7d | %7d | %7d | %7d |", i, matrix_V[i][0], matrix_V[i][1], matrix_V[i][2], matrix_V[i][3], matrix_V[i][4], matrix_V[i][5], matrix_V[i][6], matrix_V[i][7]);
            $display("    ---+---------+---------+---------+---------+---------+---------+---------+---------+");
        end
        $display("");
        $display("==================================================");
        $display("Matrix A:");
        $write("       |");
        for (i = 0; i < T_pattern; i++) begin
            $write("       %1d       |", i);
        end
        $display("");
        $write("    ---+");
        for (i = 0; i < T_pattern; i++) begin
            $write("---------------+");
        end
        $display("");
        for (i = 0; i < T_pattern; i++) begin
            $write("     %1d |", i);
            for (j = 0; j < T_pattern; j++) begin
                $write(" %13d |", matrix_A[i][j]);
            end
            $display("");
            $write("    ---+");
            for (j = 0; j < T_pattern; j++) begin
                $write("---------------+");
            end
            $display("");
        end
        $display("");
        $display("==================================================");
        $display("Matrix S:");
        $write("       |");
        for (i = 0; i < T_pattern; i++) begin
            $write("       %1d       |", i);
        end
        $display("");
        $write("    ---+");
        for (i = 0; i < T_pattern; i++) begin
            $write("---------------+");
        end
        $display("");
        for (i = 0; i < T_pattern; i++) begin
            $write("     %1d |", i);
            for (j = 0; j < T_pattern; j++) begin
                $write(" %13d |", matrix_S[i][j]);
            end
            $display("");
            $write("    ---+");
            for (j = 0; j < T_pattern; j++) begin
                $write("---------------+");
            end
            $display("");
        end
        $display("");
        $display("==================================================");
        $display("Matrix P:");
        $display("       |          0          |          1          |          2          |          3          |          4          |          5          |          6          |          7          |");
        $display("    ---+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+");
        for (i = 0; i < T_pattern; i++) begin
            $display("     %1d |%20d |%20d |%20d |%20d |%20d |%20d |%20d |%20d |", i, matrix_P[i][0], matrix_P[i][1], matrix_P[i][2], matrix_P[i][3], matrix_P[i][4], matrix_P[i][5], matrix_P[i][6], matrix_P[i][7]);
            $display("    ---+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+");
        end
        $display("");
        $display("==================================================");
        $display("Output Data:");
        $display("       |          0          |          1          |          2          |          3          |          4          |          5          |          6          |          7          |");
        $display("    ---+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+");
        for (i = 0; i < T_pattern; i++) begin
            $display("     %1d |%20d |%20d |%20d |%20d |%20d |%20d |%20d |%20d |", i, out_datar[i][0], out_datar[i][1], out_datar[i][2], out_datar[i][3], out_datar[i][4], out_datar[i][5], out_datar[i][6], out_datar[i][7]);
            $display("    ---+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+");
        end
        $display("");
        $display("==================================================");
        $write("\033[0m");
    end endtask

endmodule
