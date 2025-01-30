`define CYCLE_TIME 3.0
`ifdef RTL
    `define CYCLE_TIME 3.0
`endif
`ifdef GATE
    `define CYCLE_TIME 3.0
`endif
`define RANDOM_SEED     // Comment this line to use fixed seed
`define S33D_4UM     194188766
`define PAT_NUM         1000

`include "../00_TESTBED/pseudo_DRAM.v"

module PATTERN(
    // Input Signals
    clk,
    rst_n,
    in_valid,
    in_pic_no,
    in_mode,
    in_ratio_mode,
    out_valid,
    out_data
);

    //=========================================
    // Input & Output
    //=========================================
    output reg        clk, rst_n;
    output reg        in_valid;

    output reg [3:0] in_pic_no;
    output reg [1:0] in_mode;
    output reg [1:0] in_ratio_mode;

    input out_valid;
    input [7:0] out_data;

    //=========================================
    // Clock
    //=========================================
    real CYCLE = `CYCLE_TIME;
    real PAT_NUM = `PAT_NUM;
    always #(CYCLE/2.0) clk = ~clk; // @suppress

    `ifdef RANDOM_SEED
    int  S33d           = get_time(); // @suppress
    `else
    int  S33d           = `S33D_4UM;
    `endif

    real PIC_NUMBER = 16;

    //=========================================
    // Parameter & integer
    //=========================================
    integer i, j, k; // @suppress
    integer latency;
    integer total_latency;

    //=========================================
    // Wire & Reg
    //=========================================
    reg [7:0] dram_data [0:196607];
    reg [7:0] gray_data [31:0][31:0];
    reg [7:0] golden;
    integer D_contrast_sum [3:0];
    integer exposure_sum;
    reg [7:0] max_r, min_r, max_g, min_g, max_b, min_b;
    reg [7:0] max, min;
    reg [7:0] avg;

    reg [3:0] sent_pic_no;
    reg [1:0] sent_mode;
    reg [1:0] sent_ratio;

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
        $display("███╗   ███╗██╗██████╗ ████████╗███████╗██████╗ ███╗   ███╗");
        $display("████╗ ████║██║██╔══██╗╚══██╔══╝██╔════╝██╔══██╗████╗ ████║");
        $display("██╔████╔██║██║██║  ██║   ██║   █████╗  ██████╔╝██╔████╔██║");
        $display("██║╚██╔╝██║██║██║  ██║   ██║   ██╔══╝  ██╔══██╗██║╚██╔╝██║");
        $display("██║ ╚═╝ ██║██║██████╔╝   ██║   ███████╗██║  ██║██║ ╚═╝ ██║");
        $display("╚═╝     ╚═╝╚═╝╚═════╝    ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝");
        $write("\033[36m");
        $display("Seed: %d", S33d);
        $write("\033[0m");
        $display("==================================================");
        reset;
        read_dram;
        for (int i = 0; i < PAT_NUM; i++) begin
            sent_mode = {$random(S33d)} % 3;
            sent_pic_no = {$random(S33d)} % 16;
            sent_ratio = {$random(S33d)} % 4;
            send_input(sent_pic_no, sent_ratio, sent_mode);
            calculate_golden(sent_pic_no, sent_ratio, sent_mode);
            wait_output;
            check_output(sent_pic_no, sent_ratio, sent_mode);
            $write("\033[32m");
            $display("Pattern %d, Pic_no %2d, Mode %1d, Ratio %1d: Pass. Latency: %d", i, sent_pic_no, sent_mode, sent_ratio, latency);
            $write("\033[0m");
            wait_next_pattern;
        end
        $display("\033[32m");
        $display("**************************************************");
        $display("                 ALL PATTERN PASS                 ");
        $display("**************************************************");
        // $display("               SEED: %d", S33d);
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
        force clk       = 0;
        rst_n           = 1'b1;
        in_valid        = 1'b0;
        in_pic_no       = 4'bX;
        in_mode         = 2'bX;
        in_ratio_mode   = 2'bX;
        #`CYCLE_TIME;
        rst_n = 0;
        #(3*`CYCLE_TIME);
        rst_n = 1;
        spec7_checker;
        #`CYCLE_TIME;
        release clk;
        repeat (2) @(negedge clk);
    end endtask

    task read_dram; begin
        $readmemh(`d_DRAM_p_r, dram_data);
    end endtask
    
    task calculate_golden; 
        input [3:0] pic_no;
        input [1:0] ratio;
        input [1:0] mode;  
    begin
        reg [8:0] _diff;
        reg [7:0] diff;
        reg [31:0] D_contrast [3:0];
        reg [7:0] color;
        reg [9:0] color_exposure;
        reg [31:0] exposure_pic_avg;
        reg [7:0] _max, _min;
        integer addr;
        integer k;

        for (int y = 0; y < 32; y++) begin
            for (int x = 0; x < 32; x++) begin
                gray_data[y][x] = 0;
                for (int c = 0; c < 3; c++) begin
                    addr = 32'h10000+pic_no*32*32*3+c*32*32+y*32+x;
                    if (c == 1) begin
                        gray_data[y][x] = gray_data[y][x] + (dram_data[addr] >> 1);
                    end else begin
                        gray_data[y][x] = gray_data[y][x] + (dram_data[addr] >> 2);
                    end
                end
            end
        end
        if (mode == 2'b01) begin
            for (int s = -2; s < 2; s++) begin // exposure
                exposure_pic_avg = 0;
                for (int y = 0; y < 32; y++) begin
                    for (int x = 0; x < 32; x++) begin
                        color_exposure = 0;
                        for (int c = 0; c < 3; c++) begin
                            addr = 32'h10000+pic_no*32*32*3+c*32*32+y*32+x;
                            color = dram_data[addr];
                            if (c == 0) begin // R
                                color = color >> 2;
                            end else
                            if (c == 1) begin
                                color = color >> 1;
                            end else
                            if (c == 2) begin
                                color = color >> 2;
                            end
                            color_exposure += color;
                        end
                        exposure_pic_avg += color_exposure;
                    end
                end
                k = s+2;
                exposure_sum = exposure_pic_avg;
                exposure_pic_avg = exposure_pic_avg >> 10;
                golden = exposure_pic_avg[7:0];
            end
        end else
        if (mode == 2'b00) begin
            for (int i = 0; i < 4; i++) D_contrast[i] = 0;
            for (int h = 3; h > 0; h--) begin
                for (int y = 16-h; y < 16+h; y++) begin
                    for (int x = 16-h; x < 16+h-1; x++) begin
                        _diff = gray_data[y][x] - gray_data[y][x+1];
                        _diff = {1'b0, {8{_diff[8]}}} ^ _diff[8:0];
                        diff = _diff[8]? (_diff[7:0]+1) : _diff[7:0];
                        D_contrast[h-1] = D_contrast[h-1] + diff;
                    end 
                end
                for (int y = 16-h; y < 16+h-1; y++) begin
                    for (int x = 16-h; x < 16+h; x++) begin
                        _diff = gray_data[y][x] - gray_data[y+1][x];
                        _diff = {1'b0, {8{_diff[8]}}} ^ _diff[8:0];
                        diff = _diff[8]? (_diff[7:0]+1) : _diff[7:0];
                        D_contrast[h-1] = D_contrast[h-1] + diff;
                    end
                end
                D_contrast_sum[h-1] = D_contrast[h-1];
                D_contrast[h-1] = D_contrast[h-1] / (h*h*4);
            end
            if (
                D_contrast[0] >= D_contrast[2] &&
                D_contrast[0] >= D_contrast[1]
            ) golden = 0;
            else if (
                D_contrast[1] >= D_contrast[2] &&
                D_contrast[1] >= D_contrast[0]
            ) golden = 1;
            else if (
                D_contrast[2] >= D_contrast[0] &&
                D_contrast[2] >= D_contrast[1]
            ) golden = 2;
        end else
        if (mode == 2'b10) begin
            for (int c = 0; c < 3; c++) begin
                _max = 0;
                _min = 255;
                for (int y = 0; y < 32; y++) begin
                    for (int x = 0; x < 32; x++) begin
                        addr = 32'h10000+pic_no*32*32*3+c*32*32+y*32+x;
                        color = dram_data[addr];
                        if (color > _max) _max = color;
                        if (color < _min) _min = color;
                    end
                end
                case (c)
                    0: begin
                        max_r = _max;
                        min_r = _min;
                    end
                    1: begin
                        max_g = _max;
                        min_g = _min;
                    end
                    2: begin
                        max_b = _max;
                        min_b = _min;
                    end
                    default: begin
                        $display("Error: c = %d", c);
                    end
                endcase
            end
            max = (max_r + max_g + max_b) / 3;
            min = (min_r + min_g + min_b) / 3;
            avg = (max + min) / 2;
            golden = avg;
        end
    end endtask

    task send_input; 
        input [3:0] pic_no;
        input [1:0] ratio;
        input [1:0] mode;    
    begin
        integer addr;
        reg [8:0] _color;
        reg [7:0] color;

        in_valid = 1'b1;
        in_pic_no = pic_no;
        in_mode = mode;
        if (mode == 2'b01) begin
            in_ratio_mode = ratio;            
        end else begin
            in_ratio_mode = 2'bX;
        end
        @(negedge clk);
        in_valid = 1'b0;
        in_pic_no = 4'bX;
        in_mode = 2'bX;
        in_ratio_mode = 2'bX;
        if (mode == 2'b01) begin
            for (int y = 0; y < 32; y++) begin
                for (int x = 0; x < 32; x++) begin
                    for (int c = 0; c < 3; c++) begin
                        addr = 32'h10000+pic_no*32*32*3+c*32*32+y*32+x;
                        if (ratio == 'd3) begin
                            _color = dram_data[addr] << 1;
                        end else begin
                            _color = dram_data[addr] >> (2-ratio);
                        end
                        color = _color[8] ? 8'hFF : _color[7:0];
                        dram_data[addr] = color;
                    end
                end
            end
        end
    end endtask

    task wait_output; begin
        latency = 0;
        while (out_valid === 1'b0) begin
            latency = latency + 1;
            if (latency > 10000) begin
                $write("\033[31m");
                $display("**************************************************");
                $display("                       FAILED                     ");
                $display("              LANTENCY LIMIT EXCEEDED             ");
                $display("**************************************************");
                $display("              Lantency exceeded 10000");
                $display("--------------------------------------------------");
                $display("               time: %d", $time);
                $display("--------------------------------------------------");
                $display("**************************************************");
                $write("\033[0m");
                print_debug;
                $finish;
            end
            @(negedge clk);
        end
        total_latency = total_latency + latency;
    end endtask
    
    task check_output; 
        input [3:0] pic_no;
        input [1:0] ratio;
        input [1:0] mode;    
    begin
        if (out_valid === 1'b1) begin
            if (out_data !== golden) begin
                $write("\033[31m");
                $display("**************************************************");
                $display("                OUTPUT CHECK FAILED               ");
                $display("**************************************************");
                $display("              out_data is not correct");
                $display("--------------------------------------------------");
                $display("               time: %d", $time);
                $display("--------------------------------------------------");
                $display("mode:      %b", mode);
                $display("pic_no:    %d", pic_no);
                $display("ratio:     %d", mode == 2'b01 ? ratio : 2'bX);
                $display("--------------------------------------------------");
                $display("out_data:  %d", out_data);
                $display("golden:    %d", golden);
                $display("**************************************************");
                $write("\033[0m");
                print_debug;
                $finish;
            end
        end else begin
            $write("\033[31m");
            $display("**************************************************");
            $display("                OUTPUT CHECK FAILED               ");
            $display("**************************************************");
            $display("               out_valid is not high");
            $display("--------------------------------------------------");
            $display("               time: %d", $time);
            $display("--------------------------------------------------");
            $display("out_valid: %b", out_valid);
            $display("out_data:  %d", out_data);
            $display("**************************************************");
            $write("\033[0m");
            print_debug;
            $finish;
        end
    end endtask

    task wait_next_pattern; begin
        @(negedge clk);
        specx1_checker;
        @(negedge clk);
        specx1_checker;
    end endtask
    
    task spec7_checker; begin
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

    always @(in_valid or out_valid) spec11_checker;
    task spec11_checker; begin
        if (in_valid === 1'b1 && out_valid === 1'b1) begin
            $write("\033[31m");
            $display("**************************************************");
            $display("                 SPEC CHECK FAILED                ");
            $display("**************************************************");
            $display("     in_valid and out_valid should not be high");
            $display("     at the same time");
            $display("--------------------------------------------------");
            $display("               time: %d", $time);
            $display("--------------------------------------------------");
            $display("in_valid:  %b", in_valid);
            $display("out_valid: %b", out_valid);
            $display("**************************************************");
            $write("\033[0m");
            print_debug;
            $finish;
        end
    end endtask    
    
    // always @(negedge clk) spec12_checker;
    // task spec12_checker; begin
    //     if (out_valid === 1'b0 && out_data !== 8'b0) begin
    //         $write("\033[31m");
    //         $display("**************************************************");
    //         $display("                 SPEC CHECK FAILED                ");
    //         $display("**************************************************");
    //         $display("     out_data should be 0 when out_valid is 0");
    //         $display("--------------------------------------------------");
    //         $display("               time: %d", $time);
    //         $display("--------------------------------------------------");
    //         $display("out_valid: %b", out_valid);
    //         $display("out_data:  %b", out_data);
    //         $display("**************************************************");
    //         $write("\033[0m");
    //         $finish;
    //     end
    // end endtask
    
    task specx1_checker; begin
        if (out_valid === 1'b1) begin
            $write("\033[31m");
            $display("**************************************************");
            $display("                 SPEC CHECK FAILED                ");
            $display("**************************************************");
            $display("   out_valid should be high for only one cycle");
            $display("--------------------------------------------------");
            $display("               time: %d", $time);
            $display("--------------------------------------------------");
            $display("out_valid: %b", out_valid);
            $display("out_data:  %b", out_data);
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
        $display("++++++++++++++++++++++++++++++++++++++++++++++++++");
        $display("                   PICTURE %2d", sent_pic_no);
        $display("--------------------------------------------------");
        if (sent_mode == 2'b01) begin
            $display("Auto Exposure:");
            $display("    exposure_sum: %8d", exposure_sum);
            $display("    golden_mean : %8d", golden);
        end else 
        if (sent_mode == 2'b00) begin
            $display("Auto Focus:");
            for (int j = 0; j < 3; j++) begin
                $display("     D_contrast_sum[%2d]: %8d", j, D_contrast_sum[j]);
                $display("     D_contrast    [%2d]: %8d", j, D_contrast_sum[j]/((j+1)*(j+1)*4));
            end
            $display("    golden_contrast:     %8d", golden);
        end else
        if (sent_mode == 2'b10) begin
            $display("Average Min Max:");
            $display("    max_r: %3d, min_r: %3d", max_r, min_r);
            $display("    max_g: %3d, min_g: %3d", max_g, min_g);
            $display("    max_b: %3d, min_b: %3d", max_b, min_b);
            $display("    max  : %3d, min  : %3d", max, min);
            $display("    avg  : %3d", avg);
            $display("    golden: %3d", golden);
        end
        $display("**************************************************");
        $write("\033[0m");
    end endtask

endmodule
