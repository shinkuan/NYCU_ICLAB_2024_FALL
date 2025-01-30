
`define CYCLE_TIME_clk1 4.1
`define CYCLE_TIME_clk2 10.1
`ifdef RTL
    `define CYCLE_TIME_clk1 4.1
    `define CYCLE_TIME_clk2 10.1
`endif
`ifdef GATE
    `define CYCLE_TIME_clk1 47.1
    `define CYCLE_TIME_clk2 10.1
`endif

`define RANDOM_SEED     // Comment this line to use fixed seed
`define SEED_NUMBER     3459874
`define PAT_NUM         1000

module PATTERN(
    clk1,
    clk2,
    rst_n,
    in_valid,
    in_row,
    in_kernel,
    out_valid,
    out_data
);

    //=========================================
    // Input & Output
    //=========================================
    output reg clk1, clk2;
    output reg rst_n;
    output reg in_valid;
    output reg [17:0] in_row;
    output reg [11:0] in_kernel;

    input out_valid;
    input [7:0] out_data;

    //=========================================
    // Clock
    //=========================================
    real CYCLE_clk1 = `CYCLE_TIME_clk1;
    real CYCLE_clk2 = `CYCLE_TIME_clk2;
    always #(CYCLE_clk1/2.0) clk1 = ~clk1; // @suppress
    always #(CYCLE_clk2/2.0) clk2 = ~clk2; // @suppress

    `ifdef RANDOM_SEED
    int  SEED           = get_time(); // @suppress
    `else
    int  SEED           = `SEED_NUMBER;
    `endif
    real PAT_NUM = `PAT_NUM;

    //=========================================
    // Parameter & integer
    //=========================================
    integer i, j, k; // @suppress
    integer latency;
    integer total_latency;

    //=========================================
    // Wire & Reg
    //=========================================
    reg  [2:0] matrix [5:0][5:0];       // [y][x]
    reg  [2:0] kernel [5:0][1:0][1:0];  // [k][y][x]
    reg  [7:0] golden [5:0][4:0][4:0];  // [k][y][x]
    reg  [7:0] outdat [5:0][4:0][4:0];  // [k][y][x]

    //=========================================
    // Design
    //=========================================
    initial begin
        `ifdef SHINKUAN
        $display("**************************************************");
        $display("            PATTERN MADE BY SHIN-KUAN             ");
        $display("**************************************************");
        `endif
        $write("\033[33m");                                             
        $display("██╗      █████╗ ██████╗  ██████╗ ███████╗");
        $display("██║     ██╔══██╗██╔══██╗██╔═████╗╚════██║");
        $display("██║     ███████║██████╔╝██║██╔██║    ██╔╝");
        $display("██║     ██╔══██║██╔══██╗████╔╝██║   ██╔╝ ");
        $display("███████╗██║  ██║██████╔╝╚██████╔╝   ██║  ");
        $display("╚══════╝╚═╝  ╚═╝╚═════╝  ╚═════╝    ╚═╝  ");
        $write("\033[0m");
        $write("\033[36m");
        $display("Seed: %d", SEED);
        $display("Pattern Number: %d", PAT_NUM);
        $write("\033[0m");
        $display("==================================================");
        reset;
        for (int i = 0; i < PAT_NUM; i++) begin
            generate_stimulus;
            send_input;
            wait_output;
            check_output;
            $write("\033[32m");
            $display("Pattern %d Pass. Latency: %d", i, latency);
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
        // internal signals
        latency = 0;
        total_latency = 0;

        // input signals
        force clk1      = 0;
        force clk2      = 0;
        rst_n           = 1;
        in_valid        = 0;
        in_row          = 'bX;
        in_kernel       = 'bX;
        #CYCLE_clk1;
        rst_n = 0;
        #(3*CYCLE_clk1);
        rst_n = 1;
        outrst_checker;
        #CYCLE_clk1;
        release clk1;
        release clk2;
        repeat (2) @(negedge clk1);
    end endtask

    task generate_stimulus; begin
        for (int y = 0; y < 6; y++) begin
            for (int x = 0; x < 6; x++) begin
                matrix[y][x] = {$random(SEED)} % 8;
            end
        end
        for (int k = 0; k < 6; k++) begin
            for (int y = 0; y < 2; y++) begin
                for (int x = 0; x < 2; x++) begin
                    kernel[k][y][x] = {$random(SEED)} % 8;
                end
            end
        end

        for (int k = 0; k < 6; k++) begin
            for (int y = 0; y < 5; y++) begin
                for (int x = 0; x < 5; x++) begin
                    golden[k][y][x] = 0;
                    for (int i = 0; i < 2; i++) begin
                        for (int j = 0; j < 2; j++) begin
                            golden[k][y][x] += matrix[y+i][x+j] * kernel[k][i][j];
                        end
                    end
                end
            end
        end
    end endtask

    task send_input; begin
        in_valid = 1;
        for (int i = 0; i < 6; i++) begin
            in_row = {matrix[i][5], matrix[i][4], matrix[i][3], matrix[i][2], matrix[i][1], matrix[i][0]};
            in_kernel = {kernel[i][1][1], kernel[i][1][0], kernel[i][0][1], kernel[i][0][0]};
            @(negedge clk1);
        end
        in_valid = 0;
        in_row = 'bX;
        in_kernel = 'bX;
    end endtask

    task wait_output; begin
        integer out_count;

        out_count = 0;
        while (out_count < 5*5*6) begin
            @(negedge clk1);
            latency++;

            if (out_valid === 'b1) begin
                outdat[out_count/25][(out_count%25)/5][out_count%5] = out_data;
                out_count++;
            end
        end
    end endtask

    task wait_next_pattern; begin
        total_latency += latency;
        latency = 0;
        repeat (1+({$random(SEED)}%3)) @(negedge clk1);
    end endtask

    task check_output; begin
        for (int k = 0; k < 6; k++) begin
            for (int y = 0; y < 5; y++) begin
                for (int x = 0; x < 5; x++) begin
                    if (outdat[k][y][x] !== golden[k][y][x]) begin
                        $write("\033[31m");
                        $display("**************************************************");
                        $display("               OUTPUT DATA MISMATCH               ");
                        $display("**************************************************");
                        $display("     outdat[%1d][%1d][%1d] != golden[%1d][%1d][%1d]", k, y, x, k, y, x);
                        $display("--------------------------------------------------");
                        $display("               time: %d", $time);
                        $display("--------------------------------------------------");
                        $display("Output Data:  %b", outdat[k][y][x]);
                        $display("Golden Data:  %b", golden[k][y][x]);
                        $display("**************************************************");
                        $write("\033[0m");
                        print_debug;
                        $finish;
                    end
                end
            end
        end
    end endtask
    
    task outrst_checker; begin
        // Check the output
        if ( out_valid!==1'b0 || out_data!==8'b0 ) begin
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
    
    always @(negedge clk1) out_data_rst_checker;
    task out_data_rst_checker; begin
        if (out_valid === 0 && out_data !== 8'b0) begin
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
        if (latency > 5000) begin
            $write("\033[31m");
            $display("**************************************************");
            $display("              LATENCY LIMIT EXCEED                ");
            $display("**************************************************");
            $display("           Latency exceed 5000 cycles");
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
        $display("**************************************************");
        $display("                 DEBUG INFORMATION                ");
        $display("**************************************************");
        $display("               time: %d", $time);
        $display("--------------------------------------------------");
        $display("Output Valid: %b", out_valid);
        $display("Output Data:  %b", out_data);
        $display("--------------------------------------------------");
        $display("Matrix:");
        $display("       | 0 | 1 | 2 | 3 | 4 | 5 |");
        $display("    ---+---+---+---+---+---+---+");
        for (int i = 0; i < 6; i++) begin
            $display("     %1d | %1d | %1d | %1d | %1d | %1d | %1d |", i, matrix[i][0], matrix[i][1], matrix[i][2], matrix[i][3], matrix[i][4], matrix[i][5]);
            $display("    ---+---+---+---+---+---+---+");
        end
        $display("");
        $display("--------------------------------------------------");
        for (int i = 0; i < 6; i++) begin
            $display("Kernel[%1d]:", i);
            $display("       | 0 | 1 |");
            $display("    ---+---+---+");
            $display("     0 | %1d | %1d |", kernel[i][0][0], kernel[i][0][1]);
            $display("    ---+---+---+");
            $display("     1 | %1d | %1d |", kernel[i][1][0], kernel[i][1][1]);
            $display("    ---+---+---+");
            $display("");
            $display("Golden[%1d]:", i);
            $display("       |  0  |  1  |  2  |  3  |  4  |");
            $display("    ---+-----+-----+-----+-----+-----+");
            for (int j = 0; j < 5; j++) begin
                $display("     %1d | %3d | %3d | %3d | %3d | %3d |", j, golden[i][j][0], golden[i][j][1], golden[i][j][2], golden[i][j][3], golden[i][j][4]);
                $display("    ---+-----+-----+-----+-----+-----+");
            end
            $display("");
            $display("Output[%1d]:", i);
            $display("       |  0  |  1  |  2  |  3  |  4  |");
            $display("    ---+-----+-----+-----+-----+-----+");
            for (int j = 0; j < 5; j++) begin
                $display("     %1d | %3d | %3d | %3d | %3d | %3d |", j, outdat[i][j][0], outdat[i][j][1], outdat[i][j][2], outdat[i][j][3], outdat[i][j][4]);
                $display("    ---+-----+-----+-----+-----+-----+");
            end
            $display("");
            $display("--------------------------------------------------");
        end
        $display("**************************************************");
        $write("\033[0m");
    end endtask


endmodule