`define CYCLE_TIME 7.4
`ifdef RTL
    `define CYCLE_TIME 7.4
`endif
`ifdef GATE
    `define CYCLE_TIME 7.4
`endif

// `define USE_DIRECT      // Define this line to use direct testing
// `define CORNER_CASE     // Define this line to test corner case
// `define CORNER_CASE_2    // Define this line to test corner case 2
`define RANDOM_SEED     // Comment this line to use fixed seed
`define SEED_NUMBER     3459874
`define PATTERN_NUMBER  1000000

module PATTERN(
    // Output signals
    clk,
	rst_n,
	in_valid,
    in_data, 
	in_mode,
    // Input signals
    out_valid, 
	out_data
);

    //=========================================
    // Input & Output
    //=========================================
    output reg clk, rst_n, in_valid;
    output reg [8:0] in_mode;
    output reg [14:0] in_data;

    input out_valid;
    input [206:0] out_data;

    //=========================================
    // Clock
    //=========================================
    real CYCLE = `CYCLE_TIME;
    always #(CYCLE/2.0) clk = ~clk; // @suppress

    `ifdef RANDOM_SEED
    int  SEED           = get_time(); // @suppress
    `else
    int  SEED           = `SEED_NUMBER;
    `endif
    `ifdef USE_DIRECT
    real PATTERN_NUM    = 1005;
    `elsif CORNER_CASE_2
    real PATTERN_NUM    = 196608;
    `else
    real PATTERN_NUM    = `PATTERN_NUMBER;
    `endif

    //=========================================
    // Parameter & integer
    //=========================================
    integer i, j, k; // @suppress
    integer latency;
    integer total_latency;

    integer input_file;
    integer input_file_mode;


    //=========================================
    // Wire & Reg
    //=========================================
    reg signed [10:0] matrix    [3:0][3:0];
    reg [1:15] matrix_encoded   [3:0][3:0];
    reg [4:0 ] mode;
    reg [1:9 ] mode_encoded;

    logic signed [ 22:0] case1 [2:0][2:0];
    logic signed [ 50:0] case2 [1:0][1:0];

    reg signed [206:0] out_data_golden;

    reg [16:0] corner_counter;

    //=========================================
    // Design
    //=========================================
    initial begin
        `ifdef SHINKUAN
        $display("**************************************************");
        $display("            PATTERN MADE BY SHIN-KUAN             ");
        $display("**************************************************");
        `endif
        $display("\033[33m██╗      █████╗ ██████╗      ██████╗  ██████╗ \033[0m");
        $display("\033[33m██║     ██╔══██╗██╔══██╗    ██╔═████╗██╔════╝ \033[0m");
        $display("\033[33m██║     ███████║██████╔╝    ██║██╔██║███████╗ \033[0m");
        $display("\033[33m██║     ██╔══██║██╔══██╗    ████╔╝██║██╔═══██╗\033[0m");
        $display("\033[33m███████╗██║  ██║██████╔╝    ╚██████╔╝╚██████╔╝\033[0m");
        $display("\033[33m╚══════╝╚═╝  ╚═╝╚═════╝      ╚═════╝  ╚═════╝ \033[0m");
        $display("\033[32mSeed: %d\033[0m", SEED);
        $display("\033[32mPattern Number: %d\033[0m", PATTERN_NUM);
        $display("==================================================");
        open_file;
        reset;
        for (i = 0; i < PATTERN_NUM; i = i + 1) begin
            generate_input;
            calculate_golden;
            send_input;
            wait_output;
            check_output;
            $display("\033[32m[Pattern %d] Latency: %d\033[0m", i, latency);
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

    task debug_print; begin
        $display("\033[36m");
        $display("**************************************************");
        $display("                  DEBUG OUTPUT                    ");
        $display("**************************************************");
        case (mode)
            5'b00100: $display("Mode: 2x2 Determinant");
            5'b00110: $display("Mode: 3x3 Determinant");
            5'b10110: $display("Mode: 4x4 Determinant");
            default: $display("Mode: %b", mode);
        endcase
        $display("--------------------------------------------------");
        $display("Matrix:");
        $display("   |   0  |   1  |   2  |   3  |");
        $display("---+------+------+------+------+");
        $display(" 0 | %4d | %4d | %4d | %4d |", matrix[0][0], matrix[0][1], matrix[0][2], matrix[0][3]);
        $display("---+------+------+------+------+");
        $display(" 1 | %4d | %4d | %4d | %4d |", matrix[1][0], matrix[1][1], matrix[1][2], matrix[1][3]);
        $display("---+------+------+------+------+");
        $display(" 2 | %4d | %4d | %4d | %4d |", matrix[2][0], matrix[2][1], matrix[2][2], matrix[2][3]);
        $display("---+------+------+------+------+");
        $display(" 3 | %4d | %4d | %4d | %4d |", matrix[3][0], matrix[3][1], matrix[3][2], matrix[3][3]);
        $display("---+------+------+------+------+");
        $display("==================================================");
        case (mode)
            5'b00100: begin
                $display("2x2 Determinant:");
                $display("   |    0    |    1    |    2    |");
                $display("---+---------+---------+---------+");
                $display(" 0 | %7d | %7d | %7d |", case1[0][0], case1[0][1], case1[0][2]);
                $display("---+---------+---------+---------+");
                $display(" 1 | %7d | %7d | %7d |", case1[1][0], case1[1][1], case1[1][2]);
                $display("---+---------+---------+---------+");
                $display(" 2 | %7d | %7d | %7d |", case1[2][0], case1[2][1], case1[2][2]);
                $display("---+---------+---------+---------+");
            end
            5'b00110: begin
                $display("3x3 Determinant:");
                $display("   |      0      |      1      |");
                $display("---+-------------+-------------+");
                $display(" 0 | %11d | %11d |", case2[0][0], case2[0][1]);
                $display("---+-------------+-------------+");
                $display(" 1 | %11d | %11d |", case2[1][0], case2[1][1]);
                $display("---+-------------+-------------+");
            end
            5'b10110: begin
                $display("4x4 Determinant:");
                $display("   |           0          |");
                $display("---+----------------------+");
                $display(" 0 | %20d |", out_data_golden);
                $display("---+----------------------+");
            end
            default: $display("Mode: %b", mode);
        endcase
        $display("**************************************************");
        $display("\033[0m");
    end endtask

    task open_file; begin
        `ifdef USE_DIRECT
        input_file = $fopen("../00_TESTBED/shinkuan_in0.txt", "r");
        `else
        input_file = 0;
        `endif
        input_file_mode = 0;
    end endtask

    task reset; begin
        // internal signals
        latency = 0;
        total_latency = 0;
        corner_counter = 0;

        // input signals
        force clk   = 0;
        rst_n       = 1'b1;
        in_valid    = 1'b0;
        in_data     = 15'bX;
        in_mode     = 9'bX;
        #`CYCLE_TIME;
        rst_n = 0;
        #(3*`CYCLE_TIME);
        rst_n = 1;
        spec7_checker;
        #`CYCLE_TIME;
        release clk;
        repeat (2) @(negedge clk);
    end endtask

    task spec7_checker; begin
        // Check the output
        if ( out_valid!==1'b0 || out_data!==207'b0 ) begin
            $display("\033[31m");
            $display("**************************************************");
            $display("                SPEC7 CHECK FAILED                ");
            $display("**************************************************");
            $display("     out_valid or out_data did not reset to 0");
            $display("--------------------------------------------------");
            $display("               time: %d", $time);
            $display("--------------------------------------------------");
            $display("Output Valid: %b", out_valid);
            $display("Output Data:  %b", out_data);
            $display("**************************************************");
            $display("\033[0m");
            debug_print;
            $finish;
        end
    end endtask

    always @(latency) spec3_checker;
    task spec3_checker; begin
        if (latency > 1000) begin
            $display("\033[31m");
            $display("**************************************************");
            $display("                SPEC3 CHECK FAILED                ");
            $display("**************************************************");
            $display("         The latency exceeds 1000 cycles");
            $display("--------------------------------------------------");
            $display("               time: %d", $time);
            $display("--------------------------------------------------");
            $display("Latency: %d", latency);
            $display("**************************************************");
            $display("\033[0m");
            debug_print;
            $finish;
        end
    end endtask
        
    always @(negedge clk) spec11_checker;
    task spec11_checker; begin
        if (in_valid === 1'b1 && out_valid === 1'b1) begin
            $display("\033[31m");
            $display("**************************************************");
            $display("                SPEC11 CHECK FAILED               ");
            $display("**************************************************");
            $display("     in_valid and out_valid should not be high");
            $display("     at the same time");
            $display("--------------------------------------------------");
            $display("               time: %d", $time);
            $display("--------------------------------------------------");
            $display("in_valid:  %b", in_valid);
            $display("out_valid: %b", out_valid);
            $display("**************************************************");
            $display("\033[0m");
            debug_print;
            $finish;
        end
    end endtask

    // always @(negedge clk) spec12_checker;
    // task spec12_checker; begin
    //     if (out_valid === 1'b0 && out_data !== 207'b0) begin
    //         $display("\033[31m");
    //         $display("**************************************************");
    //         $display("                SPEC12 CHECK FAILED               ");
    //         $display("**************************************************");
    //         $display("     out_data should be 0 when out_valid is 0");
    //         $display("--------------------------------------------------");
    //         $display("               time: %d", $time);
    //         $display("--------------------------------------------------");
    //         $display("out_valid: %b", out_valid);
    //         $display("out_data:  %b", out_data);
    //         $display("**************************************************");
    //         $display("\033[0m");
    //         debug_print;
    //         $finish;
    //     end
    // end endtask

    task generate_input; begin
        integer i, j, k, l;

        for (i = 0; i < 4; i = i + 1) begin
            for (j = 0; j < 4; j = j + 1) begin
                `ifdef USE_DIRECT
                if (input_file_mode == 0) begin
                    $fscanf(input_file, "%d", matrix[i][j]);
                end
                `elsif CORNER_CASE
                case ({$random(SEED)} % 2)
                    0: matrix[i][j] = -1024;
                    1: matrix[i][j] = 1023;
                    // 2: matrix[i][j] = 0;
                    default: $display("\033[31mError: matrix[%0d][%0d] = %d\033[0m", i, j, matrix[i][j]);
                endcase
                `elsif CORNER_CASE_2
                if (corner_counter[i*4+j] == 0) begin
                    matrix[i][j] = 1023;
                end else begin
                    matrix[i][j] = -1024;
                end
                `else
                matrix[i][j] = {$random(SEED)} % 2048;
                `endif
                matrix_encoded[i][j] = {
                    1'b0, // parity[0]
                    1'b0, // parity[1]
                    matrix[i][j][10],
                    1'b0, // parity[2]
                    matrix[i][j][9:7],
                    1'b0, // parity[3]
                    matrix[i][j][6:0]
                };

                // Calculate parity
                for (k = 0; k < 16; k = k + 1) begin
                    if (k[0]) matrix_encoded[i][j][1] = matrix_encoded[i][j][1] ^ matrix_encoded[i][j][k];
                    if (k[1]) matrix_encoded[i][j][2] = matrix_encoded[i][j][2] ^ matrix_encoded[i][j][k];
                    if (k[2]) matrix_encoded[i][j][4] = matrix_encoded[i][j][4] ^ matrix_encoded[i][j][k];
                    if (k[3]) matrix_encoded[i][j][8] = matrix_encoded[i][j][8] ^ matrix_encoded[i][j][k];
                end

                // Randomly flip a bit
                if ({$random(SEED)}%2 == 1) begin
                    k = 1+({$random(SEED)} % (15)); // 1 ~ 15
                    matrix_encoded[i][j][k] = ~matrix_encoded[i][j][k];
                end
            end
        end

        `ifdef USE_DIRECT
        i = input_file_mode;
        input_file_mode = (input_file_mode + 1) % 3;
        `elsif CORNER_CASE_2
        i = input_file_mode;
        if (input_file_mode == 2) begin
            corner_counter = corner_counter + 1;
        end
        input_file_mode = (input_file_mode + 1) % 3;
        `else
        i = {$random(SEED)} % 3;
        `endif
        case (i)
            0: mode = 5'b00100;
            1: mode = 5'b00110;
            2: mode = 5'b10110;
            default: $display("\033[31mError: mode = %b\033[0m", mode);
        endcase
        // mode_encoded = {
        //     mode[4],
        //     1'b0, // parity[3]
        //     mode[3:1],
        //     1'b0, // parity[2]
        //     mode[0],
        //     1'b0, // parity[1]
        //     1'b0, // parity[0]
        //     1'b0
        // };
        mode_encoded = {
            1'b0, // parity[0]
            1'b0, // parity[1]
            mode[4],
            1'b0, // parity[2]
            mode[3:1],
            1'b0, // parity[3]
            mode[0]
        };

        // Calculate parity
        for (k = 0; k < 10; k = k + 1) begin
            if (k[0]) mode_encoded[1] = mode_encoded[1] ^ mode_encoded[k];
            if (k[1]) mode_encoded[2] = mode_encoded[2] ^ mode_encoded[k];
            if (k[2]) mode_encoded[4] = mode_encoded[4] ^ mode_encoded[k];
            if (k[3]) mode_encoded[8] = mode_encoded[8] ^ mode_encoded[k];
        end

        // Randomly flip a bit
        if ({$random(SEED)}%2 == 1) begin
            k = 1+({$random(SEED)} % (9)); // 1 ~ 9
            mode_encoded[k] = ~mode_encoded[k];
        end

    end endtask

    task calculate_golden; begin
        integer i, j;

        case (mode)
            5'b00100: begin
                for (i = 0; i < 3; i = i + 1) begin
                    for (j = 0; j < 3; j = j + 1) begin
                        case1[i][j] = matrix[i][j] * matrix[i+1][j+1] - matrix[i][j+1] * matrix[i+1][j];
                    end
                end
                out_data_golden = {
                    case1[0][0][22:0], case1[0][1][22:0], case1[0][2][22:0],
                    case1[1][0][22:0], case1[1][1][22:0], case1[1][2][22:0],
                    case1[2][0][22:0], case1[2][1][22:0], case1[2][2][22:0]
                };
            end
            5'b00110: begin
                for (i = 0; i < 2; i = i + 1) begin
                    for (j = 0; j < 2; j = j + 1) begin
                        case2[i][j] = matrix[i  ][j  ] * matrix[i+1][j+1] * matrix[i+2][j+2]
                                    + matrix[i  ][j+1] * matrix[i+1][j+2] * matrix[i+2][j  ]
                                    + matrix[i  ][j+2] * matrix[i+1][j  ] * matrix[i+2][j+1]
                                    - matrix[i  ][j+2] * matrix[i+1][j+1] * matrix[i+2][j  ]
                                    - matrix[i  ][j  ] * matrix[i+1][j+2] * matrix[i+2][j+1]
                                    - matrix[i  ][j+1] * matrix[i+1][j  ] * matrix[i+2][j+2];
                    end
                end
                out_data_golden = {
                    3'b0,
                    case2[0][0][50:0], case2[0][1][50:0],
                    case2[1][0][50:0], case2[1][1][50:0]
                };
            end
            5'b10110: begin
                logic signed [51:0] M11, M12, M13, M14;
            
                M11 = matrix[1][1]*(matrix[2][2]*matrix[3][3] - matrix[2][3]*matrix[3][2]) 
                    - matrix[1][2]*(matrix[2][1]*matrix[3][3] - matrix[2][3]*matrix[3][1]) 
                    + matrix[1][3]*(matrix[2][1]*matrix[3][2] - matrix[2][2]*matrix[3][1]);
            
                M12 = matrix[1][0]*(matrix[2][2]*matrix[3][3] - matrix[2][3]*matrix[3][2]) 
                    - matrix[1][2]*(matrix[2][0]*matrix[3][3] - matrix[2][3]*matrix[3][0]) 
                    + matrix[1][3]*(matrix[2][0]*matrix[3][2] - matrix[2][2]*matrix[3][0]);
            
                M13 = matrix[1][0]*(matrix[2][1]*matrix[3][3] - matrix[2][3]*matrix[3][1]) 
                    - matrix[1][1]*(matrix[2][0]*matrix[3][3] - matrix[2][3]*matrix[3][0]) 
                    + matrix[1][3]*(matrix[2][0]*matrix[3][1] - matrix[2][1]*matrix[3][0]);
            
                M14 = matrix[1][0]*(matrix[2][1]*matrix[3][2] - matrix[2][2]*matrix[3][1]) 
                    - matrix[1][1]*(matrix[2][0]*matrix[3][2] - matrix[2][2]*matrix[3][0]) 
                    + matrix[1][2]*(matrix[2][0]*matrix[3][1] - matrix[2][1]*matrix[3][0]);
            
                out_data_golden = matrix[0][0]*M11 - matrix[0][1]*M12 + matrix[0][2]*M13 - matrix[0][3]*M14;
            end
            default: $display("\033[31mError: mode = %b\033[0m", mode);
        endcase
    end endtask

    task send_input; begin
        integer i, j;
        in_valid = 1'b1;
        fork
            begin
                for (i = 0; i < 4; i = i + 1) begin
                    for (j = 0; j < 4; j = j + 1) begin
                        in_data = matrix_encoded[i][j][1:15];
                        @(negedge clk);
                    end
                end
                in_data = 15'bX;
            end
            begin
                in_mode = mode_encoded[1:9];
                @(negedge clk);
                in_mode = 9'bX;
            end
        join
        in_valid = 1'b0;
    end endtask

    task wait_output; begin
        latency = 0;
        while (out_valid === 1'b0) begin
            latency = latency + 1;
            @(negedge clk);
        end
        total_latency = total_latency + latency;
    end endtask

    task check_output; begin
        if (out_valid === 1'b1) begin
            spec15_checker;
        end else begin
            $display("\033[31mError: out_valid should be high\033[0m");
            debug_print;
            $finish;
        end
    end endtask

    task spec15_checker; begin
        if (out_data !== out_data_golden) begin
            $display("\033[31m");
            $display("**************************************************");
            $display("                SPEC15 CHECK FAILED               ");
            $display("**************************************************");
            $display("     out_data is not equal to out_data_golden");
            $display("--------------------------------------------------");
            $display("               time: %d", $time);
            $display("--------------------------------------------------");
            $display("out_data:        %b", out_data);
            $display("out_data_golden: %b", out_data_golden);
            $display("**************************************************");
            $display("\033[0m");
            debug_print;
            $finish;
        end
    end endtask

    task wait_next_pattern; begin
        integer i, j;
        // wait for 2~4 cycles
        i = 1 + {$random(SEED)} % 3;
        @(negedge clk);
        for (j = 0; j < i; j = j + 1) begin
            specx1_checker;
            @(negedge clk);
        end
    end endtask

    task specx1_checker; begin
        if (out_valid === 1'b1) begin
            $display("\033[31m");
            $display("**************************************************");
            $display("                SPECX1 CHECK FAILED               ");
            $display("**************************************************");
            $display("   out_valid should be high for only one cycle");
            $display("--------------------------------------------------");
            $display("               time: %d", $time);
            $display("--------------------------------------------------");
            $display("out_valid: %b", out_valid);
            $display("out_data:  %b", out_data);
            $display("**************************************************");
            $display("\033[0m");
            debug_print;
            $finish;
        end
    end endtask
                
endmodule