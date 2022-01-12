//////////////////////////////////////////////////////////////////////////////
// SPDX-FileCopyrightText: 2021 , Dinesh Annayya                          
// 
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0
// SPDX-FileContributor: Created by Dinesh Annayya <dinesha@opencores.org>
//
//////////////////////////////////////////////////////////////////////
////                                                              ////
////  Digital core                                                ////
////                                                              ////
////  This file is part of the YIFive cores project               ////
////  https://github.com/dineshannayya/yifive_r0.git              ////
////  http://www.opencores.org/cores/yifive/                      ////
////                                                              ////
////  Description                                                 ////
////      This is digital core and integrate all the main block   ////
////      here.  Following block are integrated here              ////
////      1. Risc V Core                                          ////
////      2. Quad SPI Master                                      ////
////      3. Wishbone Cross Bar                                   ////
////      4. UART                                                 ////
////      5, USB 1.1                                              ////
////      6. I2C Master                                           ////
////      7. SRAM 2KB                                             ////
////                                                              ////
////  To Do:                                                      ////
////    nothing                                                   ////
////                                                              ////
////  Author(s):                                                  ////
////      - Dinesh Annayya, dinesha@opencores.org                 ////
////                                                              ////
////  Revision :                                                  ////
////    0.1 - 16th Feb 2021, Dinesh A                             ////
////          Initial integration with Risc-V core +              ////
////          Wishbone Cross Bar + SPI  Master                    ////
////    0.2 - 17th June 2021, Dinesh A                            ////
////        1. In risc core, wishbone and core domain is          ////
////           created                                            ////
////        2. cpu and rtc clock are generated in glbl reg block  ////
////        3. in wishbone interconnect:- Stagging flop are added ////
////           at interface to break wishbone timing path         ////
////        4. buswidth warning are fixed inside spi_master       ////
////        modified rtl files are                                ////
////           verilog/rtl/digital_core/src/digital_core.sv       ////
////           verilog/rtl/digital_core/src/glbl_cfg.sv           ////
////           verilog/rtl/lib/wb_stagging.sv                     ////
////           verilog/rtl/syntacore/scr1/src/top/scr1_dmem_wb.sv ////
////           verilog/rtl/syntacore/scr1/src/top/scr1_imem_wb.sv ////
////           verilog/rtl/syntacore/scr1/src/top/scr1_top_wb.sv  ////
////           verilog/rtl/user_project_wrapper.v                 ////
////           verilog/rtl/wb_interconnect/src/wb_interconnect.sv ////
////           verilog/rtl/spi_master/src/spim_clkgen.sv          ////
////           verilog/rtl/spi_master/src/spim_ctrl.sv            ////
////    0.3 - 20th June 2021, Dinesh A                            ////
////           1. uart core is integrated                         ////
////           2. 3rd Slave ported added to wishbone interconnect ////
////    0.4 - 25th June 2021, Dinesh A                            ////
////          Moved the pad logic inside sdram,spi,uart block to  ////
////          avoid logic at digital core level                   ////
////    0.5 - 25th June 2021, Dinesh A                            ////
////          Since carvel gives only 16MB address space for user ////
////          space, we have implemented indirect address select  ////
////          with 8 bit bank select given inside wb_host         ////
////          core Address = {Bank_Sel[7:0], Wb_Address[23:0]     ////
////          caravel user address space is                       ////
////          0x3000_0000 to 0x30FF_FFFF                          ////
////    0.6 - 27th June 2021, Dinesh A                            ////
////          Digital core level tie are moved inside IP to avoid ////
////          power hook up at core level                         ////
////          u_risc_top - test_mode & test_rst_n                 ////
////          u_intercon - s*_wbd_err_i                           ////
////          unused wb_cti_i is removed from u_sdram_ctrl        ////
////    0.7 - 28th June 2021, Dinesh A                            ////
////          wb_interconnect master port are interchanged for    ////
////          better physical placement.                          ////
////          m0 - External HOST                                  ////
////          m1 - RISC IMEM                                      ////
////          m2 - RISC DMEM                                      ////
////    0.8 - 6th July 2021, Dinesh A                             ////
////          For Better SDRAM Interface timing we have taping    ////
////          sdram_clock goint to io_out[29] directly from       ////
////          global register block, this help in better SDRAM    ////
////          interface timing control                            ////
////    0.9 - 7th July 2021, Dinesh A                             ////
////          Removed 2 Unused port connection io_in[31:30] to    ////
////          spi_master to avoid lvs issue                       ////
////    1.0 - 28th July 2021, Dinesh A                            ////
////          i2cm integrated part of uart_i2cm module,           ////
////          due to number of IO pin limitation,                 ////
////          Only UART OR I2C selected based on config mode      ////
////    1.1 - 1st Aug 2021, Dinesh A                              ////
////          usb1.1 host integrated part of uart_i2cm_usb module,////
////          due to number of IO pin limitation,                 ////
////          Only UART/I2C/USB selected based on config mode     ////
////    1.2 - Oct 27, 2021, Dinesh A                              ////
////          For better power routing, clock skew block are moved////
////          corresponding destination module like wb_host, spi  ////
////          sdram                                               ////
////    1.3   Oct 28, 2021, Dinesh A                              ////
////          Modification for MPW-3 Shuttle                      ////
////    1.4   Oct 28, 2021, Dinesh A                              ////
////          Bug fix: uart_i2c_usb byte_select width changed     ////
////          from 1 to 4                                         ////
////    1.5   Nov 12, 2021, Dinesh A                              ////
////          2KB SRAM Interface added to RISC Core               ////
////    1.6   Nov 14, 2021, Dinesh A                              ////
////          Major bug, clock divider inside the wb_host reset   ////
////          connectivity open is fixed                          ////
////    1.7   Nov 15, 2021, Dinesh A                              ////
////           Bug fix in clk_ctrl High/Low counter width         ////
////           Removed sram_clock                                 ////
////    1.8   Dec 22, 2021, Dinesh A                              ////
////          software Reg 1/2/3 added in glbl reg 6/7/8          ////
////    1.9   Dec 23, 2021, Dinesh A                              ////
////          8KB SRAM+ MBIST and 4KB TSRAM ADDED                 ////
////    2.0   Jan 07, 2022, Dinesh A                              ////
////          1. TCM Bug fix                                      ////
////          2. Soft Reboot with LA[0]                           ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2000 Authors and OPENCORES.ORG                 ////
////                                                              ////
//// This source file may be used and distributed without         ////
//// restriction provided that this copyright statement is not    ////
//// removed from the file and that any derivative work contains  ////
//// the original copyright notice and the associated disclaimer. ////
////                                                              ////
//// This source file is free software; you can redistribute it   ////
//// and/or modify it under the terms of the GNU Lesser General   ////
//// Public License as published by the Free Software Foundation; ////
//// either version 2.1 of the License, or (at your option) any   ////
//// later version.                                               ////
////                                                              ////
//// This source is distributed in the hope that it will be       ////
//// useful, but WITHOUT ANY WARRANTY; without even the implied   ////
//// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      ////
//// PURPOSE.  See the GNU Lesser General Public License for more ////
//// details.                                                     ////
////                                                              ////
//// You should have received a copy of the GNU Lesser General    ////
//// Public License along with this source; if not, download it   ////
//// from http://www.opencores.org/lgpl.shtml                     ////
////                                                              ////
//////////////////////////////////////////////////////////////////////


