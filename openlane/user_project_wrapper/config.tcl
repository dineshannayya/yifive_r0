# SPDX-FileCopyrightText: 2020 Efabless Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# SPDX-License-Identifier: Apache-2.0

# Base Configurations. Don't Touch
# section begin

# YOU ARE NOT ALLOWED TO CHANGE ANY VARIABLES DEFINED IN THE FIXED WRAPPER CFGS 
source $::env(CARAVEL_ROOT)/openlane/user_project_wrapper_empty/fixed_wrapper_cfgs.tcl

# YOU CAN CHANGE ANY VARIABLES DEFINED IN THE DEFAULT WRAPPER CFGS BY OVERRIDING THEM IN THIS CONFIG.TCL
source $::env(CARAVEL_ROOT)/openlane/user_project_wrapper_empty/default_wrapper_cfgs.tcl

set script_dir [file dirname [file normalize [info script]]]

set ::env(DESIGN_NAME) user_project_wrapper
set verilog_root $script_dir/../../verilog/
set lef_root $script_dir/../../lef/
set gds_root $script_dir/../../gds/
#section end

# User Configurations
#
set ::env(DESIGN_IS_CORE) 1
set ::env(FP_PDN_CORE_RING) 1


## Source Verilog Files
set ::env(VERILOG_FILES) "\
	$script_dir/../../caravel/verilog/rtl/defines.v \
	$script_dir/../../verilog/rtl/user_project_wrapper.v"

## Clock configurations
set ::env(CLOCK_PORT) "wb_clk_i"
#set ::env(CLOCK_NET) "mprj.clk"

set ::env(CLOCK_PERIOD) "10"

## Internal Macros
### Macro Placement
set ::env(FP_SIZING) "absolute"
set ::env(MACRO_PLACEMENT_CFG) $script_dir/macro.cfg

set ::env(PDN_CFG) $script_dir/pdn.tcl

#set ::env(SDC_FILE) "$script_dir/base.sdc"
#set ::env(BASE_SDC_FILE) "$script_dir/base.sdc"

set ::env(SYNTH_READ_BLACKBOX_LIB) 1

### Black-box verilog and views
set ::env(VERILOG_FILES_BLACKBOX) "\
        $script_dir/../../verilog/gl/spi_master.v \
        $script_dir/../../verilog/gl/wb_interconnect.v \
        $script_dir/../../verilog/gl/glbl_cfg.v     \
        $script_dir/../../verilog/gl/uart_i2cm_usb.v     \
	$script_dir/../../verilog/gl/sdram.v \
	$script_dir/../../verilog/gl/wb_host.v \
	$script_dir/../../verilog/gl/mbist.v \
	$script_dir/../../verilog/gl/syntacore.v \
        $script_dir/../../verilog/rtl/sram_macros/sky130_sram_2kbyte_1rw1r_32x512_8.v
	"

set ::env(EXTRA_LEFS) "\
	$lef_root/spi_master.lef \
	$lef_root/glbl_cfg.lef \
	$lef_root/wb_interconnect.lef \
	$lef_root/sdram.lef \
	$lef_root/uart_i2cm_usb.lef \
	$lef_root/wb_host.lef \
	$lef_root/mbist.lef \
	$lef_root/syntacore.lef \
        $lef_root/sky130_sram_2kbyte_1rw1r_32x512_8.lef 
	"

set ::env(EXTRA_GDS_FILES) "\
	$gds_root/spi_master.gds \
	$gds_root/glbl_cfg.gds \
	$gds_root/wb_interconnect.gds \
	$gds_root/uart_i2cm_usb.gds \
	$gds_root/sdram.gds \
	$gds_root/wb_host.gds \
	$gds_root/mbist.gds \
	$gds_root/syntacore.gds \
        $gds_root/sky130_sram_2kbyte_1rw1r_32x512_8.gds \
	"

set ::env(SYNTH_DEFINES) [list SYNTHESIS ]

