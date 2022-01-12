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
////  Wishbone Interconnect                                       ////
////                                                              ////
////  This file is part of the YIFive cores project               ////
////  https://github.com/dineshannayya/yifive_r0.git              ////
////  http://www.opencores.org/cores/yifive/                      ////
////                                                              ////
////  Description                                                 ////
////	1. 3 masters and 3 slaves share bus Wishbone connection   ////
////	2. This block implement simple round robine request       ////
////                                                              ////
////  To Do:                                                      ////
////    nothing                                                   ////
////                                                              ////
////  Author(s):                                                  ////
////      - Dinesh Annayya, dinesha@opencores.org                 ////
////                                                              ////
////  Revision :                                                  ////
////    0.1 - 12th June 2021, Dinesh A                            ////
////    0.2 - 17th June 2021, Dinesh A                            ////
////          Stagging FF added at Slave Interface to break       ////
////          path                                                ////
////    0.3 - 21th June 2021, Dinesh A                            ////
////          slave port 3 added for uart                         ////
////    0.4 - 25th June 2021, Dinesh A                            ////
////          External Memory Map changed and made same as        ////
////          internal memory map                                 ////
////    0.4 - 27th June 2021, Dinesh A                            ////
////          unused tie off at digital core level brought inside ////
////          to avoid core level power hook up                   ////
////    0.5 - 28th June 2021, Dinesh A                            ////
////          interchange the Master port for better physical     ////
////          placement                                           ////
////          m0: external host                                   ////
////          m1: risc imem                                       ////
////          m2: risc dmem                                       ////
////   0.6 - 06 Nov 2021, Dinesh A                                ////
////          Push the clock skew logic inside the block due to   ////
////          global power hooking challanges for small block at  ////
////          top level                                           ////
////   0.7 - 07 Dec 2021, Dinesh A                                ////
////         Buffer channel are added insider wb_inter to simply  ////
////         global routing                                       ////
////   0.8  -10 Dec 2021 , Dinesh A                               ////
////         two more slave port added for MBIST and ADC port     ////
////         removed                                              ////
////         Memory remap added to move the RISC Program memory   ////
////         to SRAM Memory                                       ////
////   0.9  - 15 Dec 2021, Dinesh A                               ////
////         Consolidated 4 MBIST port into one 8KB Port          ////
////                                                              ////
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



