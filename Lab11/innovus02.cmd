update_constraint_mode -name func_mode -sdc_files CHIP_cts.sdc
set_ccopt_property update_io_latency false
create_ccopt_clock_tree_spec -file CHIP.CCOPT.spec -keep_all_sdc_clocks
get_ccopt_clock_trees
ccopt_check_and_flatten_ilms_no_restore
set_ccopt_property cts_is_sdc_clock_root -pin clk true
set_ccopt_property case_analysis -pin I_CLK/PD 0
set_ccopt_property case_analysis -pin I_CLK/PU 0
set_ccopt_property case_analysis -pin I_CLK/SMT 0
create_ccopt_clock_tree -name clk -source clk -no_skew_group
set_ccopt_property source_output_max_trans -delay_corner Delay_Corner_max -early -clock_tree clk 0.500
set_ccopt_property source_output_max_trans -delay_corner Delay_Corner_min -early -clock_tree clk 0.500
set_ccopt_property source_output_max_trans -delay_corner Delay_Corner_max -late -clock_tree clk 0.500
set_ccopt_property source_output_max_trans -delay_corner Delay_Corner_min -late -clock_tree clk 0.500
set_ccopt_property source_max_capacitance -clock_tree clk 0.150
set_ccopt_property clock_period -pin clk 8.3
create_ccopt_skew_group -name clk/func_mode -sources clk -auto_sinks
set_ccopt_property include_source_latency -skew_group clk/func_mode true
set_ccopt_property extracted_from_clock_name -skew_group clk/func_mode clk
set_ccopt_property extracted_from_constraint_mode_name -skew_group clk/func_mode func_mode
set_ccopt_property extracted_from_delay_corners -skew_group clk/func_mode {Delay_Corner_max Delay_Corner_min}
check_ccopt_clock_tree_convergence
get_ccopt_property auto_design_state_for_ilms
ccopt_design
saveDesign ./DBS/CHIP_CTS.inn
redirect -quiet {set honorDomain [getAnalysisMode -honorClockDomains]} > /dev/null
timeDesign -postCTS -pathReports -drvReports -slackReports -numPaths 50 -prefix CHIP_postCTS -outDir timingReports
setOptMode -fixCap true -fixTran true -fixFanoutLoad true
optDesign -postCTS
timeDesign -postCTS -hold -pathReports -slackReports -numPaths 50 -prefix CHIP_postCTS -outDir timingReports
setOptMode -fixCap true -fixTran true -fixFanoutLoad true
optDesign -postCTS -hold
