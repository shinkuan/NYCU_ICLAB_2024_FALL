/*
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
NYCU Institute of Electronic
2023 Autumn IC Design Laboratory 
Lab10: SystemVerilog Coverage & Assertion
File Name   : CHECKER.sv
Module Name : CHECKER
Release version : v1.0 (Release Date: Nov-2023)
Author : Jui-Huang Tsai (erictsai.10@nycu.edu.tw)
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
*/

`include "Usertype.sv"
module Checker(input clk, INF.CHECKER inf); // @suppress
    import usertype::*;
    /**
    * This section contains the definition of the class and the instantiation of the object.
    *  * 
    * The always_ff blocks update the object based on the values of valid signals.
    * When valid signal is true, the corresponding property is updated with the value of inf.D
    */

    class Formula_and_mode;
        Formula_Type f_type;
        Mode f_mode;
    endclass

    Formula_and_mode fm_info = new();
    always_ff @(posedge clk) begin
        if(inf.formula_valid) begin
            fm_info.f_type = inf.D.d_formula[0];
        end
    end
    
    always_ff @(posedge clk) begin
        if(inf.mode_valid) begin
            fm_info.f_mode = inf.D.d_mode[0];
        end
    end
    
    Action current_action;
    always @(posedge clk) begin
        if(inf.sel_action_valid) begin
            current_action = inf.D.d_act[0];
        end
    end

    //==============================================//
    //                   Coverage                   //
    //==============================================//
    // Each case of Formula_Type should be select at least 150 times.
    covergroup CoverSpec1 @(posedge clk iff inf.formula_valid);
        coverpoint inf.D.d_formula[0] {
            option.at_least = 150;
            bins formulas[] = {
                Formula_A, Formula_B, Formula_C, Formula_D, 
                Formula_E, Formula_F, Formula_G, Formula_H
            };
        }
    endgroup : CoverSpec1

    // Each case of Mode should be select at least 150 times. 
    covergroup CoverSpec2 @(posedge clk iff inf.mode_valid);
        coverpoint inf.D.d_mode[0] {
            option.at_least = 150;
            bins modes[] = {
                Insensitive, Normal, Sensitive
            };
        }
    endgroup : CoverSpec2

    // Create a cross bin for the SPEC1 and SPEC2. Each combination should 
    // be selected at least 150 times. 
    // (Formula_A,B,C,D,E,F,G,H) x (Insensitive, Normal, Sensitive)
    covergroup CoverSpec3 @(posedge clk iff (inf.date_valid && current_action == Index_Check));
        option.per_instance = 1;
        option.at_least = 150;
        cross fm_info.f_type, fm_info.f_mode; // @suppress
    endgroup : CoverSpec3
    
    // Output signal inf.warn_msg should be "No_Warn", "Date_Warn", "Data_Warn","Risk_Warn", 
    // each at least 50 times. (Sample the value when inf.out_valid is high)
    covergroup CoverSpec4 @(posedge clk iff inf.out_valid);
        coverpoint inf.warn_msg {
            option.at_least = 50;
            bins warn_msgs[] = {
                No_Warn, Date_Warn, Risk_Warn, Data_Warn
            };
        }
    endgroup : CoverSpec4
    
    // Create the transitions bin for the inf.D.act[0] signal 
    // from 
    //    [Index_Check:Check_Valid_Date] 
    // to 
    //    [Index_Check:Check_Valid_Date] 
    // Each transition should be hit at least 300 times. (sample the 
    // value at posedge clk iff inf.sel_action_valid) 
    covergroup CoverSpec5 @(posedge clk iff inf.sel_action_valid);
        coverpoint inf.D.d_act[0] {
            option.at_least = 300;
            bins action_trans[] = (
                Index_Check, Update, Check_Valid_Date =>
                Index_Check, Update, Check_Valid_Date
            );
        }
    endgroup : CoverSpec5
    
    // Create a covergroup for variation of Update action with auto_bin_max = 32, 
    // and each bin have to hit at least one time. 
    covergroup CoverSpec6 @(posedge clk iff (inf.index_valid && current_action == Update));
        coverpoint inf.D.d_index[0] {
            option.at_least = 1;
            option.auto_bin_max = 32;
        }
    endgroup
    
    CoverSpec1 CoverSpec1_inst = new();
    CoverSpec2 CoverSpec2_inst = new();
    CoverSpec3 CoverSpec3_inst = new();
    CoverSpec4 CoverSpec4_inst = new();
    CoverSpec5 CoverSpec5_inst = new();
    CoverSpec6 CoverSpec6_inst = new();

    //==============================================//
    //                  Assertion                   //
    //==============================================//
    // All outputs signals (Program.sv) should be zero after reset. 
    property AssertSpec1;
        @(posedge inf.rst_n) (1) |-> @(posedge clk) (
            inf.out_valid   === 0       &&
            inf.warn_msg    === No_Warn &&
            inf.complete    === 0       &&
            inf.AR_VALID    === 0       &&
            inf.R_READY     === 0       &&
            inf.AW_VALID    === 0       &&
            inf.W_VALID     === 0       &&
            inf.B_READY     === 0       &&
            inf.AR_ADDR     === 0       &&
            inf.AW_ADDR     === 0       &&
            inf.W_DATA      === 0       
        );
    endproperty : AssertSpec1

    // Latency should be less than 1000 cycles for each operation.
    property AssertSpec2_IndexCheck;
        @(posedge clk) (
            inf.sel_action_valid    === 1 &&
            inf.D.d_act[0]          === Index_Check
        ) 
        ##[1:  4] inf.formula_valid   === 1
        ##[1:  4] inf.mode_valid      === 1
        ##[1:  4] inf.date_valid      === 1
        ##[1:  4] inf.data_no_valid   === 1
        ##1(
        ##[0:  3] inf.index_valid     === 1
        )[*4]
        |->
        ##[1:999] inf.out_valid       === 1;
    endproperty : AssertSpec2_IndexCheck

    property AssertSpec2_Update;
        @(posedge clk) (
            inf.sel_action_valid    === 1 &&
            inf.D.d_act[0]          === Update
        ) 
        ##[1:  4] inf.date_valid      === 1
        ##[1:  4] inf.data_no_valid   === 1
        ##1(
        ##[0:  3] inf.index_valid     === 1
        )[*4]
        |->
        ##[1:999] inf.out_valid       === 1;
    endproperty : AssertSpec2_Update
    
    property AssertSpec2_CheckValidDate;
        @(posedge clk) (
            inf.sel_action_valid    === 1 &&
            inf.D.d_act[0]          === Check_Valid_Date
        ) 
        ##[1:  4] inf.date_valid      === 1
        ##[1:  4] inf.data_no_valid   === 1
        |->
        ##[1:999] inf.out_valid       === 1;
    endproperty : AssertSpec2_CheckValidDate
    
    // If action is completed (complete=1), warn_msg should be 2’b0 (No_Warn). 
    property AssertSpec3;
        @(negedge clk) (
            inf.complete    === 1
        ) |-> (
            inf.warn_msg    === No_Warn
        );
    endproperty : AssertSpec3

    // Next input valid will be valid 1-4 cycles after previous input valid fall.
    property AssertSpec4_IndexCheck;
        @(posedge clk) (
            inf.sel_action_valid    === 1 &&
            inf.D.d_act[0]          === Index_Check
        ) |-> (
            ##[1:  4] inf.formula_valid   === 1
            ##[1:  4] inf.mode_valid      === 1
            ##[1:  4] inf.date_valid      === 1
            ##[1:  4] inf.data_no_valid   === 1
            ##1(
            ##[0:  3] inf.index_valid     === 1
            )[*4]
        );
    endproperty : AssertSpec4_IndexCheck
    
    property AssertSpec4_Update;
        @(posedge clk) (
            inf.sel_action_valid    === 1 &&
            inf.D.d_act[0]          === Update
        ) |-> (
            ##[1:  4] inf.date_valid      === 1
            ##[1:  4] inf.data_no_valid   === 1
            ##1(
            ##[0:  3] inf.index_valid     === 1
            )[*4]
        );
    endproperty : AssertSpec4_Update
    
    property AssertSpec4_CheckValidDate;
        @(posedge clk) (
            inf.sel_action_valid    === 1 &&
            inf.D.d_act[0]          === Check_Valid_Date
        ) |-> (
            ##[1:  4] inf.date_valid      === 1
            ##[1:  4] inf.data_no_valid   === 1
        );
    endproperty : AssertSpec4_CheckValidDate

    // All input valid signals won’t overlap with each other.
    property AssertSpec5_sel_action;
        @(posedge clk) (
            inf.sel_action_valid    === 1
        ) |-> (
            inf.formula_valid   === 0 &&
            inf.mode_valid      === 0 &&
            inf.date_valid      === 0 &&
            inf.data_no_valid   === 0 &&
            inf.index_valid     === 0
        );
    endproperty : AssertSpec5_sel_action

    property AssertSpec5_formula;
        @(posedge clk) (
            inf.formula_valid   === 1
        ) |-> (
            inf.sel_action_valid    === 0 &&
            inf.mode_valid          === 0 &&
            inf.date_valid          === 0 &&
            inf.data_no_valid       === 0 &&
            inf.index_valid         === 0
        );
    endproperty : AssertSpec5_formula

    property AssertSpec5_mode;
        @(posedge clk) (
            inf.mode_valid      === 1
        ) |-> (
            inf.sel_action_valid    === 0 &&
            inf.formula_valid       === 0 &&
            inf.date_valid          === 0 &&
            inf.data_no_valid       === 0 &&
            inf.index_valid         === 0
        );
    endproperty : AssertSpec5_mode

    property AssertSpec5_date;
        @(posedge clk) (
            inf.date_valid      === 1
        ) |-> (
            inf.sel_action_valid    === 0 &&
            inf.formula_valid       === 0 &&
            inf.mode_valid          === 0 &&
            inf.data_no_valid       === 0 &&
            inf.index_valid         === 0
        );
    endproperty : AssertSpec5_date

    property AssertSpec5_data_no;
        @(posedge clk) (
            inf.data_no_valid   === 1
        ) |-> (
            inf.sel_action_valid    === 0 &&
            inf.formula_valid       === 0 &&
            inf.mode_valid          === 0 &&
            inf.date_valid          === 0 &&
            inf.index_valid         === 0
        );
    endproperty : AssertSpec5_data_no

    property AssertSpec5_index;
        @(posedge clk) (
            inf.index_valid     === 1
        ) |-> (
            inf.sel_action_valid    === 0 &&
            inf.formula_valid       === 0 &&
            inf.mode_valid          === 0 &&
            inf.date_valid          === 0 &&
            inf.data_no_valid       === 0
        );
    endproperty : AssertSpec5_index

    // Out_valid can only be high for exactly one cycle.
    property AssertSpec6;
        @(posedge clk) (
            inf.out_valid   !== 0
        ) |=> (
            inf.out_valid   === 0
        );
    endproperty : AssertSpec6
    
    // Next operation will be valid 1-4 cycles after out_valid fall.
    property AssertSpec7;
        @(posedge clk) (
            inf.out_valid                   === 1
        ) |-> (
            ##[1:4] inf.sel_action_valid    === 1
        );
    endproperty : AssertSpec7

    // The input date from pattern should adhere to the real calendar. (ex: 2/29, 3/0, 4/31, 13/1 are illegal cases) 
    property AssertSpec8;
        @(posedge clk) (
            inf.date_valid === 1
        ) |-> (
            (inf.D.d_date[0].M >= 1 && inf.D.d_date[0].M <= 12) &&
            (inf.D.d_date[0].D >= 1 && 
                (
                    (
                        inf.D.d_date[0].M == 1 || inf.D.d_date[0].M == 3 || inf.D.d_date[0].M == 5 || inf.D.d_date[0].M == 7 ||
                        inf.D.d_date[0].M == 8 || inf.D.d_date[0].M == 10 || inf.D.d_date[0].M == 12
                    ) && inf.D.d_date[0].D <= 31 
                ||
                    (
                        inf.D.d_date[0].M == 4 || inf.D.d_date[0].M == 6 || inf.D.d_date[0].M == 9 || inf.D.d_date[0].M == 11
                    ) && inf.D.d_date[0].D <= 30
                ||
                    (
                        inf.D.d_date[0].M == 2
                    ) && inf.D.d_date[0].D <= 28
                )
            )
        );
    endproperty : AssertSpec8

    // The AR_VALID signal should not overlap with the AW_VALID signal.
    property AssertSpec9;
        @(posedge clk) (
            inf.AR_VALID === 1 ||
            inf.AW_VALID === 1
        ) |-> (
            inf.AR_VALID ^ inf.AW_VALID
        );
    endproperty : AssertSpec9

    task assertion_violated(string id); begin
        $display("Assertion %s is violated", id);
        $fatal;
    end endtask

    assert property (AssertSpec1)                   else assertion_violated("1");
    assert property (AssertSpec2_IndexCheck)        else assertion_violated("2");
    assert property (AssertSpec2_Update)            else assertion_violated("2");
    assert property (AssertSpec2_CheckValidDate)    else assertion_violated("2");
    assert property (AssertSpec3)                   else assertion_violated("3");
    assert property (AssertSpec4_IndexCheck)        else assertion_violated("4");
    assert property (AssertSpec4_Update)            else assertion_violated("4");
    assert property (AssertSpec4_CheckValidDate)    else assertion_violated("4");
    assert property (AssertSpec5_sel_action)        else assertion_violated("5");
    assert property (AssertSpec5_formula)           else assertion_violated("5");
    assert property (AssertSpec5_mode)              else assertion_violated("5");
    assert property (AssertSpec5_date)              else assertion_violated("5");
    assert property (AssertSpec5_data_no)           else assertion_violated("5");
    assert property (AssertSpec5_index)             else assertion_violated("5");
    assert property (AssertSpec6)                   else assertion_violated("6");
    assert property (AssertSpec7)                   else assertion_violated("7");
    assert property (AssertSpec8)                   else assertion_violated("8");
    assert property (AssertSpec9)                   else assertion_violated("9");

endmodule