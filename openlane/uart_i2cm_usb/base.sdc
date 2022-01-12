###############################################################################
# Created by write_sdc
# Sat Nov 13 06:42:06 2021
###############################################################################
current_design uart_i2c_usb_top
###############################################################################
# Timing Constraints
###############################################################################
create_clock -name app_clk -period 10.0000 [get_ports {app_clk}]
create_clock -name line_clk -period 100.0000 [get_pins {u_uart_core.u_lineclk_buf.u_mux/X}]
create_clock -name usb_clk -period 100.0000 [get_ports {usb_clk}]

set_clock_transition 0.1500 [all_clocks]
set_clock_uncertainty -setup 0.2500 [all_clocks]
set_clock_uncertainty -hold 0.2500 [all_clocks]



set_clock_groups -name async_clock -asynchronous \
 -group [get_clocks {app_clk}]\
 -group [get_clocks {usb_clk}]\
 -group [get_clocks {line_clk}] -comment {Async Clock group}

### ClkSkew Adjust
set_case_analysis 0 [get_ports {cfg_cska_uart[0]}]
set_case_analysis 0 [get_ports {cfg_cska_uart[1]}]
set_case_analysis 0 [get_ports {cfg_cska_uart[2]}]
set_case_analysis 0 [get_ports {cfg_cska_uart[3]}]


set_max_delay 5 -from [get_ports {wbd_clk_int}]
set_max_delay 5 -to   [get_ports {wbd_clk_uart}]
set_max_delay 5 -from wbd_clk_int -to wbd_clk_uart



set_input_delay 3.0000 -clock [get_clocks {app_clk}] -add_delay [get_ports {i2c_rstn}]
set_input_delay 3.0000 -clock [get_clocks {app_clk}] -add_delay [get_ports {uart_rstn}]
set_input_delay 3.0000 -clock [get_clocks {app_clk}] -add_delay [get_ports {usb_rstn}]


set_input_delay  -max 6.0000 -clock [get_clocks {app_clk}] -add_delay [get_ports {reg_addr[*]}]
set_input_delay  -max 6.0000 -clock [get_clocks {app_clk}] -add_delay [get_ports {reg_be[*]}]
set_input_delay  -max 6.0000 -clock [get_clocks {app_clk}] -add_delay [get_ports {reg_cs}]
set_input_delay  -max 6.0000 -clock [get_clocks {app_clk}] -add_delay [get_ports {reg_wdata[*]}]
set_input_delay  -max 6.0000 -clock [get_clocks {app_clk}] -add_delay [get_ports {reg_wr}]

set_input_delay  -min 2.0000 -clock [get_clocks {app_clk}] -add_delay [get_ports {reg_addr[*]}]
set_input_delay  -min 2.0000 -clock [get_clocks {app_clk}] -add_delay [get_ports {reg_be[*]}]
set_input_delay  -min 2.0000 -clock [get_clocks {app_clk}] -add_delay [get_ports {reg_cs}]
set_input_delay  -min 2.0000 -clock [get_clocks {app_clk}] -add_delay [get_ports {reg_wdata[*]}]
set_input_delay  -min 2.0000 -clock [get_clocks {app_clk}] -add_delay [get_ports {reg_wr}]


set_output_delay -max 6.0000 -clock [get_clocks {app_clk}] -add_delay [get_ports {reg_ack}]
set_output_delay -max 6.0000 -clock [get_clocks {app_clk}] -add_delay [get_ports {reg_rdata[*]}]

set_output_delay -min 1.0000 -clock [get_clocks {app_clk}] -add_delay [get_ports {reg_ack}]
set_output_delay -min 1.0000 -clock [get_clocks {app_clk}] -add_delay [get_ports {reg_rdata[*]}]

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
