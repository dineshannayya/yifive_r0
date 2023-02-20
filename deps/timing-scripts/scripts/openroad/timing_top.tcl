source $::env(TIMING_ROOT)/env/common.tcl
source $::env(TIMING_ROOT)/env/caravel_spef_mapping-mpw7.tcl

if { [file exists $::env(CUP_ROOT)/env/spef-mapping.tcl] } {
    source $::env(CUP_ROOT)/env/spef-mapping.tcl
} else {
    puts "WARNING no user project spef mapping file found"
}

source $::env(TIMING_ROOT)/env/$::env(LIB_CORNER).tcl

set libs [split [regexp -all -inline {\S+} $libs]]
set verilogs [split [regexp -all -inline {\S+} $verilogs]]


foreach liberty $libs {
}

foreach liberty $libs {
    run_puts "read_liberty $liberty"
}

foreach verilog $verilogs {
    run_puts "read_verilog $verilog"
}

run_puts "link_design caravel"

if { $::env(SPEF_OVERWRITE) ne "" } {
    puts "overwriting spef from "
    puts "$spef to"
    puts "$::env(SPEF_OVERWRITE)"
    eval set spef $::env(SPEF_OVERWRITE)
}

set missing_spefs 0
set missing_spefs_list ""
run_puts "read_spef $spef"
foreach key [array names spef_mapping] {
    set spef_file $spef_mapping($key)
    if { [file exists $spef_file] } {
        run_puts "read_spef -path $key $spef_mapping($key)"
    } else {
        set missing_spefs 1
        set missing_spefs_list "$missing_spefs_list $key"
        puts "$spef_file not found"
        if { $::env(ALLOW_MISSING_SPEF) } {
            puts "WARNING ALLOW_MISSING_SPEF set to 1. continuing"
        } else {
            exit 1
        }
    }
}

#set sdc $::env(CARAVEL_ROOT)/signoff/caravel/caravel.sdc
set sdc $::env(CUP_ROOT)/sdc/caravel.sdc
run_puts "read_sdc -echo $sdc"