set ::env(VERILOG_INCLUDE_DIRS) [glob $script_dir/../../verilog/rtl/syntacore/scr1/src/includes $script_dir/../../verilog/rtl/sdram_ctrl/src/defs ]

set ::env(GLB_RT_MAXLAYER) 5

# disable pdn check nodes becuase it hangs with multiple power domains.
# any issue with pdn connections will be flagged with LVS so it is not a critical check.
set ::env(FP_PDN_CHECK_NODES) 0

### Macro PDN Connections

set ::env(VDD_NETS) "vccd1 vccd2 vdda1 vdda2"
set ::env(GND_NETS) "vssd1 vssd2 vssa1 vssa2"

set ::env(GLB_RT_OBS) " li1   150 1300  833.1  1716.54,\
	                met1  150 1300  833.1  1716.54,\
	                met3  150 1300  833.1  1716.54,\
                        li1   950 1300 1633.1  1716.54,\
                        met1  950 1300 1633.1  1716.54,\
                        met2  950 1300 1633.1  1716.54,\
                        met3  950 1300 1633.1  1716.54,\
                        li1   150 1900  833.1  2316.54,\
                        met1  150 1900  833.1  2316.54,\
                        met3  150 1900  833.1  2316.54,\
                        li1  950  1900 1633.1  2316.54,\
                        met1 950  1900 1633.1  2316.54,\
                        met3 950  1900 1633.1  2316.54,\
                        li1  150  2900  833.1  3316.54,\
                        met1 150  2900  833.1  3316.54,\
                        met3 150  2900  833.1  3316.54,\
                        li1  950  2900 1633.1  3316.54,\
                        met1 950  2900 1633.1  3316.54,\
                        met3 950  2900 1633.1  3316.54,\
	                met5  0 0 2920 3520"
set ::env(FP_PDN_MACROS) "\
	u_spi_master vccd1 vssd1 \
	u_sdram_ctrl vccd1 vssd1 \
	u_glbl_cfg vccd1 vssd1 \
	u_riscv_top vccd1 vssd1 \
	u_tsram0_2kb vccd1 vssd1 \
	u_tsram1_2kb vccd1 vssd1 \
	u_uart_i2c_usb vccd1 vssd1 \
	u_intercon vccd1 vssd1 \
	u_wb_host vccd1 vssd1 \
	u_mbist vccd1 vssd1 \
	u_sram0_2kb vccd1 vssd1 \
	u_sram1_2kb vccd1 vssd1 \
	u_sram2_2kb vccd1 vssd1 \
	u_sram3_2kb vccd1 vssd1 \
	"


# The following is because there are no std cells in the example wrapper project.
set ::env(SYNTH_TOP_LEVEL) 1
set ::env(PL_RANDOM_GLB_PLACEMENT) 1

set ::env(PL_RESIZER_DESIGN_OPTIMIZATIONS) 0
set ::env(PL_RESIZER_TIMING_OPTIMIZATIONS) 0
set ::env(PL_RESIZER_BUFFER_INPUT_PORTS) 0
set ::env(PL_RESIZER_BUFFER_OUTPUT_PORTS) 0

set ::env(FP_PDN_ENABLE_RAILS) 0

set ::env(DIODE_INSERTION_STRATEGY) 0
set ::env(FILL_INSERTION) 0
set ::env(TAP_DECAP_INSERTION) 0
set ::env(CLOCK_TREE_SYNTH) 0

set ::env(QUIT_ON_LVS_ERROR) "0"
set ::env(QUIT_ON_MAGIC_DRC) "0"
set ::env(QUIT_ON_NEGATIVE_WNS) "0"
set ::env(QUIT_ON_SLEW_VIOLATIONS) "0"
set ::env(QUIT_ON_TIMING_VIOLATIONS) "0"
set ::env(QUIT_ON_TR_DRC) "0"


set ::env(ROUTING_OPT_ITERS) "64"


set ::env(FP_PDN_HPITCH) "90"
set ::env(FP_PDN_VPITCH) "180"
set ::env(FP_PDN_HSPACING) "6"
