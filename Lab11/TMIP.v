module TMIP(
    // input signals
    clk,
    rst_n,
    in_valid, 
    in_valid2,
    
    image,
    template,
    image_size,
	action,
	
    // output signals
    out_valid,
    out_value
);

    input            clk, rst_n;
    input            in_valid, in_valid2;

    input      [7:0] image;
    input      [7:0] template;
    input      [1:0] image_size;
    input      [2:0] action;

    output reg       out_valid;
    output reg       out_value;

    //==================================================================
    // parameter & integer
    //==================================================================
    localparam [7:0] STATE_IDLE = 8'd00;
    localparam [7:0] STATE_IN_1 = 8'd01;
    localparam [7:0] STATE_IN_2 = 8'd02;
    localparam [7:0] STATE_CALC = 8'd03;
    localparam [7:0] STATE_ACTN = 8'd04;
    localparam [7:0] STATE_OUTP = 8'd05;

    localparam [2:0] ACTION_GRAY_MAX = 3'd0;
    localparam [2:0] ACTION_GRAY_AVG = 3'd1;
    localparam [2:0] ACTION_GRAY_WGT = 3'd2;
    localparam [2:0] ACTION_MAX_POOL = 3'd3;
    localparam [2:0] ACTION_NEGATIVE = 3'd4;
    localparam [2:0] ACTION_HOR_FLIP = 3'd5;
    localparam [2:0] ACTION_MED_FILT = 3'd6;
    localparam [2:0] ACTION_CROS_COR = 3'd7;

    localparam [3:0] MED_STATE_0 = 4'd0;
    localparam [3:0] MED_STATE_1 = 4'd1;
    localparam [3:0] MED_STATE_2 = 4'd2;
    localparam [3:0] MED_STATE_3 = 4'd3;
    localparam [3:0] MED_STATE_4 = 4'd4;
    localparam [3:0] MED_STATE_5 = 4'd5;
    localparam [3:0] MED_STATE_6 = 4'd6;
    localparam [3:0] MED_STATE_7 = 4'd7;
    localparam [3:0] MED_STATE_8 = 4'd8;
    localparam [3:0] MED_STATE_DONE = 4'd10;
    localparam [3:0] MED_STATE_IDLE = 4'd9;

    integer i, j, k;

    //==================================================================
    // reg & wire
    //==================================================================
    reg  [7:0] image_in_reg;
    reg  [7:0] template_in_reg;
    reg  [1:0] image_size_in_reg;
    reg  [2:0] action_in_reg;

    reg  [7:0] cs, ns;
    reg  [7:0] cs_d1;
    reg  [7:0] cnt, cnt_n;
    reg  [3:0] cnt_dyn_base;
    reg  [3:0] cnt_dyn, cnt_dyn_n;
    reg  [3:0] cnt_dyn_d1;
    reg  [8:0] cnt_bdyn, cnt_bdyn_n;
    reg  [3:0] cnt_bdyn_d1;
    wire [7:0] cnt_bdyn_sub1;
    reg  [1:0] cnt_cro_3, cnt_cro_3_n;
    reg  [1:0] cnt_cro_3_d1;
    reg  [1:0] cnt_cro_3_d2;
    reg  [1:0] cnt_cro_3b3, cnt_cro_3b3_n;
    reg  [1:0] cnt_cro_3b3_d1;
    reg  [1:0] cnt_cro_3b3_d2;
    reg  [3:0] cnt_cro_x, cnt_cro_x_n;
    reg  [3:0] cnt_cro_y, cnt_cro_y_n;
    reg  [5:0] cnt_20, cnt_20_n;
    reg        cnt_rst_flag;
    reg        cnt_rst_flag_d1;
    reg        cnt_dyn_rst_flag;
    reg        last_in_valid, last_in_valid2;
    reg        last_in_valid_d1;

    reg  [9:0] mem_addr_a, mem_addr_b;
    reg  [7:0] mem_data_a_in, mem_data_b_in;
    wire [7:0] mem_data_a_out, mem_data_b_out;
    reg        mem_we_a, mem_we_b;
    reg        mem_oe_a, mem_oe_b;
    reg        mem_cs_a, mem_cs_b;
    reg        mem_we_a_reg;

    reg  [7:0] gray_scale_0, gray_scale_0_n;
    reg  [7:0] gray_scale_0_s, gray_scale_0_s_n;
    reg  [9:0] gray_scale_1, gray_scale_1_n;
    reg  [7:0] gray_scale_1_s, gray_scale_1_s_n;
    reg  [7:0] gray_scale_2, gray_scale_2_n;
    reg  [7:0] gray_scale_2_s, gray_scale_2_s_n;

    reg  [7:0] template_reg [2:0][2:0];
    reg  [1:0] image_size_reg_master;
    reg  [1:0] image_size_reg_set;
    reg  [2:0] action_reg [7:0];

    reg  [1:0] read_layer;
    reg        action_done;
    reg  [2:0] action_doing;

    reg        action_5_flag;

    reg  [7:0] gray_img [15:0][15:0];
    reg  [7:0] gray_img_maxpooling [15:0][15:0];

    reg        cro_addr_out_of_bound;
    reg  [3:0] cro_addr_x, cro_addr_y;
    reg [19:0] cro_mac;
    reg [19:0] cro_mac_store;

    reg  [2:0] set_cnt;
    reg        out_valid_d1;
    reg        out_valid_a1;
    reg        out_value_a1;

    reg  [7:0] mem_data_out_reg_shift_0 [15:0];
    reg  [7:0] mem_data_out_reg_shift_1 [15:0];
    reg  [7:0] mem_data_out_reg_shift_2 [ 3:0];
    reg  [7:0] medfilt_in [2:0][2:0];
    wire [7:0] medfilt_out;
    reg  [7:0] medfilt_out_reg;
    reg  [3:0] medfilt_state, medfilt_state_n;
    reg  [3:0] medfilt_state_d1;
    reg  [3:0] medfilt_cnt, medfilt_cnt_n;
    reg  [3:0] medfilt_cnt_d1;
    reg  [3:0] medfilt_cnt2, medfilt_cnt2_n;
    reg  [3:0] medfilt_cnt2_d1;

    //==================================================================
    // design
    //==================================================================
    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // Memory
    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    MEM_768 MEM1024_instance (
        .clk(clk),
        .A(mem_addr_a),
        .DIA(mem_data_a_in),
        .WEAN(mem_we_a),
        .CSA(mem_cs_a),
        .OEA(1'b1),
        .DOA(mem_data_a_out)
    );

    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // A
    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    //------------------------------------------------------------------
    // Memory Address A
    //------------------------------------------------------------------
    always @(*) begin
        case (cs_d1)
            STATE_IN_1: begin
                case(image_size_reg_master)
                    2'd0: mem_addr_a = {cnt_dyn[1:0], 2'd0, cnt_bdyn_sub1[3:2], 2'd0, cnt_bdyn_sub1[1:0]};
                    2'd1: mem_addr_a = {cnt_dyn[1:0], 1'd0, cnt_bdyn_sub1[5:3], 1'd0, cnt_bdyn_sub1[2:0]};
                    2'd2: mem_addr_a = {cnt_dyn[1:0], cnt_bdyn_sub1};
                    default: mem_addr_a = 10'd0;
                endcase
            end
            default: begin
                mem_addr_a = {read_layer, cnt_bdyn[3:0], cnt_dyn};
            end
        endcase
    end

    //------------------------------------------------------------------
    // Memory Write Enable A
    //------------------------------------------------------------------
    always @(*) begin
        case (cs_d1)
            STATE_IN_1: begin
                mem_we_a = 1'b0 || mem_we_a_reg;
            end
            default: begin
                mem_we_a = 1'b1;
            end
        endcase
    end
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            mem_we_a_reg <= 1'b0;
        end else if (cs == STATE_IN_2) begin
            mem_we_a_reg <= 1'b0;
        end else if (cs == STATE_IN_1) begin
            case(image_size_reg_master)
                2'd0: mem_we_a_reg <= (cnt_dyn == 3'd2 && cnt_bdyn[4] == 1'b1) || mem_we_a_reg;
                2'd1: mem_we_a_reg <= (cnt_dyn == 3'd2 && cnt_bdyn[6] == 1'b1) || mem_we_a_reg;
                2'd2: mem_we_a_reg <= (cnt_dyn == 3'd2 && cnt_bdyn[8] == 1'b1) || mem_we_a_reg;
                default: mem_we_a_reg <= 1'b0;
            endcase
        end else begin
            mem_we_a_reg <= 1'b0;
        end
    end
    


    //------------------------------------------------------------------
    // Memory Data A
    //------------------------------------------------------------------
    always @(*) begin
        case (cs_d1)
            STATE_IN_1: begin
                case(cnt_dyn[1:0])
                    2'd0: begin
                        mem_data_a_in = gray_scale_0_s;
                    end
                    2'd1: begin
                        mem_data_a_in = gray_scale_1_s;
                    end
                    2'd2: begin
                        mem_data_a_in = gray_scale_2_s;
                    end
                    default: begin
                        mem_data_a_in = 8'b0;
                    end
                endcase
            end
            default: begin
                mem_data_a_in = 8'b0;
            end
        endcase
    end

    //------------------------------------------------------------------
    // Memory Output Enable A
    //------------------------------------------------------------------
    always @(*) begin
        case (cs_d1)
            STATE_IN_1: begin
                mem_oe_a = 1'b0;
            end
            default: begin
                mem_oe_a = 1'b1;
            end
        endcase
    end

    //------------------------------------------------------------------
    // Memory Chip Select A
    //------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            mem_cs_a <= 1'b0;
        end else begin
            mem_cs_a <= 1'b1;
        end
    end

    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // Input register buffer
    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    always @(posedge clk ) begin
        image_in_reg <= image;
        template_in_reg <= template;
        image_size_in_reg <= image_size;
        action_in_reg <= action;
    end

    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // State Machine
    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    //------------------------------------------------------------------
    // State
    //------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            cs <= STATE_IDLE;
        end else begin
            cs <= ns;
        end
    end
    
    always @(*) begin
        case(cs)
            STATE_IDLE: begin
                if (in_valid) begin
                    ns = STATE_IN_1;
                end else 
                if (in_valid2) begin
                    ns = STATE_IN_2;
                end else begin
                    ns = STATE_IDLE;
                end
            end
            STATE_IN_1: begin
                if (in_valid2) begin
                    ns = STATE_IN_2;
                end else begin
                    ns = cs;
                end
            end
            STATE_IN_2: begin
                if ((last_in_valid2) && (~in_valid2)) begin
                    ns = STATE_CALC;
                end else begin
                    ns = cs;
                end
            end
            STATE_CALC: begin
                ns = STATE_ACTN;
            end
            STATE_ACTN: begin
                if (action_done) begin
                    ns = STATE_CALC;
                end else 
                if (out_valid_d1 && ~out_valid_a1) begin
                    ns = STATE_IN_2;
                end else 
                if (cnt_20 == 6'd9 && action_doing == 3'd7 && cnt_cro_y == 4'd0 && cnt_cro_x == 4'd1 && set_cnt == 3'd7 && out_valid) begin
                    ns = STATE_IDLE;
                end else begin
                    ns = cs;
                end
            end
            default: begin
                ns = STATE_IDLE;
            end
        endcase
    end
    //------------------------------------------------------------------
    // State delay 1
    //------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            cs_d1 <= STATE_IDLE;
        end else begin
            cs_d1 <= cs;
        end
    end

    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // Counter
    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            last_in_valid  <= 1'b0;
            last_in_valid2 <= 1'b0;
            last_in_valid_d1 <= 1'b0;
        end else begin
            last_in_valid  <= in_valid;
            last_in_valid2 <= in_valid2;
            last_in_valid_d1 <= last_in_valid;
        end
    end

    //------------------------------------------------------------------
    // Counter reset flag
    //------------------------------------------------------------------
    always @(*) begin
        if (
            (last_in_valid  == 1'b0 && in_valid  == 1'b1) ||
            (last_in_valid2 == 1'b0 && in_valid2 == 1'b1)
        ) begin
            cnt_rst_flag = 1'b1;
        end else begin
            cnt_rst_flag = 1'b0;
        end
    end
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            cnt_rst_flag_d1 = 1'b0;
        end else begin
            cnt_rst_flag_d1 = cnt_rst_flag;
        end
    end
    always @(*) begin
        if (
            (last_in_valid  == 1'b0 && in_valid  == 1'b1) ||
            (cs == STATE_CALC)
        ) begin
            cnt_dyn_rst_flag = 1'b1;
        end else begin
            cnt_dyn_rst_flag = 1'b0;
        end
    end

    //------------------------------------------------------------------
    // Counter, unlimited, count per clock
    //------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            cnt <= 8'd0;
        end else begin
            cnt <= cnt_n;
        end
    end
  
    always @(*) begin
        if (cnt_rst_flag) begin
            cnt_n = 8'd0;
        end else begin
            cnt_n = cnt+1;
        end
    end
    
    //------------------------------------------------------------------
    // Counter, max 3, count per clock
    //------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            cnt_dyn <= 4'd0;
        end else begin
            cnt_dyn <= cnt_dyn_n;
        end
    end

    always @(posedge clk) begin
        cnt_dyn_d1 <= cnt_dyn;
    end
    

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            cnt_dyn_base <= 4'd0;
        end else begin
            case(cs)
                STATE_IDLE: begin
                    cnt_dyn_base <= 4'd2;
                end
                STATE_CALC: begin
                    case(image_size_reg_set)
                        2'd0: cnt_dyn_base <= 4'd3;
                        2'd1: cnt_dyn_base <= 4'd7;
                        2'd2: cnt_dyn_base <= 4'd15;
                        default: cnt_dyn_base <= 4'bX;
                    endcase
                end 
                default: begin
                    cnt_dyn_base <= cnt_dyn_base;
                end
            endcase
        end
    end
    
    always @(*) begin
        // Default value
        if (cnt_dyn_rst_flag) begin
            cnt_dyn_n = 4'd0;
        end else 
        if (cs == STATE_IDLE) begin
            cnt_dyn_n = 4'd2;
        end else begin
            cnt_dyn_n = cnt_dyn == cnt_dyn_base ? 4'd0 : cnt_dyn+1;
        end
    end

    //------------------------------------------------------------------
    // Counter, max 3, count per 3 clock
    //------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            cnt_bdyn <= 9'd0;
        end else begin
            cnt_bdyn <= cnt_bdyn_n;
        end
    end

    always @(posedge clk) begin
        cnt_bdyn_d1 <= cnt_bdyn;
    end
    

    always @(*) begin
        if (cnt_dyn_rst_flag) begin
            cnt_bdyn_n = 9'd0;
        end else begin
            cnt_bdyn_n = cnt_dyn == cnt_dyn_base ? cnt_bdyn+1 : cnt_bdyn;
        end
    end

    assign cnt_bdyn_sub1 = cnt_bdyn-9'd1;

    //------------------------------------------------------------------
    // Cross Correlation Counter
    //------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            cnt_cro_3 <= 2'd0;
            cnt_cro_3b3 <= 2'd0;
            cnt_cro_x <= 4'd0;
            cnt_cro_y <= 4'd0;
        end else begin
            if (cnt_20 < 6'd9 || cnt_dyn_rst_flag) begin
                cnt_cro_3 <= cnt_cro_3_n;
                cnt_cro_3b3 <= cnt_cro_3b3_n;
                cnt_cro_x <= cnt_cro_x_n;
                cnt_cro_y <= cnt_cro_y_n;
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            cnt_cro_3_d1 <= 2'd0;
            cnt_cro_3b3_d1 <= 2'd0;
            cnt_cro_3_d2 <= 2'd0;
            cnt_cro_3b3_d2 <= 2'd0;
        end else begin
            cnt_cro_3_d1 <= cnt_cro_3;
            cnt_cro_3b3_d1 <= cnt_cro_3b3;
            cnt_cro_3_d2 <= cnt_cro_3_d1;
            cnt_cro_3b3_d2 <= cnt_cro_3b3_d1;
        end
    end
    

    always @(*) begin
        if (cnt_dyn_rst_flag) begin
            cnt_cro_3_n = 2'd0;
        end else begin
            cnt_cro_3_n = cnt_cro_3 == 2'd2 ? 2'd0 : cnt_cro_3+1;        
        end
    end

    always @(*) begin
        if (cnt_dyn_rst_flag) begin
            cnt_cro_3b3_n = 2'd0;
        end else begin
            cnt_cro_3b3_n = cnt_cro_3 == 2'd2 ? (cnt_cro_3b3 == 2'd2 ? 2'd0 : cnt_cro_3b3+1) : cnt_cro_3b3;
        end
    end
        
    always @(*) begin
        if (cnt_dyn_rst_flag) begin
            cnt_cro_x_n = 4'd0;
        end else begin
            cnt_cro_x_n = cnt_cro_3b3 == 2'd2 && cnt_cro_3 == 2'd2 ? (cnt_cro_x == cnt_dyn_base ? 4'd0 : cnt_cro_x + 1) : cnt_cro_x;
        end
    end
    
    always @(*) begin
        
        if (cnt_dyn_rst_flag) begin
            cnt_cro_y_n = 4'd0;
        end else begin
            cnt_cro_y_n = cnt_cro_3b3 == 2'd2 && cnt_cro_3 == 2'd2 && cnt_cro_x == cnt_dyn_base ? 
                (cnt_cro_y == cnt_dyn_base ? 4'd0 : cnt_cro_y + 1) : cnt_cro_y;
        end
    end
    
    always @(*) begin
        if (
            ({cnt_cro_y, cnt_cro_3b3} == 6'b0) ||
            (cnt_cro_y == cnt_dyn_base && cnt_cro_3b3 == 2'd2) ||
            ({cnt_cro_x, cnt_cro_3} == 6'b0) ||
            (cnt_cro_x == cnt_dyn_base && cnt_cro_3 == 2'd2)
        ) begin
            cro_addr_out_of_bound = 1'b1;
        end else begin
            cro_addr_out_of_bound = 1'b0;
        end
    end

    // always @(posedge clk) begin
    //     cro_addr_out_of_bound_reg <= cro_addr_out_of_bound;
    //     cro_addr_out_of_bound_reg_d1 <= cro_addr_out_of_bound_reg;
    // end

    always @(*) begin
        cro_addr_y = cnt_cro_y + cnt_cro_3b3-1;
        if (action_5_flag) // Horizontal flip
            cro_addr_x = cnt_dyn_base - (cnt_cro_x + cnt_cro_3-1);
        else
            cro_addr_x = cnt_cro_x + cnt_cro_3-1;
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n)
            cnt_20 <= 6'd0;
        else
            cnt_20 <= cnt_20_n;
    end

    always @(*) begin
        if (cnt_dyn_rst_flag) begin
            cnt_20_n = 20'd0;
        end else begin
            cnt_20_n = cnt_20 == 20'd19 ? 20'd0 : cnt_20+1;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            set_cnt <= 3'd0;
        end else begin
            if (out_valid_d1 && ~out_valid_a1) begin
                set_cnt <= set_cnt + 3'd1;
            end else begin
                set_cnt <= set_cnt;
            end
        end
    end

    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // template_reg, image_size_reg, action_reg
    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    always @(posedge clk) begin
        if (cs == STATE_IN_1 && in_valid) begin
            if (cnt_bdyn < 3) begin
                template_reg[cnt_bdyn[1:0]][cnt_dyn[1:0]] <= template_in_reg;
            end 
        end
    end

    always @(posedge clk) begin
        if (cs == STATE_IN_1 && in_valid) begin
            if ((last_in_valid_d1 == 1'b0 && in_valid  == 1'b1)) begin
                image_size_reg_master <= image_size_in_reg;
            end else begin
                image_size_reg_master <= image_size_reg_master;
            end
        end else begin
            image_size_reg_master <= image_size_reg_master;
        end
    end
    
    always @(posedge clk) begin
        if (cs == STATE_IN_2) begin
            image_size_reg_set <= image_size_reg_master;
        end else if (action_doing == ACTION_MAX_POOL && action_done) begin
            image_size_reg_set <= image_size_reg_set == 2'd0 ? 2'd0 : image_size_reg_set-1;
        end else begin
            image_size_reg_set <= image_size_reg_set;
        end
    end
    

    always @(posedge clk) begin
        if (cs == STATE_IDLE) begin
            for (i = 0; i < 8; i = i+1) begin
                action_reg[i] <= 3'b0;
            end
        end else
        if (cs == STATE_IN_2) begin
            if (cnt < 8) begin
                action_reg[cnt] <= action_in_reg;
            end 
        end else begin
            if (action_done) begin
                action_reg[0] <= action_reg[1];
                action_reg[1] <= action_reg[2];
                action_reg[2] <= action_reg[3];
                action_reg[3] <= action_reg[4];
                action_reg[4] <= action_reg[5];
                action_reg[5] <= action_reg[6];
                action_reg[6] <= action_reg[7];
                action_reg[7] <= 3'b0;
            end
        end
    end
    

    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // gray_scale
    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            gray_scale_0 <= 8'd0;
            gray_scale_1 <= 10'd0;
            gray_scale_2 <= 8'd0;
            gray_scale_0_s <= 8'd0;
            gray_scale_1_s <= 8'd0;
            gray_scale_2_s <= 8'd0;
        end else begin
            gray_scale_0 <= gray_scale_0_n;
            gray_scale_1 <= gray_scale_1_n;
            gray_scale_2 <= gray_scale_2_n;
            gray_scale_0_s <= gray_scale_0_s_n;
            gray_scale_1_s <= gray_scale_1_s_n;
            gray_scale_2_s <= gray_scale_2_s_n;
        end
    end

    always @(*) begin
        case(cnt_dyn[1:0])
            2'd2: begin
                gray_scale_0_n = image;
                gray_scale_1_n = image;
                gray_scale_2_n = image >> 2;
            end
            2'd0: begin
                gray_scale_0_n = image >= gray_scale_0 ? image : gray_scale_0;
                gray_scale_1_n = gray_scale_1 + image;
                gray_scale_2_n = gray_scale_2 + (image >> 1);
            end
            2'd1: begin
                gray_scale_0_n = image >= gray_scale_0 ? image : gray_scale_0;
                gray_scale_1_n = gray_scale_1 + image;
                gray_scale_2_n = gray_scale_2 + (image >> 2);
            end
            default: begin
                gray_scale_0_n = 8'bX;
                gray_scale_1_n = 8'bX;
                gray_scale_2_n = 8'bX;
            end
        endcase
    end

    always @(*) begin
        case(cnt_dyn[1:0])
            2'd2: begin
                gray_scale_0_s_n = gray_scale_0;
                gray_scale_1_s_n = gray_scale_1/3;  // TODO: Truncate might cause unexpected result
                gray_scale_2_s_n = gray_scale_2;
            end
            default: begin
                gray_scale_0_s_n = gray_scale_0_s;
                gray_scale_1_s_n = gray_scale_1_s;
                gray_scale_2_s_n = gray_scale_2_s;
            end
        endcase
    end
    
    //------------------------------------------------------------------
    // Read Layer (action_reg[0])
    //------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            read_layer <= 2'd0;
        end else begin
            if (last_in_valid2 && cnt == 8'd0) begin
                read_layer <= action_in_reg;
            end else begin
                read_layer <= read_layer;
            end
        end
    end

    always @(posedge clk) begin
        case(action_doing)
            ACTION_GRAY_MAX,
            ACTION_GRAY_AVG,
            ACTION_GRAY_WGT: begin
                action_done <= (cnt_dyn == cnt_dyn_base && cnt_bdyn[3:0] == cnt_dyn_base && cs == STATE_ACTN);
            end
            ACTION_MAX_POOL: begin
                action_done <= (cnt_dyn == 4'd0 && cnt_bdyn[7:0] == 8'd0);
            end
            ACTION_NEGATIVE: begin
                action_done <= (cnt_dyn == 4'd0 && cnt_bdyn[7:0] == 8'd0);
            end
            ACTION_HOR_FLIP: begin
                action_done <= (cnt_dyn == 4'd0 && cnt_bdyn[7:0] == 8'd0);
            end
            ACTION_MED_FILT: begin
                action_done <= medfilt_state == MED_STATE_DONE;
            end
            ACTION_CROS_COR: begin
                action_done <= (out_valid_d1 && ~out_valid_a1);
            end
            default: begin
                action_done <= 1'b0;
            end
        endcase
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            action_doing <= 3'd0;
        end else begin
            if (cs == STATE_CALC) begin
                action_doing <= action_reg[0];
            end else if (cs == STATE_IDLE) begin
                action_doing <= 3'd0;
            end else begin
                action_doing <= action_doing;
            end
        end
    end
    
    always @(posedge clk) begin
        if (cs == STATE_IN_2) begin
            action_5_flag <= 1'b0;
        end else begin
            if (action_done && action_doing == ACTION_HOR_FLIP) begin
                action_5_flag <= ~action_5_flag;
            end else begin
                action_5_flag <= action_5_flag;
            end
        end
    end

    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // gray_img
    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    always @(posedge clk) begin
        case(cs)
            STATE_ACTN: begin
                case(action_doing)
                    ACTION_GRAY_MAX,
                    ACTION_GRAY_AVG,
                    ACTION_GRAY_WGT: begin
                        gray_img[cnt_bdyn_d1[3:0]][cnt_dyn_d1] <= mem_data_a_out;
                    end
                    ACTION_MAX_POOL: begin
                        if (image_size_reg_set == 2'd0 || action_done) begin
                            // gray_img[][] <= mem_data_a_out;
                        end else begin
                            for (i = 0; i < 8; i = i+1) begin
                                for (j = 0; j < 8; j = j+1) begin
                                    gray_img[i][j] <= gray_img_maxpooling[i*2][j*2] >= gray_img_maxpooling[i*2][j*2+1] ? gray_img_maxpooling[i*2][j*2] : gray_img_maxpooling[i*2][j*2+1];
                                end
                            end
                        end
                    end
                    ACTION_MED_FILT: begin
                        // TODO
                        if (medfilt_state_d1 < 9 && cs_d1 != STATE_CALC) begin
                            gray_img[medfilt_cnt2_d1][medfilt_cnt_d1] <= medfilt_out_reg;
                        end
                    end
                    ACTION_NEGATIVE: begin
                        if (action_done) begin
                            for (i = 0; i < 16; i = i+1) begin
                                for (j = 0; j < 16; j = j+1) begin
                                    gray_img[i][j] <= gray_img[i][j];
                                end
                            end
                        end else begin
                            for (i = 0; i < 16; i = i+1) begin
                                for (j = 0; j < 16; j = j+1) begin
                                    gray_img[i][j] <= ~gray_img[i][j]; // TODO Optimize
                                end
                            end
                        end
                    end
                    default: begin
                        for (i = 0; i < 16; i = i+1) begin
                            for (j = 0; j < 16; j = j+1) begin
                                gray_img[i][j] <= gray_img[i][j];
                            end
                        end
                    end
                endcase
            end
            default: begin
                for (i = 0; i < 16; i = i+1) begin
                    for (j = 0; j < 16; j = j+1) begin
                        gray_img[i][j] <= gray_img[i][j];
                    end
                end
            end
        endcase
    end

    always @(*) begin
        for (i = 0; i < 16; i = i+2) begin
            for (j = 0; j < 16; j = j+1) begin
                gray_img_maxpooling[i][j] = gray_img[i][j] >= gray_img[i+1][j] ? gray_img[i][j] : gray_img[i+1][j];
            end
        end
    end
    
    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // Medfilt
    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    always @(posedge clk) begin
        mem_data_out_reg_shift_0[0] <= gray_img[cnt_bdyn][cnt_dyn];
        for (i = 1; i < 16; i = i+1) begin
            mem_data_out_reg_shift_0[i] <= mem_data_out_reg_shift_0[i-1];
        end
        mem_data_out_reg_shift_1[0] <= mem_data_out_reg_shift_0[cnt_dyn_base];
        for (i = 1; i < 16; i = i+1) begin
            mem_data_out_reg_shift_1[i] <= mem_data_out_reg_shift_1[i-1];
        end
        mem_data_out_reg_shift_2[0] <= mem_data_out_reg_shift_1[cnt_dyn_base];
        for (i = 1; i < 4; i = i+1) begin
            mem_data_out_reg_shift_2[i] <= mem_data_out_reg_shift_2[i-1];
        end
    end

    Median_3x3 Median_3x3_instance (
        .in0(medfilt_in[0][0]), .in1(medfilt_in[0][1]), .in2(medfilt_in[0][2]),
        .in3(medfilt_in[1][0]), .in4(medfilt_in[1][1]), .in5(medfilt_in[1][2]),
        .in6(medfilt_in[2][0]), .in7(medfilt_in[2][1]), .in8(medfilt_in[2][2]),
        .out(medfilt_out)
    );
    always @(posedge clk) begin
        medfilt_out_reg <= medfilt_out;
    end
    
    always @(posedge clk) begin
        if (cnt_dyn_rst_flag) begin
            medfilt_state <= MED_STATE_IDLE;
        end else begin
            medfilt_state <= medfilt_state_n;
        end
    end

    always @(posedge clk) begin
        medfilt_state_d1 <= medfilt_state;
    end

    always @(*) begin
        case(medfilt_state)
            MED_STATE_IDLE: begin
                medfilt_state_n = MED_STATE_IDLE;
                if (cnt_dyn == 8'd2 && cnt_bdyn == 4'd1) begin
                    medfilt_state_n = MED_STATE_0;
                end
            end
            MED_STATE_0: begin
                medfilt_state_n = MED_STATE_1;
            end
            MED_STATE_1: begin
                medfilt_state_n = MED_STATE_1;
                if (medfilt_cnt == cnt_dyn_base-1) begin
                    medfilt_state_n = MED_STATE_2;
                end
            end
            MED_STATE_2: begin
                medfilt_state_n = MED_STATE_3;
            end
            MED_STATE_3: begin
                medfilt_state_n = MED_STATE_4;
            end
            MED_STATE_4: begin
                medfilt_state_n = MED_STATE_4;
                if (medfilt_cnt == cnt_dyn_base-1) begin
                    medfilt_state_n = MED_STATE_5;
                end
            end
            MED_STATE_5: begin
                medfilt_state_n = MED_STATE_3;
                if (medfilt_cnt2 == cnt_dyn_base-1) begin
                    medfilt_state_n = MED_STATE_6;
                end
            end
            MED_STATE_6: begin
                medfilt_state_n = MED_STATE_7;
            end
            MED_STATE_7: begin
                medfilt_state_n = MED_STATE_7;
                if (medfilt_cnt == cnt_dyn_base-1) begin
                    medfilt_state_n = MED_STATE_8;
                end
            end
            MED_STATE_8: begin
                medfilt_state_n = MED_STATE_DONE;
            end
            MED_STATE_DONE: begin
                medfilt_state_n = MED_STATE_IDLE;
            end
            default: begin
                medfilt_state_n = MED_STATE_IDLE;
            end
        endcase
    end

    always @(posedge clk) begin
        if (
            (cs == STATE_IN_1) ||
            (medfilt_state == MED_STATE_IDLE) ||
            (medfilt_state == MED_STATE_2)  ||
            (medfilt_state == MED_STATE_5)
        ) begin
            medfilt_cnt <= 4'd0;
        end else begin
            medfilt_cnt <= medfilt_cnt_n;
        end
        medfilt_cnt_d1 <= medfilt_cnt;
    end

    always @(*) begin
        medfilt_cnt_n = medfilt_cnt == cnt_dyn_base ? 4'd0 : medfilt_cnt+1;
    end

    always @(posedge clk) begin
        if (
            (medfilt_state == MED_STATE_IDLE) ||
            (cs == STATE_IN_1)
        ) begin
            medfilt_cnt2 <= 4'd0;
        end else begin
            medfilt_cnt2 <= medfilt_cnt2_n;
        end
        medfilt_cnt2_d1 <= medfilt_cnt2;
    end

    always @(*) begin
        medfilt_cnt2_n = medfilt_cnt == cnt_dyn_base ? medfilt_cnt2+1 : medfilt_cnt2;
    end
    
    always @(*) begin
        case(medfilt_state)
            MED_STATE_0: begin
                medfilt_in[0][0] = mem_data_out_reg_shift_1[2];
                medfilt_in[0][1] = mem_data_out_reg_shift_1[2];
                medfilt_in[0][2] = mem_data_out_reg_shift_1[1];
                medfilt_in[1][0] = mem_data_out_reg_shift_1[2];
                medfilt_in[1][1] = mem_data_out_reg_shift_1[2];
                medfilt_in[1][2] = mem_data_out_reg_shift_1[1];
                medfilt_in[2][0] = mem_data_out_reg_shift_0[2];
                medfilt_in[2][1] = mem_data_out_reg_shift_0[2];
                medfilt_in[2][2] = mem_data_out_reg_shift_0[1];
            end
            MED_STATE_1: begin
                medfilt_in[0][0] = mem_data_out_reg_shift_1[3];
                medfilt_in[0][1] = mem_data_out_reg_shift_1[2];
                medfilt_in[0][2] = mem_data_out_reg_shift_1[1];
                medfilt_in[1][0] = mem_data_out_reg_shift_1[3];
                medfilt_in[1][1] = mem_data_out_reg_shift_1[2];
                medfilt_in[1][2] = mem_data_out_reg_shift_1[1];
                medfilt_in[2][0] = mem_data_out_reg_shift_0[3];
                medfilt_in[2][1] = mem_data_out_reg_shift_0[2];
                medfilt_in[2][2] = mem_data_out_reg_shift_0[1];
            end
            MED_STATE_2: begin
                medfilt_in[0][0] = mem_data_out_reg_shift_1[3];
                medfilt_in[0][1] = mem_data_out_reg_shift_1[2];
                medfilt_in[0][2] = mem_data_out_reg_shift_1[2];
                medfilt_in[1][0] = mem_data_out_reg_shift_1[3];
                medfilt_in[1][1] = mem_data_out_reg_shift_1[2];
                medfilt_in[1][2] = mem_data_out_reg_shift_1[2];
                medfilt_in[2][0] = mem_data_out_reg_shift_0[3];
                medfilt_in[2][1] = mem_data_out_reg_shift_0[2];
                medfilt_in[2][2] = mem_data_out_reg_shift_0[2];
            end
            MED_STATE_3: begin
                medfilt_in[0][0] = mem_data_out_reg_shift_2[2];
                medfilt_in[0][1] = mem_data_out_reg_shift_2[2];
                medfilt_in[0][2] = mem_data_out_reg_shift_2[1];
                medfilt_in[1][0] = mem_data_out_reg_shift_1[2];
                medfilt_in[1][1] = mem_data_out_reg_shift_1[2];
                medfilt_in[1][2] = mem_data_out_reg_shift_1[1];
                medfilt_in[2][0] = mem_data_out_reg_shift_0[2];
                medfilt_in[2][1] = mem_data_out_reg_shift_0[2];
                medfilt_in[2][2] = mem_data_out_reg_shift_0[1];
            end
            MED_STATE_4: begin
                medfilt_in[0][0] = mem_data_out_reg_shift_2[3];
                medfilt_in[0][1] = mem_data_out_reg_shift_2[2];
                medfilt_in[0][2] = mem_data_out_reg_shift_2[1];
                medfilt_in[1][0] = mem_data_out_reg_shift_1[3];
                medfilt_in[1][1] = mem_data_out_reg_shift_1[2];
                medfilt_in[1][2] = mem_data_out_reg_shift_1[1];
                medfilt_in[2][0] = mem_data_out_reg_shift_0[3];
                medfilt_in[2][1] = mem_data_out_reg_shift_0[2];
                medfilt_in[2][2] = mem_data_out_reg_shift_0[1];
            end
            MED_STATE_5: begin
                medfilt_in[0][0] = mem_data_out_reg_shift_2[3];
                medfilt_in[0][1] = mem_data_out_reg_shift_2[2];
                medfilt_in[0][2] = mem_data_out_reg_shift_2[2];
                medfilt_in[1][0] = mem_data_out_reg_shift_1[3];
                medfilt_in[1][1] = mem_data_out_reg_shift_1[2];
                medfilt_in[1][2] = mem_data_out_reg_shift_1[2];
                medfilt_in[2][0] = mem_data_out_reg_shift_0[3];
                medfilt_in[2][1] = mem_data_out_reg_shift_0[2];
                medfilt_in[2][2] = mem_data_out_reg_shift_0[2];
            end
            MED_STATE_6: begin
                medfilt_in[0][0] = mem_data_out_reg_shift_2[2];
                medfilt_in[0][1] = mem_data_out_reg_shift_2[2];
                medfilt_in[0][2] = mem_data_out_reg_shift_2[1];
                medfilt_in[1][0] = mem_data_out_reg_shift_1[2];
                medfilt_in[1][1] = mem_data_out_reg_shift_1[2];
                medfilt_in[1][2] = mem_data_out_reg_shift_1[1];
                medfilt_in[2][0] = mem_data_out_reg_shift_1[2];
                medfilt_in[2][1] = mem_data_out_reg_shift_1[2];
                medfilt_in[2][2] = mem_data_out_reg_shift_1[1];
            end
            MED_STATE_7: begin
                medfilt_in[0][0] = mem_data_out_reg_shift_2[3];
                medfilt_in[0][1] = mem_data_out_reg_shift_2[2];
                medfilt_in[0][2] = mem_data_out_reg_shift_2[1];
                medfilt_in[1][0] = mem_data_out_reg_shift_1[3];
                medfilt_in[1][1] = mem_data_out_reg_shift_1[2];
                medfilt_in[1][2] = mem_data_out_reg_shift_1[1];
                medfilt_in[2][0] = mem_data_out_reg_shift_1[3];
                medfilt_in[2][1] = mem_data_out_reg_shift_1[2];
                medfilt_in[2][2] = mem_data_out_reg_shift_1[1];
            end
            MED_STATE_8: begin
                medfilt_in[0][0] = mem_data_out_reg_shift_2[3];
                medfilt_in[0][1] = mem_data_out_reg_shift_2[2];
                medfilt_in[0][2] = mem_data_out_reg_shift_2[2];
                medfilt_in[1][0] = mem_data_out_reg_shift_1[3];
                medfilt_in[1][1] = mem_data_out_reg_shift_1[2];
                medfilt_in[1][2] = mem_data_out_reg_shift_1[2];
                medfilt_in[2][0] = mem_data_out_reg_shift_1[3];
                medfilt_in[2][1] = mem_data_out_reg_shift_1[2];
                medfilt_in[2][2] = mem_data_out_reg_shift_1[2];
            end
            default: begin
                medfilt_in[0][0] = 8'bX;
                medfilt_in[0][1] = 8'bX;
                medfilt_in[0][2] = 8'bX;
                medfilt_in[1][0] = 8'bX;
                medfilt_in[1][1] = 8'bX;
                medfilt_in[1][2] = 8'bX;
                medfilt_in[2][0] = 8'bX;
                medfilt_in[2][1] = 8'bX;
                medfilt_in[2][2] = 8'bX;
            end
        endcase
    end

    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    
    wire [7:0] templage_selected, gray_img_selected;
    assign templage_selected = template_reg[cnt_cro_3b3][cnt_cro_3];
    assign gray_img_selected = gray_img[cro_addr_y][cro_addr_x];

    always @(posedge clk) begin
        if (cs == STATE_CALC || cnt_20 >= 6'd9) begin
            cro_mac <= 20'd0;
        end else begin
            if (cro_addr_out_of_bound) begin
                cro_mac <= cro_mac;
            end else begin
                cro_mac <= cro_mac + (gray_img[cro_addr_y][cro_addr_x] * template_reg[cnt_cro_3b3][cnt_cro_3]);
            end
        end
    end

    always @(posedge clk) begin
        if (cs == STATE_CALC || cnt_20 == 6'd9) begin
            cro_mac_store <= cro_mac;
        end else begin
            cro_mac_store <= cro_mac_store << 1;
        end
    end
    

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out_valid_a1 <= 1'b0;
            out_valid_d1 <= 1'b0;
        end else begin
            // if (!out_valid && cs == STATE_ACTN) begin
            //     out_valid <= action_doing == ACTION_CROS_COR && cnt_20 == 6'd9;
            // end else begin
            if (cnt_20 == 6'd9 && action_doing == 3'd7 && cnt_cro_y == 4'd0 && cnt_cro_x == 4'd1)
                out_valid_a1 <= ~out_valid_a1;
            else
                out_valid_a1 <= out_valid_a1;
            // end
            out_valid_d1 <= out_valid_a1;
        end
    end
    
    always @(*) begin
        out_value_a1 = cro_mac_store[19] & out_valid_a1;
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out_valid <= 1'b0;
            out_value <= 1'b0;
        end else begin
            out_valid <= out_valid_a1;
            out_value <= out_value_a1;
        end
    end

endmodule


module MEM_768(
    input clk,
    input [9:0] A,
    input [7:0] DIA,
    input WEAN,
    input CSA,
    input OEA,

    output [7:0] DOA
);

    SUMA180_768X8X1BM2 // @suppress
    SUMA180_768X8X1BM2_instance (
        .A0(A[0]),
        .A1(A[1]),
        .A2(A[2]),
        .A3(A[3]),
        .A4(A[4]),
        .A5(A[5]),
        .A6(A[6]),
        .A7(A[7]),
        .A8(A[8]),
        .A9(A[9]),
        .DO0(DOA[0]),
        .DO1(DOA[1]),
        .DO2(DOA[2]),
        .DO3(DOA[3]),
        .DO4(DOA[4]),
        .DO5(DOA[5]),
        .DO6(DOA[6]),
        .DO7(DOA[7]),
        .DI0(DIA[0]),
        .DI1(DIA[1]),
        .DI2(DIA[2]),
        .DI3(DIA[3]),
        .DI4(DIA[4]),
        .DI5(DIA[5]),
        .DI6(DIA[6]),
        .DI7(DIA[7]),
        .CK(clk),
        .WEB(WEAN),
        .OE(OEA),
        .CS(CSA)
    );

endmodule


module Median_3x3 (
    input [7:0] in0, in1, in2, in3, in4, in5, in6, in7, in8,
    output [7:0] out
);

    wire [7:0] s0_max0_n, s0_med0_n, s0_min0_n;
    wire [7:0] s0_max1_n, s0_med1_n, s0_min1_n;
    wire [7:0] s0_max2_n, s0_med2_n, s0_min2_n;
    wire [7:0] s1_min0_n;
    wire [7:0] s1_med1_n;
    wire [7:0] s1_max2_n;

    Sort3 Sort3_instance_s0_0 (
        .in0(in0), .in1(in1), .in2(in2),
        .out0(s0_max0_n), .out1(s0_med0_n), .out2(s0_min0_n)
    );
    Sort3 Sort3_instance_s0_1 (
        .in0(in3), .in1(in4), .in2(in5),
        .out0(s0_max1_n), .out1(s0_med1_n), .out2(s0_min1_n)
    );
    Sort3 Sort3_instance_s0_2 (
        .in0(in6), .in1(in7), .in2(in8),
        .out0(s0_max2_n), .out1(s0_med2_n), .out2(s0_min2_n)
    );
    Sort3 Sort3_instance_s1_0 (
        .in0(s0_max0_n), .in1(s0_max1_n), .in2(s0_max2_n),
        .out0(), .out1(), .out2(s1_min0_n)
    );
    Sort3 Sort3_instance_s1_1 (
        .in0(s0_med0_n), .in1(s0_med1_n), .in2(s0_med2_n),
        .out0(), .out1(s1_med1_n), .out2()
    );
    Sort3 Sort3_instance_s1_2 (
        .in0(s0_min0_n), .in1(s0_min1_n), .in2(s0_min2_n),
        .out0(s1_max2_n), .out1(), .out2()
    );
    Sort3 Sort3_instance_out (
        .in0(s1_min0_n), .in1(s1_med1_n), .in2(s1_max2_n),
        .out0(), .out1(out), .out2()
    );

endmodule

module Sort3 (
    input      [7:0] in0, in1, in2,
    output reg [7:0] out0, out1, out2
);

    wire cmp01, cmp02, cmp12;

    assign cmp01 = in0 <= in1;
    assign cmp02 = in0 <= in2;
    assign cmp12 = in1 <= in2;

    always @(*) begin
        case({cmp01, cmp02, cmp12})
            3'b000: begin
                out0 = in0;
                out1 = in1;
                out2 = in2;
            end
            3'b001: begin
                out0 = in0;
                out1 = in2;
                out2 = in1;
            end
            3'b100: begin
                out0 = in1;
                out1 = in0;
                out2 = in2;
            end
            3'b011: begin
                out0 = in2;
                out1 = in0;
                out2 = in1;
            end
            3'b110: begin
                out0 = in1;
                out1 = in2;
                out2 = in0;
            end
            3'b111: begin
                out0 = in2;
                out1 = in1;
                out2 = in0;
            end
            default: begin
                out0 = 8'bX;
                out1 = 8'bX;
                out2 = 8'bX;
            end
        endcase
    end

endmodule
