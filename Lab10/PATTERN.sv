
// `include "../00_TESTBED/pseudo_DRAM.sv"
`include "Usertype.sv"

program automatic PATTERN(input clk, INF.PATTERN inf); // @suppress
    import usertype::*;
    //================================================================
    // parameters & integer
    //================================================================
    parameter DRAM_p_r      = "../00_TESTBED/DRAM/dram.dat";
    parameter MAX_CYCLE     = 1000;
    integer   SEED          = 32155;

    integer i, j, k; // @suppress
    integer latency;
    integer total_latency;
    
    int result;
    int threshold;

    int pat_cnt;
    int index_check_cnt;
    int risk_warn_cnt;
    int data_warn_cnt;
    int date_warn_cnt;
    int no_warn_cnt;
    int update_var_cnt;

    //================================================================
    // wire & registers 
    //================================================================
    logic       sending;

    logic [7:0] golden_DRAM [((65536+8*256)-1):(65536+0)]; 
    logic [1:0] golden_warn_msg;
    logic [7:0] golden_complete; 
    
    logic [16:0] dram_addr;
    logic [ 7:0] dram_data [7:0];
    logic [ 3:0] dram_month;
    logic [ 4:0] dram_day;
    logic [11:0] dram_index_A;
    logic [11:0] dram_index_B;
    logic [11:0] dram_index_C;
    logic [11:0] dram_index_D;
    
    logic [11:0] L0_0, L0_1, L0_2, L0_3;
    logic [11:0] L1_0, L1_1, L1_2, L1_3;
    logic [11:0] L2_0, L2_1, L2_2, L2_3;

    //================================================================
    // Clock
    //================================================================
    real PAT_NUM = 5400;

    //================================================================
    // Random Class
    //================================================================
    class RandomAction;
        rand Action action;
        function new (int seed); begin
            this.srandom(seed);
        end endfunction
        constraint range { action inside{ Index_Check, Update, Check_Valid_Date }; }
    endclass

    class RandomFormulaType;
        rand Formula_Type formula_type;
        function new (int seed); begin
            this.srandom(seed);
        end endfunction
        constraint range { formula_type inside{ Formula_A, Formula_B, Formula_C, Formula_D, Formula_E, Formula_F, Formula_G, Formula_H }; }
    endclass

    class RandomMode;
        rand Mode mode;
        function new (int seed); begin
            this.srandom(seed);
        end endfunction
        constraint range { mode inside{ Insensitive, Normal, Sensitive }; }
    endclass

    class RandomDate;
        rand Date date;
        function new (int seed); begin
            this.srandom(seed);
        end endfunction
        constraint valid_month {
            date.M inside {[1:12]};
        }
        constraint valid_day {
            if (date.M inside {1, 3, 5, 7, 8, 10, 12})
                date.D inside {[1:31]};
            else if (date.M inside {4, 6, 9, 11})
                date.D inside {[1:30]};
            else if (date.M == 2)
                date.D inside {[1:28]};
        }
    endclass

    class RandomDataNo;
        rand Data_No data_no;
        function new (int seed); begin
            this.srandom(seed);
        end endfunction
        constraint range { data_no inside {[0:255]}; }
    endclass

    class RandomIndex;
        rand Index index_A;
        rand Index index_B;
        rand Index index_C;
        rand Index index_D;
        function new (int seed); begin
            this.srandom(seed);
        end endfunction
        constraint range { index_A inside {[0:4095]}; index_B inside {[0:4095]}; index_C inside {[0:4095]}; index_D inside {[0:4095]}; }
    endclass

    RandomAction        r_action        = new(SEED);
    RandomFormulaType   r_formula_type  = new(SEED);
    RandomMode          r_mode          = new(SEED);
    RandomDate          r_date          = new(SEED);
    RandomDataNo        r_data_no       = new(SEED);
    RandomIndex         r_index         = new(SEED);

    Action              golden_action;
    Formula_Type        golden_formula_type;
    Mode                golden_mode;
    Date                golden_date;
    Data_No             golden_data_no;
    Index               golden_index_A;
    Index               golden_index_B;
    Index               golden_index_C;
    Index               golden_index_D;

    //================================================================
    // Design
    //================================================================
    initial begin
        `ifdef SHINKUAN
        $display("**************************************************");
        $display("            PATTERN MADE BY SHIN-KUAN             ");
        $display("**************************************************");
        `endif
        // $write("\033[33m");                                             
        // $display("██╗      █████╗ ██████╗  ██████╗  █████╗ ");
        // $display("██║     ██╔══██╗██╔══██╗██╔═████╗██╔══██╗");
        // $display("██║     ███████║██████╔╝██║██╔██║╚██████║");
        // $display("██║     ██╔══██║██╔══██╗████╔╝██║ ╚═══██║");
        // $display("███████╗██║  ██║██████╔╝╚██████╔╝ █████╔╝");
        // $display("╚══════╝╚═╝  ╚═╝╚═════╝  ╚═════╝  ╚════╝ ");
        // $write("\033[36m");
        // $display("Seed: %d", SEED);
        $write("\033[0m");
        $display("==================================================");
        read_dram;
        reset;
        for (pat_cnt = 0; pat_cnt < PAT_NUM; pat_cnt++) begin
            generate_stimulus;
            generate_golden;
            send_input;
            wait_output;
            check_output;
            $write("\033[32m");
            $display("Pattern %d Pass. Latency: %d", pat_cnt, latency);
            $write("\033[0m");
            if (pat_cnt == PAT_NUM-1) break;
            wait_next_pattern;
        end
        $display("\033[32m");
        $display("**************************************************");
        $display("                 Congratulations                  ");
        $display("**************************************************");
        $display("        Total Latency: %d cycles", total_latency);
        $write("\033[0m");
        $finish;
    end
    
    task read_dram; begin
        $readmemh(DRAM_p_r, golden_DRAM);
    end endtask

    task reset; begin
        sending = 0;
        latency = 0;
        total_latency = 0;
        pat_cnt = 0;
        index_check_cnt = 0;
        risk_warn_cnt = 0;
        data_warn_cnt = 0;
        date_warn_cnt = 0;
        no_warn_cnt = 0;
        update_var_cnt = 0;

        inf.rst_n = 1;
        inf.sel_action_valid = 0;
        inf.formula_valid = 0;
        inf.mode_valid = 0;
        inf.date_valid = 0;
        inf.data_no_valid = 0;
        inf.index_valid = 0;
        inf.D = 'bX;
        #(5);
        inf.rst_n = 0;
        #(15);
        inf.rst_n = 1;
        // repeat (3) @(negedge clk);
    end endtask
    
    task generate_stimulus; begin
        if (pat_cnt < 2700) begin
            // This order of action can get the action transition coverage
            case (pat_cnt%9)
                0: golden_action = Index_Check;
                1: golden_action = Index_Check;
                2: golden_action = Update;
                3: golden_action = Update;
                4: golden_action = Check_Valid_Date;
                5: golden_action = Check_Valid_Date;
                6: golden_action = Update;
                7: golden_action = Index_Check;
                8: golden_action = Check_Valid_Date;
                default: begin
                    r_action.randomize();
                    golden_action = r_action.action;
                end
            endcase
        end else begin
            // Transition coverage is completed,
            // Now, fufill the formula type and mode coverage
            golden_action = Index_Check;
        end
        // Formula_Type x Mode each 150 times
        // 8 Formula_Type x 3 Mode = 24 patterns
        // 24 patterns x 150 times = 3600 patterns
        case ((index_check_cnt/3)%8)
            0: golden_formula_type = Formula_A;
            1: golden_formula_type = Formula_B;
            2: golden_formula_type = Formula_C;
            3: golden_formula_type = Formula_D;
            4: golden_formula_type = Formula_E;
            5: golden_formula_type = Formula_F;
            6: golden_formula_type = Formula_G;
            7: golden_formula_type = Formula_H;
            default: begin
                r_formula_type.randomize();
                golden_formula_type = r_formula_type.formula_type;
            end
        endcase
        case (index_check_cnt%3)
            0: golden_mode = Insensitive;
            1: golden_mode = Normal;
            2: golden_mode = Sensitive;
            default: begin
                r_mode.randomize();
                golden_mode = r_mode.mode;
            end
        endcase
        case (golden_action)
            Index_Check: begin
                if (risk_warn_cnt < 55) begin
                    // If Risk_Warn count is less than 55,
                    // Let golden_date be 12/31, to avoid Date_Warn
                    golden_date.M = 12;
                    golden_date.D = 31;
                end else
                if (date_warn_cnt < 55) begin
                    // If Date_Warn count is less than 55,
                    // Let golden_date be 1/1, to get Date_Warn
                    golden_date.M = 1;
                    golden_date.D = 1;
                end else begin
                    // If both Risk_Warn and Date_Warn count are more than 55,
                    // Let golden_date be random
                    r_date.randomize();
                    golden_date = r_date.date;
                end
            end
            Update: begin
                r_date.randomize();
                golden_date = r_date.date;
            end
            Check_Valid_Date: begin
                if (date_warn_cnt < 55) begin
                    // If Date_Warn count is less than 55,
                    // Let golden_date be 1/1, to get Date_Warn
                    golden_date.M = 1;
                    golden_date.D = 1;
                end else begin
                    // If Date_Warn count is more than 55,
                    // Let golden_date be random
                    r_date.randomize();
                    golden_date = r_date.date;
                end
            end
            default: begin
                r_date.randomize();
                golden_date = r_date.date;
            end
        endcase
        r_data_no.randomize();
        golden_data_no = r_data_no.data_no;
        dram_addr = golden_data_no * 8 + 17'h10000;
        for (int i = 0; i < 8; i++) dram_data[i] = golden_DRAM[dram_addr + i];
        dram_month  = dram_data[4][3:0];
        dram_day    = dram_data[0][4:0];
        dram_index_A = {dram_data[7][7:0], dram_data[6][7:4]};
        dram_index_B = {dram_data[6][3:0], dram_data[5][7:0]};
        dram_index_C = {dram_data[3][7:0], dram_data[2][7:4]};
        dram_index_D = {dram_data[2][3:0], dram_data[1][7:0]};

        case (golden_action)
            Index_Check: begin
                if (risk_warn_cnt < 55) begin
                    // If Risk_Warn count is less than 55,
                    // Let golden_index be special value, to get Risk_Warn
                    golden_index_A = 4095;
                    golden_index_B = 4095;
                    golden_index_C = 4095;
                    golden_index_D = 0;
                end else begin
                    // If Risk_Warn count is more than 55,
                    // Let golden_index be random
                    r_index.randomize();
                    golden_index_A = r_index.index_A;
                    golden_index_B = r_index.index_B;
                    golden_index_C = r_index.index_C;
                    golden_index_D = r_index.index_D;
                end
            end
            Update: begin
                if (data_warn_cnt < 55) begin
                    // If Data_Warn count is less than 55,
                    // Let golden_index be special value, to get Data_Warn
                    r_index.randomize();
                    if (dram_index_A > 2048)        golden_index_A = 2047;
                    else if (dram_index_A < 2048)   golden_index_A = 2048; // -2048
                    else                            golden_index_A = r_index.index_A;
                    if (dram_index_B > 2048)        golden_index_B = 2047;
                    else if (dram_index_B < 2048)   golden_index_B = 2048; // -2048
                    else                            golden_index_B = r_index.index_B;
                    if (dram_index_C > 2048)        golden_index_C = 2047;
                    else if (dram_index_C < 2048)   golden_index_C = 2048; // -2048
                    else                            golden_index_C = r_index.index_C;
                    if (dram_index_D > 2048)        golden_index_D = 2047;
                    else if (dram_index_D < 2048)   golden_index_D = 2048; // -2048
                    else                            golden_index_D = r_index.index_D;
                end else
                if (update_var_cnt < 32) begin
                    // Try to fufill the update variant coverage
                    golden_index_A = 128 * update_var_cnt * 1 + 64;
                    golden_index_B = 128 * update_var_cnt * 2 + 64;
                    golden_index_C = 128 * update_var_cnt * 3 + 64;
                    golden_index_D = 128 * update_var_cnt * 4 + 64;
                    update_var_cnt = update_var_cnt + 4;
                end else begin
                    r_index.randomize();
                    golden_index_A = r_index.index_A;
                    golden_index_B = r_index.index_B;
                    golden_index_C = r_index.index_C;
                    golden_index_D = r_index.index_D;
                end
            end
            Check_Valid_Date: begin
                r_index.randomize();
                golden_index_A = r_index.index_A;
                golden_index_B = r_index.index_B;
                golden_index_C = r_index.index_C;
                golden_index_D = r_index.index_D;
            end
            default: begin
                r_index.randomize();
                golden_index_A = r_index.index_A;
                golden_index_B = r_index.index_B;
                golden_index_C = r_index.index_C;
                golden_index_D = r_index.index_D;
            end
        endcase
    end endtask

    task generate_golden; begin
        case (golden_action)
            Index_Check: begin
                index_check_cnt = index_check_cnt + 1;

                golden_complete = 0;
                golden_warn_msg = No_Warn;
                if (
                    dram_month > golden_date.M ||
                    (dram_month == golden_date.M && dram_day > golden_date.D)
                ) begin
                    golden_complete = 0;
                    golden_warn_msg = Date_Warn;
                    case (golden_warn_msg)
                        Risk_Warn: risk_warn_cnt = risk_warn_cnt + 1;
                        Data_Warn: data_warn_cnt = data_warn_cnt + 1;
                        Date_Warn: date_warn_cnt = date_warn_cnt + 1;
                        No_Warn:   no_warn_cnt = no_warn_cnt + 1;
                        default: begin /* Impossible */ end
                    endcase
                    return;
                end
                case (golden_formula_type)
                    Formula_A: begin
                        case (golden_mode)
                            Insensitive: threshold = 2047;
                            Normal:      threshold = 1023;
                            Sensitive:   threshold = 511;
                            default:     threshold = 0;
                        endcase
                        result = (dram_index_A + dram_index_B + dram_index_C + dram_index_D) >> 2;
                        if (result >= threshold) golden_warn_msg = Risk_Warn;
                    end
                    Formula_B: begin
                        int max = dram_index_A;
                        int min = dram_index_A;
                        case (golden_mode)
                            Insensitive: threshold = 800;
                            Normal:      threshold = 400;
                            Sensitive:   threshold = 200;
                            default:     threshold = 0;
                        endcase
                        if (dram_index_B > max) max = dram_index_B;
                        if (dram_index_C > max) max = dram_index_C;
                        if (dram_index_D > max) max = dram_index_D;
                        if (dram_index_B < min) min = dram_index_B;
                        if (dram_index_C < min) min = dram_index_C;
                        if (dram_index_D < min) min = dram_index_D;
                        result = max - min;
                        if (result >= threshold) golden_warn_msg = Risk_Warn;
                    end
                    Formula_C: begin
                        int min;
                        case (golden_mode)
                            Insensitive: threshold = 2047;
                            Normal:      threshold = 1023;
                            Sensitive:   threshold = 511;
                            default:     threshold = 0;
                        endcase
                        min = dram_index_A;
                        if (dram_index_B < min) min = dram_index_B;
                        if (dram_index_C < min) min = dram_index_C;
                        if (dram_index_D < min) min = dram_index_D;
                        result = min;
                        if (result >= threshold) golden_warn_msg = Risk_Warn;
                    end
                    Formula_D: begin
                        logic i_A, i_B, i_C, i_D;
                        case (golden_mode)
                            Insensitive: threshold = 3;
                            Normal:      threshold = 2;
                            Sensitive:   threshold = 1;
                            default:     threshold = 0;
                        endcase
                        i_A = dram_index_A >= 2047;
                        i_B = dram_index_B >= 2047;
                        i_C = dram_index_C >= 2047;
                        i_D = dram_index_D >= 2047;
                        result = i_A + i_B + i_C + i_D;
                        if (result >= threshold) golden_warn_msg = Risk_Warn;
                    end
                    Formula_E: begin
                        logic i_A, i_B, i_C, i_D;
                        case (golden_mode)
                            Insensitive: threshold = 3;
                            Normal:      threshold = 2;
                            Sensitive:   threshold = 1;
                            default:     threshold = 0;
                        endcase
                        i_A = dram_index_A >= golden_index_A;
                        i_B = dram_index_B >= golden_index_B;
                        i_C = dram_index_C >= golden_index_C;
                        i_D = dram_index_D >= golden_index_D;
                        result = i_A + i_B + i_C + i_D;
                        if (result >= threshold) golden_warn_msg = Risk_Warn;
                    end
                    Formula_F: begin
                        int max;
                        case (golden_mode)
                            Insensitive: threshold = 800;
                            Normal:      threshold = 400;
                            Sensitive:   threshold = 200;
                            default:     threshold = 0;
                        endcase
                        L0_0 = dram_index_A > golden_index_A ? dram_index_A - golden_index_A : golden_index_A - dram_index_A;
                        L0_1 = dram_index_B > golden_index_B ? dram_index_B - golden_index_B : golden_index_B - dram_index_B;
                        L0_2 = dram_index_C > golden_index_C ? dram_index_C - golden_index_C : golden_index_C - dram_index_C;
                        L0_3 = dram_index_D > golden_index_D ? dram_index_D - golden_index_D : golden_index_D - dram_index_D;
                        max = L0_0;
                        if (L0_1 > max) max = L0_1;
                        if (L0_2 > max) max = L0_2;
                        if (L0_3 > max) max = L0_3;
                        result = (L0_0 + L0_1 + L0_2 + L0_3 - max) / 3;
                        if (result >= threshold) golden_warn_msg = Risk_Warn;
                    end
                    Formula_G: begin
                        case (golden_mode)
                            Insensitive: threshold = 800;
                            Normal:      threshold = 400;
                            Sensitive:   threshold = 200;
                            default:     threshold = 0;
                        endcase
                        L0_0 = dram_index_A > golden_index_A ? dram_index_A - golden_index_A : golden_index_A - dram_index_A;
                        L0_1 = dram_index_B > golden_index_B ? dram_index_B - golden_index_B : golden_index_B - dram_index_B;
                        L0_2 = dram_index_C > golden_index_C ? dram_index_C - golden_index_C : golden_index_C - dram_index_C;
                        L0_3 = dram_index_D > golden_index_D ? dram_index_D - golden_index_D : golden_index_D - dram_index_D;
                        {L1_0, L1_2} = L0_0 > L0_2 ? {L0_2, L0_0} : {L0_0, L0_2};
                        {L1_1, L1_3} = L0_1 > L0_3 ? {L0_3, L0_1} : {L0_1, L0_3};
                        {L2_0, L2_1} = L1_0 > L1_1 ? {L1_1, L1_0} : {L1_0, L1_1};
                        {L2_2, L2_3} = L1_2 > L1_3 ? {L1_3, L1_2} : {L1_2, L1_3};
                        result = (L2_0 >> 1) + (L2_1 >> 2) + (L2_2 >> 2);
                        if (result >= threshold) golden_warn_msg = Risk_Warn;
                    end
                    Formula_H: begin
                        logic [11:0] L0_0, L0_1, L0_2, L0_3;
                        case (golden_mode)
                            Insensitive: threshold = 800;
                            Normal:      threshold = 400;
                            Sensitive:   threshold = 200;
                            default:     threshold = 0;
                        endcase
                        L0_0 = dram_index_A > golden_index_A ? dram_index_A - golden_index_A : golden_index_A - dram_index_A;
                        L0_1 = dram_index_B > golden_index_B ? dram_index_B - golden_index_B : golden_index_B - dram_index_B;
                        L0_2 = dram_index_C > golden_index_C ? dram_index_C - golden_index_C : golden_index_C - dram_index_C;
                        L0_3 = dram_index_D > golden_index_D ? dram_index_D - golden_index_D : golden_index_D - dram_index_D;
                        result = (L0_0 + L0_1 + L0_2 + L0_3) >> 2;
                        if (result >= threshold) golden_warn_msg = Risk_Warn;
                    end
                    default: begin
                        result = 0;
                    end
                endcase
                if (golden_warn_msg == No_Warn) golden_complete = 1;
            end
            Update: begin
                logic signed [13:0] signed_dram_index_A;
                logic signed [13:0] signed_dram_index_B;
                logic signed [13:0] signed_dram_index_C;
                logic signed [13:0] signed_dram_index_D;

                golden_complete = 0;
                golden_warn_msg = No_Warn;

                signed_dram_index_A = {2'b0, dram_index_A};
                signed_dram_index_B = {2'b0, dram_index_B};
                signed_dram_index_C = {2'b0, dram_index_C};
                signed_dram_index_D = {2'b0, dram_index_D};
                signed_dram_index_A = signed_dram_index_A + $signed(golden_index_A);
                signed_dram_index_B = signed_dram_index_B + $signed(golden_index_B);
                signed_dram_index_C = signed_dram_index_C + $signed(golden_index_C);
                signed_dram_index_D = signed_dram_index_D + $signed(golden_index_D);
                if (signed_dram_index_A > 4095) begin signed_dram_index_A = 4095; golden_warn_msg = Data_Warn; end
                if (signed_dram_index_B > 4095) begin signed_dram_index_B = 4095; golden_warn_msg = Data_Warn; end
                if (signed_dram_index_C > 4095) begin signed_dram_index_C = 4095; golden_warn_msg = Data_Warn; end
                if (signed_dram_index_D > 4095) begin signed_dram_index_D = 4095; golden_warn_msg = Data_Warn; end
                if (signed_dram_index_A < 0)    begin signed_dram_index_A = 0;    golden_warn_msg = Data_Warn; end
                if (signed_dram_index_B < 0)    begin signed_dram_index_B = 0;    golden_warn_msg = Data_Warn; end
                if (signed_dram_index_C < 0)    begin signed_dram_index_C = 0;    golden_warn_msg = Data_Warn; end
                if (signed_dram_index_D < 0)    begin signed_dram_index_D = 0;    golden_warn_msg = Data_Warn; end
                {
                    golden_DRAM[dram_addr+7], golden_DRAM[dram_addr+6],
                    golden_DRAM[dram_addr+5], golden_DRAM[dram_addr+4],
                    golden_DRAM[dram_addr+3], golden_DRAM[dram_addr+2],
                    golden_DRAM[dram_addr+1], golden_DRAM[dram_addr+0]
                } = {
                    signed_dram_index_A[11:0], signed_dram_index_B[11:0],
                    4'd0, golden_date.M,
                    signed_dram_index_C[11:0], signed_dram_index_D[11:0],
                    3'd0, golden_date.D
                };
                if (golden_warn_msg == No_Warn) golden_complete = 1;
            end
            Check_Valid_Date: begin
                golden_complete = 0;
                golden_warn_msg = No_Warn;
                if (
                    dram_month > golden_date.M ||
                    (dram_month == golden_date.M && dram_day > golden_date.D)
                ) begin
                    golden_complete = 0;
                    golden_warn_msg = Date_Warn;
                end
                if (golden_warn_msg == No_Warn) golden_complete = 1;
            end
            default: begin
                golden_complete = 0;
                golden_warn_msg = No_Warn;
            end
        endcase

        case (golden_warn_msg)
            Risk_Warn: risk_warn_cnt = risk_warn_cnt + 1;
            Data_Warn: data_warn_cnt = data_warn_cnt + 1;
            Date_Warn: date_warn_cnt = date_warn_cnt + 1;
            No_Warn:   no_warn_cnt = no_warn_cnt + 1;
            default: begin /* Impossible */ end
        endcase

    end endtask

    task send_input; begin
        sending = 1;
        inf.sel_action_valid = 'b1;
        inf.D.d_act[0] = golden_action;
        @(negedge clk);
        inf.sel_action_valid = 'b0;
        inf.D = 'bX;
        if (golden_action == Index_Check) begin
            // repeat ({$random(SEED)} % 4) @(negedge clk);
            inf.formula_valid = 'b1;
            inf.D.d_formula[0] = golden_formula_type;
            @(negedge clk);
            inf.formula_valid = 'b0;
            inf.D = 'bX;
        end
        if (golden_action == Index_Check) begin
            // repeat ({$random(SEED)} % 4) @(negedge clk);
            inf.mode_valid = 'b1;
            inf.D.d_mode[0] = golden_mode;
            @(negedge clk);
            inf.mode_valid = 'b0;
            inf.D = 'bX;
        end
        // repeat ({$random(SEED)} % 4) @(negedge clk);
        inf.date_valid = 'b1;
        inf.D.d_date[0] = golden_date;
        @(negedge clk);
        inf.date_valid = 'b0;
        inf.D = 'bX;
        // repeat ({$random(SEED)} % 4) @(negedge clk);
        inf.data_no_valid = 'b1;
        inf.D.d_data_no[0] = golden_data_no;
        @(negedge clk);
        inf.data_no_valid = 'b0;
        inf.D = 'bX;
        if (golden_action == Index_Check || golden_action == Update) begin
            // repeat ({$random(SEED)} % 4) @(negedge clk);
            inf.index_valid = 'b1;
            inf.D.d_index[0] = golden_index_A;
            @(negedge clk);
            inf.index_valid = 'b0;
            inf.D = 'bX;
            // repeat ({$random(SEED)} % 4) @(negedge clk);
            inf.index_valid = 'b1;
            inf.D.d_index[0] = golden_index_B;
            @(negedge clk);
            inf.index_valid = 'b0;
            inf.D = 'bX;
            // repeat ({$random(SEED)} % 4) @(negedge clk);
            inf.index_valid = 'b1;
            inf.D.d_index[0] = golden_index_C;
            @(negedge clk);
            inf.index_valid = 'b0;
            inf.D = 'bX;
            // repeat ({$random(SEED)} % 4) @(negedge clk);
            inf.index_valid = 'b1;
            inf.D.d_index[0] = golden_index_D;
            @(negedge clk);
            inf.index_valid = 'b0;
            inf.D = 'bX;
        end
        sending = 0;
    end endtask

    task wait_output; begin
        latency = 0;
        while (inf.out_valid === 1'b0) begin
            latency = latency + 1;
            @(negedge clk);
        end
        total_latency = total_latency + latency;
    end endtask

    task check_output; begin
        if (inf.out_valid === 1'b1) begin
            if (
                inf.complete !== golden_complete ||
                inf.warn_msg !== golden_warn_msg
            )  begin
                $write("\033[31m");
                $display("**************************************************");
                $display("                   Wrong Answer                   ");
                $display("**************************************************");
                $display("              out_data is not correct");
                $display("--------------------------------------------------");
                $display("               time: %d", $time);
                $display("--------------------------------------------------");
                $display("out_valid: %2b", inf.out_valid);
                $display("complete:  %2b", inf.complete);
                $display("warn_msg:  %2b", inf.warn_msg);
                $display("--------------------------------------------------");
                $display("golden_complete:  %2b", golden_complete);
                $display("golden_warn_msg:  %2b", golden_warn_msg);
                $display("**************************************************");
                $write("\033[0m");
                $finish;
            end
        end else begin
            $write("\033[31m");
            $display("**************************************************");
            $display("                   Wrong Answer                   ");
            $display("**************************************************");
            $display("               out_valid is not high");
            $display("--------------------------------------------------");
            $display("               time: %d", $time);
            $display("--------------------------------------------------");
            $display("out_valid: %2b", inf.out_valid);
            $display("complete:  %2b", inf.complete);
            $display("warn_msg:  %2b", inf.warn_msg);
            $display("--------------------------------------------------");
            $display("golden_complete:  %2b", golden_complete);
            $display("golden_warn_msg:  %2b", golden_warn_msg);
            $display("**************************************************");
            $write("\033[0m");
            $finish;
        end
    end endtask

    task wait_next_pattern; begin
        @(negedge clk);
        // repeat ({$random(SEED)} % 4) @(negedge clk);
    end endtask

endprogram
