//================================================================
//  Include Files
//================================================================
`include "/usr/cad/synopsys/synthesis/cur/dw/sim_ver/DW_fp_add.v"
`include "/usr/cad/synopsys/synthesis/cur/dw/sim_ver/DW_fp_exp.v"
`include "/usr/cad/synopsys/synthesis/cur/dw/sim_ver/DW_fp_div.v"
`include "/usr/cad/synopsys/synthesis/cur/dw/sim_ver/DW_fp_sub.v"
`include "/usr/cad/synopsys/synthesis/cur/dw/sim_ver/DW_fp_cmp.v"
`include "/usr/cad/synopsys/synthesis/cur/dw/sim_ver/DW02_mult.v"

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

module CNN(
    //Input Port
    clk,
    rst_n,
    in_valid,
    Img,
    Kernel_ch1,
    Kernel_ch2,
	Weight,
    Opt,

    //Output Port
    out_valid,
    out
);


    //=====================================================================
    //   PARAMETER
    //=====================================================================

    // IEEE floating point parameter
    parameter inst_sig_width = 23;
    parameter inst_exp_width = 8;
    parameter inst_ieee_compliance = 0;
    parameter inst_arch_type = 0;
    parameter inst_arch = 0;
    parameter inst_faithful_round = 0;

    parameter STATE_IDLE = 0;

    input rst_n, clk, in_valid;
    input [inst_sig_width+inst_exp_width:0] Img, Kernel_ch1, Kernel_ch2, Weight;
    input Opt;

    output reg	out_valid;
    output reg [inst_sig_width+inst_exp_width:0] out;

    integer i, j, k, l, m, n; // @suppress

    //=====================================================================
    //   Reg & Wires
    //=====================================================================
    reg [inst_sig_width+inst_exp_width:0] img_shift         [0:3];
    reg [inst_sig_width+inst_exp_width:0] img_shift_2       [0:4];
    reg [inst_sig_width+inst_exp_width:0] knl_ch1_arr       [0:2] [0:1] [0:1];
    reg [inst_sig_width+inst_exp_width:0] knl_ch2_arr       [0:2] [0:1] [0:1];
    reg [inst_sig_width+inst_exp_width:0] weight_arr        [0:2] [0:7];
    reg opt;

    reg [7:0] cs, ns;
    reg [4:0] cnt_25_0_c, cnt_25_0_n;
    reg [1:0] cnt_25_1_c, cnt_25_1_n;

    reg [inst_sig_width+inst_exp_width:0] conv_2d_0_img_0, conv_2d_0_img_1, conv_2d_0_img_2, conv_2d_0_img_3;
    reg [inst_sig_width+inst_exp_width:0] conv_2d_1_img_0, conv_2d_1_img_1, conv_2d_1_img_2, conv_2d_1_img_3;
    reg [inst_sig_width+inst_exp_width:0] conv_2d_0_knl_0, conv_2d_0_knl_1, conv_2d_0_knl_2, conv_2d_0_knl_3;
    reg [inst_sig_width+inst_exp_width:0] conv_2d_1_knl_0, conv_2d_1_knl_1, conv_2d_1_knl_2, conv_2d_1_knl_3;

    wire [inst_sig_width+inst_exp_width:0] conv_2d_k0_0_out, conv_2d_k0_1_out;
    wire [inst_sig_width+inst_exp_width:0] conv_2d_k1_0_out, conv_2d_k1_1_out;

    reg [inst_sig_width+inst_exp_width:0] conv_2d_k0_0_out_reg, conv_2d_k0_1_out_reg;
    reg [inst_sig_width+inst_exp_width:0] conv_2d_k1_0_out_reg, conv_2d_k1_1_out_reg;

    reg [inst_sig_width+inst_exp_width:0] conv_2d_add_ch0_0_b, conv_2d_add_ch0_0_z;
    reg [inst_sig_width+inst_exp_width:0] conv_2d_add_ch0_1_b, conv_2d_add_ch0_1_z;
    reg [inst_sig_width+inst_exp_width:0] conv_2d_add_ch1_0_b, conv_2d_add_ch1_0_z;
    reg [inst_sig_width+inst_exp_width:0] conv_2d_add_ch1_1_b, conv_2d_add_ch1_1_z;

    reg [inst_sig_width+inst_exp_width:0] conv_2d_0_sum [0:5] [0:5];
    reg [inst_sig_width+inst_exp_width:0] conv_2d_1_sum [0:5] [0:5];

    reg [inst_sig_width+inst_exp_width:0] conv_2d_0_sum_next [0:5] [0:5];
    reg [inst_sig_width+inst_exp_width:0] conv_2d_1_sum_next [0:5] [0:5];

    reg [inst_sig_width+inst_exp_width:0] maxpooling_in0, maxpooling_in1, maxpooling_in2;
    reg [inst_sig_width+inst_exp_width:0] maxpooling_in3, maxpooling_in4, maxpooling_in5;
    reg [inst_sig_width+inst_exp_width:0] maxpooling_in6, maxpooling_in7, maxpooling_in8;
    reg [inst_sig_width+inst_exp_width:0] maxpooling_out;
    reg [inst_sig_width+inst_exp_width:0] maxpooling_out_reg [0:7];

    reg [inst_sig_width+inst_exp_width:0] activate_in;
    reg [inst_sig_width+inst_exp_width:0] activate_out;

    reg [inst_sig_width+inst_exp_width:0] fc_out [0:2];
    reg [inst_sig_width+inst_exp_width:0] fc_exp_sum;
    reg [inst_sig_width+inst_exp_width:0] fc_exp_sum_reg;

    reg [inst_sig_width+inst_exp_width:0] div_a, div_b;

    wire [inst_sig_width+inst_exp_width:0] exp_in, exp_out;
    wire [inst_sig_width+inst_exp_width:0] act_muln2, act_muln1;
    wire [inst_sig_width+inst_exp_width:0] one;
    wire [inst_sig_width+inst_exp_width:0] add_one_out;
    wire [inst_sig_width+inst_exp_width:0] recip_out;
    wire [inst_sig_width+inst_exp_width:0] recip_out_mul2_sub1;

    reg [inst_sig_width+inst_exp_width:0] add_one_out_reg;

    //=====================================================================
    // Design
    //=====================================================================
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            cs <= STATE_IDLE;
            cnt_25_0_c <= 0;
            cnt_25_1_c <= 0;
        end else begin
            cs <= ns;
            cnt_25_0_c <= cnt_25_0_n;
            cnt_25_1_c <= cnt_25_1_n;
        end
    end
    always @(*) begin
        if (cs == STATE_IDLE) begin
            if (in_valid) begin
                ns = 1;
            end else begin
                ns = 0;
            end
            cnt_25_0_n = 5'b11101; // -3
            cnt_25_1_n = 0;
        end else begin
            ns = cs == 91 ? 0 : cs + 1;
            cnt_25_0_n = cnt_25_0_c == 24 ? 0 : cnt_25_0_c + 1;
            cnt_25_1_n = cnt_25_0_c == 24 ? cnt_25_1_c + 1 : cnt_25_1_c;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            for (i = 0; i < 4; i = i + 1) begin
                img_shift[i] <= 0;
            end
            for (i = 0; i < 5; i = i + 1) begin
                img_shift_2[i] <= 0;
            end
        end else begin
            img_shift[0] <= in_valid ? Img : 0;
            img_shift[1] <= img_shift[0];
            img_shift[2] <= img_shift[1];
            img_shift[3] <= img_shift[2];
            img_shift_2[0] <= img_shift[3];
            img_shift_2[1] <= img_shift_2[0];
            img_shift_2[2] <= img_shift_2[1];
            img_shift_2[3] <= img_shift_2[2];
            img_shift_2[4] <= img_shift_2[3];
        end
    end
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            for (i = 0; i < 3; i = i + 1) begin
                for (j = 0; j < 2; j = j + 1) begin
                    for (k = 0; k < 2; k = k + 1) begin
                        knl_ch1_arr[i][j][k] <= 0;
                        knl_ch2_arr[i][j][k] <= 0;
                    end
                end
            end
        end else begin
            if (cs < 12) begin
                knl_ch1_arr[cs[3:2]][cs[1]][cs[0]] <= Kernel_ch1;
                knl_ch2_arr[cs[3:2]][cs[1]][cs[0]] <= Kernel_ch2;
            end
        end
    end
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            for (i = 0; i < 3; i = i + 1) begin
                for (j = 0; j < 8; j = j + 1) begin
                    weight_arr[i][j] <= 0;
                end
            end
        end else begin
            if (cs < 24) begin
                weight_arr[cs[4:3]][cs[2:0]] <= Weight;
            end
        end
    end
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            opt <= 0;
        end else begin
            if (cs == 0) begin
                opt <= Opt;
            end else
            if (cs == 84) begin
                opt <= 0;
            end else begin
                opt <= opt;
            end
        end
    end
    // TODO: Change state value
    always @(*) begin
        case (cnt_25_0_c)
            0: begin
                conv_2d_0_img_0 = opt ? img_shift[3] : 32'b0;
            end
            3, 19: begin
                conv_2d_0_img_0 = opt ? img_shift[2] : 32'b0;
            end
            5, 10, 15: begin
                conv_2d_0_img_0 = opt ? img_shift_2[4] : 32'b0;
            end
            8, 13, 18: begin
                conv_2d_0_img_0 = img_shift_2[3];
            end
            20, 21, 22, 23, 24: begin
                conv_2d_0_img_0 = img_shift[3];
            end
            default: begin
                conv_2d_0_img_0 = 32'bX;
            end
        endcase
        if (cnt_25_1_c == 3) begin
            case (cnt_25_0_c)
                1,2,3: begin
                    conv_2d_0_img_0 = maxpooling_out_reg[0];
                end
                5,6,7: begin
                    conv_2d_0_img_0 = maxpooling_out_reg[2];
                end
                default: begin
                    conv_2d_0_img_0 = 32'bX;
                end
            endcase
        end
    end
    always @(*) begin
        case (cnt_25_0_c)
            0, 24: begin
                conv_2d_0_img_1 = opt ? img_shift[3] : 32'b0;
            end
            3: begin
                conv_2d_0_img_1 = opt ? img_shift[2] : 32'b0;
            end
            5, 10, 15: begin
                conv_2d_0_img_1 = img_shift_2[4];
            end
            8, 13, 18: begin
                conv_2d_0_img_1 = opt ? img_shift_2[3] : 32'b0;
            end
            19, 20, 21, 22, 23: begin
                conv_2d_0_img_1 = img_shift[2];
            end
            default: begin
                conv_2d_0_img_1 = 32'bX;
            end
        endcase
        if (cnt_25_1_c == 3) begin
            case (cnt_25_0_c)
                1,2,3: begin
                    conv_2d_0_img_1 = maxpooling_out_reg[1];
                end
                5,6,7: begin
                    conv_2d_0_img_1 = maxpooling_out_reg[3];
                end
                default: begin
                    conv_2d_0_img_1 = 32'bX;
                end
            endcase
        end
    end
    always @(*) begin
        case (cnt_25_0_c)
            0, 5, 10, 15, 20, 21, 22, 23, 24: begin
                conv_2d_0_img_2 = opt ? img_shift[3] : 32'b0;
            end
            3, 8, 13, 18: begin
                conv_2d_0_img_2 = img_shift[2];
            end
            19: begin
                conv_2d_0_img_2 = opt ? img_shift[2] : 32'b0;
            end
            default: begin
                conv_2d_0_img_2 = 32'bX;
            end
        endcase
        if (cnt_25_1_c == 3) begin
            case (cnt_25_0_c)
                1,2,3: begin
                    conv_2d_0_img_2 = maxpooling_out_reg[4];
                end
                5,6,7: begin
                    conv_2d_0_img_2 = maxpooling_out_reg[6];
                end
                default: begin
                    conv_2d_0_img_2 = 32'bX;
                end
            endcase
        end
    end
    always @(*) begin
        case (cnt_25_0_c)
            0, 5, 10, 15: begin
                conv_2d_0_img_3 = img_shift[3];
            end
            3, 8, 13, 18, 19, 20, 21, 22, 23: begin
                conv_2d_0_img_3 = opt ? img_shift[2] : 32'b0;
            end
            24: begin
                conv_2d_0_img_3 = opt ? img_shift[3] : 32'b0;
            end
            default: begin
                conv_2d_0_img_3 = 32'bX;
            end
        endcase
        if (cnt_25_1_c == 3) begin
            case (cnt_25_0_c)
                1,2,3: begin
                    conv_2d_0_img_3 = maxpooling_out_reg[5];
                end
                5,6,7: begin
                    conv_2d_0_img_3 = maxpooling_out_reg[7];
                end
                default: begin
                    conv_2d_0_img_3 = 32'bX;
                end
            endcase
        end
    end
    always @(*) begin
        case (cnt_25_0_c)
            0, 1, 2, 3: begin
                conv_2d_1_img_0 = opt ? img_shift[3] : 32'b0;
            end
            5, 6, 7, 8, 10, 11, 12, 13, 15, 16, 17, 18, 20, 21, 22, 23, 24: begin
                conv_2d_1_img_0 = img_shift_2[4];
            end
            19: begin
                conv_2d_1_img_0 = opt ? img_shift_2[3] : 32'b0;
            end
            default: begin
                conv_2d_1_img_0 = 32'bX;
            end
        endcase
    end
    always @(*) begin
        case (cnt_25_0_c)
            0, 1, 2, 3: begin
                conv_2d_1_img_1 = opt ? img_shift[2] : 32'b0;
            end
            5, 6, 7, 8, 10, 11, 12, 13, 15, 16, 17, 18, 19, 20, 21, 22, 23: begin
                conv_2d_1_img_1 = img_shift_2[3];
            end
            24: begin
                conv_2d_1_img_1 = opt ? img_shift_2[4] : 32'b0;
            end
            default: begin
                conv_2d_1_img_1 = 32'bX;
            end
        endcase
    end 
    always @(*) begin
        case (cnt_25_0_c)
            0, 1, 2, 3, 5, 6, 7, 8, 10, 11, 12, 13, 15, 16, 17, 18, 20, 21, 22, 23, 24: begin
                conv_2d_1_img_2 = img_shift[3];
            end
            19: begin
                conv_2d_1_img_2 = opt ? img_shift[2] : 32'b0;
            end
            default: begin
                conv_2d_1_img_2 = 32'bX;
            end
        endcase
    end
    always @(*) begin
        case (cnt_25_0_c)
            0, 1, 2, 3, 5, 6, 7, 8, 10, 11, 12, 13, 15, 16, 17, 18, 19, 20, 21, 22, 23: begin
                conv_2d_1_img_3 = img_shift[2];
            end
            24: begin
                conv_2d_1_img_3 = opt ? img_shift[3] : 32'b0;
            end
            default: begin
                conv_2d_1_img_3 = 32'bX;
            end
        endcase
    end
    always @(*) begin
        case (cnt_25_1_c)
            0: begin
                conv_2d_0_knl_0 = knl_ch1_arr[0][0][0];
                conv_2d_0_knl_1 = knl_ch1_arr[0][0][1];
                conv_2d_0_knl_2 = knl_ch1_arr[0][1][0];
                conv_2d_0_knl_3 = knl_ch1_arr[0][1][1];
            end
            1: begin
                conv_2d_0_knl_0 = knl_ch1_arr[1][0][0];
                conv_2d_0_knl_1 = knl_ch1_arr[1][0][1];
                conv_2d_0_knl_2 = knl_ch1_arr[1][1][0];
                conv_2d_0_knl_3 = knl_ch1_arr[1][1][1];
            end
            2: begin
                conv_2d_0_knl_0 = knl_ch1_arr[2][0][0];
                conv_2d_0_knl_1 = knl_ch1_arr[2][0][1];
                conv_2d_0_knl_2 = knl_ch1_arr[2][1][0];
                conv_2d_0_knl_3 = knl_ch1_arr[2][1][1];
            end
            //--------------------------------------------
            3: begin
                case (cnt_25_0_c) 
                    1: begin
                        conv_2d_0_knl_0 = weight_arr[0][0];
                        conv_2d_0_knl_1 = weight_arr[0][1];
                        conv_2d_0_knl_2 = weight_arr[0][4];
                        conv_2d_0_knl_3 = weight_arr[0][5];
                    end
                    2: begin
                        conv_2d_0_knl_0 = weight_arr[1][0];
                        conv_2d_0_knl_1 = weight_arr[1][1];
                        conv_2d_0_knl_2 = weight_arr[1][4];
                        conv_2d_0_knl_3 = weight_arr[1][5];
                    end
                    3: begin
                        conv_2d_0_knl_0 = weight_arr[2][0];
                        conv_2d_0_knl_1 = weight_arr[2][1];
                        conv_2d_0_knl_2 = weight_arr[2][4];
                        conv_2d_0_knl_3 = weight_arr[2][5];
                    end
                    5: begin
                        conv_2d_0_knl_0 = weight_arr[0][2];
                        conv_2d_0_knl_1 = weight_arr[0][3];
                        conv_2d_0_knl_2 = weight_arr[0][6];
                        conv_2d_0_knl_3 = weight_arr[0][7];
                    end
                    6: begin
                        conv_2d_0_knl_0 = weight_arr[1][2];
                        conv_2d_0_knl_1 = weight_arr[1][3];
                        conv_2d_0_knl_2 = weight_arr[1][6];
                        conv_2d_0_knl_3 = weight_arr[1][7];
                    end
                    7: begin
                        conv_2d_0_knl_0 = weight_arr[2][2];
                        conv_2d_0_knl_1 = weight_arr[2][3];
                        conv_2d_0_knl_2 = weight_arr[2][6];
                        conv_2d_0_knl_3 = weight_arr[2][7];
                    end
                    default: begin
                        conv_2d_0_knl_0 = 32'bX;
                        conv_2d_0_knl_1 = 32'bX;
                        conv_2d_0_knl_2 = 32'bX;
                        conv_2d_0_knl_3 = 32'bX;
                    end
                endcase
            end
            default: begin
                conv_2d_0_knl_0 = 32'bX;
                conv_2d_0_knl_1 = 32'bX;
                conv_2d_0_knl_2 = 32'bX;
                conv_2d_0_knl_3 = 32'bX;
            end
        endcase
    end
    always @(*) begin
        case (cnt_25_1_c)
            0: begin
                conv_2d_1_knl_0 = knl_ch2_arr[0][0][0];
                conv_2d_1_knl_1 = knl_ch2_arr[0][0][1];
                conv_2d_1_knl_2 = knl_ch2_arr[0][1][0];
                conv_2d_1_knl_3 = knl_ch2_arr[0][1][1];
            end
            1: begin
                conv_2d_1_knl_0 = knl_ch2_arr[1][0][0];
                conv_2d_1_knl_1 = knl_ch2_arr[1][0][1];
                conv_2d_1_knl_2 = knl_ch2_arr[1][1][0];
                conv_2d_1_knl_3 = knl_ch2_arr[1][1][1];
            end
            2: begin
                conv_2d_1_knl_0 = knl_ch2_arr[2][0][0];
                conv_2d_1_knl_1 = knl_ch2_arr[2][0][1];
                conv_2d_1_knl_2 = knl_ch2_arr[2][1][0];
                conv_2d_1_knl_3 = knl_ch2_arr[2][1][1];
            end
            default: begin
                conv_2d_1_knl_0 = 32'bX;
                conv_2d_1_knl_1 = 32'bX;
                conv_2d_1_knl_2 = 32'bX;
                conv_2d_1_knl_3 = 32'bX;
            end
        endcase
    end

    // DW_fp_dp4 #(
    //     .sig_width(inst_sig_width),
    //     .exp_width(inst_exp_width),
    //     .ieee_compliance(inst_ieee_compliance),
    //     .arch_type(inst_arch_type)
    // ) DW_fp_dp4_instanc_k0_0 (
    //     .a(conv_2d_0_img_0),
    //     .b(conv_2d_0_knl_0),
    //     .c(conv_2d_0_img_1),
    //     .d(conv_2d_0_knl_1),
    //     .e(conv_2d_0_img_2),
    //     .f(conv_2d_0_knl_2),
    //     .g(conv_2d_0_img_3),
    //     .h(conv_2d_0_knl_3),
    //     .rnd(3'b000),
    //     .z(conv_2d_k0_0_out),
    //     .status()
    // );
    // DW_fp_dp4 #(
    //     .sig_width(inst_sig_width),
    //     .exp_width(inst_exp_width),
    //     .ieee_compliance(inst_ieee_compliance),
    //     .arch_type(inst_arch_type)
    // ) DW_fp_dp4_instance_k0_1 (
    //     .a(conv_2d_1_img_0),
    //     .b(conv_2d_0_knl_0),
    //     .c(conv_2d_1_img_1),
    //     .d(conv_2d_0_knl_1),
    //     .e(conv_2d_1_img_2),
    //     .f(conv_2d_0_knl_2),
    //     .g(conv_2d_1_img_3),
    //     .h(conv_2d_0_knl_3),
    //     .rnd(3'b000),
    //     .z(conv_2d_k0_1_out),
    //     .status()
    // );
    // DW_fp_dp4 #(
    //     .sig_width(inst_sig_width),
    //     .exp_width(inst_exp_width),
    //     .ieee_compliance(inst_ieee_compliance),
    //     .arch_type(inst_arch_type)
    // ) DW_fp_dp4_instance_k1_0 (
    //     .a(conv_2d_0_img_0),
    //     .b(conv_2d_1_knl_0),
    //     .c(conv_2d_0_img_1),
    //     .d(conv_2d_1_knl_1),
    //     .e(conv_2d_0_img_2),
    //     .f(conv_2d_1_knl_2),
    //     .g(conv_2d_0_img_3),
    //     .h(conv_2d_1_knl_3),
    //     .rnd(3'b000),
    //     .z(conv_2d_k1_0_out),
    //     .status()
    // );
    // DW_fp_dp4 #(
    //     .sig_width(inst_sig_width),
    //     .exp_width(inst_exp_width),
    //     .ieee_compliance(inst_ieee_compliance),
    //     .arch_type(inst_arch_type)
    // ) DW_fp_dp4_instance_k1_1 (
    //     .a(conv_2d_1_img_0),
    //     .b(conv_2d_1_knl_0),
    //     .c(conv_2d_1_img_1),
    //     .d(conv_2d_1_knl_1),
    //     .e(conv_2d_1_img_2),
    //     .f(conv_2d_1_knl_2),
    //     .g(conv_2d_1_img_3),
    //     .h(conv_2d_1_knl_3),
    //     .rnd(3'b000),
    //     .z(conv_2d_k1_1_out),
    //     .status()
    // );
    fp_dp4 #(
        .inst_sig_width(inst_sig_width),
        .inst_exp_width(inst_exp_width),
        .inst_ieee_compliance(inst_ieee_compliance)
    ) fp_dp4_instance_k0_0 (
        .img0(conv_2d_0_img_0),
        .img1(conv_2d_0_img_1),
        .img2(conv_2d_0_img_2),
        .img3(conv_2d_0_img_3),
        .krl0(conv_2d_0_knl_0),
        .krl1(conv_2d_0_knl_1),
        .krl2(conv_2d_0_knl_2),
        .krl3(conv_2d_0_knl_3),
        .out(conv_2d_k0_0_out)
    );
    fp_dp4 #(
        .inst_sig_width(inst_sig_width),
        .inst_exp_width(inst_exp_width),
        .inst_ieee_compliance(inst_ieee_compliance)
    ) fp_dp4_instance_k0_1 (
        .img0(conv_2d_1_img_0),
        .img1(conv_2d_1_img_1),
        .img2(conv_2d_1_img_2),
        .img3(conv_2d_1_img_3),
        .krl0(conv_2d_0_knl_0),
        .krl1(conv_2d_0_knl_1),
        .krl2(conv_2d_0_knl_2),
        .krl3(conv_2d_0_knl_3),
        .out(conv_2d_k0_1_out)
    );
    fp_dp4 #(
        .inst_sig_width(inst_sig_width),
        .inst_exp_width(inst_exp_width),
        .inst_ieee_compliance(inst_ieee_compliance)
    ) fp_dp4_instance_k1_0 (
        .img0(conv_2d_0_img_0),
        .img1(conv_2d_0_img_1),
        .img2(conv_2d_0_img_2),
        .img3(conv_2d_0_img_3),
        .krl0(conv_2d_1_knl_0),
        .krl1(conv_2d_1_knl_1),
        .krl2(conv_2d_1_knl_2),
        .krl3(conv_2d_1_knl_3),
        .out(conv_2d_k1_0_out)
    );
    fp_dp4 #(
        .inst_sig_width(inst_sig_width),
        .inst_exp_width(inst_exp_width),
        .inst_ieee_compliance(inst_ieee_compliance)
    ) fp_dp4_instance_k1_1 (
        .img0(conv_2d_1_img_0),
        .img1(conv_2d_1_img_1),
        .img2(conv_2d_1_img_2),
        .img3(conv_2d_1_img_3),
        .krl0(conv_2d_1_knl_0),
        .krl1(conv_2d_1_knl_1),
        .krl2(conv_2d_1_knl_2),
        .krl3(conv_2d_1_knl_3),
        .out(conv_2d_k1_1_out)
    );

    // Split the stage here
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            conv_2d_k0_0_out_reg <= 0;
            conv_2d_k0_1_out_reg <= 0;
            conv_2d_k1_0_out_reg <= 0;
            conv_2d_k1_1_out_reg <= 0;
        end else begin
            conv_2d_k0_0_out_reg <= conv_2d_k0_0_out;
            conv_2d_k0_1_out_reg <= conv_2d_k0_1_out;
            conv_2d_k1_0_out_reg <= conv_2d_k1_0_out;
            conv_2d_k1_1_out_reg <= conv_2d_k1_1_out;
        end
    end
    // TODO: Use conv_2d_k0_1_out_reg as fc_out[0]...
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            for (i = 0; i < 2; i = i+1) begin
                fc_out[i] <= 0;
            end
        end else begin
            case (cs) // @suppress "Default clause missing from case statement"
                80: fc_out[0] <= conv_2d_k0_0_out;
                81: fc_out[1] <= conv_2d_k0_0_out;
                82: fc_out[2] <= conv_2d_k0_0_out;
                85: fc_out[0] <= conv_2d_add_ch0_0_z;
                86: begin
                    fc_out[0] <= exp_out;
                    fc_out[1] <= conv_2d_add_ch0_0_z;
                end
                87: begin
                    fc_out[1] <= exp_out;
                    fc_out[2] <= conv_2d_add_ch0_0_z;
                end
                88: fc_out[2] <= exp_out;
                89: fc_out[0] <= fc_out[1];
                90: fc_out[0] <= fc_out[2];
            endcase
        end
    end

    always @(*) begin
        // Default
        conv_2d_add_ch0_0_b = 32'bX;
        conv_2d_add_ch0_1_b = 32'bX;
        conv_2d_add_ch1_0_b = 32'bX;
        conv_2d_add_ch1_1_b = 32'bX;
        for (i = 0; i < 6; i = i + 1) begin
            for (j = 0; j < 6; j = j + 1) begin
                conv_2d_0_sum_next[i][j] = conv_2d_0_sum[i][j];
                conv_2d_1_sum_next[i][j] = conv_2d_1_sum[i][j];
            end
        end
        case (cs)
            4+1,   4+1*25+1,  4+2*25+1: begin
                conv_2d_add_ch0_0_b = conv_2d_0_sum[0][0];
                conv_2d_add_ch0_1_b = conv_2d_0_sum[0][1];
                conv_2d_add_ch1_0_b = conv_2d_1_sum[0][0];
                conv_2d_add_ch1_1_b = conv_2d_1_sum[0][1];
                conv_2d_0_sum_next[0][0] = conv_2d_add_ch0_0_z;
                conv_2d_0_sum_next[0][1] = conv_2d_add_ch0_1_z;
                conv_2d_1_sum_next[0][0] = conv_2d_add_ch1_0_z;
                conv_2d_1_sum_next[0][1] = conv_2d_add_ch1_1_z;
            end
            5+1,   5+1*25+1,  5+2*25+1: begin
                conv_2d_add_ch0_1_b = conv_2d_0_sum[0][2];
                conv_2d_add_ch1_1_b = conv_2d_1_sum[0][2];
                conv_2d_0_sum_next[0][2] = conv_2d_add_ch0_1_z;
                conv_2d_1_sum_next[0][2] = conv_2d_add_ch1_1_z;
            end
            6+1,   6+1*25+1,  6+2*25+1: begin
                conv_2d_add_ch0_1_b = conv_2d_0_sum[0][3];
                conv_2d_add_ch1_1_b = conv_2d_1_sum[0][3];
                conv_2d_0_sum_next[0][3] = conv_2d_add_ch0_1_z;
                conv_2d_1_sum_next[0][3] = conv_2d_add_ch1_1_z;
            end
            7+1,   7+1*25+1,  7+2*25+1: begin
                conv_2d_add_ch0_0_b = conv_2d_0_sum[0][5];
                conv_2d_add_ch0_1_b = conv_2d_0_sum[0][4];
                conv_2d_add_ch1_0_b = conv_2d_1_sum[0][5];
                conv_2d_add_ch1_1_b = conv_2d_1_sum[0][4];
                conv_2d_0_sum_next[0][5] = conv_2d_add_ch0_0_z;
                conv_2d_0_sum_next[0][4] = conv_2d_add_ch0_1_z;
                conv_2d_1_sum_next[0][5] = conv_2d_add_ch1_0_z;
                conv_2d_1_sum_next[0][4] = conv_2d_add_ch1_1_z;
            end
            9+1,   9+1*25+1,  9+2*25+1: begin
                conv_2d_add_ch0_0_b = conv_2d_0_sum[1][0];
                conv_2d_add_ch0_1_b = conv_2d_0_sum[1][1];
                conv_2d_add_ch1_0_b = conv_2d_1_sum[1][0];
                conv_2d_add_ch1_1_b = conv_2d_1_sum[1][1];
                conv_2d_0_sum_next[1][0] = conv_2d_add_ch0_0_z;
                conv_2d_0_sum_next[1][1] = conv_2d_add_ch0_1_z;
                conv_2d_1_sum_next[1][0] = conv_2d_add_ch1_0_z;
                conv_2d_1_sum_next[1][1] = conv_2d_add_ch1_1_z;
            end
            10+1, 10+1*25+1, 10+2*25+1: begin
                conv_2d_add_ch0_1_b = conv_2d_0_sum[1][2];
                conv_2d_add_ch1_1_b = conv_2d_1_sum[1][2];
                conv_2d_0_sum_next[1][2] = conv_2d_add_ch0_1_z;
                conv_2d_1_sum_next[1][2] = conv_2d_add_ch1_1_z;
            end
            11+1, 11+1*25+1, 11+2*25+1: begin
                conv_2d_add_ch0_1_b = conv_2d_0_sum[1][3];
                conv_2d_add_ch1_1_b = conv_2d_1_sum[1][3];
                conv_2d_0_sum_next[1][3] = conv_2d_add_ch0_1_z;
                conv_2d_1_sum_next[1][3] = conv_2d_add_ch1_1_z;
            end
            12+1, 12+1*25+1, 12+2*25+1: begin
                conv_2d_add_ch0_0_b = conv_2d_0_sum[1][5];
                conv_2d_add_ch0_1_b = conv_2d_0_sum[1][4];
                conv_2d_add_ch1_0_b = conv_2d_1_sum[1][5];
                conv_2d_add_ch1_1_b = conv_2d_1_sum[1][4];
                conv_2d_0_sum_next[1][5] = conv_2d_add_ch0_0_z;
                conv_2d_0_sum_next[1][4] = conv_2d_add_ch0_1_z;
                conv_2d_1_sum_next[1][5] = conv_2d_add_ch1_0_z;
                conv_2d_1_sum_next[1][4] = conv_2d_add_ch1_1_z;
            end
            14+1, 14+1*25+1, 14+2*25+1: begin
                conv_2d_add_ch0_0_b = conv_2d_0_sum[2][0];
                conv_2d_add_ch0_1_b = conv_2d_0_sum[2][1];
                conv_2d_add_ch1_0_b = conv_2d_1_sum[2][0];
                conv_2d_add_ch1_1_b = conv_2d_1_sum[2][1];
                conv_2d_0_sum_next[2][0] = conv_2d_add_ch0_0_z;
                conv_2d_0_sum_next[2][1] = conv_2d_add_ch0_1_z;
                conv_2d_1_sum_next[2][0] = conv_2d_add_ch1_0_z;
                conv_2d_1_sum_next[2][1] = conv_2d_add_ch1_1_z;
            end
            15+1, 15+1*25+1, 15+2*25+1: begin
                conv_2d_add_ch0_1_b = conv_2d_0_sum[2][2];
                conv_2d_add_ch1_1_b = conv_2d_1_sum[2][2];
                conv_2d_0_sum_next[2][2] = conv_2d_add_ch0_1_z;
                conv_2d_1_sum_next[2][2] = conv_2d_add_ch1_1_z;
            end
            16+1, 16+1*25+1, 16+2*25+1: begin
                conv_2d_add_ch0_1_b = conv_2d_0_sum[2][3];
                conv_2d_add_ch1_1_b = conv_2d_1_sum[2][3];
                conv_2d_0_sum_next[2][3] = conv_2d_add_ch0_1_z;
                conv_2d_1_sum_next[2][3] = conv_2d_add_ch1_1_z;
            end
            17+1, 17+1*25+1, 17+2*25+1: begin
                conv_2d_add_ch0_0_b = conv_2d_0_sum[2][5];
                conv_2d_add_ch0_1_b = conv_2d_0_sum[2][4];
                conv_2d_add_ch1_0_b = conv_2d_1_sum[2][5];
                conv_2d_add_ch1_1_b = conv_2d_1_sum[2][4];
                conv_2d_0_sum_next[2][5] = conv_2d_add_ch0_0_z;
                conv_2d_0_sum_next[2][4] = conv_2d_add_ch0_1_z;
                conv_2d_1_sum_next[2][5] = conv_2d_add_ch1_0_z;
                conv_2d_1_sum_next[2][4] = conv_2d_add_ch1_1_z;
            end
            19+1, 19+1*25+1, 19+2*25+1: begin
                conv_2d_add_ch0_0_b = conv_2d_0_sum[3][0];
                conv_2d_add_ch0_1_b = conv_2d_0_sum[3][1];
                conv_2d_add_ch1_0_b = conv_2d_1_sum[3][0];
                conv_2d_add_ch1_1_b = conv_2d_1_sum[3][1];
                conv_2d_0_sum_next[3][0] = conv_2d_add_ch0_0_z;
                conv_2d_0_sum_next[3][1] = conv_2d_add_ch0_1_z;
                conv_2d_1_sum_next[3][0] = conv_2d_add_ch1_0_z;
                conv_2d_1_sum_next[3][1] = conv_2d_add_ch1_1_z;
            end
            20+1, 20+1*25+1, 20+2*25+1: begin
                conv_2d_add_ch0_1_b = conv_2d_0_sum[3][2];
                conv_2d_add_ch1_1_b = conv_2d_1_sum[3][2];
                conv_2d_0_sum_next[3][2] = conv_2d_add_ch0_1_z;
                conv_2d_1_sum_next[3][2] = conv_2d_add_ch1_1_z;
            end
            21+1, 21+1*25+1, 21+2*25+1: begin
                conv_2d_add_ch0_1_b = conv_2d_0_sum[3][3];
                conv_2d_add_ch1_1_b = conv_2d_1_sum[3][3];
                conv_2d_0_sum_next[3][3] = conv_2d_add_ch0_1_z;
                conv_2d_1_sum_next[3][3] = conv_2d_add_ch1_1_z;
            end
            22+1, 22+1*25+1, 22+2*25+1: begin
                conv_2d_add_ch0_0_b = conv_2d_0_sum[3][5];
                conv_2d_add_ch0_1_b = conv_2d_0_sum[3][4];
                conv_2d_add_ch1_0_b = conv_2d_1_sum[3][5];
                conv_2d_add_ch1_1_b = conv_2d_1_sum[3][4];
                conv_2d_0_sum_next[3][5] = conv_2d_add_ch0_0_z;
                conv_2d_0_sum_next[3][4] = conv_2d_add_ch0_1_z;
                conv_2d_1_sum_next[3][5] = conv_2d_add_ch1_0_z;
                conv_2d_1_sum_next[3][4] = conv_2d_add_ch1_1_z;
            end
            23+1, 23+1*25+1, 23+2*25+1: begin
                conv_2d_add_ch0_0_b = conv_2d_0_sum[5][0];
                conv_2d_add_ch0_1_b = conv_2d_0_sum[4][0];
                conv_2d_add_ch1_0_b = conv_2d_1_sum[5][0];
                conv_2d_add_ch1_1_b = conv_2d_1_sum[4][0];
                conv_2d_0_sum_next[5][0] = conv_2d_add_ch0_0_z;
                conv_2d_0_sum_next[4][0] = conv_2d_add_ch0_1_z;
                conv_2d_1_sum_next[5][0] = conv_2d_add_ch1_0_z;
                conv_2d_1_sum_next[4][0] = conv_2d_add_ch1_1_z;
            end
            24+1, 24+1*25+1, 24+2*25+1: begin
                conv_2d_add_ch0_0_b = conv_2d_0_sum[5][1];
                conv_2d_add_ch0_1_b = conv_2d_0_sum[4][1];
                conv_2d_add_ch1_0_b = conv_2d_1_sum[5][1];
                conv_2d_add_ch1_1_b = conv_2d_1_sum[4][1];
                conv_2d_0_sum_next[5][1] = conv_2d_add_ch0_0_z;
                conv_2d_0_sum_next[4][1] = conv_2d_add_ch0_1_z;
                conv_2d_1_sum_next[5][1] = conv_2d_add_ch1_0_z;
                conv_2d_1_sum_next[4][1] = conv_2d_add_ch1_1_z;
            end
            25+1, 25+1*25+1, 25+2*25+1: begin
                conv_2d_add_ch0_0_b = conv_2d_0_sum[5][2];
                conv_2d_add_ch0_1_b = conv_2d_0_sum[4][2];
                conv_2d_add_ch1_0_b = conv_2d_1_sum[5][2];
                conv_2d_add_ch1_1_b = conv_2d_1_sum[4][2];
                conv_2d_0_sum_next[5][2] = conv_2d_add_ch0_0_z;
                conv_2d_0_sum_next[4][2] = conv_2d_add_ch0_1_z;
                conv_2d_1_sum_next[5][2] = conv_2d_add_ch1_0_z;
                conv_2d_1_sum_next[4][2] = conv_2d_add_ch1_1_z;
            end
            26+1, 26+1*25+1, 26+2*25+1: begin
                conv_2d_add_ch0_0_b = conv_2d_0_sum[5][3];
                conv_2d_add_ch0_1_b = conv_2d_0_sum[4][3];
                conv_2d_add_ch1_0_b = conv_2d_1_sum[5][3];
                conv_2d_add_ch1_1_b = conv_2d_1_sum[4][3];
                conv_2d_0_sum_next[5][3] = conv_2d_add_ch0_0_z;
                conv_2d_0_sum_next[4][3] = conv_2d_add_ch0_1_z;
                conv_2d_1_sum_next[5][3] = conv_2d_add_ch1_0_z;
                conv_2d_1_sum_next[4][3] = conv_2d_add_ch1_1_z;
            end
            27+1, 27+1*25+1, 27+2*25+1: begin
                conv_2d_add_ch0_0_b = conv_2d_0_sum[5][4];
                conv_2d_add_ch0_1_b = conv_2d_0_sum[4][4];
                conv_2d_add_ch1_0_b = conv_2d_1_sum[5][4];
                conv_2d_add_ch1_1_b = conv_2d_1_sum[4][4];
                conv_2d_0_sum_next[5][4] = conv_2d_add_ch0_0_z;
                conv_2d_0_sum_next[4][4] = conv_2d_add_ch0_1_z;
                conv_2d_1_sum_next[5][4] = conv_2d_add_ch1_0_z;
                conv_2d_1_sum_next[4][4] = conv_2d_add_ch1_1_z;
            end
            28+1, 28+1*25+1, 28+2*25+1: begin
                conv_2d_add_ch0_0_b = conv_2d_0_sum[5][5];
                conv_2d_add_ch0_1_b = conv_2d_0_sum[4][5];
                conv_2d_add_ch1_0_b = conv_2d_1_sum[5][5];
                conv_2d_add_ch1_1_b = conv_2d_1_sum[4][5];
                conv_2d_0_sum_next[5][5] = conv_2d_add_ch0_0_z;
                conv_2d_0_sum_next[4][5] = conv_2d_add_ch0_1_z;
                conv_2d_1_sum_next[5][5] = conv_2d_add_ch1_0_z;
                conv_2d_1_sum_next[4][5] = conv_2d_add_ch1_1_z;
            end
            //--------------------------------------------
            85: begin
                conv_2d_add_ch0_0_b = fc_out[0];
            end
            86: begin
                conv_2d_add_ch0_0_b = fc_out[1];
            end
            87: begin
                conv_2d_add_ch0_0_b = fc_out[2];
            end
        endcase
    end
    
    DW_fp_add #(
        .sig_width(inst_sig_width),
        .exp_width(inst_exp_width),
        .ieee_compliance(inst_ieee_compliance)
    ) DW_fp_add_instance_k0_0 (
        .a(conv_2d_k0_0_out_reg),
        .b(conv_2d_add_ch0_0_b),
        .rnd(3'b000),
        .z(conv_2d_add_ch0_0_z),
        .status()
    );
    DW_fp_add #(
        .sig_width(inst_sig_width),
        .exp_width(inst_exp_width),
        .ieee_compliance(inst_ieee_compliance)
    ) DW_fp_add_instance_k0_1 (
        .a(conv_2d_k0_1_out_reg),
        .b(conv_2d_add_ch0_1_b),
        .rnd(3'b000),
        .z(conv_2d_add_ch0_1_z),
        .status()
    );
    DW_fp_add #(
        .sig_width(inst_sig_width),
        .exp_width(inst_exp_width),
        .ieee_compliance(inst_ieee_compliance)
    ) DW_fp_add_instance_k1_0 (
        .a(conv_2d_k1_0_out_reg),
        .b(conv_2d_add_ch1_0_b),
        .rnd(3'b000),
        .z(conv_2d_add_ch1_0_z),
        .status()
    );
    DW_fp_add #(
        .sig_width(inst_sig_width),
        .exp_width(inst_exp_width),
        .ieee_compliance(inst_ieee_compliance)
    ) DW_fp_add_instance_k1_1 (
        .a(conv_2d_k1_1_out_reg),
        .b(conv_2d_add_ch1_1_b),
        .rnd(3'b000),
        .z(conv_2d_add_ch1_1_z),
        .status()
    );

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            for (i = 0; i < 6; i = i + 1) begin
                for (j = 0; j < 6; j = j + 1) begin
                    conv_2d_0_sum[i][j] <= 0;
                    conv_2d_1_sum[i][j] <= 0;
                end
            end
        end else begin
            if (cs == 91) begin
                for (i = 0; i < 6; i = i + 1) begin
                    for (j = 0; j < 6; j = j + 1) begin
                        conv_2d_0_sum[i][j] <= 0;
                        conv_2d_1_sum[i][j] <= 0;
                    end
                end
            end else begin
                for (i = 0; i < 6; i = i + 1) begin
                    for (j = 0; j < 6; j = j + 1) begin
                        conv_2d_0_sum[i][j] <= conv_2d_0_sum_next[i][j];
                        conv_2d_1_sum[i][j] <= conv_2d_1_sum_next[i][j];
                    end
                end
            end
        end
    end
    // TODO: Use One Reg to store the max value, compare to it every time got a new value
    always @(*) begin
        case (cs)
            67: begin
                maxpooling_in0 = conv_2d_0_sum[0][0];
                maxpooling_in1 = conv_2d_0_sum[0][1];
                maxpooling_in2 = conv_2d_0_sum[0][2];
                maxpooling_in3 = conv_2d_0_sum[1][0];
                maxpooling_in4 = conv_2d_0_sum[1][1];
                maxpooling_in5 = conv_2d_0_sum[1][2];
                maxpooling_in6 = conv_2d_0_sum[2][0];
                maxpooling_in7 = conv_2d_0_sum[2][1];
                maxpooling_in8 = conv_2d_0_sum[2][2];
            end
            68: begin
                maxpooling_in0 = conv_2d_1_sum[0][0];
                maxpooling_in1 = conv_2d_1_sum[0][1];
                maxpooling_in2 = conv_2d_1_sum[0][2];
                maxpooling_in3 = conv_2d_1_sum[1][0];
                maxpooling_in4 = conv_2d_1_sum[1][1];
                maxpooling_in5 = conv_2d_1_sum[1][2];
                maxpooling_in6 = conv_2d_1_sum[2][0];
                maxpooling_in7 = conv_2d_1_sum[2][1];
                maxpooling_in8 = conv_2d_1_sum[2][2];
            end
            69: begin
                maxpooling_in0 = conv_2d_0_sum[0][3];
                maxpooling_in1 = conv_2d_0_sum[0][4];
                maxpooling_in2 = conv_2d_0_sum[0][5];
                maxpooling_in3 = conv_2d_0_sum[1][3];
                maxpooling_in4 = conv_2d_0_sum[1][4];
                maxpooling_in5 = conv_2d_0_sum[1][5];
                maxpooling_in6 = conv_2d_0_sum[2][3];
                maxpooling_in7 = conv_2d_0_sum[2][4];
                maxpooling_in8 = conv_2d_0_sum[2][5];
            end
            70: begin
                maxpooling_in0 = conv_2d_1_sum[0][3];
                maxpooling_in1 = conv_2d_1_sum[0][4];
                maxpooling_in2 = conv_2d_1_sum[0][5];
                maxpooling_in3 = conv_2d_1_sum[1][3];
                maxpooling_in4 = conv_2d_1_sum[1][4];
                maxpooling_in5 = conv_2d_1_sum[1][5];
                maxpooling_in6 = conv_2d_1_sum[2][3];
                maxpooling_in7 = conv_2d_1_sum[2][4];
                maxpooling_in8 = conv_2d_1_sum[2][5];
            end
            77: begin
                maxpooling_in0 = conv_2d_0_sum[3][0];
                maxpooling_in1 = conv_2d_0_sum[3][1];
                maxpooling_in2 = conv_2d_0_sum[3][2];
                maxpooling_in3 = conv_2d_0_sum[4][0];
                maxpooling_in4 = conv_2d_0_sum[4][1];
                maxpooling_in5 = conv_2d_0_sum[4][2];
                maxpooling_in6 = conv_2d_0_sum[5][0];
                maxpooling_in7 = conv_2d_0_sum[5][1];
                maxpooling_in8 = conv_2d_0_sum[5][2];
            end
            78: begin
                maxpooling_in0 = conv_2d_1_sum[3][0];
                maxpooling_in1 = conv_2d_1_sum[3][1];
                maxpooling_in2 = conv_2d_1_sum[3][2];
                maxpooling_in3 = conv_2d_1_sum[4][0];
                maxpooling_in4 = conv_2d_1_sum[4][1];
                maxpooling_in5 = conv_2d_1_sum[4][2];
                maxpooling_in6 = conv_2d_1_sum[5][0];
                maxpooling_in7 = conv_2d_1_sum[5][1];
                maxpooling_in8 = conv_2d_1_sum[5][2];
            end
            80: begin
                maxpooling_in0 = conv_2d_0_sum[3][3];
                maxpooling_in1 = conv_2d_0_sum[3][4];
                maxpooling_in2 = conv_2d_0_sum[3][5];
                maxpooling_in3 = conv_2d_0_sum[4][3];
                maxpooling_in4 = conv_2d_0_sum[4][4];
                maxpooling_in5 = conv_2d_0_sum[4][5];
                maxpooling_in6 = conv_2d_0_sum[5][3];
                maxpooling_in7 = conv_2d_0_sum[5][4];
                maxpooling_in8 = conv_2d_0_sum[5][5];
            end
            81: begin
                maxpooling_in0 = conv_2d_1_sum[3][3];
                maxpooling_in1 = conv_2d_1_sum[3][4];
                maxpooling_in2 = conv_2d_1_sum[3][5];
                maxpooling_in3 = conv_2d_1_sum[4][3];
                maxpooling_in4 = conv_2d_1_sum[4][4];
                maxpooling_in5 = conv_2d_1_sum[4][5];
                maxpooling_in6 = conv_2d_1_sum[5][3];
                maxpooling_in7 = conv_2d_1_sum[5][4];
                maxpooling_in8 = conv_2d_1_sum[5][5];
            end
            default: begin
                maxpooling_in0 = 32'bX;
                maxpooling_in1 = 32'bX;
                maxpooling_in2 = 32'bX;
                maxpooling_in3 = 32'bX;
                maxpooling_in4 = 32'bX;
                maxpooling_in5 = 32'bX;
                maxpooling_in6 = 32'bX;
                maxpooling_in7 = 32'bX;
                maxpooling_in8 = 32'bX;
            end
        endcase
    end
    MaxPooling #(
        .inst_sig_width(inst_sig_width),
        .inst_exp_width(inst_exp_width),
        .inst_ieee_compliance(inst_ieee_compliance)
    ) MaxPooling_instance (
        .in0(maxpooling_in0),
        .in1(maxpooling_in1),
        .in2(maxpooling_in2),
        .in3(maxpooling_in3),
        .in4(maxpooling_in4),
        .in5(maxpooling_in5),
        .in6(maxpooling_in6),
        .in7(maxpooling_in7),
        .in8(maxpooling_in8),
        .out(maxpooling_out)
    );

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            for (i = 0; i < 8; i = i + 1) begin
                maxpooling_out_reg[i] <= 0;
            end
        end else begin
            case (cs) // @suppress "Default clause missing from case statement"
                67: begin
                    maxpooling_out_reg[0] <= maxpooling_out;
                end
                68: begin
                    maxpooling_out_reg[4] <= maxpooling_out;
                end
                69: begin
                    maxpooling_out_reg[1] <= maxpooling_out;
                    maxpooling_out_reg[0] <= activate_out;
                end
                70: begin
                    maxpooling_out_reg[5] <= maxpooling_out;
                    maxpooling_out_reg[4] <= activate_out;
                end
                71: begin
                    maxpooling_out_reg[1] <= activate_out;
                end
                72: begin
                    maxpooling_out_reg[5] <= activate_out;
                end
                77: begin
                    maxpooling_out_reg[2] <= maxpooling_out;
                end
                78: begin
                    maxpooling_out_reg[6] <= maxpooling_out;
                end
                79: begin
                    maxpooling_out_reg[2] <= activate_out;
                end
                80: begin
                    maxpooling_out_reg[3] <= maxpooling_out;
                    maxpooling_out_reg[6] <= activate_out;
                end
                81: begin
                    maxpooling_out_reg[7] <= maxpooling_out;
                end
                82: begin
                    maxpooling_out_reg[3] <= activate_out;
                end
                83: begin
                    maxpooling_out_reg[7] <= activate_out;
                end
            endcase
        end
    end
    always @(*) begin
        case (cs)
            68: begin
                activate_in = maxpooling_out_reg[0];
            end
            69: begin
                activate_in = maxpooling_out_reg[4];
            end
            70: begin
                activate_in = maxpooling_out_reg[1];
            end
            71: begin
                activate_in = maxpooling_out_reg[5];
            end
            78: begin
                activate_in = maxpooling_out_reg[2];
            end
            79: begin
                activate_in = maxpooling_out_reg[6];
            end
            81: begin
                activate_in = maxpooling_out_reg[3];
            end
            82: begin
                activate_in = maxpooling_out_reg[7];
            end
            86: begin
                activate_in = {~fc_out[0][inst_sig_width+inst_exp_width], fc_out[0][inst_sig_width+inst_exp_width-1:0]};
            end
            87: begin
                activate_in = {~fc_out[1][inst_sig_width+inst_exp_width], fc_out[1][inst_sig_width+inst_exp_width-1:0]};
            end
            88: begin
                activate_in = {~fc_out[2][inst_sig_width+inst_exp_width], fc_out[2][inst_sig_width+inst_exp_width-1:0]};
            end
            default: begin
                activate_in = 32'bX;
            end
        endcase
    end
    // Activate #(
    //     .inst_sig_width(inst_sig_width),
    //     .inst_exp_width(inst_exp_width),
    //     .inst_ieee_compliance(inst_ieee_compliance),
    //     .inst_arch_type(inst_arch_type),
    //     .inst_arch(inst_arch)
    // ) Activate_instance (
    //     .opt(opt),
    //     .in(activate_in),
    //     .out(activate_out),
    //     .exp(fc_exp)
    // );
    wire [inst_exp_width-1:0] exp_p1;
    assign exp_p1 = activate_in[inst_sig_width+inst_exp_width-1:inst_sig_width]+1;
    assign one = 32'b0_01111111_00000000000000000000000;
    assign act_muln2 = {~activate_in[inst_sig_width+inst_exp_width], exp_p1, activate_in[inst_sig_width-1:0]};
    assign act_muln1 = {~activate_in[inst_sig_width+inst_exp_width], {activate_in[inst_sig_width+inst_exp_width-1:inst_sig_width]}, activate_in[inst_sig_width-1:0]};
    assign exp_in = opt ? act_muln2: act_muln1; // tanh : sigmoid
    assign activate_out = opt ? recip_out_mul2_sub1 : recip_out; // tanh : sigmoid
    always @(*) begin
        if (cs < 89) begin
            div_a = one;
        end else begin
            div_a = fc_out[0];
        end
    end
    always @(*) begin
        if (cs < 89) begin
            div_b = add_one_out_reg;
        end else begin
            div_b = fc_exp_sum_reg;
        end
    end
    
    DW_fp_exp #(
        .sig_width(inst_sig_width),
        .exp_width(inst_exp_width),
        .ieee_compliance(inst_ieee_compliance),
        .arch(inst_arch)
    ) DW_fp_exp_instance_u1 (
        .a(exp_in),
        .z(exp_out),
        .status()
    );
    DW_fp_add #(
        .sig_width(inst_sig_width),
        .exp_width(inst_exp_width),
        .ieee_compliance(inst_ieee_compliance)
    ) DW_fp_add_instance_add_one (
        .a(exp_out),
        .b(one),
        .rnd(3'b000),
        .z(add_one_out),
        .status()
    );
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            add_one_out_reg <= 0;
        end else begin
            add_one_out_reg <= add_one_out;
        end
    end
    DW_fp_div #(
        .sig_width(inst_sig_width),
        .exp_width(inst_exp_width),
        .ieee_compliance(inst_ieee_compliance),
        .faithful_round(inst_faithful_round)
    ) DW_fp_div_instance (
        .a(div_a),
        .b(div_b),
        .rnd(3'b000),
        .z(recip_out),
        .status()
    );
    wire [inst_exp_width-1:0] recip_out_exp_p1;
    assign recip_out_exp_p1 = recip_out[inst_sig_width+inst_exp_width-1:inst_sig_width]+1;
    DW_fp_sub #(
        .sig_width(inst_sig_width),
        .exp_width(inst_exp_width),
        .ieee_compliance(inst_ieee_compliance)
    ) DW_fp_sub_instance_u0 (
        .a({recip_out[inst_sig_width+inst_exp_width], recip_out_exp_p1, recip_out[inst_sig_width-1:0]}),
        .b(one),
        .rnd(3'b000),
        .z(recip_out_mul2_sub1),
        .status()
    );

    DW_fp_add #(
        .sig_width(inst_sig_width),
        .exp_width(inst_exp_width),
        .ieee_compliance(inst_ieee_compliance)
    ) DW_fp_add_instance (
        .a(exp_out),
        .b(fc_exp_sum_reg),
        .rnd(3'b000),
        .z(fc_exp_sum),
        .status()
    );
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            fc_exp_sum_reg <= 0;
        end else begin
            if (
                cs == 86 ||
                cs == 87 ||
                cs == 88
            ) begin
                fc_exp_sum_reg <= fc_exp_sum;
            end else
            if (cs == 91) begin
                fc_exp_sum_reg <= 0;
            end
        end
    end
    always @(*) begin
        out_valid = (cs == 89) || (cs == 90) || (cs == 91);
    end
    always @(*) begin
        out = {inst_sig_width+inst_exp_width+1{out_valid}} & recip_out;
    end

endmodule

module MaxPooling(
    in0, in1, in2, in3, in4, in5, in6, in7, in8,
    out
);
    // IEEE floating point parameter
    parameter inst_sig_width = 23;
    parameter inst_exp_width = 8;
    parameter inst_ieee_compliance = 0;
    input [inst_sig_width+inst_exp_width:0] in0;
    input [inst_sig_width+inst_exp_width:0] in1;
    input [inst_sig_width+inst_exp_width:0] in2;
    input [inst_sig_width+inst_exp_width:0] in3;
    input [inst_sig_width+inst_exp_width:0] in4;
    input [inst_sig_width+inst_exp_width:0] in5;
    input [inst_sig_width+inst_exp_width:0] in6;
    input [inst_sig_width+inst_exp_width:0] in7;
    input [inst_sig_width+inst_exp_width:0] in8;
    output [inst_sig_width+inst_exp_width:0] out;
    wire [inst_sig_width+inst_exp_width:0] max1, max2, max3, max4;
    wire [inst_sig_width+inst_exp_width:0] max5, max6, max7;
    DW_fp_cmp #(
        .sig_width(inst_sig_width),
        .exp_width(inst_exp_width),
        .ieee_compliance(inst_ieee_compliance)
    ) DW_fp_cmp_instance_u0 (
        .a(in0),
        .b(in1),
        .zctr(1'b0),
        .aeqb(),
        .altb(),
        .agtb(),
        .unordered(),
        .z0(),
        .z1(max1),
        .status0(),
        .status1()
    );
    DW_fp_cmp #(
        .sig_width(inst_sig_width),
        .exp_width(inst_exp_width),
        .ieee_compliance(inst_ieee_compliance)
    ) DW_fp_cmp_instance_u1 (
        .a(in2),
        .b(in3),
        .zctr(1'b0),
        .aeqb(),
        .altb(),
        .agtb(),
        .unordered(),
        .z0(),
        .z1(max2),
        .status0(),
        .status1()
    );
    DW_fp_cmp #(
        .sig_width(inst_sig_width),
        .exp_width(inst_exp_width),
        .ieee_compliance(inst_ieee_compliance)
    ) DW_fp_cmp_instance_u2 (
        .a(in4),
        .b(in5),
        .zctr(1'b0),
        .aeqb(),
        .altb(),
        .agtb(),
        .unordered(),
        .z0(),
        .z1(max3),
        .status0(),
        .status1()
    );
    DW_fp_cmp #(
        .sig_width(inst_sig_width),
        .exp_width(inst_exp_width),
        .ieee_compliance(inst_ieee_compliance)
    ) DW_fp_cmp_instance_u3 (
        .a(in6),
        .b(in7),
        .zctr(1'b0),
        .aeqb(),
        .altb(),
        .agtb(),
        .unordered(),
        .z0(),
        .z1(max4),
        .status0(),
        .status1()
    );
    DW_fp_cmp #(
        .sig_width(inst_sig_width),
        .exp_width(inst_exp_width),
        .ieee_compliance(inst_ieee_compliance)
    ) DW_fp_cmp_instance_u4 (
        .a(max1),
        .b(max2),
        .zctr(1'b0),
        .aeqb(),
        .altb(),
        .agtb(),
        .unordered(),
        .z0(),
        .z1(max5),
        .status0(),
        .status1()
    );
    DW_fp_cmp #(
        .sig_width(inst_sig_width),
        .exp_width(inst_exp_width),
        .ieee_compliance(inst_ieee_compliance)
    ) DW_fp_cmp_instance_u5 (
        .a(max3),
        .b(max4),
        .zctr(1'b0),
        .aeqb(),
        .altb(),
        .agtb(),
        .unordered(),
        .z0(),
        .z1(max6),
        .status0(),
        .status1()
    );
    DW_fp_cmp #(
        .sig_width(inst_sig_width),
        .exp_width(inst_exp_width),
        .ieee_compliance(inst_ieee_compliance)
    ) DW_fp_cmp_instance_u6 (
        .a(max5),
        .b(max6),
        .zctr(1'b0),
        .aeqb(),
        .altb(),
        .agtb(),
        .unordered(),
        .z0(),
        .z1(max7),
        .status0(),
        .status1()
    );
    DW_fp_cmp #(
        .sig_width(inst_sig_width),
        .exp_width(inst_exp_width),
        .ieee_compliance(inst_ieee_compliance)
    ) DW_fp_cmp_instance_u7 (
        .a(max7),
        .b(in8),
        .zctr(1'b0),
        .aeqb(),
        .altb(),
        .agtb(),
        .unordered(),
        .z0(),
        .z1(out),
        .status0(),
        .status1()
    );
endmodule

module fp_dp4(
    img0, img1, img2, img3,
    krl0, krl1, krl2, krl3,
    out
);
    parameter inst_sig_width = 23;
    parameter inst_exp_width = 8;
    parameter inst_ieee_compliance = 0;
    input [inst_sig_width+inst_exp_width:0] img0, img1, img2, img3;
    input [inst_sig_width+inst_exp_width:0] krl0, krl1, krl2, krl3;
    output [inst_sig_width+inst_exp_width:0] out;

    wire [inst_sig_width+inst_exp_width:0] mul_out0, mul_out1, mul_out2, mul_out3;
    wire [inst_sig_width+inst_exp_width:0] mul_sum01, mul_sum23;
    
    fp_mul #(
        .inst_sig_width(inst_sig_width),
        .inst_exp_width(inst_exp_width),
        .inst_ieee_compliance(inst_ieee_compliance)
    ) fp_mul_u0 (
        .a(img0),
        .b(krl0),
        .out(mul_out0)
    );
    fp_mul #(
        .inst_sig_width(inst_sig_width),
        .inst_exp_width(inst_exp_width),
        .inst_ieee_compliance(inst_ieee_compliance)
    ) fp_mul_u1 (
        .a(img1),
        .b(krl1),
        .out(mul_out1)
    );
    fp_mul #(
        .inst_sig_width(inst_sig_width),
        .inst_exp_width(inst_exp_width),
        .inst_ieee_compliance(inst_ieee_compliance)
    ) fp_mul_u2 (
        .a(img2),
        .b(krl2),
        .out(mul_out2)
    );
    fp_mul #(
        .inst_sig_width(inst_sig_width),
        .inst_exp_width(inst_exp_width),
        .inst_ieee_compliance(inst_ieee_compliance)
    ) fp_mul_u3 (
        .a(img3),
        .b(krl3),
        .out(mul_out3)
    );
    DW_fp_add #(
        .sig_width(inst_sig_width),
        .exp_width(inst_exp_width),
        .ieee_compliance(inst_ieee_compliance)
    ) DW_fp_add_instance_u0 (
        .a(mul_out0),
        .b(mul_out1),
        .rnd(3'd0),
        .z(mul_sum01),
        .status()
    );
    DW_fp_add #(
        .sig_width(inst_sig_width),
        .exp_width(inst_exp_width),
        .ieee_compliance(inst_ieee_compliance)
    ) DW_fp_add_instance_u1 (
        .a(mul_out2),
        .b(mul_out3),
        .rnd(3'd0),
        .z(mul_sum23),
        .status()
    );
    DW_fp_add #(
        .sig_width(inst_sig_width),
        .exp_width(inst_exp_width),
        .ieee_compliance(inst_ieee_compliance)
    ) DW_fp_add_instance_u2 (
        .a(mul_sum01),
        .b(mul_sum23),
        .rnd(3'd0),
        .z(out),
        .status()
    );

endmodule

module fp_mul(
    a, b,
    out
);
    parameter inst_sig_width = 23;
    parameter inst_exp_width = 8;
    parameter inst_ieee_compliance = 0;
    parameter mult_w = 16;
    input [inst_sig_width+inst_exp_width:0] a;
    input [inst_sig_width+inst_exp_width:0] b;
    output [inst_sig_width+inst_exp_width:0] out;

    wire [inst_sig_width:0] a_sig, b_sig;

    reg  sign_s1;
    reg  [inst_exp_width:0] exp_s1;
    reg  [inst_sig_width-1:0] sig_s1;
    reg  [inst_sig_width+inst_exp_width:0] out_reg;

    wire [mult_w*2+1:0] sig_mult;
    wire [inst_exp_width-1:0] exp_a, exp_b;

    assign a_sig = {1'b1, a[inst_sig_width-1:0]};
    assign b_sig = {1'b1, b[inst_sig_width-1:0]};
    assign exp_a = a[inst_sig_width+inst_exp_width-1:inst_sig_width];
    assign exp_b = b[inst_sig_width+inst_exp_width-1:inst_sig_width];

    always @(*) begin
        sign_s1 = a[inst_sig_width+inst_exp_width] ^ b[inst_sig_width+inst_exp_width];
    end

    always @(*) begin
        exp_s1 = exp_a + exp_b - 8'd127 + (sig_mult[mult_w*2+1] == 1'b1);
    end

    always @(*) begin
        if (sig_mult[mult_w*2+1] == 1'b1) begin
            sig_s1 = sig_mult[mult_w*2:mult_w*2-inst_sig_width+1];
        end else begin
            sig_s1 = sig_mult[mult_w*2-1:mult_w*2-inst_sig_width];
        end
    end

    always @(*) begin
        if (exp_a == 0 || exp_b == 0) begin
            out_reg = 0;
        end else begin
            out_reg = {sign_s1, exp_s1[inst_exp_width-1:0], sig_s1};
        end
    end
    

    DW02_mult #(
        .A_width(mult_w+1),
        .B_width(mult_w+1)
    ) DW02_mult_instance (
        .A(a_sig[inst_sig_width:inst_sig_width-mult_w]),
        .B(b_sig[inst_sig_width:inst_sig_width-mult_w]),
        .TC(1'b0),
        .PRODUCT(sig_mult)
    );
    
    assign out = out_reg;

endmodule