set logs_path "$::env(PROJECT_ROOT)/signoff/caravel/openlane-signoff/timing/$::env(RCX_CORNER)/$::env(LIB_CORNER)"
file mkdir [file dirname $logs_path]
 
    set spi_wb_port [get_pins {mprj/u_spi_master/wbd_adr_i[*]}]
	set spi_wb_port [concat $spi_wb_port [get_pins {mprj/u_spi_master/wbd_stb_i}]]
	set spi_wb_port [concat $spi_wb_port [get_pins {mprj/u_spi_master/wbd_dat_i[*]}]]
	set spi_wb_port [concat $spi_wb_port [get_pins {mprj/u_spi_master/wbd_sel_i[*]}]]
	set spi_wb_port [concat $spi_wb_port [get_pins {mprj/u_spi_master/wbd_we_i}]]
	set spi_wb_port [concat $spi_wb_port [get_pins {mprj/u_spi_master/wbd_ack_o}]]
	set spi_wb_port [concat $spi_wb_port [get_pins {mprj/u_spi_master/wbd_dat_o[*]}]]
	set spi_wb_port [concat $spi_wb_port [get_pins {mprj/u_spi_master/wbd_err_o}]]

    set riscv_imem_wb_port [get_pins {mprj/u_riscv_top/wbd_imem_adr_o[*]}]
	set riscv_imem_wb_port [concat $riscv_imem_wb_port [get_pins {mprj/u_riscv_top/wbd_imem_stb_o}]]
	set riscv_imem_wb_port [concat $riscv_imem_wb_port [get_pins {mprj/u_riscv_top/wbd_imem_dat_o[*]}]]
	set riscv_imem_wb_port [concat $riscv_imem_wb_port [get_pins {mprj/u_riscv_top/wbd_imem_sel_o[*]}]]
	set riscv_imem_wb_port [concat $riscv_imem_wb_port [get_pins {mprj/u_riscv_top/wbd_imem_we_o}]]
	set riscv_imem_wb_port [concat $riscv_imem_wb_port [get_pins {mprj/u_riscv_top/wbd_imem_ack_i}]]
	set riscv_imem_wb_port [concat $riscv_imem_wb_port [get_pins {mprj/u_riscv_top/wbd_imem_dat_i[*]}]]
	set riscv_imem_wb_port [concat $riscv_imem_wb_port [get_pins {mprj/u_riscv_top/wbd_imem_err_i}]]

    set riscv_dmem_wb_port [get_pins {mprj/u_riscv_top/wbd_dmem_adr_o[*]}]
	set riscv_dmem_wb_port [concat $riscv_dmem_wb_port [get_pins {mprj/u_riscv_top/wbd_dmem_stb_o}]]
	set riscv_dmem_wb_port [concat $riscv_dmem_wb_port [get_pins {mprj/u_riscv_top/wbd_dmem_dat_o[*]}]]
	set riscv_dmem_wb_port [concat $riscv_dmem_wb_port [get_pins {mprj/u_riscv_top/wbd_dmem_sel_o[*]}]]
	set riscv_dmem_wb_port [concat $riscv_dmem_wb_port [get_pins {mprj/u_riscv_top/wbd_dmem_we_o}]]
	set riscv_dmem_wb_port [concat $riscv_dmem_wb_port [get_pins {mprj/u_riscv_top/wbd_dmem_ack_i}]]
	set riscv_dmem_wb_port [concat $riscv_dmem_wb_port [get_pins {mprj/u_riscv_top/wbd_dmem_dat_i[*]}]]
	set riscv_dmem_wb_port [concat $riscv_dmem_wb_port [get_pins {mprj/u_riscv_top/wbd_dmem_err_i}]]

    ##############################################################
    # Display User Project wrapper SPI Interface Timing
    ##############################################################
	run_puts_create_logs  "######### MPRJ-SPI Wishbone Interface Min Timing ########## " "${logs_path}-mprj-spi-min.rpt"

	foreach pin $spi_wb_port {
       set pin_name [get_full_name $pin]
       set all_timing_paths [find_timing_paths -path_delay min -through $pin_name -group_count 1 ]
          foreach path $all_timing_paths {
              set slack [get_property $path slack]
              set status [format "$pin_name:%.4f" $slack]
              run_puts_logs_append "$status" "${logs_path}-mprj-spi-min.rpt"
          }
    }

	run_puts_create_logs  "######### MPRJ-SPI Wishbone Interface Max Timing ########## " "${logs_path}-mprj-spi-max.rpt"

	foreach pin $spi_wb_port {
       set pin_name [get_full_name $pin]
       set all_timing_paths [find_timing_paths -path_delay max -through $pin_name -group_count 1 ]
          foreach path $all_timing_paths {
              set slack [get_property $path slack]
              set status [format "$pin_name:%.4f" $slack]
              run_puts_logs_append "$status" "${logs_path}-mprj-spi-max.rpt"
          }
    }


    ##############################################################
    # Display User Project wrapper RISCV IMEM Interface Timing
    ##############################################################
	run_puts_create_logs  "######### MPRJ-IMEM Wishbone Interface Min Timing ########## " "${logs_path}-mprj-imem-min.rpt"

	foreach pin $riscv_imem_wb_port {
       set pin_name [get_full_name $pin]
       set all_timing_paths [find_timing_paths -path_delay min -through $pin_name -group_count 1 ]
          foreach path $all_timing_paths {
              set slack [get_property $path slack]
              set status [format "$pin_name:%.4f" $slack]
              run_puts_logs_append "$status" "${logs_path}-mprj-imem-min.rpt"
          }
    }

	run_puts_create_logs  "######### MPRJ-IMEM Wishbone Interface Max Timing ########## " "${logs_path}-mprj-imem-max.rpt"

	foreach pin $riscv_imem_wb_port {
       set pin_name [get_full_name $pin]
       set all_timing_paths [find_timing_paths -path_delay max -through $pin_name -group_count 1 ]
          foreach path $all_timing_paths {
              set slack [get_property $path slack]
              set status [format "$pin_name:%.4f" $slack]
              run_puts_logs_append "$status" "${logs_path}-mprj-imem-max.rpt"
          }
    }

    ##############################################################
    # Display User Project wrapper RISCV DMEM Interface Timing
    ##############################################################
	run_puts_create_logs  "######### MPRJ-DMEM Wishbone Interface Min Timing ########## " "${logs_path}-mprj-dmem-min.rpt"

	foreach pin $riscv_dmem_wb_port {
       set pin_name [get_full_name $pin]
       set all_timing_paths [find_timing_paths -path_delay min -through $pin_name -group_count 1 ]
          foreach path $all_timing_paths {
              set slack [get_property $path slack]
              set status [format "$pin_name:%.4f" $slack]
              run_puts_logs_append "$status" "${logs_path}-mprj-dmem-min.rpt"
          }
    }

	run_puts_create_logs  "######### MPRJ-DMEM Wishbone Interface Max Timing ########## " "${logs_path}-mprj-dmem-max.rpt"

	foreach pin $riscv_dmem_wb_port {
       set pin_name [get_full_name $pin]
       set all_timing_paths [find_timing_paths -path_delay max -through $pin_name -group_count 1 ]
          foreach path $all_timing_paths {
              set slack [get_property $path slack]
              set status [format "$pin_name:%.4f" $slack]
              run_puts_logs_append "$status" "${logs_path}-mprj-dmem-max.rpt"
          }
    }

   ########################END OF MPRJ LOCAL TIMING ANALYSIS ############################


run_puts_logs "report_checks \\
    -path_delay min \\
    -format full_clock_expanded \\
    -fields {slew cap input_pins nets fanout} \\
    -no_line_splits \\
    -group_count 100 \\
    -slack_max 10 \\
    -digits 4 \\
    -endpoint_count 10 \\
    -unique_paths_to_endpoint \\
    "\
    "${logs_path}-min.rpt"