module wb_interconnect #(
	parameter CH_CLK_WD = 9,
	parameter CH_DATA_WD = 95
        ) (
`ifdef USE_POWER_PINS
         input logic            vccd1,    // User area 1 1.8V supply
         input logic            vssd1,    // User area 1 digital ground
`endif
         // Clock Skew Adjust
         input logic [3:0]      cfg_cska_wi,
         input logic            wbd_clk_int,
	 output logic           wbd_clk_wi,

	 // Bus repeaters
	 input [CH_CLK_WD-1:0]  ch_clk_in,
	 output [CH_CLK_WD-1:0] ch_clk_out,
	 input [CH_DATA_WD-1:0] ch_data_in,
	 output [CH_DATA_WD-1:0]ch_data_out,

         input logic		clk_i, 
         input logic            rst_n,

	 input logic  [3:0]     boot_remap, // When remap is enabled
	                                     // [0] - 0x0000_0000 - 0x0000_07FF Map to MBIST1
					     // [1] - 0x0000_0800 - 0x0000_0FFF Map to MBIST2
         
         // Master 0 Interface
         input   logic	[31:0]	m0_wbd_dat_i,
         input   logic  [31:0]	m0_wbd_adr_i,
         input   logic  [3:0]	m0_wbd_sel_i,
         input   logic  	m0_wbd_we_i,
         input   logic  	m0_wbd_cyc_i,
         input   logic  	m0_wbd_stb_i,
         output  logic	[31:0]	m0_wbd_dat_o,
         output  logic		m0_wbd_ack_o,
         output  logic		m0_wbd_err_o,
         
         // Master 1 Interface
         input	logic [31:0]	m1_wbd_dat_i,
         input	logic [31:0]	m1_wbd_adr_i,
         input	logic [3:0]	m1_wbd_sel_i,
         input	logic 	        m1_wbd_we_i,
         input	logic 	        m1_wbd_cyc_i,
         input	logic 	        m1_wbd_stb_i,
         output	logic [31:0]	m1_wbd_dat_o,
         output	logic 	        m1_wbd_ack_o,
         output	logic 	        m1_wbd_err_o,
         
         // Master 2 Interface
         input	logic [31:0]	m2_wbd_dat_i,
         input	logic [31:0]	m2_wbd_adr_i,
         input	logic [3:0]	m2_wbd_sel_i,
         input	logic 	        m2_wbd_we_i,
         input	logic 	        m2_wbd_cyc_i,
         input	logic 	        m2_wbd_stb_i,
         output	logic [31:0]	m2_wbd_dat_o,
         output	logic 	        m2_wbd_ack_o,
         output	logic 	        m2_wbd_err_o,
         
         
         // Slave 0 Interface
         input	logic [31:0]	s0_wbd_dat_i,
         input	logic 	        s0_wbd_ack_i,
         //input	logic 	s0_wbd_err_i, - unused
         output	logic [31:0]	s0_wbd_dat_o,
         output	logic [31:0]	s0_wbd_adr_o,
         output	logic [3:0]	s0_wbd_sel_o,
         output	logic 	        s0_wbd_we_o,
         output	logic 	        s0_wbd_cyc_o,
         output	logic 	        s0_wbd_stb_o,
         
         // Slave 1 Interface
         input	logic [31:0]	s1_wbd_dat_i,
         input	logic 	        s1_wbd_ack_i,
         // input	logic 	s1_wbd_err_i, - unused
         output	logic [31:0]	s1_wbd_dat_o,
         output	logic [31:0]	s1_wbd_adr_o,
         output	logic [3:0]	s1_wbd_sel_o,
         output	logic 	        s1_wbd_we_o,
         output	logic 	        s1_wbd_cyc_o,
         output	logic 	        s1_wbd_stb_o,
         
         // Slave 2 Interface
         input	logic [31:0]	s2_wbd_dat_i,
         input	logic 	        s2_wbd_ack_i,
         // input	logic 	s2_wbd_err_i, - unused
         output	logic [31:0]	s2_wbd_dat_o,
         output	logic [7:0]	s2_wbd_adr_o, // glbl reg need only 8 bits
         output	logic [3:0]	s2_wbd_sel_o,
         output	logic 	        s2_wbd_we_o,
         output	logic 	        s2_wbd_cyc_o,
         output	logic 	        s2_wbd_stb_o,

         // Slave 3 Interface
	 // Uart is 8bit interface 
         input	logic [31:0]	s3_wbd_dat_i,
         input	logic 	        s3_wbd_ack_i,
         // input	logic 	s3_wbd_err_i,
         output	logic [31:0]	s3_wbd_dat_o,
         output	logic [7:0]	s3_wbd_adr_o, 
         output	logic [3:0]   	s3_wbd_sel_o,
         output	logic 	        s3_wbd_we_o,
         output	logic 	        s3_wbd_cyc_o,
         output	logic 	        s3_wbd_stb_o,

         // Slave 4 Interface
	 // MBIST
         input	logic [31:0]	        s4_wbd_dat_i,
         input	logic 	                s4_wbd_ack_i,
         // input	logic 	        s4_wbd_err_i,
         output	logic [31:0]	s4_wbd_dat_o,
         output	logic [12:0]	s4_wbd_adr_o, 
         output	logic [3:0]   	s4_wbd_sel_o,
         output	logic 	        s4_wbd_we_o,
         output	logic 	        s4_wbd_cyc_o,
         output	logic 	        s4_wbd_stb_o
	);

////////////////////////////////////////////////////////////////////
//
// Type define
//

parameter TARGET_SPI_MEM  = 4'b0000;
parameter TARGET_SPI_REG  = 4'b0000;
parameter TARGET_SDRAM    = 4'b0001;
parameter TARGET_GLBL     = 4'b0010;
parameter TARGET_UART     = 4'b0011;
parameter TARGET_MBIST    = 4'b0100;

// WishBone Wr Interface
typedef struct packed { 
  logic	[31:0]	wbd_dat;
  logic  [31:0]	wbd_adr;
  logic  [3:0]	wbd_sel;
  logic  	wbd_we;
  logic  	wbd_cyc;
  logic  	wbd_stb;
  logic [3:0] 	wbd_tid; // target id
} type_wb_wr_intf;

// WishBone Rd Interface
typedef struct packed { 
  logic	[31:0]	wbd_dat;
  logic  	wbd_ack;
  logic  	wbd_err;
} type_wb_rd_intf;


// Master Write Interface
type_wb_wr_intf  m0_wb_wr;
type_wb_wr_intf  m1_wb_wr;
type_wb_wr_intf  m2_wb_wr;

