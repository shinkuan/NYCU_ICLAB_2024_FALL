module Ramen(
    // Input Registers
    input clk, 
    input rst_n, 
    input in_valid,
    input selling,
    input portion, 
    input [1:0] ramen_type,

    // Output Signals
    output reg out_valid_order,
    output reg success,

    output reg out_valid_tot,
    output reg [27:0] sold_num,
    output reg [14:0] total_gain
);


    //==============================================//
    //             Parameter and Integer            //
    //==============================================//

    // ramen_type
    parameter TONKOTSU = 0;
    parameter TONKOTSU_SOY = 1;
    parameter MISO = 2;
    parameter MISO_SOY = 3;

    // initial ingredient
    parameter NOODLE_INIT = 12000;
    parameter BROTH_INIT = 41000;
    parameter TONKOTSU_SOUP_INIT =  9000;
    parameter MISO_INIT = 1000;
    parameter SOY_SAUSE_INIT = 1500;

    parameter STATE_INIT = 4'd0;
    parameter STATE_IN_RAMAN_TYPE = 4'd1;
    parameter STATE_IN_PORTION = 4'd2;
    parameter STATE_CALC = 4'd3;
    parameter STATE_CHECK_SOLD_OUT = 4'd4;
    parameter STATE_SOLD_OUT_REVERT = 4'd5;
    parameter STATE_ORDER_DONE = 4'd6;
    parameter STATE_WAIT_NEXT = 4'd7;
    parameter STATE_ALL_DONE = 4'd8;

    //==============================================//
    //                 reg declaration              //
    //==============================================// 
    reg [3:0] cs, ns;

    reg [14:0] noodle_stock;
    reg [16:0] broth_stock;
    reg [14:0] tonkotsu_soup_stock;
    reg [10:0]  miso_stock;
    reg [11:0] soy_sause_stock;

    reg [1:0] ramen_type_inbuf, ramen_type_reg;
    reg portion_inbuf, portion_reg;

    reg [6:0] sold_num_tonkotsu;
    reg [6:0] sold_num_tonkotsu_soy;
    reg [6:0] sold_num_miso;
    reg [6:0] sold_num_miso_soy;

    reg sold_out;
    reg [14:0] gain;

    //==============================================//
    //                    Design                    //
    //==============================================//
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            cs <= STATE_INIT;
        end else begin
            cs <= ns;
        end
    end

    always @(*) begin
        case (cs)
            STATE_INIT: begin
                ns = in_valid ? STATE_IN_RAMAN_TYPE : STATE_INIT;
            end
            STATE_IN_RAMAN_TYPE: begin
                ns = STATE_IN_PORTION;
            end
            STATE_IN_PORTION: begin
                ns = STATE_CALC;
            end
            STATE_CALC: begin
                ns = STATE_CHECK_SOLD_OUT;
            end
            STATE_CHECK_SOLD_OUT: begin
                ns = STATE_SOLD_OUT_REVERT;
            end
            STATE_SOLD_OUT_REVERT: begin
                ns = STATE_ORDER_DONE;
            end
            STATE_ORDER_DONE: begin
                ns = selling ? STATE_WAIT_NEXT : STATE_ALL_DONE;
            end
            STATE_WAIT_NEXT: begin
                ns = in_valid ? STATE_IN_RAMAN_TYPE : (selling ? STATE_WAIT_NEXT : STATE_ALL_DONE);
            end
            STATE_ALL_DONE: begin
                ns = STATE_INIT;
            end
            default: begin
                ns = STATE_INIT;
            end
        endcase
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            ramen_type_inbuf <= 2'd0;
            portion_inbuf <= 1'd0;
        end else begin
            ramen_type_inbuf <= ramen_type;
            portion_inbuf <= portion;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            ramen_type_reg <= 2'd0;
        end else begin
            if (cs == STATE_IN_RAMAN_TYPE) begin
                ramen_type_reg <= ramen_type_inbuf;
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            portion_reg <= 1'd0;
        end else begin
            if (cs == STATE_IN_PORTION) begin
                portion_reg <= portion_inbuf;
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            noodle_stock <= NOODLE_INIT;
            broth_stock <= BROTH_INIT;
            tonkotsu_soup_stock <= TONKOTSU_SOUP_INIT;
            miso_stock <= MISO_INIT;
            soy_sause_stock <= SOY_SAUSE_INIT;
        end else begin
            case (cs)
                STATE_INIT: begin
                    noodle_stock <= NOODLE_INIT;
                    broth_stock <= BROTH_INIT;
                    tonkotsu_soup_stock <= TONKOTSU_SOUP_INIT;
                    miso_stock <= MISO_INIT;
                    soy_sause_stock <= SOY_SAUSE_INIT;
                end
                STATE_CALC: begin
                    case (ramen_type_reg)
                        TONKOTSU: begin
                            if (portion_reg) begin
                                noodle_stock <= noodle_stock - 'd150;
                                broth_stock <= broth_stock - 'd500;
                                tonkotsu_soup_stock <= tonkotsu_soup_stock - 'd200;
                            end else begin
                                noodle_stock <= noodle_stock - 'd100;
                                broth_stock <= broth_stock - 'd300;
                                tonkotsu_soup_stock <= tonkotsu_soup_stock - 'd150;
                                
                            end
                        end
                        TONKOTSU_SOY: begin
                            if (portion_reg) begin
                                noodle_stock <= noodle_stock - 'd150;
                                broth_stock <= broth_stock - 'd500;
                                tonkotsu_soup_stock <= tonkotsu_soup_stock - 'd150;
                                soy_sause_stock <= soy_sause_stock - 'd50;
                            end else begin
                                
                                noodle_stock <= noodle_stock - 'd100;
                                broth_stock <= broth_stock - 'd300;
                                tonkotsu_soup_stock <= tonkotsu_soup_stock - 'd100;
                                soy_sause_stock <= soy_sause_stock - 'd30;
                            end
                        end
                        MISO: begin
                            if (portion_reg) begin
                                noodle_stock <= noodle_stock - 'd150;
                                broth_stock <= broth_stock - 'd650;
                                miso_stock <= miso_stock - 'd50;
                            end else begin
                                noodle_stock <= noodle_stock - 'd100;
                                broth_stock <= broth_stock - 'd400;
                                miso_stock <= miso_stock - 'd30;
                                
                            end
                        end
                        MISO_SOY: begin
                            if (portion_reg) begin
                                noodle_stock <= noodle_stock - 'd150;
                                broth_stock <= broth_stock - 'd500;
                                tonkotsu_soup_stock <= tonkotsu_soup_stock - 'd100;
                                soy_sause_stock <= soy_sause_stock - 'd25;
                                miso_stock <= miso_stock - 'd25;
                            end else begin
                                noodle_stock <= noodle_stock - 'd100;
                                broth_stock <= broth_stock - 'd300;
                                tonkotsu_soup_stock <= tonkotsu_soup_stock - 'd70;
                                soy_sause_stock <= soy_sause_stock - 'd15;
                                miso_stock <= miso_stock - 'd15;
                            end
                        end
                        default: begin
                            //impossible
                        end
                    endcase
                    
                end
                STATE_SOLD_OUT_REVERT: begin
                    if (sold_out) case (ramen_type_reg)
                        TONKOTSU: begin
                            if (portion_reg) begin
                                noodle_stock <= noodle_stock + 'd150;
                                broth_stock <= broth_stock + 'd500;
                                tonkotsu_soup_stock <= tonkotsu_soup_stock + 'd200;
                            end else begin
                                noodle_stock <= noodle_stock + 'd100;
                                broth_stock <= broth_stock + 'd300;
                                tonkotsu_soup_stock <= tonkotsu_soup_stock + 'd150;
                                
                            end
                        end
                        TONKOTSU_SOY: begin
                            if (portion_reg) begin
                                noodle_stock <= noodle_stock + 'd150;
                                broth_stock <= broth_stock + 'd500;
                                tonkotsu_soup_stock <= tonkotsu_soup_stock + 'd150;
                                soy_sause_stock <= soy_sause_stock + 'd50;
                            end else begin
                                
                                noodle_stock <= noodle_stock + 'd100;
                                broth_stock <= broth_stock + 'd300;
                                tonkotsu_soup_stock <= tonkotsu_soup_stock + 'd100;
                                soy_sause_stock <= soy_sause_stock + 'd30;
                            end
                        end
                        MISO: begin
                            if (portion_reg) begin
                                noodle_stock <= noodle_stock + 'd150;
                                broth_stock <= broth_stock + 'd650;
                                miso_stock <= miso_stock + 'd50;
                            end else begin
                                noodle_stock <= noodle_stock + 'd100;
                                broth_stock <= broth_stock + 'd400;
                                miso_stock <= miso_stock + 'd30;
                                
                            end
                        end
                        MISO_SOY: begin
                            if (portion_reg) begin
                                noodle_stock <= noodle_stock + 'd150;
                                broth_stock <= broth_stock + 'd500;
                                tonkotsu_soup_stock <= tonkotsu_soup_stock + 'd100;
                                soy_sause_stock <= soy_sause_stock + 'd25;
                                miso_stock <= miso_stock + 'd25;
                            end else begin
                                noodle_stock <= noodle_stock + 'd100;
                                broth_stock <= broth_stock + 'd300;
                                tonkotsu_soup_stock <= tonkotsu_soup_stock + 'd70;
                                soy_sause_stock <= soy_sause_stock + 'd15;
                                miso_stock <= miso_stock + 'd15;
                            end
                        end
                        default: begin
                            //impossible
                        end
                    endcase
                end
                default: begin
                    // Do nothing
                end
            endcase
            
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            sold_num_tonkotsu <= 'd0;
            sold_num_tonkotsu_soy <= 'd0;
            sold_num_miso <= 'd0;
            sold_num_miso_soy <= 'd0;
        end else begin
            case (cs)
                STATE_INIT: begin
                    sold_num_tonkotsu <= 'd0;
                    sold_num_tonkotsu_soy <= 'd0;
                    sold_num_miso <= 'd0;
                    sold_num_miso_soy <= 'd0;
                end
                STATE_CALC: begin
                    case (ramen_type_reg)
                        TONKOTSU: begin
                            sold_num_tonkotsu <= sold_num_tonkotsu + 1;
                        end
                        TONKOTSU_SOY: begin
                            sold_num_tonkotsu_soy <= sold_num_tonkotsu_soy + 1;
                        end
                        MISO: begin
                            sold_num_miso <= sold_num_miso + 1;
                        end
                        MISO_SOY: begin
                            sold_num_miso_soy <= sold_num_miso_soy + 1;
                        end
                        default: begin
                            //impossible
                        end
                    endcase
                end
                STATE_SOLD_OUT_REVERT: begin
                    if (sold_out) case (ramen_type_reg)
                        TONKOTSU: begin
                            sold_num_tonkotsu <= sold_num_tonkotsu - 1;
                        end
                        TONKOTSU_SOY: begin
                            sold_num_tonkotsu_soy <= sold_num_tonkotsu_soy - 1;
                        end
                        MISO: begin
                            sold_num_miso <= sold_num_miso - 1;
                        end
                        MISO_SOY: begin
                            sold_num_miso_soy <= sold_num_miso_soy - 1;
                        end
                        default: begin
                            //impossible
                        end
                    endcase
                end
                default: begin
                    // Do nothing
                end
            endcase
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            gain <= 'd0;
        end else begin
            case (cs)
                STATE_INIT: begin
                    gain <= 'd0;
                end
                STATE_CALC: begin
                    case (ramen_type_reg)
                        TONKOTSU: begin
                            gain <= gain + 'd200;
                        end
                        TONKOTSU_SOY: begin
                            gain <= gain + 'd250;
                        end
                        MISO: begin
                            gain <= gain + 'd200;
                        end
                        MISO_SOY: begin
                            gain <= gain + 'd250;
                        end
                        default: begin
                            //impossible
                        end
                    endcase
                end
                STATE_SOLD_OUT_REVERT: begin
                    if (sold_out) case (ramen_type_reg)
                        TONKOTSU: begin
                            gain <= gain - 'd200;
                        end
                        TONKOTSU_SOY: begin
                            gain <= gain - 'd250;
                        end
                        MISO: begin
                            gain <= gain - 'd200;
                        end
                        MISO_SOY: begin
                            gain <= gain - 'd250;
                        end
                        default: begin
                            //impossible
                        end
                    endcase
                end
                default: begin
                    // Do nothing
                end
            endcase
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            sold_out <= 1'd0;
        end else begin
            case (cs)
                STATE_INIT: begin
                    sold_out <= 1'd0;
                end
                STATE_CHECK_SOLD_OUT: begin
                    if (|{
                        noodle_stock[14],
                        broth_stock[16],
                        tonkotsu_soup_stock[14],
                        soy_sause_stock[11],
                        miso_stock[10]
                    }) begin
                        sold_out <= 1'd1;
                    end else begin
                        sold_out <= 1'd0;
                    end
                end
                STATE_ORDER_DONE: begin
                    sold_out <= 1'b0;
                end
                default: begin
                    // Do nothing
                end
            endcase
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out_valid_order <= 'd0;
            success <= 'd0;
        end else begin
            case (cs)
                STATE_INIT: begin
                    out_valid_order <= 'd0;
                    success <= 'd0;
                end
                STATE_ORDER_DONE: begin
                    out_valid_order <= 1'd1;
                    success <= sold_out? 1'd0 : 1'd1;
                end
                default: begin
                    out_valid_order <= 'd0;
                    success <= 'd0;
                end
            endcase
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out_valid_tot <= 1'b0;
            sold_num <= 'd0;
            total_gain <= 'd0;
        end else begin
            case (cs)
                STATE_ALL_DONE: begin
                    out_valid_tot <= 1'b1;
                    sold_num <= {sold_num_tonkotsu, sold_num_tonkotsu_soy, sold_num_miso, sold_num_miso_soy};
                    total_gain <= gain;
                end
                default: begin
                    out_valid_tot <= 1'b0;
                    sold_num <= 'd0;
                    total_gain <= 'd0;
                end
            endcase
        end
    end

endmodule
