module Program(input clk, INF.Program_inf inf); // @suppress
    import usertype::*;

    //==============================================//
    //       Parameter & Integer Declaration        //
    //==============================================//
    localparam [3:0] STATE_IDLE = 4'd0;
    localparam [3:0] STATE_CAL0 = 4'd1;     // Calculate
    localparam [3:0] STATE_CAL1 = 4'd2;     // Calculate
    localparam [3:0] STATE_CAL2 = 4'd3;     // Calculate
    localparam [3:0] STATE_CAL3 = 4'd4;     // Calculate
    localparam [3:0] STATE_CAL4 = 4'd5;     // Calculate
    localparam [3:0] STATE_CAL5 = 4'd6;     // Calculate
    localparam [3:0] STATE_CAL6 = 4'd7;     // Calculate
    localparam [3:0] STATE_CAL7 = 4'd8;     // Calculate
    localparam [3:0] STATE_UPDT = 4'd9;     // Update
    localparam [3:0] STATE_UPD2 = 4'd10;     // Update
    localparam [3:0] STATE_OUPT = 4'd11;    // Output

    localparam [3:0] DR_STATE_IDLE = 4'd0;
    localparam [3:0] DR_STATE_ARHS = 4'd1;  // Address Read Handshake
    localparam [3:0] DR_STATE_DRHS = 4'd2;  // Data Read Handshake

    localparam [3:0] DW_STATE_IDLE = 4'd0;
    localparam [3:0] DW_STATE_AWHS = 4'd1;  // Address Write Handshake
    localparam [3:0] DW_STATE_WAIT = 4'd2;  // Wait for data calculation
    localparam [3:0] DW_STATE_DWHS = 4'd3;  // Data Write Handshake
    localparam [3:0] DW_STATE_RESP = 4'd4;  // Data Write Response

    //==============================================//
    //           Reg & Wire Declaration             //
    //==============================================//
    logic [ 3:0] cs, ns;
    logic [ 3:0] dram_read_cs, dram_read_ns;
    logic [ 3:0] dram_writ_cs, dram_writ_ns;
    logic        got_data;
    logic        resetted;

    logic [ 1:0] action;
    logic [ 2:0] formula;
    logic [ 1:0] mode;
    logic [ 3:0] month;
    logic [ 4:0] day;
    logic [ 7:0] data_no;
    logic [11:0] index [3:0];

    logic [ 2:0] index_cnt;

    logic [11:0] dram_index [3:0];
    logic [ 3:0] dram_month;
    logic [ 4:0] dram_day;

    logic [12:0] dram_add12, dram_add03;
    logic [13:0] dram_add;

    logic [11:0] L1_0, L1_1, L1_2, L1_3;
    logic [11:0] L2_0, L2_1, L2_2, L2_3;
    logic [ 3:0] dram_lgeq;   // Dram equal or larger than index
    logic [ 3:0] dram_2047;   // Dram equal or larger than 2047

    logic [11:0] diff_index [3:0];  // Difference between dram_index and index
    logic [11:0] diff_op0   [3:0];
    logic [11:0] diff_op1   [3:0];

    logic [ 3:0] one_cnter_src;  // One counter source
    logic [11:0] dram_max_min_diff; // Difference between dram_max and dram_min
    logic [13:0] R;
    logic        R14;
    logic        R_Q;
    logic [ 1:0] R_mn3;
    logic [13:0] R_temp;
    logic [ 3:0] div_cnt;

    logic [13:0] update_index [3:0];
    logic [11:0] update_index_sat [3:0];

    logic R_2047, R_1023, R_511, R_800, R_400, R_200, R_3, R_2, R_1;
    logic date_warn, risk_warn, data_warn;

    //==============================================//
    //                   Design                     //
    //==============================================//
    always_ff @(posedge clk or negedge inf.rst_n) begin
        if (~inf.rst_n) begin
            cs <= STATE_IDLE;
        end else begin
            cs <= ns;
        end
    end

    always_comb begin
        case (cs)
            STATE_IDLE: begin
                if ((inf.R_VALID || got_data) && (((&index_cnt[1:0]) && inf.index_valid) || index_cnt[2])) begin
                    case (action)
                        Index_Check: begin
                            ns = STATE_CAL0;
                        end
                        Update: begin
                            ns = STATE_UPDT;
                        end
                        Check_Valid_Date: begin
                            ns = STATE_CAL7;
                        end
                        default: begin
                            ns = STATE_IDLE;
                        end
                    endcase
                end else begin
                    ns = STATE_IDLE;
                end
            end
            STATE_CAL0: begin
                if (dram_month > month || (dram_month == month && dram_day > day)) ns = STATE_CAL7;
                else ns = STATE_CAL1;
            end
            STATE_CAL1: begin
                case (formula)
                    Formula_D,
                    Formula_E,
                    Formula_A: begin
                        ns = STATE_CAL7;
                    end
                    default: begin
                        ns = STATE_CAL2;
                    end
                endcase
            end
            STATE_CAL2: begin
                case (formula)
                    Formula_B,
                    Formula_C: begin
                        ns = STATE_CAL7;
                    end
                    default: begin
                        ns = STATE_CAL3;
                    end
                endcase
            end
            STATE_CAL3: begin
                case (formula)
                    Formula_H: begin
                        ns = STATE_CAL7;
                    end
                    default: begin
                        ns = STATE_CAL4;
                    end
                endcase
            end
            STATE_CAL4: begin
                ns = STATE_CAL5;
            end
            STATE_CAL5: begin
                case (formula)
                    Formula_G: begin
                        ns = STATE_CAL7;
                    end
                    default: begin
                        ns = STATE_CAL6;
                    end
                endcase
            end
            STATE_CAL6: begin
                ns = div_cnt == 'd12 ? STATE_CAL7 : STATE_CAL6;
            end
            STATE_CAL7: begin
                ns = STATE_OUPT;
            end
            STATE_UPDT: begin
                ns = inf.B_VALID ? STATE_OUPT : STATE_UPDT;
            end
            STATE_OUPT: begin
                // TODO wait for write response
                ns = STATE_IDLE;
            end
            default: begin
                ns = STATE_IDLE;
            end
        endcase
    end

    always_ff @(posedge clk or negedge inf.rst_n) begin
        if (~inf.rst_n) begin
            dram_read_cs <= STATE_IDLE;
        end else begin
            dram_read_cs <= dram_read_ns;
        end
    end

    always_comb begin
        case (dram_read_cs)
            DR_STATE_IDLE: begin
                dram_read_ns = inf.data_no_valid ? DR_STATE_ARHS : DR_STATE_IDLE;
            end
            DR_STATE_ARHS: begin
                dram_read_ns = inf.AR_READY ? DR_STATE_DRHS : DR_STATE_ARHS;
            end
            DR_STATE_DRHS: begin
                dram_read_ns = inf.R_VALID ? DR_STATE_IDLE : DR_STATE_DRHS;
            end
            default: begin
                dram_read_ns = DR_STATE_IDLE;
            end
        endcase
    end

    // always_comb begin
    //     inf.AR_ADDR = {17{resetted}}&{1'b1, 5'b0, data_no, 3'b0};
    // end
    always_ff @(posedge clk or negedge inf.rst_n) begin
        if (~inf.rst_n) begin
            inf.AR_ADDR <= 17'b0;
        end else begin
            inf.AR_ADDR <= {1'b1, 5'b0, data_no, 3'b0};
        end
    end

    always_comb begin
        inf.AR_VALID = dram_read_cs == DR_STATE_ARHS;
    end
    
    always_comb begin
        inf.R_READY = dram_read_cs == DR_STATE_DRHS;
    end

    always_ff @(posedge clk or negedge inf.rst_n) begin
        if (~inf.rst_n) begin
            got_data <= 1'b0;
        end else begin
            if (inf.R_VALID) begin
                got_data <= 1'b1;
            end else
            if (cs != STATE_IDLE) begin
                got_data <= 1'b0;
            end else begin
                got_data <= got_data;
            end
        end
    end

    always_ff @(posedge clk or negedge inf.rst_n) begin
        if (~inf.rst_n) begin
            dram_writ_cs <= STATE_IDLE;
        end else begin
            dram_writ_cs <= dram_writ_ns;
        end
    end

    always_comb begin
        case (dram_writ_cs)
            DW_STATE_IDLE: begin
                dram_writ_ns = (inf.data_no_valid && action == Update) ? DW_STATE_AWHS : DW_STATE_IDLE;
            end
            DW_STATE_AWHS: begin
                dram_writ_ns = inf.AW_READY ? DW_STATE_WAIT : DW_STATE_AWHS;
            end
            DW_STATE_WAIT: begin
                dram_writ_ns = cs == STATE_UPDT ? DW_STATE_DWHS : DW_STATE_WAIT;
            end
            DW_STATE_DWHS: begin
                dram_writ_ns = inf.W_READY ? DW_STATE_RESP : DW_STATE_DWHS;
            end
            DW_STATE_RESP: begin
                dram_writ_ns = inf.B_VALID ? DW_STATE_IDLE : DW_STATE_RESP;
            end
            default: begin
                dram_writ_ns = DW_STATE_IDLE;
            end
        endcase
    end

    always_ff @(posedge clk or negedge inf.rst_n) begin
        if (~inf.rst_n) begin
            resetted <= 1'b0;
        end else begin
            resetted <= 1'b1;
        end
    end

    // always_comb begin
    //     inf.AW_ADDR = {17{resetted}}&{1'b1, 5'b0, data_no, 3'b0};
    // end
    always_ff @(posedge clk or negedge inf.rst_n) begin
        if (~inf.rst_n) begin
            inf.AW_ADDR <= 17'b0;
        end else begin
            inf.AW_ADDR <= {1'b1, 5'b0, data_no, 3'b0};
        end
    end

    always_comb begin
        inf.AW_VALID = dram_writ_cs == DW_STATE_AWHS;
    end

    always_comb begin
        inf.W_VALID = dram_writ_cs == DW_STATE_DWHS;
    end

    // always_comb begin
    //     inf.W_DATA = {64{resetted}}&{update_index_sat[0], update_index_sat[1], 4'd0, month, update_index_sat[2], update_index_sat[3], 3'd0, day};
    // end
    always_ff @(posedge clk or negedge inf.rst_n) begin
        if (~inf.rst_n) begin
            inf.W_DATA <= 64'b0;
        end else begin
            inf.W_DATA <= {update_index_sat[0], update_index_sat[1], 4'd0, month, update_index_sat[2], update_index_sat[3], 3'd0, day};
        end
    end
    

    always_ff @(posedge clk or negedge inf.rst_n) begin
        if (~inf.rst_n) begin
            inf.B_READY <= 1'b0;
        end else begin
            inf.B_READY <= 1'b1;
        end
    end

    always_ff @(posedge clk) begin
        if (inf.sel_action_valid) begin
            action <= inf.D.d_act[0];
        end
        if (inf.formula_valid) begin
            formula <= inf.D.d_formula[0];
        end
        if (inf.mode_valid) begin
            mode <= inf.D.d_mode[0];
        end
        if (inf.date_valid) begin
            month <= inf.D.d_date[0].M;
            day <= inf.D.d_date[0].D;
        end
        if (inf.index_valid) begin
            index[index_cnt[1:0]] <= inf.D.d_index[0];
        end
        if (inf.R_VALID) begin
            dram_month    <= inf.R_DATA[35:32];
            dram_day      <= inf.R_DATA[ 4: 0];
        end
    end

    always_ff @(posedge clk or negedge inf.rst_n) begin
        if (~inf.rst_n) begin
            data_no <= 'd0;
        end else begin
            if (inf.data_no_valid) begin
                data_no <= inf.D.d_data_no[0];
            end
        end
    end
    
    always_ff @(posedge clk or negedge inf.rst_n) begin
        if (~inf.rst_n) begin
            index_cnt <= 'd0;
        end else begin
            if (inf.data_no_valid) begin
                index_cnt <= 'd0;
            end else 
            if (action == Check_Valid_Date) begin
                index_cnt <= 'd4;
            end else 
            if (inf.index_valid) begin
                index_cnt <= index_cnt + 1;
            end else begin
                index_cnt <= index_cnt;
            end
        end
    end

    always_ff @(posedge clk) begin
        if (dram_month > month || (dram_month == month && dram_day > day)) begin
            date_warn = 1'b1;
        end else begin
            date_warn = 1'b0;
        end
    end

    always_ff @(posedge clk) begin
        case (cs)
            STATE_IDLE: begin
                if (inf.R_VALID) begin
                    dram_index[0] <= inf.R_DATA[63:52];
                    dram_index[1] <= inf.R_DATA[51:40];
                    dram_index[2] <= inf.R_DATA[31:20];
                    dram_index[3] <= inf.R_DATA[19: 8];
                end else begin
                    dram_index[0] <= dram_index[0];
                    dram_index[1] <= dram_index[1];
                    dram_index[2] <= dram_index[2];
                    dram_index[3] <= dram_index[3];
                end
            end
            STATE_CAL0: begin
                case (formula)
                    Formula_B,
                    Formula_C: begin
                        {dram_index[0], dram_index[2]} <= {L1_0, L1_2};
                        {dram_index[1], dram_index[3]} <= {L1_1, L1_3};
                    end
                    default: begin
                        dram_index[0] <= dram_index[0];
                        dram_index[1] <= dram_index[1];
                        dram_index[2] <= dram_index[2];
                        dram_index[3] <= dram_index[3];
                    end
                endcase
            end
            STATE_CAL1: begin
                case (formula)
                    Formula_B,
                    Formula_C: begin
                        {dram_index[0], dram_index[1]} <= {L2_0, L2_1};
                        {dram_index[2], dram_index[3]} <= {L2_2, L2_3};
                    end
                    Formula_F,
                    Formula_G,
                    Formula_H: begin
                        dram_index[0] <= diff_index[0];
                        dram_index[1] <= diff_index[1];
                        dram_index[2] <= diff_index[2];
                        dram_index[3] <= diff_index[3];
                    end
                    default: begin
                        dram_index[0] <= dram_index[0];
                        dram_index[1] <= dram_index[1];
                        dram_index[2] <= dram_index[2];
                        dram_index[3] <= dram_index[3];
                    end
                endcase
            end
            STATE_CAL2: begin
                case (formula)
                    Formula_F,
                    Formula_G: begin
                        {dram_index[0], dram_index[2]} <= {L1_0, L1_2};
                        {dram_index[1], dram_index[3]} <= {L1_1, L1_3};
                    end
                    default: begin
                        dram_index[0] <= dram_index[0];
                        dram_index[1] <= dram_index[1];
                        dram_index[2] <= dram_index[2];
                        dram_index[3] <= dram_index[3];
                    end
                endcase
            end
            STATE_CAL3: begin
                case (formula)
                    Formula_F,
                    Formula_G: begin
                        {dram_index[0], dram_index[1]} <= {L2_0, L2_1};
                        {dram_index[2], dram_index[3]} <= {L2_2, L2_3};
                    end
                    default: begin
                        dram_index[0] <= dram_index[0];
                        dram_index[1] <= dram_index[1];
                        dram_index[2] <= dram_index[2];
                        dram_index[3] <= dram_index[3];
                    end
                endcase
            end
            default: begin
                dram_index[0] <= dram_index[0];
                dram_index[1] <= dram_index[1];
                dram_index[2] <= dram_index[2];
                dram_index[3] <= dram_index[3];
            end
        endcase
    end

    always_comb begin
        {L1_0, L1_2} = dram_index[0] <= dram_index[2] ? {dram_index[0], dram_index[2]} : {dram_index[2], dram_index[0]};
        {L1_1, L1_3} = dram_index[1] <= dram_index[3] ? {dram_index[1], dram_index[3]} : {dram_index[3], dram_index[1]};
        {L2_0, L2_1} = dram_index[0] <= dram_index[1] ? {dram_index[0], dram_index[1]} : {dram_index[1], dram_index[0]};
        {L2_2, L2_3} = dram_index[2] <= dram_index[3] ? {dram_index[2], dram_index[3]} : {dram_index[3], dram_index[2]};
    end

    always_ff @(posedge clk) begin
        dram_lgeq[0] <= dram_index[0] >= index[0];
        dram_lgeq[1] <= dram_index[1] >= index[1];
        dram_lgeq[2] <= dram_index[2] >= index[2];
        dram_lgeq[3] <= dram_index[3] >= index[3];
        dram_2047[0] <= dram_index[0][11] || (&dram_index[0][10:0]);
        dram_2047[1] <= dram_index[1][11] || (&dram_index[1][10:0]);
        dram_2047[2] <= dram_index[2][11] || (&dram_index[2][10:0]);
        dram_2047[3] <= dram_index[3][11] || (&dram_index[3][10:0]);
    end

    always_comb begin
        one_cnter_src = formula[2] ? dram_lgeq : dram_2047;
    end

    always_comb begin
        diff_index[0] = diff_op0[0] - diff_op1[0];
        diff_index[1] = diff_op0[1] - diff_op1[1];
        diff_index[2] = diff_op0[2] - diff_op1[2];
        diff_index[3] = diff_op0[3] - diff_op1[3];
    end
    
    always_comb begin
        {diff_op0[0], diff_op1[0]} = dram_lgeq[0] ? {dram_index[0], index[0]} : {index[0], dram_index[0]};
        {diff_op0[1], diff_op1[1]} = dram_lgeq[1] ? {dram_index[1], index[1]} : {index[1], dram_index[1]};
        {diff_op0[2], diff_op1[2]} = dram_lgeq[2] ? {dram_index[2], index[2]} : {index[2], dram_index[2]};
        {diff_op0[3], diff_op1[3]} = dram_lgeq[3] ? {dram_index[3], index[3]} : {index[3], dram_index[3]};
    end
    
    always_ff @(posedge clk) begin
        dram_add12 <= dram_index[1] + dram_index[2];
        dram_add03 <= dram_index[0] + dram_index[3];
    end

    always_comb begin
        dram_add = dram_add12 + dram_add03;
    end

    always_comb begin
        dram_max_min_diff = dram_index[3] - dram_index[0];
    end

    always_ff @(posedge clk) begin
        case (cs)
            STATE_CAL1: begin
                case (formula)
                    Formula_A: begin
                        R <= dram_add[13:2];  // A
                    end
                    Formula_D,
                    Formula_E: begin
                        case (one_cnter_src)    // D or E
                            4'b0000: R <= 'd0;
                            4'b0001: R <= 'd1;
                            4'b0010: R <= 'd1;
                            4'b0011: R <= 'd2;
                            4'b0100: R <= 'd1;
                            4'b0101: R <= 'd2;
                            4'b0110: R <= 'd2;
                            4'b0111: R <= 'd3;
                            4'b1000: R <= 'd1;
                            4'b1001: R <= 'd2;
                            4'b1010: R <= 'd2;
                            4'b1011: R <= 'd3;
                            4'b1100: R <= 'd2;
                            4'b1101: R <= 'd3;
                            4'b1110: R <= 'd3;
                            4'b1111: R <= 'd4;
                            default: R <= 'd0;
                        endcase
                    end
                    default: begin
                        R <= R;
                    end
                endcase
            end
            STATE_CAL2: begin
                case (formula)
                    Formula_B: begin
                        R <= dram_max_min_diff; // B
                    end
                    Formula_C: begin
                        R <= dram_index[0]; // C
                    end
                    default: begin
                        R <= R;
                    end
                endcase
            end
            STATE_CAL3: begin
                case (formula)
                    Formula_H: begin
                        R <= dram_add[13:2]; // H
                    end
                    default: begin
                        R <= R;
                    end
                endcase
            end
            STATE_CAL4: begin
                case (formula)
                    Formula_F: begin
                        R <= dram_index[0] + dram_index[1];
                    end
                    Formula_G: begin
                        R <= dram_index[1][11:2] + dram_index[2][11:2];
                    end
                    default: begin
                        R <= R;
                    end
                endcase
            end
            STATE_CAL5: begin
                case (formula)
                    Formula_G: begin
                        R <= R[10:0] + dram_index[0][11:1]; // G
                    end
                    default: begin
                        R <= R;
                    end
                endcase
            end
            STATE_CAL6: begin
                case (formula)
                    Formula_F: begin
                        // R <= R / 3; // F
                        R <= {1'b0, R[11:0], R_Q};
                    end
                    default: begin
                        R <= R;
                    end
                endcase
            end
            default: begin
                R <= R;
            end
        endcase
    end

    always_ff @(posedge clk) begin
        case (cs)
            STATE_CAL6: begin
                R14 <= R_Q ? R_mn3[1] : R_temp[13];
            end
            default: begin
                R14 <= 'd0;
            end
        endcase
    end

    always_ff @(posedge clk) begin
        case (cs)
            STATE_CAL5: begin
                R_temp <= R[12:0] + dram_index[2];
            end
            STATE_CAL6: begin
                R_temp <= R_Q ? {R_mn3[0], R_temp[11:0], 1'b0} : {R_temp[12:0], 1'b0};
            end
            default: begin
                R_temp <= 'd0;
            end
        endcase
    end

    always_comb begin
        R_Q = R14 || (&R_temp[13:12]); // R[14:12] >= 2'd3
        R_mn3 = {R14, R_temp[13:12]} - 2'd3; // R[14:12] - 2'd3
    end

    always_ff @(posedge clk) begin
        case (cs)
            STATE_CAL6: begin
                div_cnt <= div_cnt + 1;
            end
            default: begin
                div_cnt <= 'd0;
            end
        endcase
    end

    always_comb begin
        R_2047 = R[11] || (&R[10:0]);
        R_1023 = (|R[11:10]) || (&R[9:0]);
        R_511  = (|R[11:9]) || (&R[8:0]);
        R_800  = R >= 800;
        R_400  = R >= 400;
        R_200  = R >= 200;
        R_3    = R[2] || (&R[1:0]);
        R_2    = (|R[2:1]);
        R_1    = (|R[2:0]);
    end

    always_ff @(posedge clk) begin
        case (formula)
            Formula_A,
            Formula_C: begin
                case (mode)
                    Insensitive: risk_warn <= R_2047;
                    Normal:      risk_warn <= R_1023;
                    Sensitive:   risk_warn <= R_511;
                    default:     risk_warn <= 1'b0;
                endcase
            end
            Formula_B,
            Formula_F,
            Formula_G,
            Formula_H: begin
                case (mode)
                    Insensitive: risk_warn <= R_800;
                    Normal:      risk_warn <= R_400;
                    Sensitive:   risk_warn <= R_200;
                    default:     risk_warn <= 1'b0;
                endcase
            end
            Formula_D,
            Formula_E: begin
                case (mode)
                    Insensitive: risk_warn <= R_3;
                    Normal:      risk_warn <= R_2;
                    Sensitive:   risk_warn <= R_1;
                    default:     risk_warn <= 1'b0;
                endcase
            end
            default: begin
                risk_warn <= 1'b0;
            end
        endcase
    end

    always @(posedge clk) begin
        update_index[0] <= $signed({1'b0, dram_index[0]}) + $signed(index[0]);
        update_index[1] <= $signed({1'b0, dram_index[1]}) + $signed(index[1]);
        update_index[2] <= $signed({1'b0, dram_index[2]}) + $signed(index[2]);
        update_index[3] <= $signed({1'b0, dram_index[3]}) + $signed(index[3]);
    end

    // always_ff @(posedge clk) begin
    //     for (int i = 0; i < 4; i++) begin
    //         if (update_index[i][13])
    //             update_index_sat[i] <= 'd0;
    //         else if (update_index[i][12])
    //             update_index_sat[i] <= 'd4095;
    //         else
    //             update_index_sat[i] <= update_index[i];
    //     end
    // end
    always_comb begin
        for (int i = 0; i < 4; i++) begin
            case (update_index[i][13:12])
                2'b11: update_index_sat[i] = 'd0;
                2'b10: update_index_sat[i] = 'd0;
                2'b01: update_index_sat[i] = 'd4095;
                2'b00: update_index_sat[i] = update_index[i];
                default: update_index_sat[i] = 'd0;
            endcase
        end
    end

    always_ff @(posedge clk or negedge inf.rst_n) begin
        if (~inf.rst_n) begin
            inf.out_valid <= 1'b0;
        end else begin
            if (cs == STATE_OUPT) begin
                inf.out_valid <= 1'b1;
            end else begin
                inf.out_valid <= 1'b0;
            end
        end
    end

    always_ff @(posedge clk or negedge inf.rst_n) begin
        if (~inf.rst_n) begin
            inf.complete <= 1'b0;
            inf.warn_msg <= No_Warn;
        end else begin
            if (cs == STATE_OUPT) begin
                case (action)
                    Index_Check: begin
                        if (date_warn) begin
                            inf.complete <= 1'b0;
                            inf.warn_msg <= Date_Warn;
                        end else 
                        if (risk_warn) begin
                            inf.complete <= 1'b0;
                            inf.warn_msg <= Risk_Warn;
                        end else begin
                            inf.complete <= 1'b1;
                            inf.warn_msg <= No_Warn;
                        end
                    end
                    Update: begin
                        if (update_index[0][13:12] || update_index[1][13:12] || update_index[2][13:12] || update_index[3][13:12]) begin
                            inf.complete <= 1'b0;
                            inf.warn_msg <= Data_Warn;
                        end else begin
                            inf.complete <= 1'b1;
                            inf.warn_msg <= No_Warn;
                        end
                    end
                    Check_Valid_Date: begin
                        if (date_warn) begin
                            inf.complete <= 1'b0;
                            inf.warn_msg <= Date_Warn;
                        end else begin
                            inf.complete <= 1'b1;
                            inf.warn_msg <= No_Warn;
                        end
                    end
                    default: begin
                        inf.complete <= 1'b0;
                        inf.warn_msg <= No_Warn;
                    end
                endcase
            end else begin
                inf.complete <= 1'b0;
                inf.warn_msg <= No_Warn;
            end
        end
    end

endmodule