// Master Read Interface
type_wb_rd_intf  m0_wb_rd;
type_wb_rd_intf  m1_wb_rd;
type_wb_rd_intf  m2_wb_rd;

// Slave Write Interface
type_wb_wr_intf  s0_wb_wr;
type_wb_wr_intf  s1_wb_wr;
type_wb_wr_intf  s2_wb_wr;
type_wb_wr_intf  s3_wb_wr;
type_wb_wr_intf  s4_wb_wr;

// Slave Read Interface
type_wb_rd_intf  s0_wb_rd;
type_wb_rd_intf  s1_wb_rd;
type_wb_rd_intf  s2_wb_rd;
type_wb_rd_intf  s3_wb_rd;
type_wb_rd_intf  s4_wb_rd;


type_wb_wr_intf  m_bus_wr;  // Multiplexed Master I/F
type_wb_rd_intf  m_bus_rd;  // Multiplexed Slave I/F

type_wb_wr_intf  s_bus_wr;  // Multiplexed Master I/F
type_wb_rd_intf  s_bus_rd;  // Multiplexed Slave I/F

// channel repeater
assign ch_clk_out  = ch_clk_in;
assign ch_data_out = ch_data_in;


// Wishbone interconnect clock skew control
clk_skew_adjust u_skew_wi
       (
`ifdef USE_POWER_PINS
               .vccd1      (vccd1                      ),// User area 1 1.8V supply
               .vssd1      (vssd1                      ),// User area 1 digital ground
`endif
	       .clk_in     (wbd_clk_int                 ), 
	       .sel        (cfg_cska_wi                 ), 
	       .clk_out    (wbd_clk_wi                  ) 
       );

