module ISP(
    // ===============================================================
    // Input & Output Declaration
    // ===============================================================
    // -----------------------------
    // Input Signals
    // -----------------------------
    input                           clk,
    input                           rst_n,
    input                           in_valid,
    input      [ 3:0]               in_pic_no,
    input      [ 1:0]               in_mode,
    input      [ 1:0]               in_ratio_mode,

    // -----------------------------
    // Output Signals
    // -----------------------------
    output reg                      out_valid,
    output reg [ 7:0]               out_data,
    
    // ===============================================================
    // DRAM Signals
    // ===============================================================
    // -----------------------------
    // axi write address channel
    // -----------------------------
    // src master
    output     [ 3:0]               awid_s_inf,     // Constant 0
    output     [31:0]               awaddr_s_inf,
    output     [ 2:0]               awsize_s_inf,   // Constant 4
    output     [ 1:0]               awburst_s_inf,  // Constant 1
    output     [ 7:0]               awlen_s_inf,    // Constant 64 * 3 - 1
    output reg                      awvalid_s_inf,
    // src slave
    input                           awready_s_inf,  // DRAM Write Latency is always 1
  
    // -----------------------------
    // axi write data channel 
    // -----------------------------
    // src master
    output     [127:0]              wdata_s_inf,
    output                          wlast_s_inf,
    output reg                      wvalid_s_inf,
    // src slave
    input                           wready_s_inf,   // Ignored
  
    // -----------------------------
    // axi write response channel 
    // -----------------------------
    // src slave
    input     [ 3:0]                bid_s_inf,      // Ignored
    input     [ 1:0]                bresp_s_inf,    // Ignored
    input                           bvalid_s_inf,
    // src master 
    output reg                      bready_s_inf,
  
    // -----------------------------
    // axi read address channel 
    // -----------------------------
    // src master
    output     [ 3:0]               arid_s_inf,     // Constant 0
    output reg [31:0]               araddr_s_inf,
    output     [ 7:0]               arlen_s_inf,    // Constant 64 * 3 - 1
    output     [ 2:0]               arsize_s_inf,   // Constant 4
    output     [ 1:0]               arburst_s_inf,  // Constant 1
    output reg                      arvalid_s_inf,
    // src slave
    input                           arready_s_inf,
  
    // -----------------------------
    // axi read data channel 
    // -----------------------------
    // slave
    input      [ 3:0]               rid_s_inf,      // Ignored
    input      [127:0]              rdata_s_inf,
    input      [ 1:0]               rresp_s_inf,    // Ignored
    input                           rlast_s_inf,
    input                           rvalid_s_inf,
    // master
    output reg                      rready_s_inf
    
);
    // ===============================================================
    // Parameter & Integer Declaration
    // ===============================================================
    integer i, j, k, l, m, n; //@suppress


    // ---------------------------------------------------------------
    // State Parameter
    localparam [ 3:0] STATE_IDLE = 4'd0;
    localparam [ 3:0] STATE_INPT = 4'd1;
    localparam [ 3:0] STATE_READ = 4'd2;
    localparam [ 3:0] STATE_WAIT = 4'd3;

    localparam [ 3:0] STATE_OUPT = 4'd7;

    // ---------------------------------------------------------------
    // Mode Parameter
    localparam [ 1:0] MODE_AUTO_FOCUS = 2'd0;
    localparam [ 1:0] MODE_AUTO_EXPOSURE = 2'd1;
    localparam [ 1:0] MODE_AVG_MIN_MAX = 2'd2;

    // ===============================================================
    // Wire & Reg Declaration
    // ===============================================================
    // ---------------------------------------------------------------
    // Input Buffer
    // ---------------------------------------------------------------
    reg         in_valid_buf;
    reg  [ 3:0] in_pic_no_buf;
    reg  [ 1:0] in_mode_buf;
    reg  [ 1:0] in_ratio_mode_buf;
    reg         awready_s_inf_buf;
    reg         bvalid_s_inf_buf;
    reg         arready_s_inf_buf;
    reg [127:0] rdata_s_inf_buf;
    reg         rlast_s_inf_buf;
    reg         rvalid_s_inf_buf;
    // ---------------------------------------------------------------
    // State Reg
    reg  [ 3:0] cs, ns;
    // ---------------------------------------------------------------
    // Input Data
    reg  [ 3:0] pic_no;
    reg  [ 1:0] mode;
    reg  [ 1:0] ratio_mode;
    // ---------------------------------------------------------------
    // Pre Calculated Data
    reg  [15:0] pic_calculated;          // 1 if calculated
    reg  [ 1:0] A_pre_calculated [15:0]; // Auto Focus
    reg  [ 7:0] B_pre_calculated [15:0]; // Auto Exposure
    reg  [ 7:0] C_pre_calculated [15:0]; // Avg Min Max
    // ---------------------------------------------------------------
    // Shift counter
    reg  [ 3:0] shift_cnt [15:0];
    // ---------------------------------------------------------------
    // Trigger
    reg         arvalid_trigger;
    // ---------------------------------------------------------------
    // Misc
    reg         jump_to_oupt;
    reg         rready_d [7:1];
    reg         rlast_d1;
    reg         awready_d1;
    reg         awvalid_d1;
    reg         awvalid_sent;
    // ---------------------------------------------------------------
    // AXI Read in
    reg  [ 7:0] read_data [15:0];
    reg  [ 7:0] read_data_weighted [15:0];
    // ---------------------------------------------------------------
    // Counters 
    reg  [ 7:0] cnt, cnt_n;
    reg  [ 7:0] cnt_d1; // Delay 1 cycle
    reg  [ 7:0] cnt_d5; // Delay 5 cycle
    // ---------------------------------------------------------------
    // A (Auto Focus)
    reg  [ 6:0] temp_A [3:0];
    reg  [ 6:0] curr_row [5:0];
    reg  [ 6:0] last_row [5:0];
    reg  [ 8:0] diff_h [5:0][4:0]; // [y][x]
    reg  [ 8:0] diff_v [4:0][5:0]; // [y][x]
    reg  [ 8:0] diff_hv_0, diff_hv_1, diff_hv_2, diff_hv_3, diff_hv_4, diff_hv_5;
    reg  [ 8:0] diff_hv_0_r, diff_hv_1_r, diff_hv_2_r, diff_hv_3_r, diff_hv_4_r, diff_hv_5_r;
    reg  [ 8:0] diff_hv_0_op0, diff_hv_1_op0, diff_hv_2_op0, diff_hv_3_op0, diff_hv_4_op0, diff_hv_5_op0;
    reg  [ 6:0] diff_hv_0_op1, diff_hv_1_op1, diff_hv_2_op1, diff_hv_3_op1, diff_hv_4_op1, diff_hv_5_op1;
    reg  [ 6:0] diff_hv_0_op2, diff_hv_1_op2, diff_hv_2_op2, diff_hv_3_op2, diff_hv_4_op2, diff_hv_5_op2;
    reg  [13:0] diff_sum_2;
    reg  [ 8:0] diff_sum_1;
    reg  [ 7:0] diff_sum_0;
    reg  [13:0] diff_sum_2_n;
    reg  [ 8:0] diff_sum_2_op0, diff_sum_2_op1, diff_sum_2_op2, diff_sum_2_op3;
    reg  [ 8:0] diff_sum_2_op0_abs, diff_sum_2_op1_abs, diff_sum_2_op2_abs, diff_sum_2_op3_abs;
    reg  [ 9:0] diff_sum_2_op01, diff_sum_2_op23;
    reg  [10:0] diff_sum_2_op0123;
    reg  [12:0] diff_sum_2_div9_sub;
    reg  [ 4:0] diff_sum_2_head;
    reg  [12:0] diff_sum_2_dnt;
    reg  [ 8:0] diff_sum_2_div9;
    // ---------------------------------------------------------------
    // B (Auto Exposure)
    reg  [ 7:0] read_sum_s0 [7:0];
    reg  [ 8:0] read_sum_s1 [3:0];
    reg  [ 9:0] read_sum_s2 [1:0];
    reg  [10:0] read_sum;
    reg  [17:0] sum;
    // ---------------------------------------------------------------
    // C (Avg Min Max)
    reg  [ 7:0] max_s0 [7:0];
    reg  [ 7:0] max_s1 [3:0];
    reg  [ 7:0] max_s2 [1:0];
    reg  [ 7:0] max_s3;
    reg  [ 7:0] min_s0 [7:0];
    reg  [ 7:0] min_s1 [3:0];
    reg  [ 7:0] min_s2 [1:0];
    reg  [ 7:0] min_s3;
    reg  [ 7:0] max_r, max_g, max_b;
    reg  [ 7:0] min_r, min_g, min_b;
    reg  [ 8:0] max_sum_op0, min_sum_op0;
    reg  [ 8:0] max_sum_op1, min_sum_op1;
    reg  [ 9:0] max_sum, min_sum;
    reg  [ 9:0] max_sum_div3_sub, min_sum_div3_sub;
    reg  [ 2:0] max_sum_head, min_sum_head;
    reg  [ 7:0] max_avg, min_avg;
    wire [ 8:0] sum_max_min;

    // ===============================================================
    // Design
    // ===============================================================
    // ---------------------------------------------------------------
    // Input Buffer
    // ---------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            in_valid_buf        <= 1'b0;
            in_pic_no_buf       <= 4'd0;
            in_mode_buf         <= 2'd0;
            in_ratio_mode_buf   <= 2'd0;
            awready_s_inf_buf   <= 1'b0;
            bvalid_s_inf_buf    <= 1'b0;
            arready_s_inf_buf   <= 1'b0;
            rdata_s_inf_buf     <= 128'h0;
            rlast_s_inf_buf     <= 1'b0;
            rvalid_s_inf_buf    <= 1'b0;
        end else begin
            in_valid_buf        <= in_valid;
            in_pic_no_buf       <= in_pic_no;
            in_mode_buf         <= in_mode;
            in_ratio_mode_buf   <= in_ratio_mode;
            awready_s_inf_buf   <= awready_s_inf;   // Not used
            bvalid_s_inf_buf    <= bvalid_s_inf;
            arready_s_inf_buf   <= arready_s_inf;   // Not used
            rdata_s_inf_buf     <= rdata_s_inf;
            rlast_s_inf_buf     <= rlast_s_inf;
            rvalid_s_inf_buf    <= rvalid_s_inf;
        end
    end
    // ---------------------------------------------------------------
    // Input Data
    // ---------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            pic_no <= 4'd0;
            mode <= 2'd0;
            ratio_mode <= 2'd0;
        end else begin
            if (in_valid_buf) begin
                pic_no <= in_pic_no_buf;
                mode <= in_mode_buf;
                ratio_mode <= in_mode_buf == MODE_AUTO_EXPOSURE ? in_ratio_mode_buf : 2'd2;
            end
        end
    end

    // ---------------------------------------------------------------
    // State Machine
    // ---------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            cs <= STATE_IDLE;
        end else begin
            cs <= ns;
        end
    end

    always @(*) begin
        if (shift_cnt[pic_no][3] == 1) begin
            jump_to_oupt = 'd1;
        end else
        if (mode == MODE_AUTO_EXPOSURE && ratio_mode != 2'd2) begin
            jump_to_oupt = 'd0;
        end else begin
            jump_to_oupt = pic_calculated[pic_no] == 1;
        end
    end

    always @(*) begin
        case (cs)
            STATE_IDLE: begin
                ns = in_valid_buf ? STATE_INPT : STATE_IDLE;
            end
            STATE_INPT: begin
                ns = jump_to_oupt ? STATE_OUPT : STATE_READ;
            end
            STATE_READ: begin
                ns = arready_s_inf ? STATE_WAIT : STATE_READ;
            end
            STATE_WAIT: begin
                ns = cnt_d5 == 'd202 ? STATE_OUPT : STATE_WAIT;
            end
            STATE_OUPT: begin
                ns = STATE_IDLE;
            end
            default: begin
                ns = STATE_IDLE;
            end
        endcase
    end

    // ---------------------------------------------------------------
    // AXI
    // ---------------------------------------------------------------
    // -----------------------------
    // axi write address channel
    // -----------------------------
    assign awid_s_inf = 4'd0;
    assign awaddr_s_inf = araddr_s_inf;
    assign awsize_s_inf = 3'd4;
    assign awburst_s_inf = 2'd1;
    assign awlen_s_inf = 8'd64 * 3 - 1;

    always @(posedge clk) begin
        if (cs == STATE_IDLE) begin
            awvalid_sent = 1'b0;
        end else if (awvalid_s_inf) begin
            awvalid_sent = 1'b1;
        end
    end
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            awvalid_s_inf <= 1'b0;
        end else begin
            if (mode == MODE_AUTO_EXPOSURE && ratio_mode != 2'd2 && (!awvalid_sent) && rvalid_s_inf_buf) begin
                awvalid_s_inf <= 1'b1;
            end else if (awready_s_inf) begin
                awvalid_s_inf <= 1'b0;
            end else begin
                awvalid_s_inf <= awvalid_s_inf;
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            awready_d1 <= 1'b0;
            awvalid_d1 <= 1'b0;
        end else begin
            awready_d1 <= awready_s_inf;
            awvalid_d1 <= awvalid_s_inf;
        end
    end

    // -----------------------------
    // axi write data channel
    // -----------------------------
    assign wdata_s_inf = {
        read_data[15],read_data[14],read_data[13],read_data[12],
        read_data[11],read_data[10],read_data[ 9],read_data[ 8],
        read_data[ 7],read_data[ 6],read_data[ 5],read_data[ 4],
        read_data[ 3],read_data[ 2],read_data[ 1],read_data[ 0]
    };
    assign wlast_s_inf = rlast_d1;
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            wvalid_s_inf <= 1'b0;
        end else begin
            if (awvalid_d1 && awready_d1) begin
                wvalid_s_inf <= 1'b1;
            end else if (cnt == 8'd192) begin
                wvalid_s_inf <= 1'b0;
            end else begin
                wvalid_s_inf <= wvalid_s_inf;
            end
        end
    end

    // -----------------------------
    // axi write response channel
    // -----------------------------
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            bready_s_inf <= 1'b0;
        end else begin
            if (awvalid_s_inf && awready_s_inf) begin
                bready_s_inf <= 1'b1;
            end else if (bvalid_s_inf_buf) begin
                bready_s_inf <= 1'b0;
            end else begin
                bready_s_inf <= bready_s_inf;
            end
        end
    end

    // -----------------------------
    // axi read address channel
    // -----------------------------
    assign arid_s_inf = 4'd0;
    assign arlen_s_inf = 8'd64 * 3 - 1;
    assign arsize_s_inf = 3'd4;
    assign arburst_s_inf = 2'd1;

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            araddr_s_inf <= 32'd0;
        end else begin
            case (pic_no)
                'h0: araddr_s_inf <= 32'h10000;
                'h1: araddr_s_inf <= 32'h10C00;
                'h2: araddr_s_inf <= 32'h11800;
                'h3: araddr_s_inf <= 32'h12400;
                'h4: araddr_s_inf <= 32'h13000;
                'h5: araddr_s_inf <= 32'h13C00;
                'h6: araddr_s_inf <= 32'h14800;
                'h7: araddr_s_inf <= 32'h15400;
                'h8: araddr_s_inf <= 32'h16000;
                'h9: araddr_s_inf <= 32'h16C00;
                'hA: araddr_s_inf <= 32'h17800;
                'hB: araddr_s_inf <= 32'h18400;
                'hC: araddr_s_inf <= 32'h19000;
                'hD: araddr_s_inf <= 32'h19C00;
                'hE: araddr_s_inf <= 32'h1A800;
                'hF: araddr_s_inf <= 32'h1B400;
                default: araddr_s_inf <= 32'd0; // Impossible
            endcase
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            arvalid_trigger <= 1'b0;
        end else begin
            if (cs == STATE_INPT) begin
                arvalid_trigger <= ~jump_to_oupt;
            end else begin
                arvalid_trigger <= 1'b0;
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            arvalid_s_inf <= 1'b0;
        end else begin
            if (arready_s_inf) begin
                arvalid_s_inf <= 1'b0;
            end else if (arvalid_trigger) begin
                arvalid_s_inf <= 1'b1;
            end else begin
                arvalid_s_inf <= arvalid_s_inf;
            end
        end
    end

    // -----------------------------
    // axi read data channel
    // -----------------------------
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            rready_s_inf <= 1'b0;
        end else begin
            if (mode == MODE_AUTO_EXPOSURE && ratio_mode != 2'd2) begin
                if (!awready_s_inf && awready_d1) begin
                    rready_s_inf <= 1'b1;
                end else if (rlast_s_inf_buf) begin
                    rready_s_inf <= 1'b0;
                end
            end else begin
                if (rvalid_s_inf_buf) begin
                    rready_s_inf <= 1'b1;
                end else if (rready_s_inf) begin
                    rready_s_inf <= 1'b0;
                end
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            for (int i = 1; i < 8; i = i + 1) begin
                rready_d[i] <= 1'b0;
            end
        end else begin
            rready_d[1] <= rready_s_inf;
            for (int i = 2; i < 8; i = i + 1) begin
                rready_d[i] <= rready_d[i - 1];
            end
            rlast_d1 <= rlast_s_inf_buf;
        end
    end
    
    // ---------------------------------------------------------------
    // Pre Calculated Data
    // ---------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            pic_calculated <= 16'h0;
        end else begin
            if (cs == STATE_INPT) begin
                pic_calculated[pic_no] <= 1;
            end 
        end
    end

    // ---------------------------------------------------------------
    // Shift Counter
    // ---------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            for (i = 0; i < 16; i = i + 1) begin
                shift_cnt[i] <= 4'd0;
            end
        end else begin
            if (in_valid_buf && !shift_cnt[in_pic_no_buf][3] && in_mode_buf == MODE_AUTO_EXPOSURE) begin
                case (in_ratio_mode_buf)
                    2'd0: begin
                        shift_cnt[in_pic_no_buf] <= shift_cnt[in_pic_no_buf] + 4'd2;
                    end
                    2'd1: begin
                        shift_cnt[in_pic_no_buf] <= shift_cnt[in_pic_no_buf] + 4'd1;
                    end
                    2'd2: begin
                        shift_cnt[in_pic_no_buf] <= shift_cnt[in_pic_no_buf];
                    end
                    2'd3: begin
                        shift_cnt[in_pic_no_buf] <= shift_cnt[in_pic_no_buf] - (shift_cnt[in_pic_no_buf] != 4'd0);
                    end
                    default: /* Impossible */;
                endcase
            end
        end
    end

    // ---------------------------------------------------------------
    // Read Data
    // ---------------------------------------------------------------
    // TODO: Make read_data wire, save area.
    always @(posedge clk) begin
        case (ratio_mode)
            2'd0: begin
                read_data[ 0] <= {2'b0,rdata_s_inf_buf[  7:  2]};
                read_data[ 1] <= {2'b0,rdata_s_inf_buf[ 15: 10]};
                read_data[ 2] <= {2'b0,rdata_s_inf_buf[ 23: 18]};
                read_data[ 3] <= {2'b0,rdata_s_inf_buf[ 31: 26]};
                read_data[ 4] <= {2'b0,rdata_s_inf_buf[ 39: 34]};
                read_data[ 5] <= {2'b0,rdata_s_inf_buf[ 47: 42]};
                read_data[ 6] <= {2'b0,rdata_s_inf_buf[ 55: 50]};
                read_data[ 7] <= {2'b0,rdata_s_inf_buf[ 63: 58]};
                read_data[ 8] <= {2'b0,rdata_s_inf_buf[ 71: 66]};
                read_data[ 9] <= {2'b0,rdata_s_inf_buf[ 79: 74]};
                read_data[10] <= {2'b0,rdata_s_inf_buf[ 87: 82]};
                read_data[11] <= {2'b0,rdata_s_inf_buf[ 95: 90]};
                read_data[12] <= {2'b0,rdata_s_inf_buf[103: 98]};
                read_data[13] <= {2'b0,rdata_s_inf_buf[111:106]};
                read_data[14] <= {2'b0,rdata_s_inf_buf[119:114]};
                read_data[15] <= {2'b0,rdata_s_inf_buf[127:122]};
            end
            2'd1: begin
                read_data[ 0] <= {1'b0,rdata_s_inf_buf[  7:  1]};
                read_data[ 1] <= {1'b0,rdata_s_inf_buf[ 15:  9]};
                read_data[ 2] <= {1'b0,rdata_s_inf_buf[ 23: 17]};
                read_data[ 3] <= {1'b0,rdata_s_inf_buf[ 31: 25]};
                read_data[ 4] <= {1'b0,rdata_s_inf_buf[ 39: 33]};
                read_data[ 5] <= {1'b0,rdata_s_inf_buf[ 47: 41]};
                read_data[ 6] <= {1'b0,rdata_s_inf_buf[ 55: 49]};
                read_data[ 7] <= {1'b0,rdata_s_inf_buf[ 63: 57]};
                read_data[ 8] <= {1'b0,rdata_s_inf_buf[ 71: 65]};
                read_data[ 9] <= {1'b0,rdata_s_inf_buf[ 79: 73]};
                read_data[10] <= {1'b0,rdata_s_inf_buf[ 87: 81]};
                read_data[11] <= {1'b0,rdata_s_inf_buf[ 95: 89]};
                read_data[12] <= {1'b0,rdata_s_inf_buf[103: 97]};
                read_data[13] <= {1'b0,rdata_s_inf_buf[111:105]};
                read_data[14] <= {1'b0,rdata_s_inf_buf[119:113]};
                read_data[15] <= {1'b0,rdata_s_inf_buf[127:121]};
            end
            2'd2: begin
                read_data[ 0] <= rdata_s_inf_buf[  7:  0];
                read_data[ 1] <= rdata_s_inf_buf[ 15:  8];
                read_data[ 2] <= rdata_s_inf_buf[ 23: 16];
                read_data[ 3] <= rdata_s_inf_buf[ 31: 24];
                read_data[ 4] <= rdata_s_inf_buf[ 39: 32];
                read_data[ 5] <= rdata_s_inf_buf[ 47: 40];
                read_data[ 6] <= rdata_s_inf_buf[ 55: 48];
                read_data[ 7] <= rdata_s_inf_buf[ 63: 56];
                read_data[ 8] <= rdata_s_inf_buf[ 71: 64];
                read_data[ 9] <= rdata_s_inf_buf[ 79: 72];
                read_data[10] <= rdata_s_inf_buf[ 87: 80];
                read_data[11] <= rdata_s_inf_buf[ 95: 88];
                read_data[12] <= rdata_s_inf_buf[103: 96];
                read_data[13] <= rdata_s_inf_buf[111:104];
                read_data[14] <= rdata_s_inf_buf[119:112];
                read_data[15] <= rdata_s_inf_buf[127:120];
            end
            2'd3: begin
                read_data[ 0] <= rdata_s_inf_buf[  7]? 8'b11111111 : {rdata_s_inf_buf[  6:  0],1'b0};
                read_data[ 1] <= rdata_s_inf_buf[ 15]? 8'b11111111 : {rdata_s_inf_buf[ 14:  8],1'b0};
                read_data[ 2] <= rdata_s_inf_buf[ 23]? 8'b11111111 : {rdata_s_inf_buf[ 22: 16],1'b0};
                read_data[ 3] <= rdata_s_inf_buf[ 31]? 8'b11111111 : {rdata_s_inf_buf[ 30: 24],1'b0};
                read_data[ 4] <= rdata_s_inf_buf[ 39]? 8'b11111111 : {rdata_s_inf_buf[ 38: 32],1'b0};
                read_data[ 5] <= rdata_s_inf_buf[ 47]? 8'b11111111 : {rdata_s_inf_buf[ 46: 40],1'b0};
                read_data[ 6] <= rdata_s_inf_buf[ 55]? 8'b11111111 : {rdata_s_inf_buf[ 54: 48],1'b0};
                read_data[ 7] <= rdata_s_inf_buf[ 63]? 8'b11111111 : {rdata_s_inf_buf[ 62: 56],1'b0};
                read_data[ 8] <= rdata_s_inf_buf[ 71]? 8'b11111111 : {rdata_s_inf_buf[ 70: 64],1'b0};
                read_data[ 9] <= rdata_s_inf_buf[ 79]? 8'b11111111 : {rdata_s_inf_buf[ 78: 72],1'b0};
                read_data[10] <= rdata_s_inf_buf[ 87]? 8'b11111111 : {rdata_s_inf_buf[ 86: 80],1'b0};
                read_data[11] <= rdata_s_inf_buf[ 95]? 8'b11111111 : {rdata_s_inf_buf[ 94: 88],1'b0};
                read_data[12] <= rdata_s_inf_buf[103]? 8'b11111111 : {rdata_s_inf_buf[102: 96],1'b0};
                read_data[13] <= rdata_s_inf_buf[111]? 8'b11111111 : {rdata_s_inf_buf[110:104],1'b0};
                read_data[14] <= rdata_s_inf_buf[119]? 8'b11111111 : {rdata_s_inf_buf[118:112],1'b0};
                read_data[15] <= rdata_s_inf_buf[127]? 8'b11111111 : {rdata_s_inf_buf[126:120],1'b0};
            end
            default: /* Impossible */;
        endcase
    end

    always @(*) begin
        // Green
        if (cnt_d1[7:6] == 2'b1) begin
            for (int i = 0; i < 16; i = i + 1) begin
                read_data_weighted[i] = read_data[i] >> 1;
            end
        // Red Blue
        end else begin
            for (int i = 0; i < 16; i = i + 1) begin
                read_data_weighted[i] = read_data[i] >> 2;
            end
        end
    end
    
    // ---------------------------------------------------------------
    // A (Auto Focus)
    // ---------------------------------------------------------------
    always @(posedge clk) begin
        temp_A[0] <= read_data_weighted[13][6:0];
        temp_A[1] <= read_data_weighted[14][6:0];
        temp_A[2] <= read_data_weighted[15][6:0];
    end
    always @(posedge clk) begin
        if (cnt_d1[0] == 1) begin
            curr_row[0] <= temp_A[0];
            curr_row[1] <= temp_A[1];
            curr_row[2] <= temp_A[2];
            curr_row[3] <= read_data_weighted[0][6:0];
            curr_row[4] <= read_data_weighted[1][6:0];
            curr_row[5] <= read_data_weighted[2][6:0];
            last_row[0] <= curr_row[0];
            last_row[1] <= curr_row[1];
            last_row[2] <= curr_row[2];
            last_row[3] <= curr_row[3];
            last_row[4] <= curr_row[4];
            last_row[5] <= curr_row[5];
        end
    end

    always @(posedge clk) begin
        diff_hv_0 <= diff_hv_0_op0 + diff_hv_0_r;
        diff_hv_1 <= diff_hv_1_op0 + diff_hv_1_r;
        diff_hv_2 <= diff_hv_2_op0 + diff_hv_2_r;
        diff_hv_3 <= diff_hv_3_op0 + diff_hv_3_r;
        diff_hv_4 <= diff_hv_4_op0 + diff_hv_4_r;
        diff_hv_5 <= diff_hv_5_op0 + diff_hv_5_r;
    end

    always @(posedge clk) begin
        diff_hv_0_r <= diff_hv_0_op1 - diff_hv_0_op2;
        diff_hv_1_r <= diff_hv_1_op1 - diff_hv_1_op2;
        diff_hv_2_r <= diff_hv_2_op1 - diff_hv_2_op2;
        diff_hv_3_r <= diff_hv_3_op1 - diff_hv_3_op2;
        diff_hv_4_r <= diff_hv_4_op1 - diff_hv_4_op2;
        diff_hv_5_r <= diff_hv_5_op1 - diff_hv_5_op2;
    end

    always @(posedge clk) begin
        case (cnt_d1[5:0])
            'd29: begin
                diff_hv_0_op0 = diff_h[0][0];
                diff_hv_1_op0 = diff_h[0][1];
                diff_hv_2_op0 = diff_h[0][2];
                diff_hv_3_op0 = diff_h[0][3];
                diff_hv_4_op0 = diff_h[0][4];
                diff_hv_5_op0 = diff_v[0][5];
            end
            'd30: begin
                diff_hv_0_op0 = diff_v[0][0];
                diff_hv_1_op0 = diff_v[0][1];
                diff_hv_2_op0 = diff_v[0][2];
                diff_hv_3_op0 = diff_v[0][3];
                diff_hv_4_op0 = diff_v[0][4];
                diff_hv_5_op0 = diff_v[0][5];
            end
            'd31: begin
                diff_hv_0_op0 = diff_h[1][0];
                diff_hv_1_op0 = diff_h[1][1];
                diff_hv_2_op0 = diff_h[1][2];
                diff_hv_3_op0 = diff_h[1][3];
                diff_hv_4_op0 = diff_h[1][4];
                diff_hv_5_op0 = diff_v[1][5];
            end
            'd32: begin
                diff_hv_0_op0 = diff_v[1][0];
                diff_hv_1_op0 = diff_v[1][1];
                diff_hv_2_op0 = diff_v[1][2];
                diff_hv_3_op0 = diff_v[1][3];
                diff_hv_4_op0 = diff_v[1][4];
                diff_hv_5_op0 = diff_v[1][5];
            end
            'd33: begin
                diff_hv_0_op0 = diff_h[2][0];
                diff_hv_1_op0 = diff_h[2][1];
                diff_hv_2_op0 = diff_h[2][2];
                diff_hv_3_op0 = diff_h[2][3];
                diff_hv_4_op0 = diff_h[2][4];
                diff_hv_5_op0 = diff_v[2][5];
            end
            'd34: begin
                diff_hv_0_op0 = diff_v[2][0];
                diff_hv_1_op0 = diff_v[2][1];
                diff_hv_2_op0 = diff_v[2][2];
                diff_hv_3_op0 = diff_v[2][3];
                diff_hv_4_op0 = diff_v[2][4];
                diff_hv_5_op0 = diff_v[2][5];
            end
            'd35: begin
                diff_hv_0_op0 = diff_h[3][0];
                diff_hv_1_op0 = diff_h[3][1];
                diff_hv_2_op0 = diff_h[3][2];
                diff_hv_3_op0 = diff_h[3][3];
                diff_hv_4_op0 = diff_h[3][4];
                diff_hv_5_op0 = diff_v[3][5];
            end
            'd36: begin
                diff_hv_0_op0 = diff_v[3][0];
                diff_hv_1_op0 = diff_v[3][1];
                diff_hv_2_op0 = diff_v[3][2];
                diff_hv_3_op0 = diff_v[3][3];
                diff_hv_4_op0 = diff_v[3][4];
                diff_hv_5_op0 = diff_v[3][5];
            end
            'd37: begin
                diff_hv_0_op0 = diff_h[4][0];
                diff_hv_1_op0 = diff_h[4][1];
                diff_hv_2_op0 = diff_h[4][2];
                diff_hv_3_op0 = diff_h[4][3];
                diff_hv_4_op0 = diff_h[4][4];
                diff_hv_5_op0 = diff_v[4][5];
            end
            'd38: begin
                diff_hv_0_op0 = diff_v[4][0];
                diff_hv_1_op0 = diff_v[4][1];
                diff_hv_2_op0 = diff_v[4][2];
                diff_hv_3_op0 = diff_v[4][3];
                diff_hv_4_op0 = diff_v[4][4];
                diff_hv_5_op0 = diff_v[4][5];
            end
            'd39: begin
                diff_hv_0_op0 = diff_h[5][0];
                diff_hv_1_op0 = diff_h[5][1];
                diff_hv_2_op0 = diff_h[5][2];
                diff_hv_3_op0 = diff_h[5][3];
                diff_hv_4_op0 = diff_h[5][4];
                diff_hv_5_op0 = diff_v[4][5];
            end
            default: begin
                diff_hv_0_op0 = 'd0;
                diff_hv_1_op0 = 'd0;
                diff_hv_2_op0 = 'd0;
                diff_hv_3_op0 = 'd0;
                diff_hv_4_op0 = 'd0;
                diff_hv_5_op0 = 'd0;
            end
        endcase
    end
    
    always @(*) begin
        case (cnt_d1[5:0])
            'd29: begin
                diff_hv_0_op1 = curr_row[0];
                diff_hv_0_op2 = curr_row[1];
                diff_hv_1_op1 = curr_row[1];
                diff_hv_1_op2 = curr_row[2];
                diff_hv_2_op1 = curr_row[2];
                diff_hv_2_op2 = curr_row[3];
                diff_hv_3_op1 = curr_row[3];
                diff_hv_3_op2 = curr_row[4];
                diff_hv_4_op1 = curr_row[4];
                diff_hv_4_op2 = curr_row[5];
                diff_hv_5_op1 = curr_row[5];
                diff_hv_5_op2 = last_row[5];
            end
            'd30: begin
                diff_hv_0_op1 = curr_row[0];
                diff_hv_0_op2 = last_row[0];
                diff_hv_1_op1 = curr_row[1];
                diff_hv_1_op2 = last_row[1];
                diff_hv_2_op1 = curr_row[2];
                diff_hv_2_op2 = last_row[2];
                diff_hv_3_op1 = curr_row[3];
                diff_hv_3_op2 = last_row[3];
                diff_hv_4_op1 = curr_row[4];
                diff_hv_4_op2 = last_row[4];
                diff_hv_5_op1 = curr_row[5];
                diff_hv_5_op2 = last_row[5];
            end
            'd31: begin
                diff_hv_0_op1 = curr_row[0];
                diff_hv_0_op2 = curr_row[1];
                diff_hv_1_op1 = curr_row[1];
                diff_hv_1_op2 = curr_row[2];
                diff_hv_2_op1 = curr_row[2];
                diff_hv_2_op2 = curr_row[3];
                diff_hv_3_op1 = curr_row[3];
                diff_hv_3_op2 = curr_row[4];
                diff_hv_4_op1 = curr_row[4];
                diff_hv_4_op2 = curr_row[5];
                diff_hv_5_op1 = curr_row[5];
                diff_hv_5_op2 = last_row[5];
            end
            'd32: begin
                diff_hv_0_op1 = curr_row[0];
                diff_hv_0_op2 = last_row[0];
                diff_hv_1_op1 = curr_row[1];
                diff_hv_1_op2 = last_row[1];
                diff_hv_2_op1 = curr_row[2];
                diff_hv_2_op2 = last_row[2];
                diff_hv_3_op1 = curr_row[3];
                diff_hv_3_op2 = last_row[3];
                diff_hv_4_op1 = curr_row[4];
                diff_hv_4_op2 = last_row[4];
                diff_hv_5_op1 = curr_row[5];
                diff_hv_5_op2 = last_row[5];
            end
            'd33: begin
                diff_hv_0_op1 = curr_row[0];
                diff_hv_0_op2 = curr_row[1];
                diff_hv_1_op1 = curr_row[1];
                diff_hv_1_op2 = curr_row[2];
                diff_hv_2_op1 = curr_row[2];
                diff_hv_2_op2 = curr_row[3];
                diff_hv_3_op1 = curr_row[3];
                diff_hv_3_op2 = curr_row[4];
                diff_hv_4_op1 = curr_row[4];
                diff_hv_4_op2 = curr_row[5];
                diff_hv_5_op1 = curr_row[5];
                diff_hv_5_op2 = last_row[5];
            end
            'd34: begin
                diff_hv_0_op1 = curr_row[0];
                diff_hv_0_op2 = last_row[0];
                diff_hv_1_op1 = curr_row[1];
                diff_hv_1_op2 = last_row[1];
                diff_hv_2_op1 = curr_row[2];
                diff_hv_2_op2 = last_row[2];
                diff_hv_3_op1 = curr_row[3];
                diff_hv_3_op2 = last_row[3];
                diff_hv_4_op1 = curr_row[4];
                diff_hv_4_op2 = last_row[4];
                diff_hv_5_op1 = curr_row[5];
                diff_hv_5_op2 = last_row[5];
            end
            'd35: begin
                diff_hv_0_op1 = curr_row[0];
                diff_hv_0_op2 = curr_row[1];
                diff_hv_1_op1 = curr_row[1];
                diff_hv_1_op2 = curr_row[2];
                diff_hv_2_op1 = curr_row[2];
                diff_hv_2_op2 = curr_row[3];
                diff_hv_3_op1 = curr_row[3];
                diff_hv_3_op2 = curr_row[4];
                diff_hv_4_op1 = curr_row[4];
                diff_hv_4_op2 = curr_row[5];
                diff_hv_5_op1 = curr_row[5];
                diff_hv_5_op2 = last_row[5];
            end
            'd36: begin
                diff_hv_0_op1 = curr_row[0];
                diff_hv_0_op2 = last_row[0];
                diff_hv_1_op1 = curr_row[1];
                diff_hv_1_op2 = last_row[1];
                diff_hv_2_op1 = curr_row[2];
                diff_hv_2_op2 = last_row[2];
                diff_hv_3_op1 = curr_row[3];
                diff_hv_3_op2 = last_row[3];
                diff_hv_4_op1 = curr_row[4];
                diff_hv_4_op2 = last_row[4];
                diff_hv_5_op1 = curr_row[5];
                diff_hv_5_op2 = last_row[5];
            end
            'd37: begin
                diff_hv_0_op1 = curr_row[0];
                diff_hv_0_op2 = curr_row[1];
                diff_hv_1_op1 = curr_row[1];
                diff_hv_1_op2 = curr_row[2];
                diff_hv_2_op1 = curr_row[2];
                diff_hv_2_op2 = curr_row[3];
                diff_hv_3_op1 = curr_row[3];
                diff_hv_3_op2 = curr_row[4];
                diff_hv_4_op1 = curr_row[4];
                diff_hv_4_op2 = curr_row[5];
                diff_hv_5_op1 = curr_row[5];
                diff_hv_5_op2 = last_row[5];
            end
            'd38: begin
                diff_hv_0_op1 = curr_row[0];
                diff_hv_0_op2 = last_row[0];
                diff_hv_1_op1 = curr_row[1];
                diff_hv_1_op2 = last_row[1];
                diff_hv_2_op1 = curr_row[2];
                diff_hv_2_op2 = last_row[2];
                diff_hv_3_op1 = curr_row[3];
                diff_hv_3_op2 = last_row[3];
                diff_hv_4_op1 = curr_row[4];
                diff_hv_4_op2 = last_row[4];
                diff_hv_5_op1 = curr_row[5];
                diff_hv_5_op2 = last_row[5];
            end
            'd39: begin
                diff_hv_0_op1 = curr_row[0];
                diff_hv_0_op2 = curr_row[1];
                diff_hv_1_op1 = curr_row[1];
                diff_hv_1_op2 = curr_row[2];
                diff_hv_2_op1 = curr_row[2];
                diff_hv_2_op2 = curr_row[3];
                diff_hv_3_op1 = curr_row[3];
                diff_hv_3_op2 = curr_row[4];
                diff_hv_4_op1 = curr_row[4];
                diff_hv_4_op2 = curr_row[5];
                diff_hv_5_op1 = curr_row[5];
                diff_hv_5_op2 = last_row[5];
            end
            'd40: begin
                
                diff_hv_0_op1 = 'd0;
                diff_hv_0_op2 = 'd0;
                diff_hv_1_op1 = 'd0;
                diff_hv_1_op2 = 'd0;
                diff_hv_2_op1 = 'd0;
                diff_hv_2_op2 = 'd0;
                diff_hv_3_op1 = 'd0;
                diff_hv_3_op2 = 'd0;
                diff_hv_4_op1 = 'd0;
                diff_hv_4_op2 = 'd0;
                diff_hv_5_op1 = 'd0;
                diff_hv_5_op2 = 'd0;
            end
            default: begin
                diff_hv_0_op1 = 'd0;
                diff_hv_0_op2 = 'd0;
                diff_hv_1_op1 = 'd0;
                diff_hv_1_op2 = 'd0;
                diff_hv_2_op1 = 'd0;
                diff_hv_2_op2 = 'd0;
                diff_hv_3_op1 = 'd0;
                diff_hv_3_op2 = 'd0;
                diff_hv_4_op1 = 'd0;
                diff_hv_4_op2 = 'd0;
                diff_hv_5_op1 = 'd0;
                diff_hv_5_op2 = 'd0;
            end
        endcase
    end
    
    always @(posedge clk) begin
        if (cs == STATE_IDLE) begin
            for (i = 0; i < 6; i = i + 1) begin
                for (j = 0; j < 5; j = j + 1) begin
                    diff_h[i][j] <= 'd0;
                end
            end
            for (i = 0; i < 5; i = i + 1) begin
                for (j = 0; j < 6; j = j + 1) begin
                    diff_v[i][j] <= 'd0;
                end
            end
        end else begin
            if (rready_d[1]) begin
                case (cnt_d1[5:0])
                    'd31: begin
                        diff_h[0][0] <= diff_hv_0;
                        diff_h[0][1] <= diff_hv_1;
                        diff_h[0][2] <= diff_hv_2;
                        diff_h[0][3] <= diff_hv_3;
                        diff_h[0][4] <= diff_hv_4;
                    end
                    'd32: begin
                        diff_v[0][0] <= diff_hv_0;
                        diff_v[0][1] <= diff_hv_1;
                        diff_v[0][2] <= diff_hv_2;
                        diff_v[0][3] <= diff_hv_3;
                        diff_v[0][4] <= diff_hv_4;
                        diff_v[0][5] <= diff_hv_5;
                    end
                    'd33: begin
                        diff_h[1][0] <= diff_hv_0;
                        diff_h[1][1] <= diff_hv_1;
                        diff_h[1][2] <= diff_hv_2;
                        diff_h[1][3] <= diff_hv_3;
                        diff_h[1][4] <= diff_hv_4;
                    end
                    'd34: begin
                        diff_v[1][0] <= diff_hv_0;
                        diff_v[1][1] <= diff_hv_1;
                        diff_v[1][2] <= diff_hv_2;
                        diff_v[1][3] <= diff_hv_3;
                        diff_v[1][4] <= diff_hv_4;
                        diff_v[1][5] <= diff_hv_5;
                    end
                    'd35: begin
                        diff_h[2][0] <= diff_hv_0;
                        diff_h[2][1] <= diff_hv_1;
                        diff_h[2][2] <= diff_hv_2;
                        diff_h[2][3] <= diff_hv_3;
                        diff_h[2][4] <= diff_hv_4;
                    end
                    'd36: begin
                        diff_v[2][0] <= diff_hv_0;
                        diff_v[2][1] <= diff_hv_1;
                        diff_v[2][2] <= diff_hv_2;
                        diff_v[2][3] <= diff_hv_3;
                        diff_v[2][4] <= diff_hv_4;
                        diff_v[2][5] <= diff_hv_5;
                    end
                    'd37: begin
                        diff_h[3][0] <= diff_hv_0;
                        diff_h[3][1] <= diff_hv_1;
                        diff_h[3][2] <= diff_hv_2;
                        diff_h[3][3] <= diff_hv_3;
                        diff_h[3][4] <= diff_hv_4;
                    end
                    'd38: begin
                        diff_v[3][0] <= diff_hv_0;
                        diff_v[3][1] <= diff_hv_1;
                        diff_v[3][2] <= diff_hv_2;
                        diff_v[3][3] <= diff_hv_3;
                        diff_v[3][4] <= diff_hv_4;
                        diff_v[3][5] <= diff_hv_5;
                    end
                    'd39: begin
                        diff_h[4][0] <= diff_hv_0;
                        diff_h[4][1] <= diff_hv_1;
                        diff_h[4][2] <= diff_hv_2;
                        diff_h[4][3] <= diff_hv_3;
                        diff_h[4][4] <= diff_hv_4;
                    end
                    'd40: begin
                        diff_v[4][0] <= diff_hv_0;
                        diff_v[4][1] <= diff_hv_1;
                        diff_v[4][2] <= diff_hv_2;
                        diff_v[4][3] <= diff_hv_3;
                        diff_v[4][4] <= diff_hv_4;
                        diff_v[4][5] <= diff_hv_5;
                    end
                    'd41: begin
                        diff_h[5][0] <= diff_hv_0;
                        diff_h[5][1] <= diff_hv_1;
                        diff_h[5][2] <= diff_hv_2;
                        diff_h[5][3] <= diff_hv_3;
                        diff_h[5][4] <= diff_hv_4;
                    end
                    default:begin
                        // Do nothing 
                    end
                endcase
            end
        end
    end
    
    function [7:0] abs;
        input [8:0] a;
        begin
            if (a[8] == 1'b1) begin
                abs = ~a[7:0] + 1;
            end else begin
                abs = a[7:0];
            end
        end
    endfunction

    always @(*) begin
        diff_sum_2_n = diff_sum_2[13:0] + diff_sum_2_op0123;
    end

    always @(posedge clk) begin
        diff_sum_2_op0_abs <= abs(diff_sum_2_op0);
        diff_sum_2_op1_abs <= abs(diff_sum_2_op1);
        diff_sum_2_op2_abs <= abs(diff_sum_2_op2);
        diff_sum_2_op3_abs <= abs(diff_sum_2_op3);

        diff_sum_2_op01 <= diff_sum_2_op0_abs + diff_sum_2_op1_abs;
        diff_sum_2_op23 <= diff_sum_2_op2_abs + diff_sum_2_op3_abs;

        diff_sum_2_op0123 <= diff_sum_2_op01 + diff_sum_2_op23;
    end

    always @(*) begin
        case (cnt_d1[5:0])
            'd42: begin
                diff_sum_2_op0 = diff_h[2][2];
                diff_sum_2_op1 = diff_h[3][2];
                diff_sum_2_op2 = diff_v[2][2];
                diff_sum_2_op3 = diff_v[2][3];
            end
            'd43: begin
                diff_sum_2_op0 = diff_v[1][1];
                diff_sum_2_op1 = diff_v[1][2];
                diff_sum_2_op2 = diff_v[1][3];
                diff_sum_2_op3 = diff_v[1][4];
            end
            'd44: begin
                diff_sum_2_op0 = diff_v[3][1];
                diff_sum_2_op1 = diff_v[3][2];
                diff_sum_2_op2 = diff_v[3][3];
                diff_sum_2_op3 = diff_v[3][4];
            end
            'd45: begin
                diff_sum_2_op0 = diff_h[1][1];
                diff_sum_2_op1 = diff_h[2][1];
                diff_sum_2_op2 = diff_h[3][1];
                diff_sum_2_op3 = diff_h[4][1];
            end
            'd46: begin
                diff_sum_2_op0 = diff_h[1][3];
                diff_sum_2_op1 = diff_h[2][3];
                diff_sum_2_op2 = diff_h[3][3];
                diff_sum_2_op3 = diff_h[4][3];
            end
            'd47: begin
                diff_sum_2_op0 = diff_h[1][2];
                diff_sum_2_op1 = diff_h[4][2];
                diff_sum_2_op2 = diff_v[2][1];
                diff_sum_2_op3 = diff_v[2][4];
            end
            'd48: begin
                diff_sum_2_op0 = diff_h[0][0];
                diff_sum_2_op1 = diff_h[0][1];
                diff_sum_2_op2 = diff_h[0][2];
                diff_sum_2_op3 = diff_h[0][3];
            end
            'd49: begin
                diff_sum_2_op0 = diff_h[5][0];
                diff_sum_2_op1 = diff_h[5][1];
                diff_sum_2_op2 = diff_h[5][2];
                diff_sum_2_op3 = diff_h[5][3];
            end
            'd50: begin
                diff_sum_2_op0 = diff_h[1][0];
                diff_sum_2_op1 = diff_h[2][0];
                diff_sum_2_op2 = diff_h[3][0];
                diff_sum_2_op3 = diff_h[4][0];
            end
            'd51: begin
                diff_sum_2_op0 = diff_h[1][4];
                diff_sum_2_op1 = diff_h[2][4];
                diff_sum_2_op2 = diff_h[3][4];
                diff_sum_2_op3 = diff_h[4][4];
            end
            'd52: begin
                diff_sum_2_op0 = diff_v[0][0];
                diff_sum_2_op1 = diff_v[1][0];
                diff_sum_2_op2 = diff_v[2][0];
                diff_sum_2_op3 = diff_v[3][0];
            end
            'd53: begin
                diff_sum_2_op0 = diff_v[0][5];
                diff_sum_2_op1 = diff_v[1][5];
                diff_sum_2_op2 = diff_v[2][5];
                diff_sum_2_op3 = diff_v[3][5];
            end
            'd54: begin
                diff_sum_2_op0 = diff_v[0][1];
                diff_sum_2_op1 = diff_v[0][2];
                diff_sum_2_op2 = diff_v[0][3];
                diff_sum_2_op3 = diff_v[0][4];
            end
            'd55: begin
                diff_sum_2_op0 = diff_v[4][1];
                diff_sum_2_op1 = diff_v[4][2];
                diff_sum_2_op2 = diff_v[4][3];
                diff_sum_2_op3 = diff_v[4][4];
            end
            'd56: begin
                diff_sum_2_op0 = diff_h[0][4];
                diff_sum_2_op1 = diff_h[5][4];
                diff_sum_2_op2 = diff_v[4][0];
                diff_sum_2_op3 = diff_v[4][5];
            end
            default: begin
                diff_sum_2_op0 = 'd0;
                diff_sum_2_op1 = 'd0;
                diff_sum_2_op2 = 'd0;
                diff_sum_2_op3 = 'd0;
            end
        endcase
    end

    always @(posedge clk) begin
        if (cs == STATE_IDLE) begin
            diff_sum_2 <= 'd0;
            diff_sum_1 <= 'd0;
            diff_sum_0 <= 'd0;
        end else begin
            if (cnt_d1[7:6] == 2'b10) case (cnt_d1[5:0])
                'd45: begin
                    diff_sum_2 <= diff_sum_2_n;
                end
                'd46: begin
                    diff_sum_2 <= diff_sum_2_n;
                    diff_sum_0 <= diff_sum_2[9:2];
                end
                'd47: begin
                    diff_sum_2 <= diff_sum_2_n;
                end
                'd48: begin
                    diff_sum_2 <= diff_sum_2_n;
                end
                'd49: begin
                    diff_sum_2 <= diff_sum_2_n;
                end
                'd50: begin
                    diff_sum_2 <= diff_sum_2_n;
                end
                'd51: begin
                    diff_sum_2 <= diff_sum_2_n;
                    diff_sum_1 <= diff_sum_2[12:4];
                end
                'd52: begin
                    diff_sum_2 <= diff_sum_2_n;
                end
                'd53: begin
                    diff_sum_2 <= diff_sum_2_n;
                end
                'd54: begin
                    diff_sum_2 <= diff_sum_2_n;
                end
                'd55: begin
                    diff_sum_2 <= diff_sum_2_n;
                end
                'd56: begin
                    diff_sum_2 <= diff_sum_2_n;
                end
                'd57: begin
                    diff_sum_2 <= diff_sum_2_n;
                end
                'd58: begin
                    diff_sum_2 <= diff_sum_2_n;
                end
                'd59: begin
                    diff_sum_2 <= diff_sum_2_n;
                end
                // 'd60: begin
                //     diff_sum_2 <= diff_sum_2 >> 2;
                // end
                // 'd61: begin
                //     diff_sum_2 <= diff_sum_2 / 9;
                // end
                default: /* Do Nothing */;
            endcase
        end
    end

    always @(posedge clk) begin
        if (cnt_d1[7:0] == {2'b10, 6'd59}) begin
            diff_sum_2_dnt <= {1'b0, diff_sum_2_n[13:2]};
        end else begin
            diff_sum_2_dnt <= diff_sum_2_div9_sub;
        end
    end

    always @(*) begin
        diff_sum_2_head = diff_sum_2_dnt[12:8] - 4'd9;
    end
    
    always @(*) begin
        diff_sum_2_div9_sub <= diff_sum_2_head[4] ? diff_sum_2_dnt << 1 : {diff_sum_2_head[3:0], diff_sum_2_dnt[7:0], 1'b0};
    end

    always @(posedge clk) begin
        diff_sum_2_div9 <= {diff_sum_2_div9[7:0], ~diff_sum_2_head[4]};
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            for (int i = 0; i < 16; i = i + 1) begin
                A_pre_calculated[i] <= 2'd0;
            end
        end else begin
            // if (cnt_d1[7:6] == 2'b10) if (cnt_d1[5:0] == 6'd69) begin
            if (cnt[7:0] == 'd198) begin
                if (diff_sum_0[7:0] >= diff_sum_1[8:0] &&
                    diff_sum_0[7:0] >= diff_sum_2_div9[8:0])
                    A_pre_calculated[pic_no] <= 2'd0;
                else if (diff_sum_1[8:0] >= diff_sum_2_div9[8:0])
                    A_pre_calculated[pic_no] <= 2'd1;
                else
                    A_pre_calculated[pic_no] <= 2'd2;
            end
        end
    end

    // ---------------------------------------------------------------
    // B (Auto Exposure)
    // ---------------------------------------------------------------
    always @(posedge clk) begin
        read_sum_s0[0] <= read_data_weighted[ 0][6:0] + read_data_weighted[ 1][6:0];
        read_sum_s0[1] <= read_data_weighted[ 2][6:0] + read_data_weighted[ 3][6:0];
        read_sum_s0[2] <= read_data_weighted[ 4][6:0] + read_data_weighted[ 5][6:0];
        read_sum_s0[3] <= read_data_weighted[ 6][6:0] + read_data_weighted[ 7][6:0];
        read_sum_s0[4] <= read_data_weighted[ 8][6:0] + read_data_weighted[ 9][6:0];
        read_sum_s0[5] <= read_data_weighted[10][6:0] + read_data_weighted[11][6:0];
        read_sum_s0[6] <= read_data_weighted[12][6:0] + read_data_weighted[13][6:0];
        read_sum_s0[7] <= read_data_weighted[14][6:0] + read_data_weighted[15][6:0];

        read_sum_s1[0] <= read_sum_s0[0] + read_sum_s0[1];
        read_sum_s1[1] <= read_sum_s0[2] + read_sum_s0[3];
        read_sum_s1[2] <= read_sum_s0[4] + read_sum_s0[5];
        read_sum_s1[3] <= read_sum_s0[6] + read_sum_s0[7];

        read_sum_s2[0] <= read_sum_s1[0] + read_sum_s1[1];
        read_sum_s2[1] <= read_sum_s1[2] + read_sum_s1[3];

        read_sum       <= read_sum_s2[0] + read_sum_s2[1];
    end

    always @(posedge clk) begin
        if (cs == STATE_IDLE) begin
            sum <= 18'd0;
        end else begin
            if (rready_d[6]) begin
                sum <= sum + read_sum;
            end else begin
                // Stablized at cnt: 197
                sum <= sum;
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            for (int i = 0; i < 16; i = i + 1) begin
                B_pre_calculated[i] <= 8'd0;
            end
        end else begin
            if (cnt == 'd197) begin
                B_pre_calculated[pic_no] <= sum[17:10];
            end
        end
    end

    // ---------------------------------------------------------------
    // C (Avg Min Max)
    // ---------------------------------------------------------------
    always @(posedge clk) begin
        {max_s0[0], min_s0[0]} <= read_data[ 0] >= read_data[ 1] ? {read_data[ 0], read_data[ 1]} : {read_data[ 1], read_data[ 0]};
        {max_s0[1], min_s0[1]} <= read_data[ 2] >= read_data[ 3] ? {read_data[ 2], read_data[ 3]} : {read_data[ 3], read_data[ 2]};
        {max_s0[2], min_s0[2]} <= read_data[ 4] >= read_data[ 5] ? {read_data[ 4], read_data[ 5]} : {read_data[ 5], read_data[ 4]};
        {max_s0[3], min_s0[3]} <= read_data[ 6] >= read_data[ 7] ? {read_data[ 6], read_data[ 7]} : {read_data[ 7], read_data[ 6]};
        {max_s0[4], min_s0[4]} <= read_data[ 8] >= read_data[ 9] ? {read_data[ 8], read_data[ 9]} : {read_data[ 9], read_data[ 8]};
        {max_s0[5], min_s0[5]} <= read_data[10] >= read_data[11] ? {read_data[10], read_data[11]} : {read_data[11], read_data[10]};
        {max_s0[6], min_s0[6]} <= read_data[12] >= read_data[13] ? {read_data[12], read_data[13]} : {read_data[13], read_data[12]};
        {max_s0[7], min_s0[7]} <= read_data[14] >= read_data[15] ? {read_data[14], read_data[15]} : {read_data[15], read_data[14]};
    end
    
    always @(posedge clk) begin
        max_s1[0] <= max_s0[0] >= max_s0[1] ? max_s0[0] : max_s0[1];
        max_s1[1] <= max_s0[2] >= max_s0[3] ? max_s0[2] : max_s0[3];
        max_s1[2] <= max_s0[4] >= max_s0[5] ? max_s0[4] : max_s0[5];
        max_s1[3] <= max_s0[6] >= max_s0[7] ? max_s0[6] : max_s0[7];

        min_s1[0] <= min_s0[0] <= min_s0[1] ? min_s0[0] : min_s0[1];
        min_s1[1] <= min_s0[2] <= min_s0[3] ? min_s0[2] : min_s0[3];
        min_s1[2] <= min_s0[4] <= min_s0[5] ? min_s0[4] : min_s0[5];
        min_s1[3] <= min_s0[6] <= min_s0[7] ? min_s0[6] : min_s0[7];

        max_s2[0] <= max_s1[0] >= max_s1[1] ? max_s1[0] : max_s1[1];
        max_s2[1] <= max_s1[2] >= max_s1[3] ? max_s1[2] : max_s1[3];

        min_s2[0] <= min_s1[0] <= min_s1[1] ? min_s1[0] : min_s1[1];
        min_s2[1] <= min_s1[2] <= min_s1[3] ? min_s1[2] : min_s1[3];

        max_s3    <= max_s2[0] >= max_s2[1] ? max_s2[0] : max_s2[1];
        min_s3    <= min_s2[0] <= min_s2[1] ? min_s2[0] : min_s2[1];
    end
    
    always @(posedge clk) begin
        if (cs == STATE_IDLE) begin
            max_r <= 8'd0;
            min_r <= 8'd255;
        end else begin
            if (rready_d[5] && cnt_d5[7:6] == 2'b00) begin
                max_r <= max_s3 >= max_r ? max_s3 : max_r;
                min_r <= min_s3 <= min_r ? min_s3 : min_r;
            end
        end
    end

    always @(posedge clk) begin
        if (cs == STATE_IDLE) begin
            max_g <= 8'd0;
            min_g <= 8'd255;
        end else begin
            if (rready_d[5] && cnt_d5[7:6] == 2'b01) begin
                max_g <= max_s3 >= max_g ? max_s3 : max_g;
                min_g <= min_s3 <= min_g ? min_s3 : min_g;
            end
        end
    end

    always @(posedge clk) begin
        if (cs == STATE_IDLE) begin
            max_b <= 8'd0;
            min_b <= 8'd255;
        end else begin
            if (rready_d[5] && cnt_d5[7:6] == 2'b10) begin
                max_b <= max_s3 >= max_b ? max_s3 : max_b;
                min_b <= min_s3 <= min_b ? min_s3 : min_b;
            end
        end
    end

    always @(*) begin
        if (cnt_d5[0] == 1'b0) begin
            max_sum_op0 = max_r;
            max_sum_op1 = max_g;
            min_sum_op0 = min_r;
            min_sum_op1 = min_g;
        end else begin
            max_sum_op0 = max_sum;
            max_sum_op1 = max_b;
            min_sum_op0 = min_sum;
            min_sum_op1 = min_b;
        end
    end

    always @(posedge clk) begin
        if (&cnt_d5[7:6] && (|cnt_d5[5:1])) begin
            max_sum <= max_sum_div3_sub;
            min_sum <= min_sum_div3_sub;
        end else begin
            max_sum <= max_sum_op0 + max_sum_op1;
            min_sum <= min_sum_op0 + min_sum_op1;
        end
    end
    
    always @(*) begin
        max_sum_head = max_sum[9:7] - 2'b11;
        min_sum_head = min_sum[9:7] - 2'b11;
    end
    
    always @(*) begin
        max_sum_div3_sub = max_sum_head[2] ? max_sum << 1 : {max_sum_head[1:0], max_sum[6:0], 1'b0};
        min_sum_div3_sub = min_sum_head[2] ? min_sum << 1 : {min_sum_head[1:0], min_sum[6:0], 1'b0};
    end

    always @(posedge clk) begin
        max_avg <= {max_avg[6:0], ~max_sum_head[2]};
        min_avg <= {min_avg[6:0], ~min_sum_head[2]};
    end

    assign sum_max_min = max_avg + min_avg;
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            for (int i = 0; i < 16; i = i + 1) begin
                C_pre_calculated[i] <= 8'd0;
            end
        end else begin
            if (cnt_d5 == 'd202) begin
                C_pre_calculated[pic_no] <= sum_max_min[8:1];
            end
        end
    end

    // ---------------------------------------------------------------
    // Counters
    // ---------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            cnt <= 8'd0;
        end else begin
            cnt <= cnt_n;
        end
    end

    always @(*) begin
        if (cs == STATE_IDLE) begin
            cnt_n = 8'd0;
        end else
        if (rready_d[1] || cnt[7]) begin
            cnt_n = cnt + 1;
        end else begin
            cnt_n = cnt;
        end
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            cnt_d1 <= 8'd0;
            cnt_d5 <= 8'd0;
        end else begin
            cnt_d1 <= cnt;
            cnt_d5 <= {cnt[7:2] - 6'd1, cnt[1:0]}; // cnt_d5 = cnt_d1 - 4
        end
    end

    // ---------------------------------------------------------------
    // Output
    // ---------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out_valid <= 1'b0;
        end else begin
            out_valid <= cs == STATE_OUPT;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out_data <= 8'd0;
        end else begin
            if (shift_cnt[pic_no][3] | cs != STATE_OUPT) begin
                out_data <= 8'd0;
            end else begin
                case (mode)
                    MODE_AUTO_FOCUS: out_data <= A_pre_calculated[pic_no];
                    MODE_AUTO_EXPOSURE: out_data <= B_pre_calculated[pic_no];
                    MODE_AVG_MIN_MAX: out_data <= C_pre_calculated[pic_no];
                    default: out_data <= 8'd0;
                endcase    
            end
        end
    end

endmodule
