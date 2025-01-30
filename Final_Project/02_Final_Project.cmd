#====================================================================
#  Set Placement Blockage & Placement Std Cell
#====================================================================
setPlaceMode -prerouteAsObs {2 3}
setPlaceMode -fp false
place_design -noPrePlaceOpt

#====================================================================
#  Check Timing
#====================================================================
timeDesign -preCTS -pathReports -drvReports -slackReports -numPaths 50 -prefix CHIP_preCTS -outDir timingReports

#=================
#  Optimize
#=================
setOptMode -fixCap true -fixTran true -fixFanoutLoad true
optDesign -preCTS

saveDesign ./DBS/CHIP_placement.inn


#====================================================================
#  Clock Tree Synthesis (CTS)
#====================================================================
update_constraint_mode -name func_mode -sdc_files CHIP_cts.sdc
set_ccopt_property update_io_latency false
create_ccopt_clock_tree_spec -file CHIP.CCOPT.spec -keep_all_sdc_clocks
source CHIP.CCOPT.spec
ccopt_design


#=================
#  Optimize
#=================
# === check setup timing ===
timeDesign -postCTS -pathReports -drvReports -slackReports -numPaths 50 -prefix CHIP_postCTS -outDir timingReports

setOptMode -fixCap true -fixTran true -fixFanoutLoad true
optDesign -postCTS

# === check hold timing ===
timeDesign -postCTS -hold -pathReports -slackReports -numPaths 50 -prefix CHIP_postCTS -outDir timingReports

setOptMode -fixCap true -fixTran true -fixFanoutLoad true
optDesign -postCTS -hold

saveDesign ./DBS/CHIP_CTS.inn
#====================================================================
#  Add PAD Filler  (No pad in Final Project, just skip)
#====================================================================
# addIoFiller -cell EMPTY16D -prefix IOFILLER
# addIoFiller -cell EMPTY8D -prefix IOFILLER
# addIoFiller -cell EMPTY4D -prefix IOFILLER
# addIoFiller -cell EMPTY2D -prefix IOFILLER
# addIoFiller -cell EMPTY1D -prefix IOFILLER -fillAnyGap
