//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2023 Fall
//   Lab04 Exercise		: Convolution Neural Network 
//   Author     		: Yu-Chi Lin (a6121461214.st12@nycu.edu.tw)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : CNN.v
//   Module Name : CNN
//   Release version : V1.0 (Release Date: 2024-10)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

`define CYCLE_TIME      36.0
`define SEED_NUMBER     28825252
`define PATTERN_NUMBER 10000

module PATTERN(
    //Output Port
    clk,
    rst_n,
    in_valid,
    Img,
    Kernel_ch1,
    Kernel_ch2,
	Weight,
    Opt,
    //Input Port
    out_valid,
    out
    );

    //---------------------------------------------------------------------
    //   PORT DECLARATION          
    //---------------------------------------------------------------------
    output  logic        clk, rst_n, in_valid;
    output  logic[31:0]  Img;
    output  logic[31:0]  Kernel_ch1;
    output  logic[31:0]  Kernel_ch2;
    output  logic[31:0]  Weight;
    output  logic        Opt;
    input           out_valid;
    input   [31:0]  out;

    //---------------------------------------------------------------------
    //   PARAMETER & INTEGER DECLARATION
    //---------------------------------------------------------------------
    real CYCLE = `CYCLE_TIME;
    parameter inst_sig_width = 23;
    parameter inst_exp_width = 8;
    parameter inst_ieee_compliance = 0;
    parameter inst_arch_type = 0;
    parameter inst_arch = 0;

    real SEED = `SEED_NUMBER;

    integer i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y, z;
    integer img_x, img_y, img_ch;
    integer kernel_ch1_x, kernel_ch1_y, kernel_ch1_ch;
    integer kernel_ch2_x, kernel_ch2_y, kernel_ch2_ch;
    integer weight_x, weight_y, weight_ch;
    integer out_x, out_y, out_ch;

    integer img_txt, opt_txt, out_txt, kernel_ch1_txt, kernel_ch2_txt, weight_txt;
    integer img_txt_id, opt_txt_id, out_txt_id, kernel_ch1_txt_id, kernel_ch2_txt_id, weight_txt_id;
    integer img_txt_scan, opt_txt_scan, out_txt_scan, kernel_ch1_txt_scan, kernel_ch2_txt_scan, weight_txt_scan;

    //---------------------------------------------------------------------
    //   Reg & Wires
    //---------------------------------------------------------------------
    reg [31:0] s_img, s_kernel_ch1, s_kernel_ch2, s_weight;
    reg s_opt;

    reg  [31:0] s_img_arr [2:0][4:0][4:0];
    reg  [31:0] s_img_arr_pad [2:0][5:-1][5:-1];
    reg  [31:0] s_kernel_ch1_arr [2:0][1:0][1:0];
    reg  [31:0] s_kernel_ch2_arr [2:0][1:0][1:0];
    reg  [31:0] s_conv2d_out_ch1 [2:0][5:0][5:0];
    reg  [31:0] s_conv2d_out_ch2 [2:0][5:0][5:0];
    reg  [31:0] s_conv2d_sum_ch1 [5:0][5:0];
    reg  [31:0] s_conv2d_sum_ch2 [5:0][5:0];
    reg  [31:0] s_maxpool_out [7:0];
    reg  [31:0] s_maxpool_out_act [7:0];
    reg  [31:0] s_weight_arr [2:0][7:0];
    reg  [31:0] s_fc_out [2:0];
    reg  [31:0] s_calc_out [2:0];
    reg  [31:0] s_out_arr [2:0];
    reg  [31:0] s_ans [2:0];
    wire [31:0] s_golden_ans_diff [2:0];
    wire [31:0] s_ans_err [2:0];
    wire error_flag [2:0];
    wire [31:0] maximum_error = 32'b00111000110100011011011100010111; // 0.0001
    // wire [31:0] maximum_error = 32'b00111010100000110001001001101111; // 0.001

    reg all_error_flag = 0;
    reg file_error_flag = 0;

    integer total_latency = 0;
    integer latency = 0;

    reg [31:0] random_int;

    //================================================================
    // clock
    //================================================================

    always #(CYCLE/2.0) clk = ~clk;
    initial	clk = 0;

    //---------------------------------------------------------------------
    //   Pattern_Design
    //---------------------------------------------------------------------
    initial begin
        `ifdef SHINKUAN
            $display("**************************************************");
            $display("            PATTERN MADE BY SHIN-KUAN             ");
            $display("**************************************************");
        `endif
        $display("\033[33m██╗      █████╗ ██████╗      ██████╗ ██╗  ██╗\033[0m");
        $display("\033[33m██║     ██╔══██╗██╔══██╗    ██╔═████╗██║  ██║\033[0m");
        $display("\033[33m██║     ███████║██████╔╝    ██║██╔██║███████║\033[0m");
        $display("\033[33m██║     ██╔══██║██╔══██╗    ████╔╝██║╚════██║\033[0m");
        $display("\033[33m███████╗██║  ██║██████╔╝    ╚██████╔╝     ██║\033[0m");
        $display("\033[33m╚══════╝╚═╝  ╚═╝╚═════╝      ╚═════╝      ╚═╝\033[0m");
        open_file;
        reset;
        while ($feof(opt_txt) != 1 && file_error_flag == 0) begin
            read_file_id;
            read_and_send;
            if (file_error_flag) begin
                break;
            end
            read_out;
            wait_out;
            check_ans;
            random_int = $random(SEED);
            repeat (random_int[2:0]) @(negedge clk);
        end
        if (!all_error_flag) begin
            $display("\033[32m");
            $display("**************************************************");
            $display("                 ALL PATTERN PASS                 ");
            $display("**************************************************");
            $display("           Total Latency: %d cycles", total_latency);
            $display("\033[33m /| ､\033[0m");
            $display("\033[33m(°､ ｡ 7\033[0m");
            $display("\033[33m |､  ~ヽ\033[0m");
            $display("\033[33m じしf_,)〳\033[0m");
        end
        $finish(1);
    end
    task open_file; begin
        img_txt = $fopen("../00_TESTBED/Img.txt", "r");
        opt_txt = $fopen("../00_TESTBED/Opt.txt", "r");
        out_txt = $fopen("../00_TESTBED/Out.txt", "r");
        kernel_ch1_txt = $fopen("../00_TESTBED/Kernel_ch1.txt", "r");
        kernel_ch2_txt = $fopen("../00_TESTBED/Kernel_ch2.txt", "r");
        weight_txt = $fopen("../00_TESTBED/Weight.txt", "r");
    end endtask
    task read_file_id; begin
        img_txt_scan = $fscanf(img_txt, "%d", img_txt_id);
        opt_txt_scan = $fscanf(opt_txt, "%d", opt_txt_id);
        out_txt_scan = $fscanf(out_txt, "%d", out_txt_id);
        kernel_ch1_txt_scan = $fscanf(kernel_ch1_txt, "%d", kernel_ch1_txt_id);
        kernel_ch2_txt_scan = $fscanf(kernel_ch2_txt, "%d", kernel_ch2_txt_id);
        weight_txt_scan = $fscanf(weight_txt, "%d", weight_txt_id);
        assert (img_txt_id == opt_txt_id &&
                opt_txt_id == out_txt_id &&
                out_txt_id == kernel_ch1_txt_id &&
                kernel_ch1_txt_id == kernel_ch2_txt_id &&
                kernel_ch2_txt_id == weight_txt_id
        ) else begin
            $display("Error: Pattern File Error");
            $finish(1);
        end
    end endtask
    task read_and_send; begin
        in_valid = 1'b1;
        fork
            read_and_send_img;
            read_and_send_kernel_ch1;
            read_and_send_kernel_ch2;
            read_and_send_weight;
            read_and_send_opt;    
        join
        in_valid = 1'b0;
    end endtask
    task read_and_send_img; begin
        for (i = 0; i < 75; i = i + 1) begin
            img_txt_scan = $fscanf(img_txt, "%H", s_img);
            assert (img_txt_scan == 1) else begin
                $display("Error: Img File Error");
                file_error_flag = 1;
                return;
            end
            Img = s_img;
            img_x  = i % 5;
            img_y  = (i / 5) % 5;
            img_ch = i / 25;
            s_img_arr[img_ch][img_y][img_x] = s_img;
            @(negedge clk);
        end
        Img = 32'bX;
    end endtask
    task read_and_send_kernel_ch1; begin
        for (j = 0; j < 12; j = j + 1) begin
            kernel_ch1_txt_scan = $fscanf(kernel_ch1_txt, "%H", s_kernel_ch1);
            assert (kernel_ch1_txt_scan == 1) else begin
                file_error_flag = 1;
                return;
            end
            Kernel_ch1 = s_kernel_ch1;
            kernel_ch1_x  = j % 2;
            kernel_ch1_y  = (j / 2) % 2;
            kernel_ch1_ch = j / 4;
            s_kernel_ch1_arr[kernel_ch1_ch][kernel_ch1_y][kernel_ch1_x] = s_kernel_ch1;
            @(negedge clk);
        end
        Kernel_ch1 = 32'bX;
    end endtask
    task read_and_send_kernel_ch2; begin
        for (k = 0; k < 12; k = k + 1) begin
            kernel_ch2_txt_scan = $fscanf(kernel_ch2_txt, "%H", s_kernel_ch2);
            assert (kernel_ch2_txt_scan == 1) else begin
                file_error_flag = 1;
                return;
            end
            Kernel_ch2 = s_kernel_ch2;
            kernel_ch2_x  = k % 2;
            kernel_ch2_y  = (k / 2) % 2;
            kernel_ch2_ch = k / 4;
            s_kernel_ch2_arr[kernel_ch2_ch][kernel_ch2_y][kernel_ch2_x] = s_kernel_ch2;
            @(negedge clk);
        end
        Kernel_ch2 = 32'bX;
    end endtask
    task read_and_send_weight; begin
        for (l = 0; l < 24; l = l + 1) begin
            weight_txt_scan = $fscanf(weight_txt, "%H", s_weight);
            assert (weight_txt_scan == 1) else begin
                file_error_flag = 1;
                return;
            end
            Weight = s_weight;
            weight_x  = l % 8;
            weight_y  = (l / 8) % 3;
            s_weight_arr[weight_y][weight_x] = s_weight;
            @(negedge clk);
        end
        Weight = 32'bX;
    end endtask
    task read_and_send_opt; begin
        for (m = 0; m < 1; m = m + 1) begin
            opt_txt_scan = $fscanf(opt_txt, "%b", s_opt);
            assert (opt_txt_scan == 1) else begin
                file_error_flag = 1;
                return;
            end
            Opt = s_opt;
            @(negedge clk);
        end
        Opt = 1'bX;
    end endtask
    task read_out; begin
        for (n = 0; n < 3; n = n + 1) begin
            out_txt_scan = $fscanf(out_txt, "%H", s_out_arr[n]);
            assert (out_txt_scan == 1) else begin
                file_error_flag = 1;
                return;
            end
        end
    end endtask
    task reset; begin
        force clk   = 0;
        rst_n       = 1'b1;
        in_valid    = 1'b0;
        Img         = 32'bX;
        Kernel_ch1  = 32'bX;
        Kernel_ch2  = 32'bX;
        Weight      = 32'bX;
        #50;
        rst_n = 0;
        #100;
        rst_n = 1;
        #50;
        release clk;
        repeat (3) @(negedge clk);
    end endtask
    task wait_out; begin
        latency = 0;
        while (out_valid !== 1'b1) begin
            latency = latency + 1;
            @(negedge clk);
        end
        total_latency = total_latency + latency;
        for (r = 0; r < 3; r = r + 1) begin
            s_ans[r] = out;
            @(negedge clk);
        end
    end endtask
    task check_ans; begin
        if (|{error_flag[0], error_flag[1], error_flag[2]} == 1'b0) begin
            $display("\033[32mPattern %d Pass.\033[0m", img_txt_id);
        end else begin
            $display("\033[31mPattern %d Fail.\033[0m", img_txt_id);
            all_error_flag = 1;
        end
        for (s = 0; s < 3; s = s + 1) begin
            $display("\033[95mClass: %d \033[93mGolden: %H \t \033[96mOutput: %H \t \033[36mDiff: %H \t \033[91mError: %H \033[32mLatency: %d\033[0m", s, s_out_arr[s], s_ans[s], s_golden_ans_diff[s], {1'b0,s_ans_err[s][30:0]}, latency);
        end
        if (|{error_flag[0], error_flag[1], error_flag[2]} == 1'b1) begin
            $display("\033[31m");
            $display("**************************************************");
            $display("              SPEC2 CHECKER ERROR                 ");
            $display("**************************************************");
            $display("The error is larger than 0.0001 at pattern[%d]", img_txt_id);
            $display("\033[0m");
            $finish(1);
        end
    end endtask
    genvar gr;
    generate for (gr = 0; gr < 3; gr = gr + 1) begin : g10
        DW_fp_sub #(
            .sig_width(inst_sig_width),
            .exp_width(inst_exp_width),
            .ieee_compliance(inst_ieee_compliance)
        ) DW_fp_sub_instance (
            .a(s_out_arr[gr]),
            .b(s_ans[gr]),
            .rnd(3'd0),
            .z(s_golden_ans_diff[gr]),
            .status()
        );
        DW_fp_div #(
            .sig_width(inst_sig_width),
            .exp_width(inst_exp_width),
            .ieee_compliance(inst_ieee_compliance),
            .faithful_round(0)
        ) DW_fp_div_instance (
            .a(s_golden_ans_diff[gr]),
            .b(s_out_arr[gr]),
            .rnd(3'd0),
            .z(s_ans_err[gr]),
            .status()
        );
        DW_fp_cmp #(
            .sig_width(inst_sig_width),
            .exp_width(inst_exp_width),
            .ieee_compliance(inst_ieee_compliance)
        ) DW_fp_cmp_instance (
            .a({1'b0,s_ans_err[gr][30:0]}), // abs
            .b(maximum_error),
            .zctr(),
            .aeqb(),
            .altb(),
            .agtb(error_flag[gr]),
            .unordered(),
            .z0(),
            .z1(),
            .status0(),
            .status1()
        );
    end endgenerate

    always @(negedge rst_n) begin #20; spec3_checker; end
    task spec3_checker; begin
        if (out !== 32'b0 || out_valid) begin
            $display("\033[31m");
            $display("**************************************************");
            $display("              SPEC4 CHECKER ERROR                 ");
            $display("**************************************************");
            $display("out and out_valid should be reset to 0 after reset at %d", $time);
            $display("out: %H, out_valid: %b", out, out_valid);
            $display("\033[0m");
            repeat (20) @(negedge clk);
            $finish(1);
        end
    end endtask

    always @(negedge clk) spec5_checker;
    task spec5_checker; begin
        if (out_valid === 1'b0) begin
            if (out !== 32'b0) begin
                $display("\033[31m");
                $display("**************************************************");
                $display("              SPEC5 CHECKER ERROR                 ");
                $display("**************************************************");
                $display("out should be 0 when out_valid is 0 at time %d", $time);
                $display("\033[0m");
                repeat (20) @(negedge clk);
                $finish(1);
            end
        end
    end endtask

    always @(negedge clk) spec6_checker;
    task spec6_checker; begin
        if (latency > 200) begin
            $display("\033[31m");
            $display("**************************************************");
            $display("              SPEC6 CHECKER ERROR                 ");
            $display("**************************************************");
            $display("latency should be less than 200 at time %d", $time);
            $display("\033[0m");
            repeat (20) @(negedge clk);
            $finish(1);
        end
    end endtask
    // always @(*) begin
    //     for (o = 0; o < 3; o = o + 1) begin
    //         s_img_arr_pad[o][-1][-1] = s_opt ? s_img_arr[o][0][0] : 32'b0;
    //         s_img_arr_pad[o][-1][ 5] = s_opt ? s_img_arr[o][0][4] : 32'b0;
    //         s_img_arr_pad[o][ 5][-1] = s_opt ? s_img_arr[o][4][0] : 32'b0;
    //         s_img_arr_pad[o][ 5][ 5] = s_opt ? s_img_arr[o][4][4] : 32'b0;
    //         for (p = 0; p < 5; p = p + 1) begin
    //             s_img_arr_pad[o][-1][p] = s_opt ? s_img_arr[o][0][p] : 32'b0;
    //             s_img_arr_pad[o][ 5][p] = s_opt ? s_img_arr[o][4][p] : 32'b0;
    //             s_img_arr_pad[o][p][-1] = s_opt ? s_img_arr[o][p][0] : 32'b0;
    //             s_img_arr_pad[o][p][ 5] = s_opt ? s_img_arr[o][p][4] : 32'b0;
    //         end
    //         for (p = 0; p < 5; p = p + 1) begin
    //             for (q = 0; q < 5; q = q + 1) begin
    //                 s_img_arr_pad[o][p][q] = s_img_arr[o][p][q];
    //             end
    //         end
    //     end
    // end
    // genvar gi, gj, gk;
    // generate for (gi = 0; gi < 3; gi = gi + 1) begin : g1
    //     for (gj = 0; gj < 6; gj = gj + 1) begin : g2
    //         for (gk = 0; gk < 6; gk = gk + 1) begin : g3
    //             CONV2D #(
    //                 .inst_sig_width(inst_sig_width),
    //                 .inst_exp_width(inst_exp_width),
    //                 .inst_ieee_compliance(inst_ieee_compliance),
    //                 .inst_arch_type(inst_arch_type)
    //             ) CONV2D_instance_ch1 (
    //                 .img0(s_img_arr_pad[gi][gj-1][gk-1]),
    //                 .img1(s_img_arr_pad[gi][gj-1][gk  ]),
    //                 .img2(s_img_arr_pad[gi][gj  ][gk-1]),
    //                 .img3(s_img_arr_pad[gi][gj  ][gk  ]),
    //                 .kernel0(s_kernel_ch1_arr[gi][0][0]),
    //                 .kernel1(s_kernel_ch1_arr[gi][0][1]),
    //                 .kernel2(s_kernel_ch1_arr[gi][1][0]),
    //                 .kernel3(s_kernel_ch1_arr[gi][1][1]),
    //                 .out(s_conv2d_out_ch1[gi][gj][gk])
    //             );
    //             CONV2D #(
    //                 .inst_sig_width(inst_sig_width),
    //                 .inst_exp_width(inst_exp_width),
    //                 .inst_ieee_compliance(inst_ieee_compliance),
    //                 .inst_arch_type(inst_arch_type)
    //             ) CONV2D_instance_ch2 (
    //                 .img0(s_img_arr_pad[gi][gj-1][gk-1]),
    //                 .img1(s_img_arr_pad[gi][gj-1][gk  ]),
    //                 .img2(s_img_arr_pad[gi][gj  ][gk-1]),
    //                 .img3(s_img_arr_pad[gi][gj  ][gk  ]),
    //                 .kernel0(s_kernel_ch2_arr[gi][0][0]),
    //                 .kernel1(s_kernel_ch2_arr[gi][0][1]),
    //                 .kernel2(s_kernel_ch2_arr[gi][1][0]),
    //                 .kernel3(s_kernel_ch2_arr[gi][1][1]),
    //                 .out(s_conv2d_out_ch2[gi][gj][gk])
    //             );
    //         end
    //     end
    // end endgenerate
    // genvar gl, gm;
    // generate for (gl = 0; gl < 6; gl = gl + 1) begin : g4
    //     for (gm = 0; gm < 6; gm = gm + 1) begin : g5
    //         SUM3 #(
    //             .inst_sig_width(inst_sig_width),
    //             .inst_exp_width(inst_exp_width),
    //             .inst_ieee_compliance(inst_ieee_compliance),
    //             .inst_arch_type(inst_arch_type)
    //         ) SUM3_instance_u0 (
    //             .in0(s_conv2d_out_ch1[0][gl][gm]),
    //             .in1(s_conv2d_out_ch1[1][gl][gm]),
    //             .in2(s_conv2d_out_ch1[2][gl][gm]),
    //             .out(s_conv2d_sum_ch1[gl][gm])
    //         );
    //         SUM3 #(
    //             .inst_sig_width(inst_sig_width),
    //             .inst_exp_width(inst_exp_width),
    //             .inst_ieee_compliance(inst_ieee_compliance),
    //             .inst_arch_type(inst_arch_type)
    //         ) SUM3_instance_u1 (
    //             .in0(s_conv2d_out_ch2[0][gl][gm]),
    //             .in1(s_conv2d_out_ch2[1][gl][gm]),
    //             .in2(s_conv2d_out_ch2[2][gl][gm]),
    //             .out(s_conv2d_sum_ch2[gl][gm])
    //         );
    //     end
    // end endgenerate
    // genvar gn, go;
    // generate for (gn = 0; gn < 2; gn = gn + 1) begin : g6
    //     for (go = 0; go < 2; go = go + 1) begin : g7
    //         MaxPooling_PAT #(
    //             .inst_sig_width(inst_sig_width),
    //             .inst_exp_width(inst_exp_width),
    //             .inst_ieee_compliance(inst_ieee_compliance)
    //         ) MaxPooling_instance_ch1 (
    //             .in0(s_conv2d_sum_ch1[gn*3+0][go*3+0]),
    //             .in1(s_conv2d_sum_ch1[gn*3+0][go*3+1]),
    //             .in2(s_conv2d_sum_ch1[gn*3+0][go*3+2]),
    //             .in3(s_conv2d_sum_ch1[gn*3+1][go*3+0]),
    //             .in4(s_conv2d_sum_ch1[gn*3+1][go*3+1]),
    //             .in5(s_conv2d_sum_ch1[gn*3+1][go*3+2]),
    //             .in6(s_conv2d_sum_ch1[gn*3+2][go*3+0]),
    //             .in7(s_conv2d_sum_ch1[gn*3+2][go*3+1]),
    //             .in8(s_conv2d_sum_ch1[gn*3+2][go*3+2]),
    //             .out(s_maxpool_out[gn*2+go])
    //         );
    //         MaxPooling_PAT #(
    //             .inst_sig_width(inst_sig_width),
    //             .inst_exp_width(inst_exp_width),
    //             .inst_ieee_compliance(inst_ieee_compliance)
    //         ) MaxPooling_instance_ch2 (
    //             .in0(s_conv2d_sum_ch2[gn*3+0][go*3+0]),
    //             .in1(s_conv2d_sum_ch2[gn*3+0][go*3+1]),
    //             .in2(s_conv2d_sum_ch2[gn*3+0][go*3+2]),
    //             .in3(s_conv2d_sum_ch2[gn*3+1][go*3+0]),
    //             .in4(s_conv2d_sum_ch2[gn*3+1][go*3+1]),
    //             .in5(s_conv2d_sum_ch2[gn*3+1][go*3+2]),
    //             .in6(s_conv2d_sum_ch2[gn*3+2][go*3+0]),
    //             .in7(s_conv2d_sum_ch2[gn*3+2][go*3+1]),
    //             .in8(s_conv2d_sum_ch2[gn*3+2][go*3+2]),
    //             .out(s_maxpool_out[gn*2+go+4])
    //         );
    //     end
    // end endgenerate
    // genvar gp;
    // generate for (gp = 0; gp < 8; gp = gp + 1) begin : g8
    //     Activate_PAT #(
    //         .inst_sig_width(inst_sig_width),
    //         .inst_exp_width(inst_exp_width),
    //         .inst_ieee_compliance(inst_ieee_compliance),
    //         .inst_arch_type(inst_arch_type),
    //         .inst_arch(inst_arch)
    //     ) Activate_instance (
    //         .opt(s_opt),
    //         .in(s_maxpool_out[gp]),
    //         .out(s_maxpool_out_act[gp])
    //     );
    // end endgenerate
    // genvar gq;
    // generate for (gq = 0; gq < 3; gq = gq + 1) begin : g9
    //     FullConnected_PAT #(
    //         .inst_sig_width(inst_sig_width),
    //         .inst_exp_width(inst_exp_width),
    //         .inst_ieee_compliance(inst_ieee_compliance),
    //         .inst_arch_type(inst_arch_type)
    //     ) FullConnected_instance (
    //         .in0(s_maxpool_out_act[0]),
    //         .in1(s_maxpool_out_act[1]),
    //         .in2(s_maxpool_out_act[2]),
    //         .in3(s_maxpool_out_act[3]),
    //         .in4(s_maxpool_out_act[4]),
    //         .in5(s_maxpool_out_act[5]),
    //         .in6(s_maxpool_out_act[6]),
    //         .in7(s_maxpool_out_act[7]),
    //         .weight0(s_weight_arr[gq][0]),
    //         .weight1(s_weight_arr[gq][1]),
    //         .weight2(s_weight_arr[gq][2]),
    //         .weight3(s_weight_arr[gq][3]),
    //         .weight4(s_weight_arr[gq][4]),
    //         .weight5(s_weight_arr[gq][5]),
    //         .weight6(s_weight_arr[gq][6]),
    //         .weight7(s_weight_arr[gq][7]),
    //         .out(s_fc_out[gq])
    //     );
    // end endgenerate
    // SoftMax_PAT #(
    //     .inst_sig_width(inst_sig_width),
    //     .inst_exp_width(inst_exp_width),
    //     .inst_ieee_compliance(inst_ieee_compliance),
    //     .inst_arch_type(inst_arch_type),
    //     .inst_arch(inst_arch)
    // ) SoftMax_instance (
    //     .in0(s_fc_out[0]),
    //     .in1(s_fc_out[1]),
    //     .in2(s_fc_out[2]),
    //     .out0(s_calc_out[0]),
    //     .out1(s_calc_out[1]),
    //     .out2(s_calc_out[2])
    // );

endmodule

// module CONV2D(
//     input [31:0] img0,
//     input [31:0] img1,
//     input [31:0] img2,
//     input [31:0] img3,
//     input [31:0] kernel0,
//     input [31:0] kernel1,
//     input [31:0] kernel2,
//     input [31:0] kernel3,
//     output reg [31:0] out
// );
//     // IEEE floating point parameter
//     parameter inst_sig_width = 23;
//     parameter inst_exp_width = 8;
//     parameter inst_ieee_compliance = 0;
//     parameter inst_arch_type = 0;
//     DW_fp_dp4 #(
//         .sig_width(inst_sig_width),
//         .exp_width(inst_exp_width),
//         .ieee_compliance(inst_ieee_compliance),
//         .arch_type(inst_arch_type)
//     ) DW_fp_dp4_instance (
//         .a(img0),
//         .b(kernel0),
//         .c(img1),
//         .d(kernel1),
//         .e(img2),
//         .f(kernel2),
//         .g(img3),
//         .h(kernel3),
//         .rnd(3'b000),
//         .z(out),
//         .status()
//     );
 
// endmodule

// module SUM3(
//     input [31:0] in0,
//     input [31:0] in1,
//     input [31:0] in2,
//     output [31:0] out
// );
//     // IEEE floating point parameter
//     parameter inst_sig_width = 23;
//     parameter inst_exp_width = 8;
//     parameter inst_ieee_compliance = 0;
//     parameter inst_arch_type = 0;
//     DW_fp_sum3 #(
//         .sig_width(inst_sig_width),
//         .exp_width(inst_exp_width),
//         .ieee_compliance(inst_ieee_compliance),
//         .arch_type(inst_arch_type)
//     ) DW_fp_sum3_instance (
//         .a(in0),
//         .b(in1),
//         .c(in2),
//         .rnd(3'd0),
//         .z(out),
//         .status()
//     );
// endmodule

// module MaxPooling_PAT(
//     input [31:0] in0,
//     input [31:0] in1,
//     input [31:0] in2,
//     input [31:0] in3,
//     input [31:0] in4,
//     input [31:0] in5,
//     input [31:0] in6,
//     input [31:0] in7,
//     input [31:0] in8,
//     output [31:0] out
// );
//     // IEEE floating point parameter
//     parameter inst_sig_width = 23;
//     parameter inst_exp_width = 8;
//     parameter inst_ieee_compliance = 0;
//     wire [31:0] max1, max2, max3, max4;
//     wire [31:0] max5, max6, max7;
//     DW_fp_cmp #(
//         .sig_width(inst_sig_width),
//         .exp_width(inst_exp_width),
//         .ieee_compliance(inst_ieee_compliance)
//     ) DW_fp_cmp_instance_u0 (
//         .a(in0),
//         .b(in1),
//         .zctr(1'b0),
//         .aeqb(),
//         .altb(),
//         .agtb(),
//         .unordered(),
//         .z0(),
//         .z1(max1),
//         .status0(),
//         .status1()
//     );
//     DW_fp_cmp #(
//         .sig_width(inst_sig_width),
//         .exp_width(inst_exp_width),
//         .ieee_compliance(inst_ieee_compliance)
//     ) DW_fp_cmp_instance_u1 (
//         .a(in2),
//         .b(in3),
//         .zctr(1'b0),
//         .aeqb(),
//         .altb(),
//         .agtb(),
//         .unordered(),
//         .z0(),
//         .z1(max2),
//         .status0(),
//         .status1()
//     );
//     DW_fp_cmp #(
//         .sig_width(inst_sig_width),
//         .exp_width(inst_exp_width),
//         .ieee_compliance(inst_ieee_compliance)
//     ) DW_fp_cmp_instance_u2 (
//         .a(in4),
//         .b(in5),
//         .zctr(1'b0),
//         .aeqb(),
//         .altb(),
//         .agtb(),
//         .unordered(),
//         .z0(),
//         .z1(max3),
//         .status0(),
//         .status1()
//     );
//     DW_fp_cmp #(
//         .sig_width(inst_sig_width),
//         .exp_width(inst_exp_width),
//         .ieee_compliance(inst_ieee_compliance)
//     ) DW_fp_cmp_instance_u3 (
//         .a(in6),
//         .b(in7),
//         .zctr(1'b0),
//         .aeqb(),
//         .altb(),
//         .agtb(),
//         .unordered(),
//         .z0(),
//         .z1(max4),
//         .status0(),
//         .status1()
//     );
//     DW_fp_cmp #(
//         .sig_width(inst_sig_width),
//         .exp_width(inst_exp_width),
//         .ieee_compliance(inst_ieee_compliance)
//     ) DW_fp_cmp_instance_u4 (
//         .a(max1),
//         .b(max2),
//         .zctr(1'b0),
//         .aeqb(),
//         .altb(),
//         .agtb(),
//         .unordered(),
//         .z0(),
//         .z1(max5),
//         .status0(),
//         .status1()
//     );
//     DW_fp_cmp #(
//         .sig_width(inst_sig_width),
//         .exp_width(inst_exp_width),
//         .ieee_compliance(inst_ieee_compliance)
//     ) DW_fp_cmp_instance_u5 (
//         .a(max3),
//         .b(max4),
//         .zctr(1'b0),
//         .aeqb(),
//         .altb(),
//         .agtb(),
//         .unordered(),
//         .z0(),
//         .z1(max6),
//         .status0(),
//         .status1()
//     );
//     DW_fp_cmp #(
//         .sig_width(inst_sig_width),
//         .exp_width(inst_exp_width),
//         .ieee_compliance(inst_ieee_compliance)
//     ) DW_fp_cmp_instance_u6 (
//         .a(max5),
//         .b(max6),
//         .zctr(1'b0),
//         .aeqb(),
//         .altb(),
//         .agtb(),
//         .unordered(),
//         .z0(),
//         .z1(max7),
//         .status0(),
//         .status1()
//     );
//     DW_fp_cmp #(
//         .sig_width(inst_sig_width),
//         .exp_width(inst_exp_width),
//         .ieee_compliance(inst_ieee_compliance)
//     ) DW_fp_cmp_instance_u7 (
//         .a(max7),
//         .b(in8),
//         .zctr(1'b0),
//         .aeqb(),
//         .altb(),
//         .agtb(),
//         .unordered(),
//         .z0(),
//         .z1(out),
//         .status0(),
//         .status1()
//     );
// endmodule

// module Sigmoid_PAT(
//     input [31:0] in,
//     output [31:0] out
// );
//     // IEEE floating point parameter
//     parameter inst_sig_width = 23;
//     parameter inst_exp_width = 8;
//     parameter inst_ieee_compliance = 0;
//     parameter inst_arch_type = 0;
//     parameter inst_arch = 0;

//     wire [31:0] exp;
//     wire [31:0] sum;
//     wire [31:0] one;
//     assign one = 32'b0_01111111_00000000000000000000000;
//     DW_fp_exp #(
//         .sig_width(inst_sig_width),
//         .exp_width(inst_exp_width),
//         .ieee_compliance(inst_ieee_compliance),
//         .arch(inst_arch)
//     ) DW_fp_exp_instance_u0 (
//         .a(in),
//         .z(exp),
//         .status()
//     );
//     DW_fp_add #(
//         .sig_width(inst_sig_width),
//         .exp_width(inst_exp_width),
//         .ieee_compliance(inst_ieee_compliance)
//     ) DW_fp_add_instance (
//         .a(exp),
//         .b(one),
//         .rnd(3'd0),
//         .z(sum),
//         .status()
//     );
//     DW_fp_recip #(
//         .sig_width(inst_sig_width),
//         .exp_width(inst_exp_width),
//         .ieee_compliance(inst_ieee_compliance),
//         .faithful_round(0)
//     ) DW_fp_recip_instance (
//         .a(sum),
//         .rnd(3'd0),
//         .z(out),
//         .status()
//     );
// endmodule

// module Tanh_PAT(
//     input [31:0] in,
//     output [31:0] out
// );
//     // IEEE floating point parameter
//     parameter inst_sig_width = 23;
//     parameter inst_exp_width = 8;
//     parameter inst_ieee_compliance = 0;
//     parameter inst_arch_type = 0;
//     parameter inst_arch = 0;

//     wire [31:0] pos_in, neg_in;
//     wire [31:0] exp_pos, exp_neg;
//     wire [31:0] exp_add, exp_sub;
    
//     assign {pos_in, neg_in} = in[31] ? {{1'b0, in[30:0]}, in[31:0]} : {in[31:0], {1'b1, in[30:0]}};

//     DW_fp_exp #(
//         .sig_width(inst_sig_width),
//         .exp_width(inst_exp_width),
//         .ieee_compliance(inst_ieee_compliance),
//         .arch(inst_arch)
//     ) DW_fp_exp_instance_u0 (
//         .a(pos_in),
//         .z(exp_pos),
//         .status()
//     );
//     DW_fp_exp #(
//         .sig_width(inst_sig_width),
//         .exp_width(inst_exp_width),
//         .ieee_compliance(inst_ieee_compliance),
//         .arch(inst_arch)
//     ) DW_fp_exp_instance_u1 (
//         .a(neg_in),
//         .z(exp_neg),
//         .status()
//     );
//     DW_fp_add #(
//         .sig_width(inst_sig_width),
//         .exp_width(inst_exp_width),
//         .ieee_compliance(inst_ieee_compliance)
//     ) DW_fp_add_instance_u0 (
//         .a(exp_pos),
//         .b(exp_neg),
//         .rnd(3'd0),
//         .z(exp_add),
//         .status()
//     );
//     DW_fp_sub #(
//         .sig_width(inst_sig_width),
//         .exp_width(inst_exp_width),
//         .ieee_compliance(inst_ieee_compliance)
//     ) DW_fp_sub_instance_u0 (
//         .a(exp_pos),
//         .b(exp_neg),
//         .rnd(3'd0),
//         .z(exp_sub),
//         .status()
//     );
//     DW_fp_div #(
//         .sig_width(inst_sig_width),
//         .exp_width(inst_exp_width),
//         .ieee_compliance(inst_ieee_compliance),
//         .faithful_round(0)
//     ) DW_fp_div_instance_u0 (
//         .a(exp_sub),
//         .b(exp_add),
//         .rnd(3'd0),
//         .z(out),
//         .status()
//     );

// endmodule

// module Activate_PAT(
//     input opt,
//     input [31:0] in,
//     output [31:0] out
// );
//     // IEEE floating point parameter
//     parameter inst_sig_width = 23;
//     parameter inst_exp_width = 8;
//     parameter inst_ieee_compliance = 0;
//     parameter inst_arch_type = 0;
//     parameter inst_arch = 0;
//     wire [31:0] sigmoid_out, tanh_out;
//     Sigmoid_PAT #(
//         .inst_sig_width(inst_sig_width),
//         .inst_exp_width(inst_exp_width),
//         .inst_ieee_compliance(inst_ieee_compliance),
//         .inst_arch(inst_arch)
//     ) Sigmoid_instance (
//         .in(in),
//         .out(sigmoid_out)
//     );
//     Tanh_PAT #(
//         .inst_sig_width(inst_sig_width),
//         .inst_exp_width(inst_exp_width),
//         .inst_ieee_compliance(inst_ieee_compliance),
//         .inst_arch(inst_arch)
//     ) Tanh_instance (
//         .in(in),
//         .out(tanh_out)
//     );
//     assign out = opt ? tanh_out : sigmoid_out;

// endmodule

// module FullConnected_PAT(
//     input [31:0] in0,
//     input [31:0] in1,
//     input [31:0] in2,
//     input [31:0] in3,
//     input [31:0] in4,
//     input [31:0] in5,
//     input [31:0] in6,
//     input [31:0] in7,
//     input [31:0] weight0,
//     input [31:0] weight1,
//     input [31:0] weight2,
//     input [31:0] weight3,
//     input [31:0] weight4,
//     input [31:0] weight5,
//     input [31:0] weight6,
//     input [31:0] weight7,
//     output reg [31:0] out
// );
//     // IEEE floating point parameter
//     parameter inst_sig_width = 23;
//     parameter inst_exp_width = 8;
//     parameter inst_ieee_compliance = 0;
//     parameter inst_arch_type = 0;
//     wire [31:0] dp4_0, dp4_1;
//     DW_fp_dp4 #(
//         .sig_width(inst_sig_width),
//         .exp_width(inst_exp_width),
//         .ieee_compliance(inst_ieee_compliance),
//         .arch_type(inst_arch_type)
//     ) DW_fp_dp4_instance_u0 (
//         .a(in0),
//         .b(weight0),
//         .c(in1),
//         .d(weight1),
//         .e(in2),
//         .f(weight2),
//         .g(in3),
//         .h(weight3),
//         .rnd(3'b000),
//         .z(dp4_0),
//         .status()
//     );
//     DW_fp_dp4 #(
//         .sig_width(inst_sig_width),
//         .exp_width(inst_exp_width),
//         .ieee_compliance(inst_ieee_compliance),
//         .arch_type(inst_arch_type)
//     ) DW_fp_dp4_instance_u1 (
//         .a(in4),
//         .b(weight4),
//         .c(in5),
//         .d(weight5),
//         .e(in6),
//         .f(weight6),
//         .g(in7),
//         .h(weight7),
//         .rnd(3'b000),
//         .z(dp4_1),
//         .status()
//     );
//     DW_fp_add #(
//         .sig_width(inst_sig_width),
//         .exp_width(inst_exp_width),
//         .ieee_compliance(inst_ieee_compliance)
//     ) DW_fp_add_instance_u0 (
//         .a(dp4_0),
//         .b(dp4_1),
//         .rnd(3'b000),
//         .z(out),
//         .status()
//     );
// endmodule

// module SoftMax_PAT(
//     input [31:0] in0,
//     input [31:0] in1,
//     input [31:0] in2,
//     output [31:0] out0,
//     output [31:0] out1,
//     output [31:0] out2
// );
//     // IEEE floating point parameter
//     parameter inst_sig_width = 23;
//     parameter inst_exp_width = 8;
//     parameter inst_ieee_compliance = 0;
//     parameter inst_arch_type = 0;
//     parameter inst_arch = 0;
//     wire [31:0] exp0, exp1, exp2;
//     wire [31:0] sum;

//     DW_fp_exp #(
//         .sig_width(inst_sig_width),
//         .exp_width(inst_exp_width),
//         .ieee_compliance(inst_ieee_compliance),
//         .arch(inst_arch)
//     ) DW_fp_exp_instance_u0 (
//         .a(in0),
//         .z(exp0),
//         .status()
//     );
//     DW_fp_exp #(
//         .sig_width(inst_sig_width),
//         .exp_width(inst_exp_width),
//         .ieee_compliance(inst_ieee_compliance),
//         .arch(inst_arch)
//     ) DW_fp_exp_instance_u1 (
//         .a(in1),
//         .z(exp1),
//         .status()
//     );
//     DW_fp_exp #(
//         .sig_width(inst_sig_width),
//         .exp_width(inst_exp_width),
//         .ieee_compliance(inst_ieee_compliance),
//         .arch(inst_arch)
//     ) DW_fp_exp_instance_u2 (
//         .a(in2),
//         .z(exp2),
//         .status()
//     );
//     DW_fp_sum3 #(
//         .sig_width(inst_sig_width),
//         .exp_width(inst_exp_width),
//         .ieee_compliance(inst_ieee_compliance),
//         .arch_type(inst_arch_type)
//     ) DW_fp_sum3_instance (
//         .a(exp0),
//         .b(exp1),
//         .c(exp2),
//         .rnd(3'd0),
//         .z(sum),
//         .status()
//     );
//     DW_fp_div #(
//         .sig_width(inst_sig_width),
//         .exp_width(inst_exp_width),
//         .ieee_compliance(inst_ieee_compliance),
//         .faithful_round(0) // 1 for general, can have 1ulp error
//     ) DW_fp_div_instance (
//         .a(exp0),
//         .b(sum),
//         .rnd(3'd0),
//         .z(out0),
//         .status()
//     );
//     DW_fp_div #(
//         .sig_width(inst_sig_width),
//         .exp_width(inst_exp_width),
//         .ieee_compliance(inst_ieee_compliance),
//         .faithful_round(0) // 1 for general, can have 1ulp error
//     ) DW_fp_div_instance_u1 (
//         .a(exp1),
//         .b(sum),
//         .rnd(3'd0),
//         .z(out1),
//         .status()
//     );
//     DW_fp_div #(
//         .sig_width(inst_sig_width),
//         .exp_width(inst_exp_width),
//         .ieee_compliance(inst_ieee_compliance),
//         .faithful_round(0) // 1 for general, can have 1ulp error
//     ) DW_fp_div_instance_u2 (
//         .a(exp2),
//         .b(sum),
//         .rnd(3'd0),
//         .z(out2),
//         .status()
//     );

// endmodule