//-------------------------------------------------------------------
// EXTERNAL MEMORY MAP
// 0x0000_0000 to 0x0FFF_FFFF  - SPI FLASH MEMORY
// 0x1000_0000 to 0x1000_00FF  - SPI REGISTER
// 0x1001_0000 to 0x1001_003F  - UART
// 0x1001_0000 to 0x1001_003F  - I2C
// 0x1001_0000 to 0x1001_003F  - USB
// 0x1002_0000 to 0x1002_00FF  - GLOBAL REGISTER
// 0x1003_0000 to 0x1003_07FF  - SRAM-0 (2KB)
// 0x1003_0800 to 0x1003_0FFF  - SRAM-1 (2KB)
// 0x1003_1000 to 0x1003_17FF  - SRAM-2 (2KB)
// 0x1003_1800 to 0x1003_1FFF  - SRAM-3 (2KB)
// 0x2000_0000 to 0x2FFF_FFFF  - SDRAM
// 0x3080_0000 to 0x3080_00FF  - WB HOST (This decoding happens at wb_host block)
// ---------------------------------------------------------------------------
//
wire [3:0] m0_wbd_tid_i       = (m0_wbd_adr_i[31:28] == 4'h0     ) ? TARGET_SPI_MEM :
                                (m0_wbd_adr_i[31:16] == 16'h1000 ) ? TARGET_SPI_REG :
                                (m0_wbd_adr_i[31:16] == 16'h1001 ) ? TARGET_UART :
                                (m0_wbd_adr_i[31:16] == 16'h1002 ) ? TARGET_GLBL :
                                (m0_wbd_adr_i[31:16] == 16'h1003 ) ? TARGET_MBIST: 
                                (m0_wbd_adr_i[31:28] == 4'h2     ) ? TARGET_SDRAM : 4'b0000; 

//------------------------------
// RISC Data Memory Map
// 0x0000_0000 to 0x0FFF_FFFF  - SPI FLASH MEMORY
// 0x1000_0000 to 0x1000_00FF  - SPI REGISTER
// 0x1001_0000 to 0x1001_003F  - UART
// 0x1001_0000 to 0x1001_003F  - I2C
// 0x1001_0000 to 0x1001_003F  - USB
// 0x1002_0000 to 0x1002_00FF  - GLOBAL REGISTER
// 0x1003_0000 to 0x1003_07FF  - SRAM-0 (2KB)
// 0x1003_0800 to 0x1003_0FFF  - SRAM-1 (2KB)
// 0x1003_1000 to 0x1003_17FF  - SRAM-2 (2KB)
// 0x1003_1800 to 0x1003_1FFF  - SRAM-3 (2KB)
// 0x2000_0000 to 0x2FFF_FFFF  - SDRAM
//-----------------------------
// 
wire [3:0] m1_wbd_tid_i     = (boot_remap[0] && m1_wbd_adr_i[31:11] == 21'h0) ? TARGET_MBIST:
	                      (boot_remap[1] && m1_wbd_adr_i[31:11] == 21'h1) ? TARGET_MBIST:
	                      (boot_remap[2] && m1_wbd_adr_i[31:11] == 21'h2) ? TARGET_MBIST:
	                      (boot_remap[3] && m1_wbd_adr_i[31:11] == 21'h3) ? TARGET_MBIST:
                              (m1_wbd_adr_i[31:28] == 4'h0     ) ? TARGET_SPI_MEM :
                              (m1_wbd_adr_i[31:16] == 16'h1000 ) ? TARGET_SPI_REG :
                              (m1_wbd_adr_i[31:16] == 16'h1001 ) ? TARGET_UART :
                              (m1_wbd_adr_i[31:16] == 16'h1002 ) ? TARGET_GLBL :
                              (m1_wbd_adr_i[31:16] == 16'h1003 ) ? TARGET_MBIST: 
                              (m1_wbd_adr_i[31:28] == 4'h2     ) ? TARGET_SDRAM : 4'b0000; 

wire [3:0] m2_wbd_tid_i     = (boot_remap[0] && m2_wbd_adr_i[31:11] == 21'h0) ? TARGET_MBIST:
	                      (boot_remap[1] && m2_wbd_adr_i[31:11] == 21'h1) ? TARGET_MBIST:
	                      (boot_remap[2] && m2_wbd_adr_i[31:11] == 21'h2) ? TARGET_MBIST:
	                      (boot_remap[3] && m2_wbd_adr_i[31:11] == 21'h3) ? TARGET_MBIST:
                              (m2_wbd_adr_i[31:28] == 4'h0     ) ? TARGET_SPI_MEM :
                              (m2_wbd_adr_i[31:16] == 16'h1000 ) ? TARGET_SPI_REG :
                              (m2_wbd_adr_i[31:16] == 16'h1001 ) ? TARGET_UART :
                              (m2_wbd_adr_i[31:16] == 16'h1002 ) ? TARGET_GLBL :
                              (m2_wbd_adr_i[31:16] == 16'h1003 ) ? TARGET_MBIST: 
                              (m2_wbd_adr_i[31:28] == 4'h2     ) ? TARGET_SDRAM : 4'b0000; 

//----------------------------------------
// Master Mapping
// -------------------------------------
assign m0_wb_wr.wbd_dat = m0_wbd_dat_i;
assign m0_wb_wr.wbd_adr = {m0_wbd_adr_i[31:2],2'b00};
assign m0_wb_wr.wbd_sel = m0_wbd_sel_i;
assign m0_wb_wr.wbd_we  = m0_wbd_we_i;
assign m0_wb_wr.wbd_cyc = m0_wbd_cyc_i;
assign m0_wb_wr.wbd_stb = m0_wbd_stb_i;
assign m0_wb_wr.wbd_tid = m0_wbd_tid_i;

assign m1_wb_wr.wbd_dat = m1_wbd_dat_i;
assign m1_wb_wr.wbd_adr = {m1_wbd_adr_i[31:2],2'b00};
assign m1_wb_wr.wbd_sel = m1_wbd_sel_i;
assign m1_wb_wr.wbd_we  = m1_wbd_we_i;
assign m1_wb_wr.wbd_cyc = m1_wbd_cyc_i;
assign m1_wb_wr.wbd_stb = m1_wbd_stb_i;
assign m1_wb_wr.wbd_tid = m1_wbd_tid_i;

assign m2_wb_wr.wbd_dat = m2_wbd_dat_i;
assign m2_wb_wr.wbd_adr = {m2_wbd_adr_i[31:2],2'b00};
assign m2_wb_wr.wbd_sel = m2_wbd_sel_i;
assign m2_wb_wr.wbd_we  = m2_wbd_we_i;
assign m2_wb_wr.wbd_cyc = m2_wbd_cyc_i;
assign m2_wb_wr.wbd_stb = m2_wbd_stb_i;
assign m2_wb_wr.wbd_tid = m2_wbd_tid_i;

assign m0_wbd_dat_o  =  m0_wb_rd.wbd_dat;
assign m0_wbd_ack_o  =  m0_wb_rd.wbd_ack;
assign m0_wbd_err_o  =  m0_wb_rd.wbd_err;

assign m1_wbd_dat_o  =  m1_wb_rd.wbd_dat;
assign m1_wbd_ack_o  =  m1_wb_rd.wbd_ack;
assign m1_wbd_err_o  =  m1_wb_rd.wbd_err;

assign m2_wbd_dat_o  =  m2_wb_rd.wbd_dat;
assign m2_wbd_ack_o  =  m2_wb_rd.wbd_ack;
assign m2_wbd_err_o  =  m2_wb_rd.wbd_err;

//----------------------------------------
// Slave Mapping
// -------------------------------------
// Masked Now and added stagging FF now
 assign  s0_wbd_dat_o =  s0_wb_wr.wbd_dat ;
 assign  s0_wbd_adr_o =  s0_wb_wr.wbd_adr ;
 assign  s0_wbd_sel_o =  s0_wb_wr.wbd_sel ;
 assign  s0_wbd_we_o  =  s0_wb_wr.wbd_we  ;
 assign  s0_wbd_cyc_o =  s0_wb_wr.wbd_cyc ;
 assign  s0_wbd_stb_o =  s0_wb_wr.wbd_stb ;
                      
 assign  s1_wbd_dat_o =  s1_wb_wr.wbd_dat ;
 assign  s1_wbd_adr_o =  {4'b0,s1_wb_wr.wbd_adr[27:0]} ;
 assign  s1_wbd_sel_o =  s1_wb_wr.wbd_sel ;
 assign  s1_wbd_we_o  =  s1_wb_wr.wbd_we  ;
 assign  s1_wbd_cyc_o =  s1_wb_wr.wbd_cyc ;
 assign  s1_wbd_stb_o =  s1_wb_wr.wbd_stb ;
                      
 assign  s2_wbd_dat_o =  s2_wb_wr.wbd_dat ;
 assign  s2_wbd_adr_o =  s2_wb_wr.wbd_adr[7:0] ; // Global Reg Need 8 bit
 assign  s2_wbd_sel_o =  s2_wb_wr.wbd_sel ;
 assign  s2_wbd_we_o  =  s2_wb_wr.wbd_we  ;
 assign  s2_wbd_cyc_o =  s2_wb_wr.wbd_cyc ;
 assign  s2_wbd_stb_o =  s2_wb_wr.wbd_stb ;

 assign  s3_wbd_dat_o =  s3_wb_wr.wbd_dat[31:0] ;
 assign  s3_wbd_adr_o =  s3_wb_wr.wbd_adr[7:0] ; // Global Reg Need 8 bit
 assign  s3_wbd_sel_o =  s3_wb_wr.wbd_sel ;
 assign  s3_wbd_we_o  =  s3_wb_wr.wbd_we  ;
 assign  s3_wbd_cyc_o =  s3_wb_wr.wbd_cyc ;
 assign  s3_wbd_stb_o =  s3_wb_wr.wbd_stb ;
 

 assign  s4_wbd_dat_o =  s4_wb_wr.wbd_dat[31:0] ;
 assign  s4_wbd_adr_o =  s4_wb_wr.wbd_adr[12:0] ; // MBIST Need 13 bit
 assign  s4_wbd_sel_o =  s4_wb_wr.wbd_sel[3:0] ;
 assign  s4_wbd_we_o  =  s4_wb_wr.wbd_we  ;
 assign  s4_wbd_cyc_o =  s4_wb_wr.wbd_cyc ;
 assign  s4_wbd_stb_o =  s4_wb_wr.wbd_stb ;

 assign s0_wb_rd.wbd_dat  = s0_wbd_dat_i ;
 assign s0_wb_rd.wbd_ack  = s0_wbd_ack_i ;
 assign s0_wb_rd.wbd_err  = 1'b0; // s0_wbd_err_i ; - unused
 
 assign s1_wb_rd.wbd_dat  = s1_wbd_dat_i ;
 assign s1_wb_rd.wbd_ack  = s1_wbd_ack_i ;
 assign s1_wb_rd.wbd_err  = 1'b0; // s1_wbd_err_i ; - unused
 
 assign s2_wb_rd.wbd_dat  = s2_wbd_dat_i ;
 assign s2_wb_rd.wbd_ack  = s2_wbd_ack_i ;
 assign s2_wb_rd.wbd_err  = 1'b0; // s2_wbd_err_i ; - unused

 assign s3_wb_rd.wbd_dat  = s3_wbd_dat_i ;
 assign s3_wb_rd.wbd_ack  = s3_wbd_ack_i ;
 assign s3_wb_rd.wbd_err  = 1'b0; // s3_wbd_err_i ; - unused

 assign s4_wb_rd.wbd_dat  = s4_wbd_dat_i ;
 assign s4_wb_rd.wbd_ack  = s4_wbd_ack_i ;
 assign s4_wb_rd.wbd_err  = 1'b0; // s3_wbd_err_i ; - unused

//
// arbitor 
//
logic [1:0]  gnt;

wb_arb	u_wb_arb(
	.clk(clk_i), 
	.rstn(rst_n),
	.req({	m2_wbd_stb_i & !m2_wbd_ack_o,
		m1_wbd_stb_i & !m1_wbd_ack_o,
		m0_wbd_stb_i & !m0_wbd_ack_o}),
	.gnt(gnt)
);


// Generate Multiplexed Master Interface based on grant
always_comb begin
     case(gnt)
        3'h0:	   m_bus_wr = m0_wb_wr;
        3'h1:	   m_bus_wr = m1_wb_wr;
        3'h2:	   m_bus_wr = m2_wb_wr;
        default:   m_bus_wr = m0_wb_wr;
     endcase			
end


// Generate Multiplexed Slave Interface based on target Id
wire [3:0] s_wbd_tid =  s_bus_wr.wbd_tid; // to fix iverilog warning
always_comb begin
     case(s_wbd_tid)
        4'h0:	   s_bus_rd = s0_wb_rd;
        4'h1:	   s_bus_rd = s1_wb_rd;
        4'h2:	   s_bus_rd = s2_wb_rd;
        4'h3:	   s_bus_rd = s3_wb_rd;
        4'h4:	   s_bus_rd = s4_wb_rd;
        default:   s_bus_rd = s0_wb_rd;
     endcase			
end


// Connect Master => Slave
assign  s0_wb_wr = (s_wbd_tid == 4'b0000) ? s_bus_wr : 'h0;
assign  s1_wb_wr = (s_wbd_tid == 4'b0001) ? s_bus_wr : 'h0;
assign  s2_wb_wr = (s_wbd_tid == 4'b0010) ? s_bus_wr : 'h0;
assign  s3_wb_wr = (s_wbd_tid == 4'b0011) ? s_bus_wr : 'h0;
assign  s4_wb_wr = (s_wbd_tid == 4'b0100) ? s_bus_wr : 'h0;

// Connect Slave to Master
assign  m0_wb_rd = (gnt == 2'b00) ? m_bus_rd : 'h0;
assign  m1_wb_rd = (gnt == 2'b01) ? m_bus_rd : 'h0;
assign  m2_wb_rd = (gnt == 2'b10) ? m_bus_rd : 'h0;


// Stagging FF to break write and read timing path
wb_stagging u_m_wb_stage(
         .clk_i            (clk_i              ), 
         .rst_n            (rst_n              ),
         // WishBone Input master I/P
         .m_wbd_dat_i      (m_bus_wr.wbd_dat   ),
         .m_wbd_adr_i      (m_bus_wr.wbd_adr   ),
         .m_wbd_sel_i      (m_bus_wr.wbd_sel   ),
         .m_wbd_we_i       (m_bus_wr.wbd_we    ),
         .m_wbd_cyc_i      (m_bus_wr.wbd_cyc   ),
         .m_wbd_stb_i      (m_bus_wr.wbd_stb   ),
         .m_wbd_tid_i      (m_bus_wr.wbd_tid   ),
         .m_wbd_dat_o      (m_bus_rd.wbd_dat   ),
         .m_wbd_ack_o      (m_bus_rd.wbd_ack   ),
         .m_wbd_err_o      (m_bus_rd.wbd_err   ),

         // Slave Interface
         .s_wbd_dat_i      (s_bus_rd.wbd_dat   ),
         .s_wbd_ack_i      (s_bus_rd.wbd_ack   ),
         .s_wbd_err_i      (s_bus_rd.wbd_err   ),
         .s_wbd_dat_o      (s_bus_wr.wbd_dat    ),
         .s_wbd_adr_o      (s_bus_wr.wbd_adr    ),
         .s_wbd_sel_o      (s_bus_wr.wbd_sel    ),
         .s_wbd_we_o       (s_bus_wr.wbd_we     ),
         .s_wbd_cyc_o      (s_bus_wr.wbd_cyc    ),
         .s_wbd_stb_o      (s_bus_wr.wbd_stb    ),
         .s_wbd_tid_o      (s_bus_wr.wbd_tid    )

);


endmodule

