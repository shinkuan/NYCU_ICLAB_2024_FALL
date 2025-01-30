
set_pg_library_mode -celltype techonly -default_area_cap 0.5 -filler_cells {FILLER1 FILLER16 FILLER2 FILLER32 FILLER4 FILLER64 FILLER8} -extraction_tech_file RC/icecaps.tch -lef_layermap layermap/lefdef.layermap.libgen -power_pins {VCC 1.8} -ground_pins GND
generate_pg_library -output power_log
set_pg_library_mode -celltype stdcells -filler_cells {FILLER1 FILLER16 FILLER2 FILLER32 FILLER4 FILLER64 FILLER8} -extraction_tech_file RC/icecaps.tch -lef_layermap layermap/lefdef.layermap.libgen -power_pins {VCC 1.8} -ground_pins GND -current_distribution propagation
generate_pg_library -output power_log
set_rail_analysis_mode -method static -power_switch_eco false -accuracy xd -power_grid_library {power_log/techonly.cl power_log/stdcells.cl} -process_techgen_em_rules false -enable_rlrp_analysis false -vsrc_search_distance 50 -ignore_shorts false -enable_manufacturing_effects false -report_via_current_direction false
setDrawView place
create_power_pads -net VCC -auto_fetch
setDrawView place
create_power_pads -net VCC -vsrc_file power_log/CHIP_VCC.pp
create_power_pads -net GND -auto_fetch
setDrawView place
create_power_pads -net GND -vsrc_file power_log/CHIP_GND.pp
set_pg_nets -net VCC -voltage 1.8 -threshold 1.7
set_pg_nets -net GND -voltage 0 -threshold 0.1
set_rail_analysis_domain -name PD -pwrnets { VCC} -gndnets { GND}
set_power_data -reset
set_power_data -format current -scale 1 {power_log/static_VCC.ptiavg power_log/static_GND.ptiavg}
set_power_pads -reset
set_power_pads -net VCC -format xy -file power_log/CHIP_VCC.pp
set_power_pads -net GND -format xy -file power_log/CHIP_GND.pp
set_package -reset
set_package -spice {} -mapping {}
set_net_group -reset
set_advanced_rail_options -reset
analyze_rail -type domain -results_directory power_log PD
setLayerPreference powerNet -color {#0000FF #0010DE #0020BD #00319C #00417B #00525A #006239 #007318 #088300 #299400 #4AA400 #6AB400 #8BC500 #ACD500 #CDE600 #EEF600 #FFF900 #FFED00 #FFE200 #FFD600 #FFCB00 #FFBF00 #FFB400 #FFA800 #FF9500 #FF8000 #FF6A00 #FF5500 #FF4000 #FF2A00 #FF1500 #FF0000}
set_power_rail_display -plot none
setLayerPreference powerNet -color {#0000ff #0010de #0020bd #00319c #00417b #00525a #006239 #007318 #088300 #299400 #4aa400 #6ab400 #8bc500 #acd500 #cde600 #eef600 #fff900 #ffed00 #ffe200 #ffd600 #ffcb00 #ffbf00 #ffb400 #ffa800 #ff9500 #ff8000 #ff6a00 #ff5500 #ff4000 #ff2a00 #ff1500 #ff0000}
set_power_rail_display -enable_voltage_sources 0
set_power_rail_display -enable_percentage_range 0
fit
::read_power_rail_results -power_db power_log/power.db -rail_directory power_log/PD_25C_avg_1 -instance_voltage_window { timing  whole  } -instance_voltage_method {  worst  best  avg  worstavg worstslidingavg bestslidingavg }
set_power_rail_display -plot none
setLayerPreference powerNet -color {#0000ff #0010de #0020bd #00319c #00417b #00525a #006239 #007318 #088300 #299400 #4aa400 #6ab400 #8bc500 #acd500 #cde600 #eef600 #fff900 #ffed00 #ffe200 #ffd600 #ffcb00 #ffbf00 #ffb400 #ffa800 #ff9500 #ff8000 #ff6a00 #ff5500 #ff4000 #ff2a00 #ff1500 #ff0000}
set_power_rail_display -plot ir
setLayerPreference powerNet -color {#0000ff #0010de #0020bd #00319c #00417b #00525a #006239 #007318 #088300 #299400 #4aa400 #6ab400 #8bc500 #acd500 #cde600 #eef600 #fff900 #ffed00 #ffe200 #ffd600 #ffcb00 #ffbf00 #ffb400 #ffa800 #ff9500 #ff8000 #ff6a00 #ff5500 #ff4000 #ff2a00 #ff1500 #ff0000}
set_power_rail_display -enable_result_browser 1
set_power_rail_display -enable_result_browser 0