module user_project_wrapper (
`ifdef USE_POWER_PINS
    inout vdda1,	// User area 1 3.3V supply
    inout vdda2,	// User area 2 3.3V supply
    inout vssa1,	// User area 1 analog ground
    inout vssa2,	// User area 2 analog ground
    inout vccd1,	// User area 1 1.8V supply
    inout vccd2,	// User area 2 1.8v supply
    inout vssd1,	// User area 1 digital ground
    inout vssd2,	// User area 2 digital ground
`endif
    input   wire                       wb_clk_i        ,  // System clock
    input   wire                       user_clock2     ,  // user Clock
    input   wire                       wb_rst_i        ,  // Regular Reset signal

    input   wire                       wbs_cyc_i       ,  // strobe/request
    input   wire                       wbs_stb_i       ,  // strobe/request
    input   wire [WB_WIDTH-1:0]        wbs_adr_i       ,  // address
    input   wire                       wbs_we_i        ,  // write
    input   wire [WB_WIDTH-1:0]        wbs_dat_i       ,  // data output
    input   wire [3:0]                 wbs_sel_i       ,  // byte enable
    output  wire [WB_WIDTH-1:0]        wbs_dat_o       ,  // data input
    output  wire                       wbs_ack_o       ,  // acknowlegement

    // Analog (direct connection to GPIO pad---use with caution)
    // Note that analog I/O is not available on the 7 lowest-numbered
    // GPIO pads, and so the analog_io indexing is offset from the
    // GPIO indexing by 7 (also upper 2 GPIOs do not have analog_io).
    inout [`MPRJ_IO_PADS-10:0] analog_io,
 
    // Logic Analyzer Signals
    input  wire [127:0]                la_data_in      ,
    output wire [127:0]                la_data_out     ,
    input  wire [127:0]                la_oenb         ,
 

    // IOs
    input  wire  [37:0]                io_in           ,
    output wire  [37:0]                io_out          ,
    output wire  [37:0]                io_oeb          ,

    output wire  [2:0]                 user_irq             

);

//---------------------------------------------------
// Local Parameter Declaration
// --------------------------------------------------

parameter  BIST_NO_SRAM  = 4; // NO of MBIST MEMORY
parameter  BIST1_ADDR_WD = 11; // 512x32 SRAM
parameter  BIST_DATA_WD  = 32;
parameter  SDR_DW        = 8;  // SDR Data Width 
parameter  SDR_BW        = 1;  // SDR Byte Width
parameter  WB_WIDTH      = 32; // WB ADDRESS/DARA WIDTH

//---------------------------------------------------------------------
// Wishbone Risc V Instruction Memory Interface
//---------------------------------------------------------------------
wire                           wbd_riscv_imem_stb_i; // strobe/request
wire   [WB_WIDTH-1:0]          wbd_riscv_imem_adr_i; // address
wire                           wbd_riscv_imem_we_i;  // write
wire   [WB_WIDTH-1:0]          wbd_riscv_imem_dat_i; // data output
wire   [3:0]                   wbd_riscv_imem_sel_i; // byte enable
wire   [WB_WIDTH-1:0]          wbd_riscv_imem_dat_o; // data input
wire                           wbd_riscv_imem_ack_o; // acknowlegement
wire                           wbd_riscv_imem_err_o;  // error

//---------------------------------------------------------------------
// RISC V Wishbone Data Memory Interface
//---------------------------------------------------------------------
wire                           wbd_riscv_dmem_stb_i; // strobe/request
wire   [WB_WIDTH-1:0]          wbd_riscv_dmem_adr_i; // address
wire                           wbd_riscv_dmem_we_i;  // write
wire   [WB_WIDTH-1:0]          wbd_riscv_dmem_dat_i; // data output
wire   [3:0]                   wbd_riscv_dmem_sel_i; // byte enable
wire   [WB_WIDTH-1:0]          wbd_riscv_dmem_dat_o; // data input
wire                           wbd_riscv_dmem_ack_o; // acknowlegement
wire                           wbd_riscv_dmem_err_o; // error

//---------------------------------------------------------------------
// WB HOST Interface
//---------------------------------------------------------------------
wire                           wbd_int_cyc_i; // strobe/request
wire                           wbd_int_stb_i; // strobe/request
wire   [WB_WIDTH-1:0]          wbd_int_adr_i; // address
wire                           wbd_int_we_i;  // write
wire   [WB_WIDTH-1:0]          wbd_int_dat_i; // data output
wire   [3:0]                   wbd_int_sel_i; // byte enable
wire   [WB_WIDTH-1:0]          wbd_int_dat_o; // data input
wire                           wbd_int_ack_o; // acknowlegement
wire                           wbd_int_err_o; // error
//---------------------------------------------------------------------
//    SPI Master Wishbone Interface
//---------------------------------------------------------------------
wire                           wbd_spim_stb_o; // strobe/request
wire   [WB_WIDTH-1:0]          wbd_spim_adr_o; // address
wire                           wbd_spim_we_o;  // write
wire   [WB_WIDTH-1:0]          wbd_spim_dat_o; // data output
wire   [3:0]                   wbd_spim_sel_o; // byte enable
wire                           wbd_spim_cyc_o ;
wire   [WB_WIDTH-1:0]          wbd_spim_dat_i; // data input
wire                           wbd_spim_ack_i; // acknowlegement
wire                           wbd_spim_err_i;  // error

//---------------------------------------------------------------------
//    SPI Master Wishbone Interface
//---------------------------------------------------------------------
wire                           wbd_sdram_stb_o ;
wire [WB_WIDTH-1:0]            wbd_sdram_adr_o ;
wire                           wbd_sdram_we_o  ; // 1 - Write, 0 - Read
wire [WB_WIDTH-1:0]            wbd_sdram_dat_o ;
wire [WB_WIDTH/8-1:0]          wbd_sdram_sel_o ; // Byte enable
wire                           wbd_sdram_cyc_o ;
wire  [2:0]                    wbd_sdram_cti_o ;
wire  [WB_WIDTH-1:0]           wbd_sdram_dat_i ;
wire                           wbd_sdram_ack_i ;

//---------------------------------------------------------------------
//    Global Register Wishbone Interface
//---------------------------------------------------------------------
wire                           wbd_glbl_stb_o; // strobe/request
wire   [7:0]                   wbd_glbl_adr_o; // address
wire                           wbd_glbl_we_o;  // write
wire   [WB_WIDTH-1:0]          wbd_glbl_dat_o; // data output
wire   [3:0]                   wbd_glbl_sel_o; // byte enable
wire                           wbd_glbl_cyc_o ;
wire   [WB_WIDTH-1:0]          wbd_glbl_dat_i; // data input
wire                           wbd_glbl_ack_i; // acknowlegement
wire                           wbd_glbl_err_i;  // error

//---------------------------------------------------------------------
//    Global Register Wishbone Interface
//---------------------------------------------------------------------
wire                           wbd_uart_stb_o; // strobe/request
wire   [7:0]                   wbd_uart_adr_o; // address
wire                           wbd_uart_we_o;  // write
wire   [31:0]                  wbd_uart_dat_o; // data output
wire   [3:0]                   wbd_uart_sel_o; // byte enable
wire                           wbd_uart_cyc_o ;
wire   [31:0]                  wbd_uart_dat_i; // data input
wire                           wbd_uart_ack_i; // acknowlegement
wire                           wbd_uart_err_i;  // error

//---------------------------------------------------------------------
//  MBIST1  
//---------------------------------------------------------------------
wire                           wbd_mbist_stb_o; // strobe/request
wire   [12:0]                  wbd_mbist_adr_o; // address
wire                           wbd_mbist_we_o;  // write
wire   [WB_WIDTH-1:0]          wbd_mbist_dat_o; // data output
wire   [3:0]                   wbd_mbist_sel_o; // byte enable
wire                           wbd_mbist_cyc_o ;
wire   [WB_WIDTH-1:0]          wbd_mbist_dat_i; // data input
wire                           wbd_mbist_ack_i; // acknowlegement
wire                           wbd_mbist_err_i;  // error

//----------------------------------------------------
//  CPU Configuration
//----------------------------------------------------
wire                              cpu_rst_n     ;
wire                              spi_rst_n     ;
wire                              sdram_rst_n   ;
wire                              uart_rst_n    ;// uart reset
wire                              i2c_rst_n     ;// i2c reset
wire                              mbist_rst_n   ;// Mbist Reset
wire   [1:0]                      uart_i2c_usb_sel  ;// 0 - uart, 1 - I2C, 2- USb
wire                              sdram_clk           ;
wire                              cpu_clk       ;
wire                              rtc_clk       ;
wire                              usb_clk       ;
wire                              wbd_clk_int   ;

wire                              wbd_clk_spim_rp   ;
wire                              wbd_clk_sdrc_rp   ;
wire                              wbd_clk_glbl_rp   ;
wire                              wbd_clk_uart_rp   ;
wire                              wbd_clk_riscv_rp  ;
wire                              wbd_clk_mbist_rp  ;

wire                              wbd_int_rst_n ;

wire [31:0]                       fuse_mhartid  ;
wire [15:0]                       irq_lines     ;
wire                              soft_irq      ;
wire [31:0]                       fuse_mhartid_rp  ;
wire [15:0]                       irq_lines_rp ;
wire                              soft_irq_rp  ;

wire [31:0]                       cfg_clk_ctrl1 ;
wire [31:0]                       cfg_clk_ctrl2 ;

wire [3:0]                        cfg_boot_remap; // remaping risc imem to SRAM

wire [3:0]                        cfg_cska_wi   ; // clock skew adjust for wishbone interconnect
wire [3:0]                        cfg_cska_riscv; // clock skew adjust for riscv
wire [3:0]                        cfg_cska_uart ; // clock skew adjust for uart
wire [3:0]                        cfg_cska_spi  ; // clock skew adjust for spi
wire [3:0]                        cfg_cska_sdram; // clock skew adjust for sdram
wire [3:0]                        cfg_cska_glbl ; // clock skew adjust for global reg
wire [3:0]                        cfg_cska_wh   ; // clock skew adjust for web host
wire [3:0]                        cfg_cska_mbist; // clock skew adjust for MBIST

wire [3:0]                        cfg_cska_sd_co; // clock skew adjust for sdram clock out
wire [3:0]                        cfg_cska_sd_ci; // clock skew adjust for sdram clock input
wire [3:0]                        cfg_cska_sp_co; // clock skew adjust for SPI clock out

// Config though wb_interconnect repeate
wire [3:0]                        cfg_cska_riscv_rp; // clock skew adjust for riscv
wire [3:0]                        cfg_cska_uart_rp ; // clock skew adjust for uart
wire [3:0]                        cfg_cska_spi_rp  ; // clock skew adjust for spi
wire [3:0]                        cfg_cska_sdram_rp; // clock skew adjust for sdram
wire [3:0]                        cfg_cska_glbl_rp ; // clock skew adjust for global reg
wire [3:0]                        cfg_cska_mbist_rp; // clock skew adjust for MBIST

wire [3:0]                        cfg_cska_sd_co_rp; // clock skew adjust for sdram clock out
wire [3:0]                        cfg_cska_sd_ci_rp; // clock skew adjust for sdram clock input
wire [3:0]                        cfg_cska_sp_co_rp; // clock skew adjust for SPI clock out


// Clock from skew cells
wire                              wbd_clk_wi_skew    ; // skew clock for wishbone interconnect
wire                              wbd_clk_riscv_skew ; // skew clock for riscv
wire                              wbd_clk_uart_skew  ; // skew clock for uart
wire                              wbd_clk_spi_skew   ; // skew clock for spi
wire                              wbd_clk_sdram_skew ; // skew clock for sdram
wire                              wbd_clk_glbl_skew  ; // skew clock for global reg
wire                              wbd_clk_wh_skew    ; // skew clock for global reg
wire                              wbd_clk_mbist_skew ; // skew clock for MBIST

wire                              io_in_29_     ; // Clock Skewed Pad SDRAM clock
wire                              io_in_30_     ; // SPI clock out

//------------------------------------------------
// Configuration Parameter
//------------------------------------------------
wire [1:0]                        cfg_sdr_width       ; // 2'b00 - 32 Bit SDR, 2'b01 - 16 Bit SDR, 2'b1x - 8 Bit
wire [1:0]                        cfg_colbits         ; // 2'b00 - 8 Bit column address, 
wire                              sdr_init_done       ; // Indicate SDRAM Initialisation Done
wire [3:0] 		          cfg_sdr_tras_d      ; // Active to precharge delay
wire [3:0]                        cfg_sdr_trp_d       ; // Precharge to active delay
wire [3:0]                        cfg_sdr_trcd_d      ; // Active to R/W delay
wire 			          cfg_sdr_en          ; // Enable SDRAM controller
wire [1:0] 		          cfg_req_depth       ; // Maximum Request accepted by SDRAM controller
wire [12:0] 		          cfg_sdr_mode_reg    ;
wire [2:0] 		          cfg_sdr_cas         ; // SDRAM CAS Latency
wire [3:0] 		          cfg_sdr_trcar_d     ; // Auto-refresh period
wire [3:0]                        cfg_sdr_twr_d       ; // Write recovery delay
wire [11: 0]                      cfg_sdr_rfsh        ;
wire [2 : 0]                      cfg_sdr_rfmax       ;

wire [31:0]                       sdram_debug_rp     ;
wire [31:0]                       spi_debug           ;
wire [31:0]                       sdram_debug         ;
wire [63:0]                       riscv_debug         ;

`ifndef SCR1_TCM_MEM
// SRAM-0 PORT-0 - DMEM I/F
wire                             sram0_clk0           ; // CLK
wire                             sram0_csb0           ; // CS#
wire                             sram0_web0           ; // WE#
wire   [8:0]                     sram0_addr0          ; // Address
wire   [3:0]                     sram0_wmask0         ; // WMASK#
wire   [31:0]                    sram0_din0           ; // Write Data
wire   [31:0]                    sram0_dout0          ; // Read Data

// SRAM-0 PORT-1, IMEM I/F
wire                             sram0_clk1           ; // CLK
wire                             sram0_csb1           ; // CS#
wire  [8:0]                      sram0_addr1          ; // Address
wire  [31:0]                     sram0_dout1          ; // Read Data

// SRAM-1 PORT-0 - DMEM I/F
wire                             sram1_clk0           ; // CLK
wire                             sram1_csb0           ; // CS#
wire                             sram1_web0           ; // WE#
wire   [8:0]                     sram1_addr0          ; // Address
wire   [3:0]                     sram1_wmask0         ; // WMASK#
wire   [31:0]                    sram1_din0           ; // Write Data
wire   [31:0]                    sram1_dout0          ; // Read Data

// SRAM-1 PORT-1, IMEM I/F
wire                             sram1_clk1           ; // CLK
wire                             sram1_csb1           ; // CS#
wire  [8:0]                      sram1_addr1          ; // Address
wire  [31:0]                     sram1_dout1          ; // Read Data


`endif

//----------------------------------------------------------
// BIST I/F
// ---------------------------------------------------------
wire                             bist_en             ;
wire                             bist_run            ;
wire                             bist_load           ;

wire                             bist_sdi            ;
wire                             bist_shift          ;
wire                             bist_sdo            ;

wire                             bist_done           ;
wire [3:0]                       bist_error          ;
wire [3:0]                       bist_correct        ;
wire [3:0]                       bist_error_cnt0     ;
wire [3:0]                       bist_error_cnt1     ;
wire [3:0]                       bist_error_cnt2     ;
wire [3:0]                       bist_error_cnt3     ;

// With Repeater Buffer
wire                             bist_en_rp          ;
wire                             bist_run_rp         ;
wire                             bist_load_rp        ;

wire                             bist_sdi_rp         ;
wire                             bist_shift_rp       ;
wire                             bist_sdo_rp         ;

wire                             bist_done_rp        ;
wire [3:0]                       bist_error_rp       ;
wire [3:0]                       bist_correct_rp     ;
wire [3:0]                       bist_error_cnt0_rp  ;
wire [3:0]                       bist_error_cnt1_rp  ;
wire [3:0]                       bist_error_cnt2_rp  ;
wire [3:0]                       bist_error_cnt3_rp  ;

// towards memory MBIST1
// PORT-A
wire   [BIST_NO_SRAM-1:0]      mem_clk_a;
wire   [BIST1_ADDR_WD-1:2]     mem0_addr_a;
wire   [BIST1_ADDR_WD-1:2]     mem1_addr_a;
wire   [BIST1_ADDR_WD-1:2]     mem2_addr_a;
wire   [BIST1_ADDR_WD-1:2]     mem3_addr_a;
wire   [BIST_NO_SRAM-1:0]      mem_cen_a;
wire   [BIST_NO_SRAM-1:0]      mem_web_a;
wire [BIST_DATA_WD/8-1:0]      mem0_mask_a;
wire [BIST_DATA_WD/8-1:0]      mem1_mask_a;
wire [BIST_DATA_WD/8-1:0]      mem2_mask_a;
wire [BIST_DATA_WD/8-1:0]      mem3_mask_a;
wire   [BIST_DATA_WD-1:0]      mem0_din_a;
wire   [BIST_DATA_WD-1:0]      mem1_din_a;
wire   [BIST_DATA_WD-1:0]      mem2_din_a;
wire   [BIST_DATA_WD-1:0]      mem3_din_a;
wire   [BIST_DATA_WD-1:0]      mem0_dout_a;
wire   [BIST_DATA_WD-1:0]      mem1_dout_a;
wire   [BIST_DATA_WD-1:0]      mem2_dout_a;
wire   [BIST_DATA_WD-1:0]      mem3_dout_a;

// PORT-B
wire [BIST_NO_SRAM-1:0]        mem_clk_b;
wire [BIST_NO_SRAM-1:0]        mem_cen_b;
wire [BIST1_ADDR_WD-1:2]       mem0_addr_b;
wire [BIST1_ADDR_WD-1:2]       mem1_addr_b;
wire [BIST1_ADDR_WD-1:2]       mem2_addr_b;
wire [BIST1_ADDR_WD-1:2]       mem3_addr_b;

/////////////////////////////////////////////////////////
// Clock Skew Ctrl
////////////////////////////////////////////////////////

assign cfg_cska_wi    = cfg_clk_ctrl1[3:0];
assign cfg_cska_riscv = cfg_clk_ctrl1[7:4];
assign cfg_cska_spi   = cfg_clk_ctrl1[11:8];
assign cfg_cska_sdram = cfg_clk_ctrl1[15:12];
assign cfg_cska_uart  = cfg_clk_ctrl1[19:16];
assign cfg_cska_glbl  = cfg_clk_ctrl1[23:20];
assign cfg_cska_mbist = cfg_clk_ctrl1[27:24];
assign cfg_cska_wh    = cfg_clk_ctrl1[31:28];

assign cfg_cska_sd_co = cfg_clk_ctrl2[3:0]; // SDRAM clock out control
assign cfg_cska_sd_ci = cfg_clk_ctrl2[7:4]; // SDRAM clock in control
assign cfg_cska_sp_co = cfg_clk_ctrl2[11:8];// SPI clock out control

//assign la_data_out    = {riscv_debug,spi_debug,sdram_debug};
assign la_data_out[127:0]    = {sdram_debug,spi_debug,riscv_debug};

//clk_buf u_buf1_wb_rstn  (.clk_i(wbd_int_rst_n),.clk_o(wbd_int1_rst_n));
//clk_buf u_buf2_wb_rstn  (.clk_i(wbd_int1_rst_n),.clk_o(wbd_int2_rst_n));
//
//clk_buf u_buf1_wbclk    (.clk_i(wbd_clk_int),.clk_o(wbd_clk_int1));
//clk_buf u_buf2_wbclk    (.clk_i(wbd_clk_int1),.clk_o(wbd_clk_int2));

wb_host u_wb_host(
`ifdef USE_POWER_PINS
         .vccd1         (vccd1                 ),// User area 1 1.8V supply
         .vssd1         (vssd1                 ),// User area 1 digital ground
`endif
       .user_clock1      (wb_clk_i             ),
       .user_clock2      (user_clock2          ),

       .sdram_clk        (sdram_clk            ),
       .cpu_clk          (cpu_clk              ),
       .rtc_clk          (rtc_clk              ),
       .usb_clk          (usb_clk              ),

       .wbd_int_rst_n    (wbd_int_rst_n        ),
       .cpu_rst_n        (cpu_rst_n            ),
       .spi_rst_n        (spi_rst_n            ),
       .sdram_rst_n      (sdram_rst_n          ),
       .uart_rst_n       (uart_rst_n           ), // uart reset
       .i2cm_rst_n       (i2c_rst_n            ), // i2c reset
       .mbist_rst_n      (mbist_rst_n          ), // usb reset
       .uart_i2c_usb_sel (uart_i2c_usb_sel     ), // 0 - uart, 1 - I2C, 2- USB

    // Master Port
       .wbm_rst_i        (wb_rst_i             ),  
       .wbm_clk_i        (wb_clk_i             ),  
       .wbm_cyc_i        (wbs_cyc_i            ),  
       .wbm_stb_i        (wbs_stb_i            ),  
       .wbm_adr_i        (wbs_adr_i            ),  
       .wbm_we_i         (wbs_we_i             ),  
       .wbm_dat_i        (wbs_dat_i            ),  
       .wbm_sel_i        (wbs_sel_i            ),  
       .wbm_dat_o        (wbs_dat_o            ),  
       .wbm_ack_o        (wbs_ack_o            ),  
       .wbm_err_o        (                     ),  

    // Clock Skeq Adjust
       .wbd_clk_int      (wbd_clk_int          ),
       .wbd_clk_wh       (wbd_clk_wh           ),  
       .cfg_cska_wh      (cfg_cska_wh          ),

    // Slave Port
       .wbs_clk_out      (wbd_clk_int          ),
       .wbs_clk_i        (wbd_clk_wh           ),  
       .wbs_cyc_o        (wbd_int_cyc_i        ),  
       .wbs_stb_o        (wbd_int_stb_i        ),  
       .wbs_adr_o        (wbd_int_adr_i        ),  
       .wbs_we_o         (wbd_int_we_i         ),  
       .wbs_dat_o        (wbd_int_dat_i        ),  
       .wbs_sel_o        (wbd_int_sel_i        ),  
       .wbs_dat_i        (wbd_int_dat_o        ),  
       .wbs_ack_i        (wbd_int_ack_o        ),  
       .wbs_err_i        (wbd_int_err_o        ),  

       .cfg_clk_ctrl1    (cfg_clk_ctrl1        ),
       .cfg_clk_ctrl2    (cfg_clk_ctrl2        ),
       .cfg_boot_remap   (cfg_boot_remap       ),

       .la_data_in       (la_data_in[0]        )

    );




//------------------------------------------------------------------------------
// RISC V Core instance
//------------------------------------------------------------------------------
scr1_top_wb u_riscv_top (
`ifdef USE_POWER_PINS
    .vccd1                 (vccd1                    ),// User area 1 1.8V supply
    .vssd1                 (vssd1                    ),// User area 1 digital ground
`endif
    .wbd_clk_int           (wbd_clk_riscv_rp          ), 
    .cfg_cska_riscv        (cfg_cska_riscv_rp         ), 
    .wbd_clk_riscv         (wbd_clk_riscv             ),

    // Reset
    .pwrup_rst_n            (wbd_int_rst_n             ),
    .rst_n                  (wbd_int_rst_n             ),
    .cpu_rst_n              (cpu_rst_n                 ),
    .riscv_debug            (riscv_debug               ),

    // Clock
    .core_clk               (cpu_clk                   ),
    .rtc_clk                (rtc_clk                   ),

    // Fuses
    .fuse_mhartid           (fuse_mhartid_rp           ),

    // IRQ
    .irq_lines              (irq_lines_rp              ), 
    .soft_irq               (soft_irq_rp               ), // TODO - Interrupts

    // DFT
    // .test_mode           (1'b0                      ), // Moved inside IP
    // .test_rst_n          (1'b1                      ), // Moved inside IP

`ifndef SCR1_TCM_MEM
    // SRAM-0 PORT-0
    .sram0_clk0             (sram0_clk0                ),
    .sram0_csb0             (sram0_csb0                ),
    .sram0_web0             (sram0_web0                ),
    .sram0_addr0            (sram0_addr0               ),
    .sram0_wmask0           (sram0_wmask0              ),
    .sram0_din0             (sram0_din0                ),
    .sram0_dout0            (sram0_dout0               ),
    
    // SRAM-0 PORT-0
    .sram0_clk1             (sram0_clk1                ),
    .sram0_csb1             (sram0_csb1                ),
    .sram0_addr1            (sram0_addr1               ),
    .sram0_dout1            (sram0_dout1               ),

    // SRAM-1 PORT-0
    .sram1_clk0             (sram1_clk0                ),
    .sram1_csb0             (sram1_csb0                ),
    .sram1_web0             (sram1_web0                ),
    .sram1_addr0            (sram1_addr0               ),
    .sram1_wmask0           (sram1_wmask0              ),
    .sram1_din0             (sram1_din0                ),
    .sram1_dout0            (sram1_dout0               ),
    
    // SRAM PORT-0
    .sram1_clk1             (sram1_clk1                ),
    .sram1_csb1             (sram1_csb1                ),
    .sram1_addr1            (sram1_addr1               ),
    .sram1_dout1            (sram1_dout1               ),

`endif
    
    .wb_rst_n               (wbd_int_rst_n             ),
    .wb_clk                 (wbd_clk_riscv             ),
    // Instruction memory interface
    .wbd_imem_stb_o         (wbd_riscv_imem_stb_i      ),
    .wbd_imem_adr_o         (wbd_riscv_imem_adr_i      ),
    .wbd_imem_we_o          (wbd_riscv_imem_we_i       ), 
    .wbd_imem_dat_o         (wbd_riscv_imem_dat_i      ),
    .wbd_imem_sel_o         (wbd_riscv_imem_sel_i      ),
    .wbd_imem_dat_i         (wbd_riscv_imem_dat_o      ),
    .wbd_imem_ack_i         (wbd_riscv_imem_ack_o      ),
    .wbd_imem_err_i         (wbd_riscv_imem_err_o      ),

    // Data memory interface
    .wbd_dmem_stb_o         (wbd_riscv_dmem_stb_i      ),
    .wbd_dmem_adr_o         (wbd_riscv_dmem_adr_i      ),
    .wbd_dmem_we_o          (wbd_riscv_dmem_we_i       ), 
    .wbd_dmem_dat_o         (wbd_riscv_dmem_dat_i      ),
    .wbd_dmem_sel_o         (wbd_riscv_dmem_sel_i      ),
    .wbd_dmem_dat_i         (wbd_riscv_dmem_dat_o      ),
    .wbd_dmem_ack_i         (wbd_riscv_dmem_ack_o      ),
    .wbd_dmem_err_i         (wbd_riscv_dmem_err_o      ) 
);

`ifndef SCR1_TCM_MEM

sky130_sram_2kbyte_1rw1r_32x512_8 u_tsram0_2kb(
`ifdef USE_POWER_PINS
    .vccd1 (vccd1),// User area 1 1.8V supply
    .vssd1 (vssd1),// User area 1 digital ground
`endif
// Port 0: RW
    .clk0     (sram0_clk0),
    .csb0     (sram0_csb0),
    .web0     (sram0_web0),
    .wmask0   (sram0_wmask0),
    .addr0    (sram0_addr0),
    .din0     (sram0_din0),
    .dout0    (sram0_dout0),
// Port 1: R
    .clk1     (sram0_clk1),
    .csb1     (sram0_csb1),
    .addr1    (sram0_addr1),
    .dout1    (sram0_dout1)
  );

sky130_sram_2kbyte_1rw1r_32x512_8 u_tsram1_2kb(
`ifdef USE_POWER_PINS
    .vccd1 (vccd1),// User area 1 1.8V supply
    .vssd1 (vssd1),// User area 1 digital ground
`endif
// Port 0: RW
    .clk0     (sram1_clk0),
    .csb0     (sram1_csb0),
    .web0     (sram1_web0),
    .wmask0   (sram1_wmask0),
    .addr0    (sram1_addr0),
    .din0     (sram1_din0),
    .dout0    (sram1_dout0),
// Port 1: R
    .clk1     (sram1_clk1),
    .csb1     (sram1_csb1),
    .addr1    (sram1_addr1),
    .dout1    (sram1_dout1)
  );
`endif


/*********************************************************
* SPI Master
* This is an implementation of an SPI master that is controlled via an AXI bus. 
* It has FIFOs for transmitting and receiving data. 
* It supports both the normal SPI mode and QPI mode with 4 data lines.
* *******************************************************/

spim_top
#(
`ifndef SYNTHESIS
    .WB_WIDTH  (WB_WIDTH)
`endif
) u_spi_master
(
`ifdef USE_POWER_PINS
         .vccd1         (vccd1                 ),// User area 1 1.8V supply
         .vssd1         (vssd1                 ),// User area 1 digital ground
`endif
    .mclk                   (wbd_clk_spi_skew          ),
    .rst_n                  (spi_rst_n                 ),

    // Clock Skew Adjust
    .cfg_cska_sp_co         (cfg_cska_sp_co_rp         ),
    .cfg_cska_spi           (cfg_cska_spi_rp           ),
    .wbd_clk_int            (wbd_clk_spim_rp           ),
    .wbd_clk_spi            (wbd_clk_spi_skew          ),

    .wbd_stb_i              (wbd_spim_stb_o            ),
    .wbd_adr_i              (wbd_spim_adr_o            ),
    .wbd_we_i               (wbd_spim_we_o             ), 
    .wbd_dat_i              (wbd_spim_dat_o            ),
    .wbd_sel_i              (wbd_spim_sel_o            ),
    .wbd_dat_o              (wbd_spim_dat_i            ),
    .wbd_ack_o              (wbd_spim_ack_i            ),
    .wbd_err_o              (wbd_spim_err_i            ),

    .spi_debug              (spi_debug                 ),

    // Pad Interface
    .io_in                  (io_in[35:32]              ), // io_in[31:30] unused ports
    .io_out                 (io_out[35:30]             ),
    .io_oeb                 (io_oeb[35:30]             )

);


sdrc_top  
    `ifndef SYNTHESIS
    #(.APP_AW(WB_WIDTH), 
	    .APP_DW(WB_WIDTH), 
	    .APP_BW(4),
	    .SDR_DW(8), 
	    .SDR_BW(1))
      `endif
     u_sdram_ctrl (
`ifdef USE_POWER_PINS
     .vccd1                  (vccd1                     ),// User area 1 1.8V supply
     .vssd1                  (vssd1                     ),// User area 1 digital ground
`endif
     .wbd_clk_int            (wbd_clk_sdrc_rp           ),
     .cfg_cska_sdram         (cfg_cska_sdram_rp         ),
     .wbd_clk_sdram          (wbd_clk_sdram_skew        ),

     .cfg_cska_sd_co         (cfg_cska_sd_co_rp         ),
     .cfg_cska_sd_ci         (cfg_cska_sd_ci_rp         ),


    .cfg_sdr_width          (cfg_sdr_width              ),
    .cfg_colbits            (cfg_colbits                ),
    .sdram_debug            (sdram_debug                ),
                    
    // WB bus
    .wb_rst_n               (wbd_int_rst_n              ),
    .wb_clk_i               (wbd_clk_sdram_skew         ),
    
    .wb_stb_i               (wbd_sdram_stb_o            ),
    .wb_addr_i              (wbd_sdram_adr_o            ),
    .wb_we_i                (wbd_sdram_we_o             ),
    .wb_dat_i               (wbd_sdram_dat_o            ),
    .wb_sel_i               (wbd_sdram_sel_o            ),
    .wb_cyc_i               (wbd_sdram_cyc_o            ),
    .wb_ack_o               (wbd_sdram_ack_i            ),
    .wb_dat_o               (wbd_sdram_dat_i            ),

		
    /* Interface to SDRAMs */
    .sdram_clk              (sdram_clk                 ),
    .sdram_resetn           (sdram_rst_n               ),

    /** Pad Interface       **/
    .io_in                  (io_in[29:0]               ),
    .io_oeb                 (io_oeb[29:0]              ),
    .io_out                 (io_out[29:0]              ),
                    
    /* Parameters */
    .sdr_init_done          (sdr_init_done             ),
    .cfg_req_depth          (cfg_req_depth             ), //how many req. buffer should hold
    .cfg_sdr_en             (cfg_sdr_en                ),
    .cfg_sdr_mode_reg       (cfg_sdr_mode_reg          ),
    .cfg_sdr_tras_d         (cfg_sdr_tras_d            ),
    .cfg_sdr_trp_d          (cfg_sdr_trp_d             ),
    .cfg_sdr_trcd_d         (cfg_sdr_trcd_d            ),
    .cfg_sdr_cas            (cfg_sdr_cas               ),
    .cfg_sdr_trcar_d        (cfg_sdr_trcar_d           ),
    .cfg_sdr_twr_d          (cfg_sdr_twr_d             ),
    .cfg_sdr_rfsh           (cfg_sdr_rfsh              ),
    .cfg_sdr_rfmax          (cfg_sdr_rfmax             )
   );


wb_interconnect  
          #(
	`ifndef SYNTHESIS
	        .CH_CLK_WD(6),
	        .CH_DATA_WD(116)
        `endif
	   )
       u_intercon (
`ifdef USE_POWER_PINS
         .vccd1         (vccd1                 ),// User area 1 1.8V supply
         .vssd1         (vssd1                 ),// User area 1 digital ground
`endif
     // Clock Skew adjust
	 .wbd_clk_int   (wbd_clk_int           ), 
	 .cfg_cska_wi   (cfg_cska_wi           ), 
	 .wbd_clk_wi    (wbd_clk_wi_skew       ),

	 .boot_remap    (cfg_boot_remap        ),

	 // Feed Through Signals
	 .ch_clk_in     ({
	                  wbd_clk_int,
	                  wbd_clk_int,
	                  wbd_clk_int,
                          wbd_clk_int, 
                          wbd_clk_int, 
                          wbd_clk_int}),
	 .ch_clk_out    ({
                         wbd_clk_mbist_rp,  
                         wbd_clk_glbl_rp,  
                         wbd_clk_uart_rp,
                         wbd_clk_sdrc_rp,  
                         wbd_clk_spim_rp,  
                         wbd_clk_riscv_rp
		         }),
	 .ch_data_in    ({
	                 bist_error_cnt3[3:0],
			 bist_correct[3],
			 bist_error[3],

	                 bist_error_cnt2[3:0],
			 bist_correct[2],
			 bist_error[2],

	                 bist_error_cnt1[3:0],
			 bist_correct[1],
			 bist_error[1],

	                 bist_error_cnt0[3:0],
			 bist_correct[0],
			 bist_error[0],
			 bist_done,
			 bist_sdo,
			 bist_shift,
			 bist_sdi,
			 bist_load,
			 bist_run,
			 bist_en,

			 soft_irq,
			 irq_lines[15:0],
			 fuse_mhartid[31:0],

			 cfg_cska_sp_co[3:0],
			 cfg_cska_sd_ci[3:0],
			 cfg_cska_sd_co[3:0],

		         cfg_cska_mbist[3:0],
		         cfg_cska_glbl[3:0],
			 cfg_cska_uart[3:0],
		         cfg_cska_sdram[3:0],
		         cfg_cska_spi[3:0],
                         cfg_cska_riscv[3:0]
			 } ),
	 .ch_data_out   ({
	                 bist_error_cnt3_rp[3:0],
			 bist_correct_rp[3],
			 bist_error_rp[3],

	                 bist_error_cnt2_rp[3:0],
			 bist_correct_rp[2],
			 bist_error_rp[2],

	                 bist_error_cnt1_rp[3:0],
			 bist_correct_rp[1],
			 bist_error_rp[1],

	                 bist_error_cnt0_rp[3:0],
			 bist_correct_rp[0],
			 bist_error_rp[0],
			 bist_done_rp,
			 bist_sdo_rp,
			 bist_shift_rp,
			 bist_sdi_rp,
			 bist_load_rp,
			 bist_run_rp,
			 bist_en_rp,

			 soft_irq_rp,
			 irq_lines_rp[15:0],
			 fuse_mhartid_rp[31:0],

			 cfg_cska_sp_co_rp[3:0],
			 cfg_cska_sd_ci_rp[3:0],
			 cfg_cska_sd_co_rp[3:0],

		         cfg_cska_mbist_rp[3:0],
		         cfg_cska_glbl_rp[3:0],
			 cfg_cska_uart_rp[3:0],
		         cfg_cska_sdram_rp[3:0],
		         cfg_cska_spi_rp[3:0],
                         cfg_cska_riscv_rp[3:0]
                         }),

         .clk_i         (wbd_clk_wi_skew       ), 
         .rst_n         (wbd_int_rst_n         ),

         // Master 0 Interface
         .m0_wbd_dat_i  (wbd_int_dat_i         ),
         .m0_wbd_adr_i  (wbd_int_adr_i         ),
         .m0_wbd_sel_i  (wbd_int_sel_i         ),
         .m0_wbd_we_i   (wbd_int_we_i          ),
         .m0_wbd_cyc_i  (wbd_int_cyc_i         ),
         .m0_wbd_stb_i  (wbd_int_stb_i         ),
         .m0_wbd_dat_o  (wbd_int_dat_o         ),
         .m0_wbd_ack_o  (wbd_int_ack_o         ),
         .m0_wbd_err_o  (wbd_int_err_o         ),
         
         // Master 0 Interface
         .m1_wbd_dat_i  (wbd_riscv_imem_dat_i  ),
         .m1_wbd_adr_i  (wbd_riscv_imem_adr_i  ),
         .m1_wbd_sel_i  (wbd_riscv_imem_sel_i  ),
         .m1_wbd_we_i   (wbd_riscv_imem_we_i   ),
         .m1_wbd_cyc_i  (wbd_riscv_imem_stb_i  ),
         .m1_wbd_stb_i  (wbd_riscv_imem_stb_i  ),
         .m1_wbd_dat_o  (wbd_riscv_imem_dat_o  ),
         .m1_wbd_ack_o  (wbd_riscv_imem_ack_o  ),
         .m1_wbd_err_o  (wbd_riscv_imem_err_o  ),
         
         // Master 1 Interface
         .m2_wbd_dat_i  (wbd_riscv_dmem_dat_i  ),
         .m2_wbd_adr_i  (wbd_riscv_dmem_adr_i  ),
         .m2_wbd_sel_i  (wbd_riscv_dmem_sel_i  ),
         .m2_wbd_we_i   (wbd_riscv_dmem_we_i   ),
         .m2_wbd_cyc_i  (wbd_riscv_dmem_stb_i  ),
         .m2_wbd_stb_i  (wbd_riscv_dmem_stb_i  ),
         .m2_wbd_dat_o  (wbd_riscv_dmem_dat_o  ),
         .m2_wbd_ack_o  (wbd_riscv_dmem_ack_o  ),
         .m2_wbd_err_o  (wbd_riscv_dmem_err_o  ),
         
         
         // Slave 0 Interface
         // .s0_wbd_err_i  (1'b0           ), - Moved inside IP
         .s0_wbd_dat_i  (wbd_spim_dat_i ),
         .s0_wbd_ack_i  (wbd_spim_ack_i ),
         .s0_wbd_dat_o  (wbd_spim_dat_o ),
         .s0_wbd_adr_o  (wbd_spim_adr_o ),
         .s0_wbd_sel_o  (wbd_spim_sel_o ),
         .s0_wbd_we_o   (wbd_spim_we_o  ),  
         .s0_wbd_cyc_o  (wbd_spim_cyc_o ),
         .s0_wbd_stb_o  (wbd_spim_stb_o ),
         
         // Slave 1 Interface
         // .s1_wbd_err_i  (1'b0           ), - Moved inside IP
         .s1_wbd_dat_i  (wbd_sdram_dat_i ),
         .s1_wbd_ack_i  (wbd_sdram_ack_i ),
         .s1_wbd_dat_o  (wbd_sdram_dat_o ),
         .s1_wbd_adr_o  (wbd_sdram_adr_o ),
         .s1_wbd_sel_o  (wbd_sdram_sel_o ),
         .s1_wbd_we_o   (wbd_sdram_we_o  ),  
         .s1_wbd_cyc_o  (wbd_sdram_cyc_o ),
         .s1_wbd_stb_o  (wbd_sdram_stb_o ),
         
         // Slave 2 Interface
         // .s2_wbd_err_i  (1'b0           ), - Moved inside IP
         .s2_wbd_dat_i  (wbd_glbl_dat_i ),
         .s2_wbd_ack_i  (wbd_glbl_ack_i ),
         .s2_wbd_dat_o  (wbd_glbl_dat_o ),
         .s2_wbd_adr_o  (wbd_glbl_adr_o ),
         .s2_wbd_sel_o  (wbd_glbl_sel_o ),
         .s2_wbd_we_o   (wbd_glbl_we_o  ),  
         .s2_wbd_cyc_o  (wbd_glbl_cyc_o ),
         .s2_wbd_stb_o  (wbd_glbl_stb_o ),

         // Slave 3 Interface
         // .s3_wbd_err_i  (1'b0           ), - Moved inside IP
         .s3_wbd_dat_i  (wbd_uart_dat_i ),
         .s3_wbd_ack_i  (wbd_uart_ack_i ),
         .s3_wbd_dat_o  (wbd_uart_dat_o ),
         .s3_wbd_adr_o  (wbd_uart_adr_o ),
         .s3_wbd_sel_o  (wbd_uart_sel_o ),
         .s3_wbd_we_o   (wbd_uart_we_o  ),  
         .s3_wbd_cyc_o  (wbd_uart_cyc_o ),
         .s3_wbd_stb_o  (wbd_uart_stb_o ),

         // Slave 4 Interface
         // .s4_wbd_err_i  (1'b0          ), - Moved inside IP
         .s4_wbd_dat_i  (wbd_mbist_dat_i ),
         .s4_wbd_ack_i  (wbd_mbist_ack_i ),
         .s4_wbd_dat_o  (wbd_mbist_dat_o ),
         .s4_wbd_adr_o  (wbd_mbist_adr_o ),
         .s4_wbd_sel_o  (wbd_mbist_sel_o ),
         .s4_wbd_we_o   (wbd_mbist_we_o  ),  
         .s4_wbd_cyc_o  (wbd_mbist_cyc_o ),
         .s4_wbd_stb_o  (wbd_mbist_stb_o )

	);

glbl_cfg   u_glbl_cfg (
`ifdef USE_POWER_PINS
       .vccd1                  (vccd1                     ),// User area 1 1.8V supply
       .vssd1                  (vssd1                     ),// User area 1 digital ground
`endif
       .wbd_clk_int            (wbd_clk_glbl_rp           ), 
       .cfg_cska_glbl          (cfg_cska_glbl_rp          ), 
       .wbd_clk_glbl           (wbd_clk_glbl_skew         ), 

       .mclk                   (wbd_clk_glbl_skew         ),
       .reset_n                (wbd_int_rst_n             ),

        // Reg Bus Interface Signal
       .reg_cs                 (wbd_glbl_stb_o            ),
       .reg_wr                 (wbd_glbl_we_o             ),
       .reg_addr               (wbd_glbl_adr_o            ),
       .reg_wdata              (wbd_glbl_dat_o            ),
       .reg_be                 (wbd_glbl_sel_o            ),

       // Outputs
       .reg_rdata              (wbd_glbl_dat_i            ),
       .reg_ack                (wbd_glbl_ack_i            ),

       // Risc configuration
       .fuse_mhartid           (fuse_mhartid              ),
       .irq_lines              (irq_lines                 ), 
       .soft_irq               (soft_irq                  ),
       .user_irq               (user_irq                  ),

       // SDRAM Config
       .cfg_sdr_width          (cfg_sdr_width             ),
       .cfg_colbits            (cfg_colbits               ),

	/* Parameters */
       .sdr_init_done          (sdr_init_done             ),
       .cfg_req_depth          (cfg_req_depth             ), //how many req. buffer should hold
       .cfg_sdr_en             (cfg_sdr_en                ),
       .cfg_sdr_mode_reg       (cfg_sdr_mode_reg          ),
       .cfg_sdr_tras_d         (cfg_sdr_tras_d            ),
       .cfg_sdr_trp_d          (cfg_sdr_trp_d             ),
       .cfg_sdr_trcd_d         (cfg_sdr_trcd_d            ),
       .cfg_sdr_cas            (cfg_sdr_cas               ),
       .cfg_sdr_trcar_d        (cfg_sdr_trcar_d           ),
       .cfg_sdr_twr_d          (cfg_sdr_twr_d             ),
       .cfg_sdr_rfsh           (cfg_sdr_rfsh              ),
       .cfg_sdr_rfmax          (cfg_sdr_rfmax             ),

       // BIST I/F
        .bist_en                (bist_en                   ),
        .bist_run               (bist_run                  ),
        .bist_load              (bist_load                 ),
        
        .bist_sdi               (bist_sdi                  ),
        .bist_shift             (bist_shift                ),
        .bist_sdo               (bist_sdo_rp               ),
        
        .bist_done              (bist_done_rp              ),
        .bist_error             (bist_error_rp             ),
        .bist_correct           (bist_correct_rp           ),
        .bist_error_cnt0        (bist_error_cnt0_rp        ),
        .bist_error_cnt1        (bist_error_cnt1_rp        ),
        .bist_error_cnt2        (bist_error_cnt2_rp        ),
        .bist_error_cnt3        (bist_error_cnt3_rp        )


        );

uart_i2c_usb_top   u_uart_i2c_usb (
`ifdef USE_POWER_PINS
         .vccd1                 (vccd1                    ),// User area 1 1.8V supply
         .vssd1                 (vssd1                    ),// User area 1 digital ground
`endif
	.wbd_clk_int            (wbd_clk_uart_rp          ), 
	.cfg_cska_uart          (cfg_cska_uart_rp         ), 
	.wbd_clk_uart           (wbd_clk_uart_skew        ),

        .uart_rstn              (uart_rst_n               ), // uart reset
        .i2c_rstn               (i2c_rst_n                ), // i2c reset
        .usb_rstn               (i2c_rst_n                ), // i2c reset
	.uart_i2c_usb_sel       (uart_i2c_usb_sel         ), // 0 - uart, 1 - I2C
        .app_clk                (wbd_clk_uart_skew        ),
	.usb_clk                (usb_clk                  ),

        // Reg Bus Interface Signal
       .reg_cs                 (wbd_uart_stb_o            ),
       .reg_wr                 (wbd_uart_we_o             ),
       .reg_addr               (wbd_uart_adr_o[5:2]       ),
       .reg_wdata              (wbd_uart_dat_o            ),
       .reg_be                 (wbd_uart_sel_o            ),

       // Outputs
       .reg_rdata              (wbd_uart_dat_i            ),
       .reg_ack                (wbd_uart_ack_i            ),

       // Pad interface
       .io_in                  (io_in [37:36]              ),
       .io_oeb                 (io_oeb[37:36]              ),
       .io_out                 (io_out[37:36]              )

     );

//------------- MBIST1 - 512x32             ----

mbist_top  #(
	`ifndef SYNTHESIS
	.BIST_NO_SRAM           (4                      ),
	.BIST_ADDR_WD           (BIST1_ADDR_WD-2        ),
	.BIST_DATA_WD           (BIST_DATA_WD           ),
	.BIST_ADDR_START        (9'h000                 ),
	.BIST_ADDR_END          (9'h1FB                 ),
	.BIST_REPAIR_ADDR_START (9'h1FC                 ),
	.BIST_RAD_WD_I          (BIST1_ADDR_WD-2        ),
	.BIST_RAD_WD_O          (BIST1_ADDR_WD-2        )
        `endif
     ) 
	     u_mbist (

`ifdef USE_POWER_PINS
       .vccd1                  (vccd1                     ),// User area 1 1.8V supply
       .vssd1                  (vssd1                     ),// User area 1 digital ground
`endif

     // Clock Skew adjust
	.wbd_clk_int          (wbd_clk_mbist_rp     ), 
	.cfg_cska_mbist       (cfg_cska_mbist_rp    ), 
	.wbd_clk_mbist        (wbd_clk_mbist_skew   ),

	// WB I/F
        .wb_clk2_i            (wbd_clk_mbist_skew  ),  
        .wb_clk_i             (wbd_clk_mbist_skew  ),  
        .wb_cyc_i             (wbd_mbist_cyc_o),  
        .wb_stb_i             (wbd_mbist_stb_o),  
	.wb_cs_i              (wbd_mbist_adr_o[12:11]),
        .wb_adr_i             (wbd_mbist_adr_o[BIST1_ADDR_WD-1:2]),  
        .wb_we_i              (wbd_mbist_we_o ),  
        .wb_dat_i             (wbd_mbist_dat_o),  
        .wb_sel_i             (wbd_mbist_sel_o),  
        .wb_dat_o             (wbd_mbist_dat_i),  
        .wb_ack_o             (wbd_mbist_ack_i),  
        .wb_err_o             (                 ), 

	.rst_n                (mbist_rst_n      ),

	
	.bist_en              (bist_en_rp       ),
	.bist_run             (bist_run_rp      ),
	.bist_shift           (bist_shift_rp    ),
	.bist_load            (bist_load_rp     ),
	.bist_sdi             (bist_sdi_rp      ),

	.bist_error_cnt3      (bist_error_cnt3  ),
	.bist_error_cnt2      (bist_error_cnt2  ),
	.bist_error_cnt1      (bist_error_cnt1  ),
	.bist_error_cnt0      (bist_error_cnt0  ),
	.bist_correct         (bist_correct     ),
	.bist_error           (bist_error       ),
	.bist_done            (bist_done        ),
	.bist_sdo             (bist_sdo         ),

     // towards memory
     // PORT-A
        .mem_clk_a            (mem_clk_a         ),
        .mem_addr_a0          (mem0_addr_a       ),
        .mem_addr_a1          (mem1_addr_a       ),
        .mem_addr_a2          (mem2_addr_a       ),
        .mem_addr_a3          (mem3_addr_a       ),
        .mem_cen_a            (mem_cen_a         ),
        .mem_web_a            (mem_web_a         ),
        .mem_mask_a0          (mem0_mask_a       ),
        .mem_mask_a1          (mem1_mask_a       ),
        .mem_mask_a2          (mem2_mask_a       ),
        .mem_mask_a3          (mem3_mask_a       ),
        .mem_din_a0           (mem0_din_a        ),
        .mem_din_a1           (mem1_din_a        ),
        .mem_din_a2           (mem2_din_a        ),
        .mem_din_a3           (mem3_din_a        ),
        .mem_dout_a0          (mem0_dout_a       ),
        .mem_dout_a1          (mem1_dout_a       ),
        .mem_dout_a2          (mem2_dout_a       ),
        .mem_dout_a3          (mem3_dout_a       ),
     // PORT-B
        .mem_clk_b            (mem_clk_b         ),
        .mem_cen_b            (mem_cen_b         ),
        .mem_addr_b0          (mem0_addr_b       ),
        .mem_addr_b1          (mem1_addr_b       ),
        .mem_addr_b2          (mem2_addr_b       ),
        .mem_addr_b3          (mem3_addr_b       )


);

sky130_sram_2kbyte_1rw1r_32x512_8 u_sram0_2kb(
`ifdef USE_POWER_PINS
    .vccd1 (vccd1),// User area 1 1.8V supply
    .vssd1 (vssd1),// User area 1 digital ground
`endif
// Port 0: RW
    .clk0     (mem_clk_a[0]),
    .csb0     (mem_cen_a[0]),
    .web0     (mem_web_a[0]),
    .wmask0   (mem0_mask_a),
    .addr0    (mem0_addr_a),
    .din0     (mem0_din_a),
    .dout0    (mem0_dout_a),
// Port 1: R
    .clk1     (mem_clk_b[0]),
    .csb1     (mem_cen_b[0]),
    .addr1    (mem0_addr_b),
    .dout1    ()
  );

sky130_sram_2kbyte_1rw1r_32x512_8 u_sram1_2kb(
`ifdef USE_POWER_PINS
    .vccd1 (vccd1),// User area 1 1.8V supply
    .vssd1 (vssd1),// User area 1 digital ground
`endif
// Port 0: RW
    .clk0     (mem_clk_a[1]),
    .csb0     (mem_cen_a[1]),
    .web0     (mem_web_a[1]),
    .wmask0   (mem1_mask_a),
    .addr0    (mem1_addr_a),
    .din0     (mem1_din_a),
    .dout0    (mem1_dout_a),
// Port 1: R
    .clk1     (mem_clk_b[1]),
    .csb1     (mem_cen_b[1]),
    .addr1    (mem1_addr_b),
    .dout1    ()
  );

sky130_sram_2kbyte_1rw1r_32x512_8 u_sram2_2kb(
`ifdef USE_POWER_PINS
    .vccd1 (vccd1),// User area 1 1.8V supply
    .vssd1 (vssd1),// User area 1 digital ground
`endif
// Port 0: RW
    .clk0     (mem_clk_a[2]),
    .csb0     (mem_cen_a[2]),
    .web0     (mem_web_a[2]),
    .wmask0   (mem2_mask_a),
    .addr0    (mem2_addr_a),
    .din0     (mem2_din_a),
    .dout0    (mem2_dout_a),
// Port 1: R
    .clk1     (mem_clk_b[2]),
    .csb1     (mem_cen_b[2]),
    .addr1    (mem2_addr_b),
    .dout1    ()
  );


sky130_sram_2kbyte_1rw1r_32x512_8 u_sram3_2kb(
`ifdef USE_POWER_PINS
    .vccd1 (vccd1),// User area 1 1.8V supply
    .vssd1 (vssd1),// User area 1 digital ground
`endif
// Port 0: RW
    .clk0     (mem_clk_a[3]),
    .csb0     (mem_cen_a[3]),
    .web0     (mem_web_a[3]),
    .wmask0   (mem3_mask_a),
    .addr0    (mem3_addr_a),
    .din0     (mem3_din_a),
    .dout0    (mem3_dout_a),
// Port 1: R
    .clk1     (mem_clk_b[3]),
    .csb1     (mem_cen_b[3]),
    .addr1    (mem3_addr_b),
    .dout1    ()
  );


endmodule : user_project_wrapper