run_puts_logs "report_checks \\
    -path_delay max \\
    -format full_clock_expanded \\
    -fields {slew cap input_pins nets fanout} \\
    -no_line_splits \\
    -group_count 100 \\
    -slack_max 10 \\
    -digits 4 \\
    -endpoint_count 10 \\
    -unique_paths_to_endpoint \\
    "\
    "${logs_path}-max.rpt"

run_puts_logs "report_checks \\
    -path_delay min \\
    -format full_clock_expanded \\
    -fields {slew cap input_pins nets fanout} \\
    -no_line_splits \\
    -path_group hk_serial_clk \\
    -group_count 100 \\
    -slack_max 10 \\
    -digits 4 \\
    -unique_paths_to_endpoint \\
    "\
    "${logs_path}-hk_serial_clk-min.rpt"


run_puts_logs "report_checks \\
    -path_delay max \\
    -format full_clock_expanded \\
    -fields {slew cap input_pins nets fanout} \\
    -no_line_splits \\
    -path_group hk_serial_clk \\
    -group_count 100 \\
    -slack_max 10 \\
    -digits 4 \\
    -unique_paths_to_endpoint \\
    "\
    "${logs_path}-hk_serial_clk-max.rpt"

run_puts_logs "report_checks \\
    -path_delay max \\
    -format full_clock_expanded \\
    -fields {slew cap input_pins nets fanout} \\
    -no_line_splits \\
    -path_group hkspi_clk \\
    -group_count 100 \\
    -slack_max 10 \\
    -digits 4 \\
    -unique_paths_to_endpoint \\
    "\
    "${logs_path}-hkspi_clk-max.rpt"

run_puts_logs "report_checks \\
    -path_delay min \\
    -format full_clock_expanded \\
    -fields {slew cap input_pins nets fanout} \\
    -no_line_splits \\
    -path_group hkspi_clk \\
    -group_count 100 \\
    -slack_max 10 \\
    -digits 4 \\
    -unique_paths_to_endpoint \\
    "\
    "${logs_path}-hkspi_clk-min.rpt"

run_puts_logs "report_checks \\
    -path_delay min \\
    -format full_clock_expanded \\
    -fields {slew cap input_pins nets fanout} \\
    -no_line_splits \\
    -path_group clk \\
    -group_count 100 \\
    -slack_max 10 \\
    -digits 4 \\
    -unique_paths_to_endpoint \\
    "\
    "${logs_path}-clk-min.rpt"
        
run_puts_logs "report_checks \\
    -path_delay max \\
    -format full_clock_expanded \\
    -fields {slew cap input_pins nets fanout} \\
    -no_line_splits \\
    -path_group clk \\
    -group_count 100 \\
    -slack_max 10 \\
    -digits 4 \\
    -unique_paths_to_endpoint \\
    "\
    "${logs_path}-clk-max.rpt"

run_puts_logs "report_checks \\
    -path_delay min \\
    -through [get_cells soc] \\
    -format full_clock_expanded \\
    -fields {slew cap input_pins nets fanout} \\
    -no_line_splits \\
    -group_count 100 \\
    -slack_max 10 \\
    -digits 4 \\
    -unique_paths_to_endpoint \\
    "\
    "${logs_path}-soc-min.rpt"

run_puts_logs "report_checks \\
    -path_delay max \\
    -through [get_cells soc] \\
    -format full_clock_expanded \\
    -fields {slew cap input_pins nets fanout} \\
    -no_line_splits \\
    -group_count 100 \\
    -slack_max 10 \\
    -digits 4 \\
    -unique_paths_to_endpoint \\
    "\
    "${logs_path}-soc-max.rpt"

run_puts_logs "report_checks \\
    -path_delay min \\
    -through [get_cells mprj] \\
    -format full_clock_expanded \\
    -fields {slew cap input_pins nets fanout} \\
    -no_line_splits \\
    -group_count 100 \\
    -slack_max 40 \\
    -digits 4 \\
    -unique_paths_to_endpoint \\
    "\
    "${logs_path}-mprj-min.rpt"

run_puts_logs "report_checks \\
    -path_delay max \\
    -through [get_cells mprj] \\
    -format full_clock_expanded \\
    -fields {slew cap input_pins nets fanout} \\
    -no_line_splits \\
    -group_count 100 \\
    -slack_max 40 \\
    -digits 4 \\
    -unique_paths_to_endpoint \\
    "\
    "${logs_path}-mprj-max.rpt"

run_puts "report_parasitic_annotation -report_unannotated > ${logs_path}-unannotated.log"
if { $missing_spefs } {
    puts "there are missing spefs. check the log for ALLOW_MISSING_SPEF"
    puts "the following macros don't have spefs"
    foreach spef $missing_spefs_list {
        puts "$spef"
    }
}
report_parasitic_annotation 
puts "you may want to edit sdc: $sdc to change i/o constraints"
puts "check $logs_path"
