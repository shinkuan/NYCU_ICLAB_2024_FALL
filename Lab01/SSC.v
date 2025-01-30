//================================================================
//  Include Files
//================================================================
`include "/usr/cad/synopsys/synthesis/cur/dw/sim_ver/DW02_mult.v"
`include "/usr/cad/synopsys/synthesis/cur/dw/sim_ver/DW01_sub.v"
`include "/usr/cad/synopsys/synthesis/cur/dw/sim_ver/DW02_sum.v"
`include "/usr/cad/synopsys/synthesis/cur/dw/sim_ver/DW01_cmp2.v"

//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2024 Fall
//   Lab01 Exercise		: Snack Shopping Calculator
//   Author     		  : Yu-Hsiang Wang
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : SSC.v
//   Module Name : SSC
//   Release version : V1.0 (Release Date: 2024-09)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
module SSC(
    // Input signals
    card_num,
    input_money,
    snack_num,
    price, 
    // Output signals
    out_valid,
    out_change
);

    //================================================================
    //   INPUT AND OUTPUT DECLARATION                         
    //================================================================
    input [63:0] card_num;
    input [8:0] input_money;
    input [31:0] snack_num;
    input [31:0] price;
    output out_valid;
    output [8:0] out_change; 

    //================================================================
    //    Wire & Registers 
    //================================================================
    wire [63:0] snack_total_price;
    wire [63:0] snack_total_price_sorted;
    wire [ 8:0] mm_out_change [0:8];
    wire        overflow [0:7];
    reg  [ 8:0] out_change_reg;

    //================================================================
    //    DESIGN
    //================================================================
    // ----------------------------------------------------------------
    // Check the card number is valid or not
    // ----------------------------------------------------------------
    Card_Checker card_checker(
        .card_num(card_num),
        .out_valid(out_valid)
    );

    // ----------------------------------------------------------------
    // Calculate the total price of each snack
    // ----------------------------------------------------------------
    genvar i;
    generate for (i = 0; i < 8; i = i + 1) begin: snack_total_price_gen 
        // assign snack_total_price[(i+1)*8-1:i*8] = snack_num[(i+1)*4-1:i*4] * price[(i+1)*4-1:i*4];
        DW02_mult #(4, 4) DW02_mult_instance(
            .A(snack_num[(i+1)*4-1:i*4]),
            .B(price[(i+1)*4-1:i*4]),
            .TC(1'b0),
            .PRODUCT(snack_total_price[(i+1)*8-1:i*8])
        );
    end endgenerate

    // ----------------------------------------------------------------
    // Sort the total price of each snack in ascending order
    // ----------------------------------------------------------------
    Sort_8x8 sort_8x8(
        .in(snack_total_price),
        .out(snack_total_price_sorted)
    );

    // ----------------------------------------------------------------
    // Calculate the change
    // ----------------------------------------------------------------
    assign mm_out_change[0] = input_money;
    generate for (i = 0; i < 8; i = i + 1) begin: mm_out_change_gen
        // assign {overflow[i], mm_out_change[i+1]} = mm_out_change[i] - snack_total_price_sorted[8*i+7:8*i];
        DW01_sub #(.width(9)) DW01_sub_instance(
            .A(mm_out_change[i]),
            .B({1'b0, snack_total_price_sorted[8*i+7:8*i]}),
            .CI(1'b0),
            .DIFF(mm_out_change[i+1]),
            .CO(overflow[i])
        );
    end endgenerate

    always @(*) begin
        case (1'b1)
            !out_valid:  out_change_reg = input_money;
            overflow[0]: out_change_reg = mm_out_change[0];
            overflow[1]: out_change_reg = mm_out_change[1];
            overflow[2]: out_change_reg = mm_out_change[2];
            overflow[3]: out_change_reg = mm_out_change[3];
            overflow[4]: out_change_reg = mm_out_change[4];
            overflow[5]: out_change_reg = mm_out_change[5];
            overflow[6]: out_change_reg = mm_out_change[6];
            overflow[7]: out_change_reg = mm_out_change[7];
            default:     out_change_reg = mm_out_change[8];
        endcase
    end
    assign out_change = out_change_reg;
    
endmodule

//================================================================
//
//   Module Name : Card_Checker
//   Release version : V1.0 (Release Date: 2024-09)
//
//================================================================
//
//   Input  : card_num (64-bit)
//   Output : out_valid (1-bit)
//
//   Function :
//      Check the card number is valid or not.
//
//================================================================
module Card_Checker(
    //================================================================
    //   INPUT AND OUTPUT DECLARATION                         
    //================================================================
    input [63:0] card_num,
    output out_valid
);

    //================================================================
    //    Wire & Registers 
    //================================================================
    wire [3:0] odd_digit [0:7];
    wire [3:0] even_digit [0:7];
    wire [3:0] odd_digit_multx2 [0:7];
    wire [7:0] sum;

    //================================================================
    //    DESIGN
    //================================================================
    // ----------------------------------------------------------------
    // Separate the card number into odd and even digits
    // ----------------------------------------------------------------
    assign odd_digit[0]  = card_num[63:60];
    assign even_digit[0] = card_num[59:56];
    assign odd_digit[1]  = card_num[55:52];
    assign even_digit[1] = card_num[51:48];
    assign odd_digit[2]  = card_num[47:44];
    assign even_digit[2] = card_num[43:40];
    assign odd_digit[3]  = card_num[39:36];
    assign even_digit[3] = card_num[35:32];
    assign odd_digit[4]  = card_num[31:28];
    assign even_digit[4] = card_num[27:24];
    assign odd_digit[5]  = card_num[23:20];
    assign even_digit[5] = card_num[19:16];
    assign odd_digit[6]  = card_num[15:12];
    assign even_digit[6] = card_num[11:8];
    assign odd_digit[7]  = card_num[7:4];
    assign even_digit[7] = card_num[3:0];

    // ----------------------------------------------------------------
    // Multiply all the odd digits by 2
    // ----------------------------------------------------------------
    wire [2:0] odd_digit_sub5 [0:7];
    wire LT_5 [0:7];
    genvar i;
    generate for (i = 0; i < 8; i = i + 1) begin: odd_digit_multx2_gen
        // assign {LT_5[i], odd_digit_sub5[i]} = odd_digit[i] - 3'd5;
        DW01_sub #(.width(3)) DW01_sub_instance_u(
            .A(odd_digit[i][2:0]),
            .B(3'd5),
            .CI(1'b0),
            .DIFF(odd_digit_sub5[i]),
            .CO(LT_5[i])
        );
        assign odd_digit_multx2[i] = (LT_5[i] & (~odd_digit[i][3])) ? odd_digit[i] << 1 : {odd_digit_sub5[i], 1'b1};
    end endgenerate

    // ----------------------------------------------------------------
    // Add all the digits
    // ----------------------------------------------------------------
    DW02_sum #(
        .num_inputs(16),
        .input_width(8)
    ) DW02_sum_instance(
        .INPUT({
            {4'd0, odd_digit_multx2[0]},
            {4'd0, even_digit[0]},
            {4'd0, odd_digit_multx2[1]},
            {4'd0, even_digit[1]},
            {4'd0, odd_digit_multx2[2]},
            {4'd0, even_digit[2]},
            {4'd0, odd_digit_multx2[3]},
            {4'd0, even_digit[3]},
            {4'd0, odd_digit_multx2[4]},
            {4'd0, even_digit[4]},
            {4'd0, odd_digit_multx2[5]},
            {4'd0, even_digit[5]},
            {4'd0, odd_digit_multx2[6]},
            {4'd0, even_digit[6]},
            {4'd0, odd_digit_multx2[7]},
            {4'd0, even_digit[7]}
        }),
        .SUM(sum)
    );

    // ----------------------------------------------------------------
    // Check the sum is multiple of 10 or not
    // ----------------------------------------------------------------
    // Max possible sum is 16*9 = 144
    // So we only need to check till 140
    // assign out_valid = (sum % 10 == 0);
    assign out_valid =| {
        (sum == 8'd0  ),
        (sum == 8'd10 ),
        (sum == 8'd20 ),
        (sum == 8'd30 ),
        (sum == 8'd40 ),
        (sum == 8'd50 ),
        (sum == 8'd60 ),
        (sum == 8'd70 ),
        (sum == 8'd80 ),
        (sum == 8'd90 ),
        (sum == 8'd100),
        (sum == 8'd110),
        (sum == 8'd120),
        (sum == 8'd130),
        (sum == 8'd140)
    };

endmodule

//================================================================
//
//   Module Name : Sort_8x8
//   Release version : V1.0 (Release Date: 2024-09)
//
//================================================================
//
//   Input  : 
//      [63:0] in;
//   Output :
//      [63:0] out;
//
//   Function :
//      Sort the 8 8-bit numbers in ascending order.
//
//================================================================
module Sort_8x8(
    input [63:0] in,
    output [63:0] out
);

//================================================================
//  Sorting network for 8 inputs, 19 CEs, 6 layers:
//      [(0,2),(1,3),(4,6),(5,7)]
//      [(0,4),(1,5),(2,6),(3,7)]
//      [(0,1),(2,3),(4,5),(6,7)]
//      [(2,4),(3,5)]
//      [(1,4),(3,6)]
//      [(1,2),(3,4),(5,6)]
// 
//     |[L1]|[L2]|[L3]|[L4]|[L5]|[L6]|
//  in0---+--+-----+---------------------> out0
//        |  |     |
//  in1--+|--|+----+---------+----+------> out1
//       ||  ||              |    |
//  in2--|+--||+---+----+----|----+------> out2
//       |   |||   |    |    |
//  in3--+---|||+--+----|+---|+---+------> out3
//           ||||       ||   ||   |
//  in4--+---+|||--+----+|---+|---+------> out4
//       |    |||  |     |    |
//  in5--|+---+||--+-----+----|---+------> out5
//       ||    ||             |   |
//  in6--+|----+|--+----------+---+------> out6
//        |     |  |
//  in7---+-----+--+---------------------> out7
//================================================================


    //================================================================
    //    Wire & Registers 
    //================================================================
    wire [7:0] L0_0, L0_1, L0_2, L0_3, L0_4, L0_5, L0_6, L0_7;
    wire [7:0] L1_0, L1_1, L1_2, L1_3, L1_4, L1_5, L1_6, L1_7;
    wire [7:0] L2_0, L2_1, L2_2, L2_3, L2_4, L2_5, L2_6, L2_7;
    wire [7:0] L3_0, L3_1, L3_2, L3_3, L3_4, L3_5, L3_6, L3_7;
    wire [7:0] L4_0, L4_1, L4_2, L4_3, L4_4, L4_5, L4_6, L4_7;
    wire [7:0] L5_0, L5_1, L5_2, L5_3, L5_4, L5_5, L5_6, L5_7;
    wire [7:0] L6_0, L6_1, L6_2, L6_3, L6_4, L6_5, L6_6, L6_7;

    wire cmp_L0_02, cmp_L0_13, cmp_L0_46, cmp_L0_57;

    //================================================================
    //    DESIGN
    //================================================================
    // Layer 0
    assign L0_0 = in[8*0+7:8*0];
    assign L0_1 = in[8*1+7:8*1];
    assign L0_2 = in[8*2+7:8*2];
    assign L0_3 = in[8*3+7:8*3];
    assign L0_4 = in[8*4+7:8*4];
    assign L0_5 = in[8*5+7:8*5];
    assign L0_6 = in[8*6+7:8*6];
    assign L0_7 = in[8*7+7:8*7];
    // Layer 1
    // [(0,2),(1,3),(4,6),(5,7)]
    // -!-!-!-!-!-!-!-!-!-!-!-
    // For some unknown reason, using DW01_cmp2 in Layer 1 will result
    // in a smaller area than using the compare operator.
    // While using DW01_cmp2 in other layers will result in a larger area.
    // -!-!-!-!-!-!-!-!-!-!-!-
    DW01_cmp2 #(.width(8)) DW01_cmp2_instance_u0(
        .A(L0_0),
        .B(L0_2),
        .LEQ(1'b1),
        .TC(1'b0),
        .LT_LE(cmp_L0_02),
        .GE_GT()
    );
    DW01_cmp2 #(.width(8)) DW01_cmp2_instance_u1(
        .A(L0_1),
        .B(L0_3),
        .LEQ(1'b1),
        .TC(1'b0),
        .LT_LE(cmp_L0_13),
        .GE_GT()
    );
    DW01_cmp2 #(.width(8)) DW01_cmp2_instance_u2(
        .A(L0_4),
        .B(L0_6),
        .LEQ(1'b1),
        .TC(1'b0),
        .LT_LE(cmp_L0_46),
        .GE_GT()
    );
    DW01_cmp2 #(.width(8)) DW01_cmp2_instance_u3(
        .A(L0_5),
        .B(L0_7),
        .LEQ(1'b1),
        .TC(1'b0),
        .LT_LE(cmp_L0_57),
        .GE_GT()
    );
    assign {L1_0, L1_2} = (cmp_L0_02) ? {L0_0, L0_2} : {L0_2, L0_0};
    assign {L1_1, L1_3} = (cmp_L0_13) ? {L0_1, L0_3} : {L0_3, L0_1};
    assign {L1_4, L1_6} = (cmp_L0_46) ? {L0_4, L0_6} : {L0_6, L0_4};
    assign {L1_5, L1_7} = (cmp_L0_57) ? {L0_5, L0_7} : {L0_7, L0_5};
    // Layer 2
    // [(0,4),(1,5),(2,6),(3,7)]
    assign {L2_0, L2_4} = (L1_0 <= L1_4) ? {L1_0, L1_4} : {L1_4, L1_0};
    assign {L2_1, L2_5} = (L1_1 <= L1_5) ? {L1_1, L1_5} : {L1_5, L1_1};
    assign {L2_2, L2_6} = (L1_2 <= L1_6) ? {L1_2, L1_6} : {L1_6, L1_2};
    assign {L2_3, L2_7} = (L1_3 <= L1_7) ? {L1_3, L1_7} : {L1_7, L1_3};
    // Layer 3
    // [(0,1),(2,3),(4,5),(6,7)]
    assign {L3_0, L3_1} = (L2_0 <= L2_1) ? {L2_0, L2_1} : {L2_1, L2_0};
    assign {L3_2, L3_3} = (L2_2 <= L2_3) ? {L2_2, L2_3} : {L2_3, L2_2};
    assign {L3_4, L3_5} = (L2_4 <= L2_5) ? {L2_4, L2_5} : {L2_5, L2_4};
    assign {L3_6, L3_7} = (L2_6 <= L2_7) ? {L2_6, L2_7} : {L2_7, L2_6};
    // Layer 4
    // [(2,4),(3,5)]
    assign {L4_2, L4_4} = (L3_2 <= L3_4) ? {L3_2, L3_4} : {L3_4, L3_2};
    assign {L4_3, L4_5} = (L3_3 <= L3_5) ? {L3_3, L3_5} : {L3_5, L3_3};
    assign L4_0 = L3_0;
    assign L4_1 = L3_1;
    assign L4_6 = L3_6;
    assign L4_7 = L3_7;
    // Layer 5
    // [(1,4),(3,6)]
    assign {L5_1, L5_4} = (L4_1 <= L4_4) ? {L4_1, L4_4} : {L4_4, L4_1};
    assign {L5_3, L5_6} = (L4_3 <= L4_6) ? {L4_3, L4_6} : {L4_6, L4_3};
    assign L5_0 = L4_0;
    assign L5_2 = L4_2;
    assign L5_5 = L4_5;
    assign L5_7 = L4_7;
    // Layer 6
    // [(1,2),(3,4),(5,6)]
    assign {L6_1, L6_2} = (L5_1 <= L5_2) ? {L5_1, L5_2} : {L5_2, L5_1};
    assign {L6_3, L6_4} = (L5_3 <= L5_4) ? {L5_3, L5_4} : {L5_4, L5_3};
    assign {L6_5, L6_6} = (L5_5 <= L5_6) ? {L5_5, L5_6} : {L5_6, L5_5};
    assign L6_0 = L5_0;
    assign L6_7 = L5_7;
    // Output
    assign out = {L6_0, L6_1, L6_2, L6_3, L6_4, L6_5, L6_6, L6_7};

endmodule

