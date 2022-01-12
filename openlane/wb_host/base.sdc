###############################################################################
# Created by write_sdc
# Sat Nov 13 02:44:28 2021
###############################################################################
current_design wb_host
###############################################################################
# Timing Constraints
###############################################################################
create_clock -name wbm_clk_i -period 10.0000 [get_ports {wbm_clk_i}]
create_clock -name wbs_clk_i -period 10.0000 [get_ports {wbs_clk_i}]

set_clock_transition 0.1500 [all_clocks]
set_clock_uncertainty -setup 0.2500 [all_clocks]
set_clock_uncertainty -hold 0.2500 [all_clocks]

set_clock_groups -name async_clock -asynchronous \
 -group [get_clocks {wbs_clk_i}]\
 -group [get_clocks {wbm_clk_i}] -comment {Async Clock group}

### ClkSkew Adjust
set_case_analysis 0 [get_ports {cfg_cska_wh[0]}]
set_case_analysis 0 [get_ports {cfg_cska_wh[1]}]
set_case_analysis 0 [get_ports {cfg_cska_wh[2]}]
set_case_analysis 0 [get_ports {cfg_cska_wh[3]}]


set_max_delay   3.5 -from [get_ports {wbd_clk_int}]
set_max_delay   2 -to   [get_ports {wbd_clk_wh}]
set_max_delay 3.5 -from wbd_clk_int -to wbd_clk_wh

### WBM I/F
#Strobe is registered inside the wb_host before generating chip select
# So wbm_adr_i  wbm_we_i wbm_sel_i wbm_dat_i are having 2 cycle setup
set_multicycle_path -setup  -from [get_ports {wbm_adr_i[*]}] 2
set_multicycle_path -setup  -from [get_ports {wbm_cyc_i}]  2
set_multicycle_path -setup  -from [get_ports {wbm_dat_i[*]}] 2
set_multicycle_path -setup  -from [get_ports {wbm_sel_i[*]}] 2
set_multicycle_path -setup  -from [get_ports {wbm_we_i}] 2

set_multicycle_path -hold  -from [get_ports {wbm_adr_i[*]}] 2
set_multicycle_path -hold  -from [get_ports {wbm_cyc_i}]  2
set_multicycle_path -hold  -from [get_ports {wbm_dat_i[*]}] 2
set_multicycle_path -hold  -from [get_ports {wbm_sel_i[*]}] 2
set_multicycle_path -hold  -from [get_ports {wbm_we_i}] 2

#
set_input_delay 5.0000 -clock [get_clocks {wbm_clk_i}] -max -add_delay [get_ports {wbm_rst_i}]
set_input_delay 5.0000 -clock [get_clocks {wbm_clk_i}] -max -add_delay [get_ports {wbm_stb_i}]

set_input_delay 1.0000 -clock [get_clocks {wbm_clk_i}] -min -add_delay [get_ports {wbm_rst_i}]
set_input_delay 1.0000 -clock [get_clocks {wbm_clk_i}] -min -add_delay [get_ports {wbm_stb_i}]

set_output_delay -max 5.0000 -clock [get_clocks {wbm_clk_i}] -add_delay [get_ports {wbm_ack_o}]
set_output_delay -max 5.0000 -clock [get_clocks {wbm_clk_i}] -add_delay [get_ports {wbm_dat_o[*]}]
set_output_delay -max 5.0000 -clock [get_clocks {wbm_clk_i}] -add_delay [get_ports {wbm_err_o}]

set_output_delay -min 1.0000 -clock [get_clocks {wbm_clk_i}] -add_delay [get_ports {wbm_ack_o}]
set_output_delay -min 1.0000 -clock [get_clocks {wbm_clk_i}] -add_delay [get_ports {wbm_dat_o[*]}]
set_output_delay -min 1.0000 -clock [get_clocks {wbm_clk_i}] -add_delay [get_ports {wbm_err_o}]
# WBS I/F
set_input_delay -max 6.0000 -clock [get_clocks {wbs_clk_i}] -add_delay [get_ports {wbs_ack_i}]
set_input_delay -max 6.0000 -clock [get_clocks {wbs_clk_i}] -add_delay [get_ports {wbs_dat_i[*]}]

set_input_delay -min 2.0000 -clock [get_clocks {wbs_clk_i}] -add_delay [get_ports {wbs_ack_i}]
set_input_delay -min 2.0000 -clock [get_clocks {wbs_clk_i}] -add_delay [get_ports {wbs_dat_i[*]}]

set_output_delay -max 4.5000 -clock [get_clocks {wbs_clk_i}] -add_delay [get_ports {wbs_adr_o[*]}]
set_output_delay -max 4.5000 -clock [get_clocks {wbs_clk_i}] -add_delay [get_ports {wbs_cyc_o}]
set_output_delay -max 4.5000 -clock [get_clocks {wbs_clk_i}] -add_delay [get_ports {wbs_dat_o[*]}]
set_output_delay -max 4.5000 -clock [get_clocks {wbs_clk_i}] -add_delay [get_ports {wbs_sel_o[*]}]
set_output_delay -max 4.5000 -clock [get_clocks {wbs_clk_i}] -add_delay [get_ports {wbs_stb_o}]
set_output_delay -max 4.5000 -clock [get_clocks {wbs_clk_i}] -add_delay [get_ports {wbs_we_o}]

set_output_delay -min 1.0000 -clock [get_clocks {wbs_clk_i}] -add_delay [get_ports {wbs_adr_o[*]}]
set_output_delay -min 1.0000 -clock [get_clocks {wbs_clk_i}] -add_delay [get_ports {wbs_cyc_o}]
set_output_delay -min 1.0000 -clock [get_clocks {wbs_clk_i}] -add_delay [get_ports {wbs_dat_o[*]}]
set_output_delay -min 1.0000 -clock [get_clocks {wbs_clk_i}] -add_delay [get_ports {wbs_sel_o[*]}]
set_output_delay -min 1.0000 -clock [get_clocks {wbs_clk_i}] -add_delay [get_ports {wbs_stb_o}]
set_output_delay -min 1.0000 -clock [get_clocks {wbs_clk_i}] -add_delay [get_ports {wbs_we_o}]

###############################################################################
# Environment
###############################################################################
set_driving_cell -lib_cell sky130_fd_sc_hd__inv_8 -pin $::env(SYNTH_DRIVING_CELL_PIN) [all_inputs]
set cap_load [expr $::env(SYNTH_CAP_LOAD) / 1000.0]
puts "\[INFO\]: Setting load to: $cap_load"
set_load  $cap_load [all_outputs]

set ::env(SYNTH_TIMING_DERATE) 0.05
puts "\[INFO\]: Setting timing derate to: [expr {$::env(SYNTH_TIMING_DERATE) * 10}] %"
set_timing_derate -early [expr {1-$::env(SYNTH_TIMING_DERATE)}]
set_timing_derate -late [expr {1+$::env(SYNTH_TIMING_DERATE)}]
###############################################################################
# Design Rules
###############################################################################

#disable clock gating check at static clock select pins
set_false_path -through [get_pins u_cpu_ref_sel.u_mux/S]
set_false_path -through [get_pins u_cpu_clk_sel.u_mux/S]
set_false_path -through [get_pins u_wbs_clk_sel.u_mux/S]
set_false_path -through [get_pins u_usb_clk_sel.u_mux/S]
