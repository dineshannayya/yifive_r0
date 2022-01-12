////////////////////////////////////////////////////////////////////////////
// SPDX-FileCopyrightText:  2021 , Dinesh Annayya
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
// SPDX-FileContributor: Modified by Dinesh Annayya <dinesha@opencores.org>
//////////////////////////////////////////////////////////////////////
////                                                              ////
////  Standalone User validation Test bench                       ////
////                                                              ////
////  This file is part of the YIFive cores project               ////
////  https://github.com/dineshannayya/yifive_r0.git              ////
////  http://www.opencores.org/cores/yifive/                      ////
////                                                              ////
////  Description                                                 ////
////   This is a standalone test bench to validate the            ////
////   Digital core.                                              ////
////   1. User Risc core is booted using  compiled code of        ////
////      user_risc_boot.c                                        ////
////   2. User Risc core uses Serial Flash and SDRAM to boot      ////
////   3. After successful boot, Risc core will  write signature  ////
////      in to  user register from 0x3000_0018 to 0x3000_002C    ////
////   4. Through the External Wishbone Interface we read back    ////
////       and validate the user register to declared pass fail   ////
////                                                              ////
////  To Do:                                                      ////
////    nothing                                                   ////
////                                                              ////
////  Author(s):                                                  ////
////      - Dinesh Annayya, dinesha@opencores.org                 ////
////                                                              ////
////  Revision :                                                  ////
////    0.1 - 16th Feb 2021, Dinesh A                             ////
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

`default_nettype wire

`timescale 1 ns / 1 ns

`include "s25fl256s.sv"
`include "uprj_netlists.v"
`include "mt48lc8m8a2.v"

module user_spi_tb;
	reg clock;
	reg wb_rst_i;
	reg power1, power2;
	reg power3, power4;

        reg        wbd_ext_cyc_i;  // strobe/request
        reg        wbd_ext_stb_i;  // strobe/request
        reg [31:0] wbd_ext_adr_i;  // address
        reg        wbd_ext_we_i;  // write
        reg [31:0] wbd_ext_dat_i;  // data output
        reg [3:0]  wbd_ext_sel_i;  // byte enable

        wire [31:0] wbd_ext_dat_o;  // data input
        wire        wbd_ext_ack_o;  // acknowlegement
        wire        wbd_ext_err_o;  // error

	// User I/O
	wire [37:0] io_oeb;
	wire [37:0] io_out;
	wire [37:0] io_in;

	wire gpio;
	wire [37:0] mprj_io;
	wire [7:0] mprj_io_0;
	reg        test_fail;
	reg [31:0] read_data;

/*************************************************************
*  SPI FSM State Control
*
*   OPERATION   COMMAND                   SEQUENCE 
*
*    ERASE       P4E(0x20)           ->  COMMAND + ADDRESS
*    ERASE       P8E(0x40)           ->  COMMAND + ADDRESS
*    ERASE       SE(0xD8)            ->  COMMAND + ADDRESS
*    ERASE       BE(0x60)            ->  COMMAND + ADDRESS
*    ERASE       BE(0xC7)            ->  COMMAND 
*    PROGRAM     PP(0x02)            ->  COMMAND + ADDRESS + Write DATA
*    PROGRAM     QPP(0x32)           ->  COMMAND + ADDRESS + Write DATA
*    READ        READ(0x3)           ->  COMMAND + ADDRESS + READ DATA
*    READ        FAST_READ(0xB)      ->  COMMAND + ADDRESS + DUMMY + READ DATA
*    READ        DOR (0x3B)          ->  COMMAND + ADDRESS + DUMMY + READ DATA
*    READ        QOR (0x6B)          ->  COMMAND + ADDRESS + DUMMY + READ DATA
*    READ        DIOR (0xBB)         ->  COMMAND + ADDRESS + MODE  + READ DATA
*    READ        QIOR (0xEB)         ->  COMMAND + ADDRESS + MODE  + DUMMY + READ DATA
*    READ        RDID (0x9F)         ->  COMMAND + READ DATA
*    READ        READ_ID (0x90)      ->  COMMAND + ADDRESS + READ DATA
*    WRITE       WREN(0x6)           ->  COMMAND
*    WRITE       WRDI                ->  COMMAND
*    STATUS      RDSR(0x05)          ->  COMMAND + READ DATA
*    STATUS      RCR(0x35)           ->  COMMAND + READ DATA
*    CONFIG      WRR(0x01)           ->  COMMAND + WRITE DATA
*    CONFIG      CLSR(0x30)          ->  COMMAND
*    Power Saving DP(0xB9)           ->  COMMAND
*    Power Saving RES(0xAB)          ->  COMMAND + READ DATA
*    OTP          OTPP(0x42)         ->  COMMAND + ADDR+ WRITE DATA
*    OTP          OTPR(0x4B)         ->  COMMAND + ADDR + DUMMY + READ DATA
*    ********************************************************************/
parameter P_FSM_C      = 4'b0000; // Command Phase Only
parameter P_FSM_CW     = 4'b0001; // Command + Write DATA Phase Only
parameter P_FSM_CA     = 4'b0010; // Command -> Address Phase Only

parameter P_FSM_CAR    = 4'b0011; // Command -> Address -> Read Data
parameter P_FSM_CADR   = 4'b0100; // Command -> Address -> Dummy -> Read Data
parameter P_FSM_CAMR   = 4'b0101; // Command -> Address -> Mode -> Read Data
parameter P_FSM_CAMDR  = 4'b0110; // Command -> Address -> Mode -> Dummy -> Read Data

parameter P_FSM_CAW    = 4'b0111; // Command -> Address ->Write Data
parameter P_FSM_CADW   = 4'b1000; // Command -> Address -> DUMMY + Write Data

parameter P_FSM_CDR    = 4'b1001; // COMMAND -> DUMMY -> READ
parameter P_FSM_CDW    = 4'b1010; // COMMAND -> DUMMY -> WRITE
parameter P_FSM_CR     = 4'b1011;  // COMMAND -> READ

	// External clock is used by default.  Make this artificially fast for the
	// simulation.  Normally this would be a slow clock and the digital PLL
	// would be the fast clock.

	always #12.5 clock <= (clock === 1'b0);

	initial begin
		clock = 0;
                wbd_ext_cyc_i ='h0;  // strobe/request
                wbd_ext_stb_i ='h0;  // strobe/request
                wbd_ext_adr_i ='h0;  // address
                wbd_ext_we_i  ='h0;  // write
                wbd_ext_dat_i ='h0;  // data output
                wbd_ext_sel_i ='h0;  // byte enable
	end

	`ifdef WFDUMP
	   initial begin
	   	$dumpfile("user_spi.vcd");
	   	$dumpvars(5, user_spi_tb);
	   end
       `endif

	initial begin

		#200; // Wait for reset removal
	        repeat (10) @(posedge clock);
		$display("Monitor: Standalone User Risc Boot Test Started");

		// Remove Wb Reset
		wb_user_core_write('h3080_0000,'h1);

	        repeat (2) @(posedge clock);
		#1;
		// Remove WB and SPI Reset, Keep SDARM and CORE under Reset
                wb_user_core_write('h3080_0000,'h5);

                wb_user_core_write('h3080_0004,'h0); // Change the Bank Sel 0


		test_fail = 0;
	        repeat (200) @(posedge clock);
		$display("#############################################");
		$display("  Read Identification (RDID:0x9F)            ");
		$display("#############################################");
                wb_user_core_write('h3080_0004,'h10); // Change the Bank Sel 10
		wb_user_core_write(32'h1000000C,{15'h0,1'b0,2'b00,2'b00,4'b0001});
		wb_user_core_write(32'h10000010,{8'h4,2'b00,2'b00,4'b1011,8'h00,8'h9F});
		wb_user_core_read_check(32'h1000001C,read_data,32'h00190201);
		$display("#############################################");
		$display("Testing Direct SPI Memory Read              ");
		$display(" SPI Mode: QDDR (Dual 4 but)                ");
		$display("Prefetch : 1DW, OPCODE:READ(0xED)           ");
		$display("SEQ: Command -> Address -> Read Data        ");
		$display("#############################################");
		// QDDR Config
                wb_user_core_write('h3080_0004,'h10); // Change the Bank Sel 10
		wb_user_core_write(32'h10000004,{24'h0,2'b01,2'b11,4'b0001});
		wb_user_core_write(32'h10000008,{8'h04,2'b01,2'b10,4'h6,8'h00,8'hED});
                wb_user_core_write('h3080_0004,'h00); // Change the Bank Sel 00
		wb_user_core_read_check(32'h00000200,read_data,32'h00000093);
		wb_user_core_read_check(32'h00000204,read_data,32'h00000113);
		wb_user_core_read_check(32'h00000208,read_data,32'h00000193);
		wb_user_core_read_check(32'h0000020C,read_data,32'h00000213);
		wb_user_core_read_check(32'h00000210,read_data,32'h00000293);
		wb_user_core_read_check(32'h00000214,read_data,32'h00000313);
		wb_user_core_read_check(32'h00000218,read_data,32'h00000393);
		wb_user_core_read_check(32'h0000021C,read_data,32'h00000413);
		wb_user_core_read_check(32'h00000400,read_data,32'h11223737);
		wb_user_core_read_check(32'h00000404,read_data,32'h100207b7);
		wb_user_core_read_check(32'h00000408,read_data,32'h34470293);
		wb_user_core_read_check(32'h0000040C,read_data,32'h22334337);
		wb_user_core_read_check(32'h00000410,read_data,32'h0057ac23);
		wb_user_core_read_check(32'h00000414,read_data,32'h45530393);
		wb_user_core_read_check(32'h00000418,read_data,32'h33445537);
		wb_user_core_read_check(32'h0000041C,read_data,32'h0077ae23);
		$display("#############################################");
		$display("Testing Direct SPI Memory Read              ");
		$display(" SPI Mode: Normal/Single Bit                ");
		$display("Prefetch : 1DW, OPCODE:READ(0x3)            ");
		$display("SEQ: Command -> Address -> Read Data        ");
		$display("#############################################");
                wb_user_core_write('h3080_0004,'h10); // Change the Bank Sel 10
		wb_user_core_write(32'h10000004,{24'h0,2'b00,2'b00,4'b0001});
		wb_user_core_write(32'h10000008,{8'h04,2'b00,2'b10,4'h3,8'h00,8'h03});
                wb_user_core_write('h3080_0004,'h00); // Change the Bank Sel 00
		wb_user_core_read_check(32'h00000200,read_data,32'h00000093);
		wb_user_core_read_check(32'h00000204,read_data,32'h00000113);
		wb_user_core_read_check(32'h00000208,read_data,32'h00000193);
		wb_user_core_read_check(32'h0000020C,read_data,32'h00000213);
		wb_user_core_read_check(32'h00000210,read_data,32'h00000293);
		wb_user_core_read_check(32'h00000214,read_data,32'h00000313);
		wb_user_core_read_check(32'h00000218,read_data,32'h00000393);
		wb_user_core_read_check(32'h0000021C,read_data,32'h00000413);
		wb_user_core_read_check(32'h00000400,read_data,32'h11223737);
		wb_user_core_read_check(32'h00000404,read_data,32'h100207b7);
		wb_user_core_read_check(32'h00000408,read_data,32'h34470293);
		wb_user_core_read_check(32'h0000040C,read_data,32'h22334337);
		wb_user_core_read_check(32'h00000410,read_data,32'h0057ac23);
		wb_user_core_read_check(32'h00000414,read_data,32'h45530393);
		wb_user_core_read_check(32'h00000418,read_data,32'h33445537);
		wb_user_core_read_check(32'h0000041C,read_data,32'h0077ae23);
		$display("#############################################");
		$display("Testing Direct SPI Memory Read              ");
		$display(" SPI Mode: Normal/Single Bit                ");
		$display("Prefetch : 1DW, OPCODE:FASTREAD(0xB)        ");
		$display("SEQ: Command -> Address -> Dummy -> Read Data");
		$display("#############################################");
                wb_user_core_write('h3080_0004,'h10); // Change the Bank Sel 10
		wb_user_core_write(32'h10000004,{24'h0,2'b00,2'b00,4'b0001});
		wb_user_core_write(32'h10000008,{8'h04,2'b00,2'b10,4'h4,8'h00,8'h0B});
                wb_user_core_write('h3080_0004,'h00); // Change the Bank Sel 00
		wb_user_core_read_check(32'h00000200,read_data,32'h00000093);
		wb_user_core_read_check(32'h00000204,read_data,32'h00000113);
		wb_user_core_read_check(32'h00000208,read_data,32'h00000193);
		wb_user_core_read_check(32'h0000020C,read_data,32'h00000213);
		wb_user_core_read_check(32'h00000210,read_data,32'h00000293);
		wb_user_core_read_check(32'h00000214,read_data,32'h00000313);
		wb_user_core_read_check(32'h00000218,read_data,32'h00000393);
		wb_user_core_read_check(32'h0000021C,read_data,32'h00000413);
		wb_user_core_read_check(32'h00000400,read_data,32'h11223737);
		wb_user_core_read_check(32'h00000404,read_data,32'h100207b7);
		wb_user_core_read_check(32'h00000408,read_data,32'h34470293);
		wb_user_core_read_check(32'h0000040C,read_data,32'h22334337);
		wb_user_core_read_check(32'h00000410,read_data,32'h0057ac23);
		wb_user_core_read_check(32'h00000414,read_data,32'h45530393);
		wb_user_core_read_check(32'h00000418,read_data,32'h33445537);
		wb_user_core_read_check(32'h0000041C,read_data,32'h0077ae23);

		$display("#############################################");
		$display("Testing Direct SPI Memory Read              ");
		$display(" SPI Mode: Dual Mode                        ");
		$display("Prefetch : 1DW, OPCODE:DOR(0x3B)        ");
		$display("SEQ: Command -> Address -> Dummy -> Read Data");
		$display("#############################################");
                wb_user_core_write('h3080_0004,'h10); // Change the Bank Sel 10
		wb_user_core_write(32'h10000004,{24'h0,2'b10,2'b01,4'b0001});
		wb_user_core_write(32'h10000008,{8'h04,2'b00,2'b10,4'h4,8'h00,8'h3B});
                wb_user_core_write('h3080_0004,'h00); // Change the Bank Sel 00
		wb_user_core_read_check(32'h00000200,read_data,32'h00000093);
		wb_user_core_read_check(32'h00000204,read_data,32'h00000113);
		wb_user_core_read_check(32'h00000208,read_data,32'h00000193);
		wb_user_core_read_check(32'h0000020C,read_data,32'h00000213);
		wb_user_core_read_check(32'h00000210,read_data,32'h00000293);
		wb_user_core_read_check(32'h00000214,read_data,32'h00000313);
		wb_user_core_read_check(32'h00000218,read_data,32'h00000393);
		wb_user_core_read_check(32'h0000021C,read_data,32'h00000413);
		wb_user_core_read_check(32'h00000400,read_data,32'h11223737);
		wb_user_core_read_check(32'h00000404,read_data,32'h100207b7);
		wb_user_core_read_check(32'h00000408,read_data,32'h34470293);
		wb_user_core_read_check(32'h0000040C,read_data,32'h22334337);
		wb_user_core_read_check(32'h00000410,read_data,32'h0057ac23);
		wb_user_core_read_check(32'h00000414,read_data,32'h45530393);
		wb_user_core_read_check(32'h00000418,read_data,32'h33445537);
		wb_user_core_read_check(32'h0000041C,read_data,32'h0077ae23);

		$display("#############################################");
		$display("Testing Direct SPI Memory Read with Prefetch");
		$display(" SPI Mode: Quad                             ");
		$display("Prefetch : 8DW, OPCODE:URAD READ(0xEB)      ");
		$display("SEQ: Command -> Address -> Dummy -> Read Data");
		$display("#############################################");
                wb_user_core_write('h3080_0004,'h10); // Change the Bank Sel 10
		wb_user_core_write(32'h10000004,{24'h0,2'b01,2'b10,4'b0001});
		wb_user_core_write(32'h10000008,{8'h20,2'b01,2'b10,4'h6,8'h00,8'hEB});
                wb_user_core_write('h3080_0004,'h00); // Change the Bank Sel 00
		wb_user_core_read_check(32'h00000200,read_data,32'h00000093);
		wb_user_core_read_check(32'h00000204,read_data,32'h00000113);
		wb_user_core_read_check(32'h00000208,read_data,32'h00000193);
		wb_user_core_read_check(32'h0000020C,read_data,32'h00000213);
		wb_user_core_read_check(32'h00000210,read_data,32'h00000293);
		wb_user_core_read_check(32'h00000214,read_data,32'h00000313);
		wb_user_core_read_check(32'h00000218,read_data,32'h00000393);
		wb_user_core_read_check(32'h0000021C,read_data,32'h00000413);
		wb_user_core_read_check(32'h00000400,read_data,32'h11223737);
		wb_user_core_read_check(32'h00000404,read_data,32'h100207b7);
		wb_user_core_read_check(32'h00000408,read_data,32'h34470293);
		wb_user_core_read_check(32'h0000040C,read_data,32'h22334337);
		wb_user_core_read_check(32'h00000410,read_data,32'h0057ac23);
		wb_user_core_read_check(32'h00000414,read_data,32'h45530393);
		wb_user_core_read_check(32'h00000418,read_data,32'h33445537);
		wb_user_core_read_check(32'h0000041C,read_data,32'h0077ae23);

		$display("#############################################");
		$display("Testing Direct SPI Memory Read with Prefetch:3DW");
		$display("#############################################");
                wb_user_core_write('h3080_0004,'h10); // Change the Bank Sel 10
		wb_user_core_write(32'h10000004,{24'h0,2'b01,2'b10,4'b0001});
		wb_user_core_write(32'h10000008,{8'hC,2'b01,2'b10,4'h6,8'h00,8'hEB});
                wb_user_core_write('h3080_0004,'h00); // Change the Bank Sel 00
		wb_user_core_read_check(32'h00000200,read_data,32'h00000093);
		wb_user_core_read_check(32'h00000204,read_data,32'h00000113);
		wb_user_core_read_check(32'h00000208,read_data,32'h00000193);
		wb_user_core_read_check(32'h0000020C,read_data,32'h00000213);
		wb_user_core_read_check(32'h00000210,read_data,32'h00000293);
		wb_user_core_read_check(32'h00000214,read_data,32'h00000313);
		wb_user_core_read_check(32'h00000218,read_data,32'h00000393);
		wb_user_core_read_check(32'h0000021C,read_data,32'h00000413);
		wb_user_core_read_check(32'h00000400,read_data,32'h11223737);
		wb_user_core_read_check(32'h00000404,read_data,32'h100207b7);
		wb_user_core_read_check(32'h00000408,read_data,32'h34470293);
		wb_user_core_read_check(32'h0000040C,read_data,32'h22334337);
		wb_user_core_read_check(32'h00000410,read_data,32'h0057ac23);
		wb_user_core_read_check(32'h00000414,read_data,32'h45530393);
		wb_user_core_read_check(32'h00000418,read_data,32'h33445537);
		wb_user_core_read_check(32'h0000041C,read_data,32'h0077ae23);

		$display("#############################################");
		$display("Testing Direct SPI Memory Read with Prefetch:2DW");
		$display("#############################################");
                wb_user_core_write('h3080_0004,'h10); // Change the Bank Sel 10
		wb_user_core_write(32'h10000004,{24'h0,2'b01,2'b10,4'b0001});
		wb_user_core_write(32'h10000008,{8'h8,2'b01,2'b10,4'h6,8'h00,8'hEB});
                wb_user_core_write('h3080_0004,'h00); // Change the Bank Sel 00
		wb_user_core_read_check(32'h00000200,read_data,32'h00000093);
		wb_user_core_read_check(32'h00000204,read_data,32'h00000113);
		wb_user_core_read_check(32'h00000208,read_data,32'h00000193);
		wb_user_core_read_check(32'h0000020C,read_data,32'h00000213);
		wb_user_core_read_check(32'h00000210,read_data,32'h00000293);
		wb_user_core_read_check(32'h00000214,read_data,32'h00000313);
		wb_user_core_read_check(32'h00000218,read_data,32'h00000393);
		wb_user_core_read_check(32'h0000021C,read_data,32'h00000413);
		wb_user_core_read_check(32'h00000400,read_data,32'h11223737);
		wb_user_core_read_check(32'h00000404,read_data,32'h100207b7);
		wb_user_core_read_check(32'h00000408,read_data,32'h34470293);
		wb_user_core_read_check(32'h0000040C,read_data,32'h22334337);
		wb_user_core_read_check(32'h00000410,read_data,32'h0057ac23);
		wb_user_core_read_check(32'h00000414,read_data,32'h45530393);
		wb_user_core_read_check(32'h00000418,read_data,32'h33445537);
		wb_user_core_read_check(32'h0000041C,read_data,32'h0077ae23);

		$display("#############################################");
		$display("Testing Direct SPI Memory Read with Prefetch:1DW");
		$display("#############################################");
                wb_user_core_write('h3080_0004,'h10); // Change the Bank Sel 10
		wb_user_core_write(32'h10000004,{24'h0,2'b01,2'b10,4'b0001});
		wb_user_core_write(32'h10000008,{8'h4,2'b01,2'b10,4'h6,8'h00,8'hEB});
                wb_user_core_write('h3080_0004,'h00); // Change the Bank Sel 00
		wb_user_core_read_check(32'h00000200,read_data,32'h00000093);
		wb_user_core_read_check(32'h00000204,read_data,32'h00000113);
		wb_user_core_read_check(32'h00000208,read_data,32'h00000193);
		wb_user_core_read_check(32'h0000020C,read_data,32'h00000213);
		wb_user_core_read_check(32'h00000210,read_data,32'h00000293);
		wb_user_core_read_check(32'h00000214,read_data,32'h00000313);
		wb_user_core_read_check(32'h00000218,read_data,32'h00000393);
		wb_user_core_read_check(32'h0000021C,read_data,32'h00000413);
		wb_user_core_read_check(32'h00000400,read_data,32'h11223737);
		wb_user_core_read_check(32'h00000404,read_data,32'h100207b7);
		wb_user_core_read_check(32'h00000408,read_data,32'h34470293);
		wb_user_core_read_check(32'h0000040C,read_data,32'h22334337);
		wb_user_core_read_check(32'h00000410,read_data,32'h0057ac23);
		wb_user_core_read_check(32'h00000414,read_data,32'h45530393);
		wb_user_core_read_check(32'h00000418,read_data,32'h33445537);
		wb_user_core_read_check(32'h0000041C,read_data,32'h0077ae23);

		$display("#############################################");
		$display("Testing Direct SPI Memory Read with Prefetch:7DW");
		$display("#############################################");
                wb_user_core_write('h3080_0004,'h10); // Change the Bank Sel 10
		wb_user_core_write(32'h10000004,{24'h0,2'b01,2'b10,4'b0001});
		wb_user_core_write(32'h10000008,{8'h1C,2'b01,2'b10,4'h6,8'h00,8'hEB});
                wb_user_core_write('h3080_0004,'h00); // Change the Bank Sel 00
		wb_user_core_read_check(32'h00000200,read_data,32'h00000093);
		wb_user_core_read_check(32'h00000204,read_data,32'h00000113);
		wb_user_core_read_check(32'h00000208,read_data,32'h00000193);
		wb_user_core_read_check(32'h0000020C,read_data,32'h00000213);
		wb_user_core_read_check(32'h00000210,read_data,32'h00000293);
		wb_user_core_read_check(32'h00000214,read_data,32'h00000313);
		wb_user_core_read_check(32'h00000218,read_data,32'h00000393);
		wb_user_core_read_check(32'h0000021C,read_data,32'h00000413);
		wb_user_core_read_check(32'h00000400,read_data,32'h11223737);
		wb_user_core_read_check(32'h00000404,read_data,32'h100207b7);
		wb_user_core_read_check(32'h00000408,read_data,32'h34470293);
		wb_user_core_read_check(32'h0000040C,read_data,32'h22334337);
		wb_user_core_read_check(32'h00000410,read_data,32'h0057ac23);
		wb_user_core_read_check(32'h00000414,read_data,32'h45530393);
		wb_user_core_read_check(32'h00000418,read_data,32'h33445537);
		wb_user_core_read_check(32'h0000041C,read_data,32'h0077ae23);

		$display("#############################################");
		$display("  Testing Single Word Indirect SPI Memory Read");
		$display("#############################################");
                wb_user_core_write('h3080_0004,'h10); // Change the Bank Sel 10
		wb_user_core_write(32'h1000000C,{15'h0,1'b0,2'b01,2'b10,4'b0001});
		wb_user_core_write(32'h10000010,{8'h4,2'b01,2'b10,4'b0110,8'h00,8'hEB});
		wb_user_core_write(32'h10000014,32'h00000200);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00000093);
		wb_user_core_write(32'h10000014,32'h00000204);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00000113);
		wb_user_core_write(32'h10000014,32'h00000208);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00000193);
		wb_user_core_write(32'h10000014,32'h0000020C);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00000213);
		wb_user_core_write(32'h10000014,32'h00000210);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00000293);
		wb_user_core_write(32'h10000014,32'h00000214);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00000313);
		wb_user_core_write(32'h10000014,32'h00000218);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00000393);
		wb_user_core_write(32'h10000014,32'h0000021C);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00000413);
		wb_user_core_write(32'h10000014,32'h00000400);
		wb_user_core_read_check(32'h1000001C,read_data,32'h11223737);
		wb_user_core_write(32'h10000014,32'h00000404);
		wb_user_core_read_check(32'h1000001C,read_data,32'h100207b7);
		wb_user_core_write(32'h10000014,32'h00000408);
		wb_user_core_read_check(32'h1000001C,read_data,32'h34470293);
		wb_user_core_write(32'h10000014,32'h0000040C);
		wb_user_core_read_check(32'h1000001C,read_data,32'h22334337);
		wb_user_core_write(32'h10000014,32'h00000410);
		wb_user_core_read_check(32'h1000001C,read_data,32'h0057ac23);
		wb_user_core_write(32'h10000014,32'h00000414);
		wb_user_core_read_check(32'h1000001C,read_data,32'h45530393);
		wb_user_core_write(32'h10000014,32'h00000418);
		wb_user_core_read_check(32'h1000001C,read_data,32'h33445537);
		wb_user_core_write(32'h10000014,32'h0000041C);
		wb_user_core_read_check(32'h1000001C,read_data,32'h0077ae23);
		repeat (100) @(posedge clock);
		$display("#############################################");
		$display("  Testing Two Word Indirect SPI Memory Read");
		$display("#############################################");
                wb_user_core_write('h3080_0004,'h10); // Change the Bank Sel 10
		wb_user_core_write(32'h1000000C,{15'h0,1'b0,2'b01,2'b10,4'b0001});
		wb_user_core_write(32'h10000010,{8'h8,2'b01,2'b10,4'b0110,8'h00,8'hEB});
		wb_user_core_write(32'h10000014,32'h00000200);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00000093);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00000113);
		wb_user_core_write(32'h10000014,32'h00000208);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00000193);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00000213);
		wb_user_core_write(32'h10000014,32'h00000210);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00000293);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00000313);
		wb_user_core_write(32'h10000014,32'h00000218);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00000393);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00000413);
		wb_user_core_write(32'h10000014,32'h00000400);
		wb_user_core_read_check(32'h1000001C,read_data,32'h11223737);
		wb_user_core_read_check(32'h1000001C,read_data,32'h100207b7);
		wb_user_core_write(32'h10000014,32'h00000408);
		wb_user_core_read_check(32'h1000001C,read_data,32'h34470293);
		wb_user_core_read_check(32'h1000001C,read_data,32'h22334337);
		wb_user_core_write(32'h10000014,32'h00000410);
		wb_user_core_read_check(32'h1000001C,read_data,32'h0057ac23);
		wb_user_core_read_check(32'h1000001C,read_data,32'h45530393);
		wb_user_core_write(32'h10000014,32'h00000418);
		wb_user_core_read_check(32'h1000001C,read_data,32'h33445537);
		wb_user_core_read_check(32'h1000001C,read_data,32'h0077ae23);
		repeat (100) @(posedge clock);
		$display("#############################################");
		$display("  Testing Three Word Indirect SPI Memory Read");
		$display("#############################################");
                wb_user_core_write('h3080_0004,'h10); // Change the Bank Sel 10
		wb_user_core_write(32'h1000000C,{15'h0,1'b0,2'b01,2'b10,4'b0001});
		wb_user_core_write(32'h10000010,{8'hC,2'b01,2'b10,4'b0110,8'h00,8'hEB});
		wb_user_core_write(32'h10000014,32'h00000200);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00000093);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00000113);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00000193);
		wb_user_core_write(32'h10000014,32'h0000020C);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00000213);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00000293);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00000313);
		wb_user_core_write(32'h10000014,32'h00000400);
		wb_user_core_read_check(32'h1000001C,read_data,32'h11223737);
		wb_user_core_read_check(32'h1000001C,read_data,32'h100207b7);
		wb_user_core_read_check(32'h1000001C,read_data,32'h34470293);
		wb_user_core_write(32'h10000014,32'h0000040C);
		wb_user_core_read_check(32'h1000001C,read_data,32'h22334337);
		wb_user_core_read_check(32'h1000001C,read_data,32'h0057ac23);
		wb_user_core_read_check(32'h1000001C,read_data,32'h45530393);
		repeat (100) @(posedge clock);
		$display("#############################################");
		$display("  Testing Four Word Indirect SPI Memory Read");
		$display("#############################################");
                wb_user_core_write('h3080_0004,'h10); // Change the Bank Sel 10
		wb_user_core_write(32'h1000000C,{15'h0,1'b0,2'b01,2'b10,4'b0001});
		wb_user_core_write(32'h10000010,{8'h10,2'b01,2'b10,4'b0110,8'h00,8'hEB});
		wb_user_core_write(32'h10000014,32'h00000200);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00000093);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00000113);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00000193);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00000213);
		wb_user_core_write(32'h10000014,32'h00000210);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00000293);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00000313);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00000393);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00000413);
		wb_user_core_write(32'h10000014,32'h00000400);
		wb_user_core_read_check(32'h1000001C,read_data,32'h11223737);
		wb_user_core_read_check(32'h1000001C,read_data,32'h100207b7);
		wb_user_core_read_check(32'h1000001C,read_data,32'h34470293);
		wb_user_core_read_check(32'h1000001C,read_data,32'h22334337);
		wb_user_core_write(32'h10000014,32'h00000410);
		wb_user_core_read_check(32'h1000001C,read_data,32'h0057ac23);
		wb_user_core_read_check(32'h1000001C,read_data,32'h45530393);
		wb_user_core_read_check(32'h1000001C,read_data,32'h33445537);
		wb_user_core_read_check(32'h1000001C,read_data,32'h0077ae23);
		repeat (100) @(posedge clock);
		$display("#############################################");
		$display("  Testing Five Word Indirect SPI Memory Read");
		$display("#############################################");
                wb_user_core_write('h3080_0004,'h10); // Change the Bank Sel 10
		wb_user_core_write(32'h1000000C,{15'h0,1'b0,2'b01,2'b10,4'b0001});
		wb_user_core_write(32'h10000010,{8'h14,2'b01,2'b10,4'b0110,8'h00,8'hEB});
		wb_user_core_write(32'h10000014,32'h00000200);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00000093);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00000113);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00000193);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00000213);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00000293);
		wb_user_core_write(32'h10000014,32'h00000400);
		wb_user_core_read_check(32'h1000001C,read_data,32'h11223737);
		wb_user_core_read_check(32'h1000001C,read_data,32'h100207b7);
		wb_user_core_read_check(32'h1000001C,read_data,32'h34470293);
		wb_user_core_read_check(32'h1000001C,read_data,32'h22334337);
		wb_user_core_read_check(32'h1000001C,read_data,32'h0057ac23);
		$display("#############################################");
		$display("  Testing Eight Word Indirect SPI Memory Read");
		$display("#############################################");
                wb_user_core_write('h3080_0004,'h10); // Change the Bank Sel 10
		wb_user_core_write(32'h1000000C,{15'h0,1'b0,2'b01,2'b10,4'b0001});
		wb_user_core_write(32'h10000010,{8'h20,2'b01,2'b10,4'b0110,8'h00,8'hEB});
		wb_user_core_write(32'h10000014,32'h00000200);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00000093);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00000113);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00000193);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00000213);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00000293);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00000313);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00000393);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00000413);
		wb_user_core_write(32'h10000014,32'h00000400);
		wb_user_core_read_check(32'h1000001C,read_data,32'h11223737);
		wb_user_core_read_check(32'h1000001C,read_data,32'h100207b7);
		wb_user_core_read_check(32'h1000001C,read_data,32'h34470293);
		wb_user_core_read_check(32'h1000001C,read_data,32'h22334337);
		wb_user_core_read_check(32'h1000001C,read_data,32'h0057ac23);
		wb_user_core_read_check(32'h1000001C,read_data,32'h45530393);
		wb_user_core_read_check(32'h1000001C,read_data,32'h33445537);
		wb_user_core_read_check(32'h1000001C,read_data,32'h0077ae23);

		$display("#############################################");
		$display("  Sector Erase Command            ");
		$display("#############################################");
                wb_user_core_write('h3080_0004,'h10); // Change the Bank Sel 10
		// WEN COMMAND
		wb_user_core_write(32'h1000000C,{15'h0,1'b0,2'b00,2'b00,4'b0001});
		wb_user_core_write(32'h10000010,{8'h0,2'b00,2'b00,4'b0000,8'h00,8'h06});
		wb_user_core_write(32'h10000018,32'h0);
                // Sector Erase
		wb_user_core_write(32'h1000000C,{15'h0,1'b0,2'b00,2'b00,4'b0001});
		wb_user_core_write(32'h10000010,{8'h0,2'b00,2'b10,4'b0010,8'h00,8'hD8});
		wb_user_core_write(32'h10000014,32'h00000000);
		wb_user_core_write(32'h10000018,32'h0);

		// RDSR
		wb_user_core_write(32'h1000000C,{15'h0,1'b0,2'b00,2'b00,4'b0001});
		wb_user_core_write(32'h10000010,{8'h4,2'b00,2'b00,4'b1011,8'h00,8'h05});
		read_data = 32'hFFFF_FFFF;
		while (read_data[1:0] == 2'b11) begin
		    wb_user_core_read(32'h1000001C,read_data);
		    repeat (10) @(posedge clock);
		end

		$display("#############################################");
		$display("  Page Write Command Address: 0x00          ");
		$display("#############################################");
		// WEN COMMAND
		wb_user_core_write(32'h1000000C,{15'h0,1'b0,2'b00,2'b00,4'b0001});
		wb_user_core_write(32'h10000010,{8'h0,2'b00,2'b00,4'b0000,8'h00,8'h06});
		wb_user_core_write(32'h10000018,32'h0);
		 // Page Programing
		wb_user_core_write(32'h1000000C,{15'h0,1'b0,2'b00,2'b00,4'b0001});
		wb_user_core_write(32'h10000010,{8'hF0,2'b00,2'b10,P_FSM_CAW,8'h00,8'h02});
		wb_user_core_write(32'h10000014,32'h00000000);
		wb_user_core_write(32'h10000018,32'h00010000);
		wb_user_core_write(32'h10000018,32'h00010001);
		wb_user_core_write(32'h10000018,32'h00010002);
		wb_user_core_write(32'h10000018,32'h00010003);
		wb_user_core_write(32'h10000018,32'h00010004);
		wb_user_core_write(32'h10000018,32'h00010005);
		wb_user_core_write(32'h10000018,32'h00010006);
		wb_user_core_write(32'h10000018,32'h00010007);
		wb_user_core_write(32'h10000018,32'h00010008);
		wb_user_core_write(32'h10000018,32'h00010009);
		wb_user_core_write(32'h10000018,32'h00010010);
		wb_user_core_write(32'h10000018,32'h00010011);
		wb_user_core_write(32'h10000018,32'h00010012);
		wb_user_core_write(32'h10000018,32'h00010013);
		wb_user_core_write(32'h10000018,32'h00010014);
		wb_user_core_write(32'h10000018,32'h00010015);
		wb_user_core_write(32'h10000018,32'h00010016);
		wb_user_core_write(32'h10000018,32'h00010017);
		wb_user_core_write(32'h10000018,32'h00010018);
		wb_user_core_write(32'h10000018,32'h00010019);
		wb_user_core_write(32'h10000018,32'h00010020);
		wb_user_core_write(32'h10000018,32'h00010021);
		wb_user_core_write(32'h10000018,32'h00010022);
		wb_user_core_write(32'h10000018,32'h00010023);
		wb_user_core_write(32'h10000018,32'h00010024);
		wb_user_core_write(32'h10000018,32'h00010025);
		wb_user_core_write(32'h10000018,32'h00010026);
		wb_user_core_write(32'h10000018,32'h00010027);
		wb_user_core_write(32'h10000018,32'h00010028);
		wb_user_core_write(32'h10000018,32'h00010029);
		wb_user_core_write(32'h10000018,32'h00010030);
		wb_user_core_write(32'h10000018,32'h00010031);
		wb_user_core_write(32'h10000018,32'h00010032);
		wb_user_core_write(32'h10000018,32'h00010033);
		wb_user_core_write(32'h10000018,32'h00010034);
		wb_user_core_write(32'h10000018,32'h00010035);
		wb_user_core_write(32'h10000018,32'h00010036);
		wb_user_core_write(32'h10000018,32'h00010037);
		wb_user_core_write(32'h10000018,32'h00010038);
		wb_user_core_write(32'h10000018,32'h00010039);
		wb_user_core_write(32'h10000018,32'h00010040);
		wb_user_core_write(32'h10000018,32'h00010041);
		wb_user_core_write(32'h10000018,32'h00010042);
		wb_user_core_write(32'h10000018,32'h00010043);
		wb_user_core_write(32'h10000018,32'h00010044);
		wb_user_core_write(32'h10000018,32'h00010045);
		wb_user_core_write(32'h10000018,32'h00010046);
		wb_user_core_write(32'h10000018,32'h00010047);
		wb_user_core_write(32'h10000018,32'h00010048);
		wb_user_core_write(32'h10000018,32'h00010049);
		wb_user_core_write(32'h10000018,32'h00010050);
		wb_user_core_write(32'h10000018,32'h00010051);
		wb_user_core_write(32'h10000018,32'h00010052);
		wb_user_core_write(32'h10000018,32'h00010053);
		wb_user_core_write(32'h10000018,32'h00010054);
		wb_user_core_write(32'h10000018,32'h00010055);
		wb_user_core_write(32'h10000018,32'h00010056);
		wb_user_core_write(32'h10000018,32'h00010057);
		wb_user_core_write(32'h10000018,32'h00010058);
		wb_user_core_write(32'h10000018,32'h00010059);

		// RDSR
		wb_user_core_write(32'h1000000C,{15'h0,1'b0,2'b00,2'b00,4'b0001});
		wb_user_core_write(32'h10000010,{8'h4,2'b00,2'b00,4'b1011,8'h00,8'h05});
		read_data = 32'hFFFF_FFFF;
		while (read_data[1:0] == 2'b11) begin
		    wb_user_core_read(32'h1000001C,read_data);
		    repeat (10) @(posedge clock);
		 end

		$display("#############################################");
		$display("  Page Read through Direct Access            ");
		$display("#############################################");
                wb_user_core_write('h3080_0004,'h00); // Change the Bank Sel 00
		wb_user_core_read_check(32'h00000000,read_data,32'h00010000);
		wb_user_core_read_check(32'h00000004,read_data,32'h00010001);
		wb_user_core_read_check(32'h00000008,read_data,32'h00010002);
		wb_user_core_read_check(32'h0000000C,read_data,32'h00010003);
		wb_user_core_read_check(32'h00000010,read_data,32'h00010004);
		wb_user_core_read_check(32'h00000014,read_data,32'h00010005);
		wb_user_core_read_check(32'h00000018,read_data,32'h00010006);
		wb_user_core_read_check(32'h0000001C,read_data,32'h00010007);
		wb_user_core_read_check(32'h00000020,read_data,32'h00010008);
		wb_user_core_read_check(32'h00000024,read_data,32'h00010009);
		wb_user_core_read_check(32'h00000028,read_data,32'h00010010);
		wb_user_core_read_check(32'h0000002C,read_data,32'h00010011);
		wb_user_core_read_check(32'h00000030,read_data,32'h00010012);
		wb_user_core_read_check(32'h00000034,read_data,32'h00010013);
		wb_user_core_read_check(32'h00000038,read_data,32'h00010014);
		wb_user_core_read_check(32'h0000003C,read_data,32'h00010015);
		wb_user_core_read_check(32'h00000040,read_data,32'h00010016);
		wb_user_core_read_check(32'h00000044,read_data,32'h00010017);
		wb_user_core_read_check(32'h00000048,read_data,32'h00010018);
		wb_user_core_read_check(32'h0000004C,read_data,32'h00010019);
		wb_user_core_read_check(32'h00000050,read_data,32'h00010020);
		wb_user_core_read_check(32'h00000054,read_data,32'h00010021);
		wb_user_core_read_check(32'h00000058,read_data,32'h00010022);
		wb_user_core_read_check(32'h0000005C,read_data,32'h00010023);
		wb_user_core_read_check(32'h00000060,read_data,32'h00010024);
		wb_user_core_read_check(32'h00000064,read_data,32'h00010025);
		wb_user_core_read_check(32'h00000068,read_data,32'h00010026);
		wb_user_core_read_check(32'h0000006C,read_data,32'h00010027);
		wb_user_core_read_check(32'h00000070,read_data,32'h00010028);
		wb_user_core_read_check(32'h00000074,read_data,32'h00010029);
		wb_user_core_read_check(32'h00000078,read_data,32'h00010030);
		wb_user_core_read_check(32'h0000007C,read_data,32'h00010031);
		wb_user_core_read_check(32'h00000080,read_data,32'h00010032);
		wb_user_core_read_check(32'h00000084,read_data,32'h00010033);
		wb_user_core_read_check(32'h00000088,read_data,32'h00010034);
		wb_user_core_read_check(32'h0000008C,read_data,32'h00010035);
		wb_user_core_read_check(32'h00000090,read_data,32'h00010036);
		wb_user_core_read_check(32'h00000094,read_data,32'h00010037);
		wb_user_core_read_check(32'h00000098,read_data,32'h00010038);
		wb_user_core_read_check(32'h0000009C,read_data,32'h00010039);
		wb_user_core_read_check(32'h000000A0,read_data,32'h00010040);
		wb_user_core_read_check(32'h000000A4,read_data,32'h00010041);
		wb_user_core_read_check(32'h000000A8,read_data,32'h00010042);
		wb_user_core_read_check(32'h000000AC,read_data,32'h00010043);
		wb_user_core_read_check(32'h000000B0,read_data,32'h00010044);
		wb_user_core_read_check(32'h000000B4,read_data,32'h00010045);
		wb_user_core_read_check(32'h000000B8,read_data,32'h00010046);
		wb_user_core_read_check(32'h000000BC,read_data,32'h00010047);
		wb_user_core_read_check(32'h000000C0,read_data,32'h00010048);
		wb_user_core_read_check(32'h000000C4,read_data,32'h00010049);
		wb_user_core_read_check(32'h000000C8,read_data,32'h00010050);
		wb_user_core_read_check(32'h000000CC,read_data,32'h00010051);
		wb_user_core_read_check(32'h000000D0,read_data,32'h00010052);
		wb_user_core_read_check(32'h000000D4,read_data,32'h00010053);
		wb_user_core_read_check(32'h000000D8,read_data,32'h00010054);
		wb_user_core_read_check(32'h000000DC,read_data,32'h00010055);
		wb_user_core_read_check(32'h000000E0,read_data,32'h00010056);
		wb_user_core_read_check(32'h000000E4,read_data,32'h00010057);
		wb_user_core_read_check(32'h000000E8,read_data,32'h00010058);
		wb_user_core_read_check(32'h000000EC,read_data,32'h00010059);

		repeat (100) @(posedge clock);
		$display("#############################################");
		$display("  Page Read through Indirect Access           ");
		$display("#############################################");
                wb_user_core_write('h3080_0004,'h10); // Change the Bank Sel 10
		wb_user_core_write(32'h1000000C,{15'h0,1'b0,2'b01,2'b10,4'b0001});
		wb_user_core_write(32'h10000010,{8'hF0,2'b01,2'b10,4'b0110,8'h00,8'hEB});
		wb_user_core_write(32'h10000014,32'h00000000);

		wb_user_core_read_check(32'h1000001C,read_data,32'h00010000);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00010001);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00010002);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00010003);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00010004);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00010005);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00010006);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00010007);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00010008);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00010009);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00010010);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00010011);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00010012);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00010013);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00010014);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00010015);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00010016);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00010017);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00010018);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00010019);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00010020);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00010021);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00010022);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00010023);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00010024);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00010025);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00010026);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00010027);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00010028);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00010029);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00010030);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00010031);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00010032);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00010033);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00010034);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00010035);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00010036);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00010037);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00010038);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00010039);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00010040);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00010041);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00010042);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00010043);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00010044);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00010045);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00010046);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00010047);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00010048);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00010049);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00010050);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00010051);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00010052);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00010053);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00010054);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00010055);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00010056);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00010057);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00010058);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00010059);

		repeat (100) @(posedge clock);
		$display("#############################################");
		$display("  Page Write Command Address: 0x200          ");
		$display("#############################################");
                wb_user_core_write('h3080_0004,'h10); // Change the Bank Sel 10
		// WEN COMMAND
		wb_user_core_write(32'h1000000C,{15'h0,1'b0,2'b00,2'b00,4'b0001});
		wb_user_core_write(32'h10000010,{8'h0,2'b00,2'b00,4'b0000,8'h00,8'h06});
		wb_user_core_write(32'h10000018,32'h0);
		 // Page Programing
		wb_user_core_write(32'h1000000C,{15'h0,1'b0,2'b00,2'b00,4'b0001});
		wb_user_core_write(32'h10000010,{8'hF0,2'b00,2'b10,P_FSM_CAW,8'h00,8'h02});
		wb_user_core_write(32'h10000014,32'h00000200);
		wb_user_core_write(32'h10000018,32'h00020000);
		wb_user_core_write(32'h10000018,32'h00020001);
		wb_user_core_write(32'h10000018,32'h00020002);
		wb_user_core_write(32'h10000018,32'h00020003);
		wb_user_core_write(32'h10000018,32'h00020004);
		wb_user_core_write(32'h10000018,32'h00020005);
		wb_user_core_write(32'h10000018,32'h00020006);
		wb_user_core_write(32'h10000018,32'h00020007);
		wb_user_core_write(32'h10000018,32'h00020008);
		wb_user_core_write(32'h10000018,32'h00020009);
		wb_user_core_write(32'h10000018,32'h00020010);
		wb_user_core_write(32'h10000018,32'h00020011);
		wb_user_core_write(32'h10000018,32'h00020012);
		wb_user_core_write(32'h10000018,32'h00020013);
		wb_user_core_write(32'h10000018,32'h00020014);
		wb_user_core_write(32'h10000018,32'h00020015);
		wb_user_core_write(32'h10000018,32'h00020016);
		wb_user_core_write(32'h10000018,32'h00020017);
		wb_user_core_write(32'h10000018,32'h00020018);
		wb_user_core_write(32'h10000018,32'h00020019);
		wb_user_core_write(32'h10000018,32'h00020020);
		wb_user_core_write(32'h10000018,32'h00020021);
		wb_user_core_write(32'h10000018,32'h00020022);
		wb_user_core_write(32'h10000018,32'h00020023);
		wb_user_core_write(32'h10000018,32'h00020024);
		wb_user_core_write(32'h10000018,32'h00020025);
		wb_user_core_write(32'h10000018,32'h00020026);
		wb_user_core_write(32'h10000018,32'h00020027);
		wb_user_core_write(32'h10000018,32'h00020028);
		wb_user_core_write(32'h10000018,32'h00020029);
		wb_user_core_write(32'h10000018,32'h00020030);
		wb_user_core_write(32'h10000018,32'h00020031);
		wb_user_core_write(32'h10000018,32'h00020032);
		wb_user_core_write(32'h10000018,32'h00020033);
		wb_user_core_write(32'h10000018,32'h00020034);
		wb_user_core_write(32'h10000018,32'h00020035);
		wb_user_core_write(32'h10000018,32'h00020036);
		wb_user_core_write(32'h10000018,32'h00020037);
		wb_user_core_write(32'h10000018,32'h00020038);
		wb_user_core_write(32'h10000018,32'h00020039);
		wb_user_core_write(32'h10000018,32'h00020040);
		wb_user_core_write(32'h10000018,32'h00020041);
		wb_user_core_write(32'h10000018,32'h00020042);
		wb_user_core_write(32'h10000018,32'h00020043);
		wb_user_core_write(32'h10000018,32'h00020044);
		wb_user_core_write(32'h10000018,32'h00020045);
		wb_user_core_write(32'h10000018,32'h00020046);
		wb_user_core_write(32'h10000018,32'h00020047);
		wb_user_core_write(32'h10000018,32'h00020048);
		wb_user_core_write(32'h10000018,32'h00020049);
		wb_user_core_write(32'h10000018,32'h00020050);
		wb_user_core_write(32'h10000018,32'h00020051);
		wb_user_core_write(32'h10000018,32'h00020052);
		wb_user_core_write(32'h10000018,32'h00020053);
		wb_user_core_write(32'h10000018,32'h00020054);
		wb_user_core_write(32'h10000018,32'h00020055);
		wb_user_core_write(32'h10000018,32'h00020056);
		wb_user_core_write(32'h10000018,32'h00020057);
		wb_user_core_write(32'h10000018,32'h00020058);
		wb_user_core_write(32'h10000018,32'h00020059);

		// RDSR
		wb_user_core_write(32'h1000000C,{15'h0,1'b0,2'b00,2'b00,4'b0001});
		wb_user_core_write(32'h10000010,{8'h4,2'b00,2'b00,4'b1011,8'h00,8'h05});
		read_data = 32'hFFFF_FFFF;
		while (read_data[1:0] == 2'b11) begin
		    wb_user_core_read(32'h1000001C,read_data);
		    repeat (10) @(posedge clock);
		 end

		$display("#############################################");
		$display("  Page Read through Direct Access            ");
		$display("#############################################");
                wb_user_core_write('h3080_0004,'h00); // Change the Bank Sel 00
		wb_user_core_read_check(32'h00000200,read_data,32'h00020000);
		wb_user_core_read_check(32'h00000204,read_data,32'h00020001);
		wb_user_core_read_check(32'h00000208,read_data,32'h00020002);
		wb_user_core_read_check(32'h0000020C,read_data,32'h00020003);
		wb_user_core_read_check(32'h00000210,read_data,32'h00020004);
		wb_user_core_read_check(32'h00000214,read_data,32'h00020005);
		wb_user_core_read_check(32'h00000218,read_data,32'h00020006);
		wb_user_core_read_check(32'h0000021C,read_data,32'h00020007);
		wb_user_core_read_check(32'h00000220,read_data,32'h00020008);
		wb_user_core_read_check(32'h00000224,read_data,32'h00020009);
		wb_user_core_read_check(32'h00000228,read_data,32'h00020010);
		wb_user_core_read_check(32'h0000022C,read_data,32'h00020011);
		wb_user_core_read_check(32'h00000230,read_data,32'h00020012);
		wb_user_core_read_check(32'h00000234,read_data,32'h00020013);
		wb_user_core_read_check(32'h00000238,read_data,32'h00020014);
		wb_user_core_read_check(32'h0000023C,read_data,32'h00020015);
		wb_user_core_read_check(32'h00000240,read_data,32'h00020016);
		wb_user_core_read_check(32'h00000244,read_data,32'h00020017);
		wb_user_core_read_check(32'h00000248,read_data,32'h00020018);
		wb_user_core_read_check(32'h0000024C,read_data,32'h00020019);
		wb_user_core_read_check(32'h00000250,read_data,32'h00020020);
		wb_user_core_read_check(32'h00000254,read_data,32'h00020021);
		wb_user_core_read_check(32'h00000258,read_data,32'h00020022);
		wb_user_core_read_check(32'h0000025C,read_data,32'h00020023);
		wb_user_core_read_check(32'h00000260,read_data,32'h00020024);
		wb_user_core_read_check(32'h00000264,read_data,32'h00020025);
		wb_user_core_read_check(32'h00000268,read_data,32'h00020026);
		wb_user_core_read_check(32'h0000026C,read_data,32'h00020027);
		wb_user_core_read_check(32'h00000270,read_data,32'h00020028);
		wb_user_core_read_check(32'h00000274,read_data,32'h00020029);
		wb_user_core_read_check(32'h00000278,read_data,32'h00020030);
		wb_user_core_read_check(32'h0000027C,read_data,32'h00020031);
		wb_user_core_read_check(32'h00000280,read_data,32'h00020032);
		wb_user_core_read_check(32'h00000284,read_data,32'h00020033);
		wb_user_core_read_check(32'h00000288,read_data,32'h00020034);
		wb_user_core_read_check(32'h0000028C,read_data,32'h00020035);
		wb_user_core_read_check(32'h00000290,read_data,32'h00020036);
		wb_user_core_read_check(32'h00000294,read_data,32'h00020037);
		wb_user_core_read_check(32'h00000298,read_data,32'h00020038);
		wb_user_core_read_check(32'h0000029C,read_data,32'h00020039);
		wb_user_core_read_check(32'h000002A0,read_data,32'h00020040);
		wb_user_core_read_check(32'h000002A4,read_data,32'h00020041);
		wb_user_core_read_check(32'h000002A8,read_data,32'h00020042);
		wb_user_core_read_check(32'h000002AC,read_data,32'h00020043);
		wb_user_core_read_check(32'h000002B0,read_data,32'h00020044);
		wb_user_core_read_check(32'h000002B4,read_data,32'h00020045);
		wb_user_core_read_check(32'h000002B8,read_data,32'h00020046);
		wb_user_core_read_check(32'h000002BC,read_data,32'h00020047);
		wb_user_core_read_check(32'h000002C0,read_data,32'h00020048);
		wb_user_core_read_check(32'h000002C4,read_data,32'h00020049);
		wb_user_core_read_check(32'h000002C8,read_data,32'h00020050);
		wb_user_core_read_check(32'h000002CC,read_data,32'h00020051);
		wb_user_core_read_check(32'h000002D0,read_data,32'h00020052);
		wb_user_core_read_check(32'h000002D4,read_data,32'h00020053);
		wb_user_core_read_check(32'h000002D8,read_data,32'h00020054);
		wb_user_core_read_check(32'h000002DC,read_data,32'h00020055);
		wb_user_core_read_check(32'h000002E0,read_data,32'h00020056);
		wb_user_core_read_check(32'h000002E4,read_data,32'h00020057);
		wb_user_core_read_check(32'h000002E8,read_data,32'h00020058);
		wb_user_core_read_check(32'h000002EC,read_data,32'h00020059);

		repeat (10) @(posedge clock);
		$display("#############################################");
		$display("  Page Read through Indirect Access           ");
		$display("#############################################");
                wb_user_core_write('h3080_0004,'h10); // Change the Bank Sel 10
		wb_user_core_write(32'h1000000C,{15'h0,1'b0,2'b01,2'b10,4'b0001});
		wb_user_core_write(32'h10000010,{8'hF0,2'b01,2'b10,4'b0110,8'h00,8'hEB});
		wb_user_core_write(32'h10000014,32'h00000200);

		wb_user_core_read_check(32'h1000001C,read_data,32'h00020000);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00020001);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00020002);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00020003);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00020004);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00020005);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00020006);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00020007);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00020008);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00020009);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00020010);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00020011);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00020012);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00020013);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00020014);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00020015);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00020016);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00020017);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00020018);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00020019);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00020020);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00020021);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00020022);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00020023);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00020024);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00020025);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00020026);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00020027);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00020028);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00020029);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00020030);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00020031);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00020032);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00020033);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00020034);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00020035);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00020036);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00020037);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00020038);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00020039);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00020040);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00020041);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00020042);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00020043);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00020044);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00020045);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00020046);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00020047);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00020048);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00020049);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00020050);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00020051);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00020052);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00020053);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00020054);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00020055);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00020056);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00020057);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00020058);
		wb_user_core_read_check(32'h1000001C,read_data,32'h00020059);

		repeat (100) @(posedge clock);
			// $display("+1000 cycles");

          	if(test_fail == 0) begin
		   `ifdef GL
	    	       $display("Monitor: SPI Master Mode (GL) Passed");
		   `else
		       $display("Monitor: SPI Master Mode (RTL) Passed");
		   `endif
	        end else begin
		    `ifdef GL
	    	        $display("Monitor: SPI Master Mode (GL) Failed");
		    `else
		        $display("Monitor: SPI Master Mode (RTL) Failed");
		    `endif
		 end
	    	$display("###################################################");
	        $finish;
	end

	initial begin
		wb_rst_i <= 1'b1;
		#100;
		wb_rst_i <= 1'b0;	    	// Release reset
	end
wire USER_VDD1V8 = 1'b1;
wire VSS = 1'b0;

user_project_wrapper u_top(
`ifdef USE_POWER_PINS
    .vccd1(USER_VDD1V8),	// User area 1 1.8V supply
    .vssd1(VSS),	// User area 1 digital ground
`endif
    .wb_clk_i        (clock),  // System clock
    .user_clock2     (1'b1),  // Real-time clock
    .wb_rst_i        (wb_rst_i),  // Regular Reset signal

    .wbs_cyc_i   (wbd_ext_cyc_i),  // strobe/request
    .wbs_stb_i   (wbd_ext_stb_i),  // strobe/request
    .wbs_adr_i   (wbd_ext_adr_i),  // address
    .wbs_we_i    (wbd_ext_we_i),  // write
    .wbs_dat_i   (wbd_ext_dat_i),  // data output
    .wbs_sel_i   (wbd_ext_sel_i),  // byte enable

    .wbs_dat_o   (wbd_ext_dat_o),  // data input
    .wbs_ack_o   (wbd_ext_ack_o),  // acknowlegement

 
    // Logic Analyzer Signals
    .la_data_in      ('1) ,
    .la_data_out     (),
    .la_oenb         ('0),
 

    // IOs
    .io_in          (io_in)  ,
    .io_out         (io_out) ,
    .io_oeb         (io_oeb) ,

    .user_irq       () 

);

`ifndef GL // Drive Power for Hold Fix Buf
    // All standard cell need power hook-up for functionality work
    initial begin
    end
`endif    

//------------------------------------------------------
//  Integrate the Serial flash with qurd support to
//  user core using the gpio pads
//  ----------------------------------------------------

   wire flash_clk = io_out[30];
   wire flash_csb = io_out[31];
   // Creating Pad Delay
   wire #1 io_oeb_32 = io_oeb[32];
   wire #1 io_oeb_33 = io_oeb[33];
   wire #1 io_oeb_34 = io_oeb[34];
   wire #1 io_oeb_35 = io_oeb[35];
   tri  flash_io0 = (io_oeb_32== 1'b0) ? io_out[32] : 1'bz;
   tri  flash_io1 = (io_oeb_33== 1'b0) ? io_out[33] : 1'bz;
   tri  flash_io2 = (io_oeb_34== 1'b0) ? io_out[34] : 1'bz;
   tri  flash_io3 = (io_oeb_35== 1'b0) ? io_out[35] : 1'bz;

   assign io_in[32] = flash_io0;
   assign io_in[33] = flash_io1;
   assign io_in[34] = flash_io2;
   assign io_in[35] = flash_io3;


   // Quard flash
     s25fl256s #(.mem_file_name("user_risc_boot.hex"),
	         .otp_file_name("none"),
                 .TimingModel("S25FL512SAGMFI010_F_30pF")) 
		 u_spi_flash_256mb (
           // Data Inputs/Outputs
       .SI      (flash_io0),
       .SO      (flash_io1),
       // Controls
       .SCK     (flash_clk),
       .CSNeg   (flash_csb),
       .WPNeg   (flash_io2),
       .HOLDNeg (flash_io3),
       .RSTNeg  (!wb_rst_i)

       );



//------------------------------------------------
// Integrate the SDRAM 8 BIT Memory
// -----------------------------------------------

wire [7:0]    Dq                 ; // SDRAM Read/Write Data Bus
wire [0:0]    sdr_dqm            ; // SDRAM DATA Mask
wire [1:0]    sdr_ba             ; // SDRAM Bank Select
wire [12:0]   sdr_addr           ; // SDRAM ADRESS
wire          sdr_cs_n           ; // chip select
wire          sdr_cke            ; // clock gate
wire          sdr_ras_n          ; // ras
wire          sdr_cas_n          ; // cas
wire          sdr_we_n           ; // write enable        
wire          sdram_clk         ;      

assign  Dq[7:0]           =  (io_oeb[7:0] == 8'h0) ? io_out [7:0] : 8'hZZ;
assign  sdr_addr[12:0]    =    io_out [20:8]     ;
assign  sdr_ba[1:0]       =    io_out [22:21]    ;
assign  sdr_dqm[0]        =    io_out [23]       ;
assign  sdr_we_n          =    io_out [24]       ;
assign  sdr_cas_n         =    io_out [25]       ;
assign  sdr_ras_n         =    io_out [26]       ;
assign  sdr_cs_n          =    io_out [27]       ;
assign  sdr_cke           =    io_out [28]       ;
assign  sdram_clk         =    io_out [29]       ;
assign  io_in[29]         =    sdram_clk;
assign  #(1) io_in[7:0]   =    Dq;

// to fix the sdram interface timing issue
wire #(1) sdram_clk_d   = sdram_clk;

	// SDRAM 8bit
mt48lc8m8a2 #(.data_bits(8)) u_sdram8 (
          .Dq                 (Dq                 ) , 
          .Addr               (sdr_addr[11:0]     ), 
          .Ba                 (sdr_ba             ), 
          .Clk                (sdram_clk_d        ), 
          .Cke                (sdr_cke            ), 
          .Cs_n               (sdr_cs_n           ), 
          .Ras_n              (sdr_ras_n          ), 
          .Cas_n              (sdr_cas_n          ), 
          .We_n               (sdr_we_n           ), 
          .Dqm                (sdr_dqm            )
     );

task wb_user_core_write;
input [31:0] address;
input [31:0] data;
begin
  repeat (1) @(posedge clock);
  #1;
  wbd_ext_adr_i =address;  // address
  wbd_ext_we_i  ='h1;  // write
  wbd_ext_dat_i =data;  // data output
  wbd_ext_sel_i ='hF;  // byte enable
  wbd_ext_cyc_i ='h1;  // strobe/request
  wbd_ext_stb_i ='h1;  // strobe/request
  wait(wbd_ext_ack_o == 1);
  repeat (1) @(posedge clock);
  #1;
  wbd_ext_cyc_i ='h0;  // strobe/request
  wbd_ext_stb_i ='h0;  // strobe/request
  wbd_ext_adr_i ='h0;  // address
  wbd_ext_we_i  ='h0;  // write
  wbd_ext_dat_i ='h0;  // data output
  wbd_ext_sel_i ='h0;  // byte enable
  $display("STATUS: WB USER ACCESS WRITE Address : 0x%x, Data : 0x%x",address,data);
  repeat (2) @(posedge clock);
end
endtask

task  wb_user_core_read;
input [31:0] address;
output [31:0] data;
reg    [31:0] data;
begin
  repeat (1) @(posedge clock);
  #1;
  wbd_ext_adr_i =address;  // address
  wbd_ext_we_i  ='h0;  // write
  wbd_ext_dat_i ='0;  // data output
  wbd_ext_sel_i ='hF;  // byte enable
  wbd_ext_cyc_i ='h1;  // strobe/request
  wbd_ext_stb_i ='h1;  // strobe/request
  wait(wbd_ext_ack_o == 1);
  data  = wbd_ext_dat_o;  
  repeat (1) @(posedge clock);
  #1;
  wbd_ext_cyc_i ='h0;  // strobe/request
  wbd_ext_stb_i ='h0;  // strobe/request
  wbd_ext_adr_i ='h0;  // address
  wbd_ext_we_i  ='h0;  // write
  wbd_ext_dat_i ='h0;  // data output
  wbd_ext_sel_i ='h0;  // byte enable
  $display("STATUS: WB USER ACCESS READ  Address : 0x%x, Data : 0x%x",address,data);
  repeat (2) @(posedge clock);
end
endtask

task  wb_user_core_read_check;
input [31:0] address;
output [31:0] data;
input [31:0] cmp_data;
reg    [31:0] data;
begin
  repeat (1) @(posedge clock);
  #1;
  wbd_ext_adr_i =address;  // address
  wbd_ext_we_i  ='h0;  // write
  wbd_ext_dat_i ='0;  // data output
  wbd_ext_sel_i ='hF;  // byte enable
  wbd_ext_cyc_i ='h1;  // strobe/request
  wbd_ext_stb_i ='h1;  // strobe/request
  wait(wbd_ext_ack_o == 1);
  data  = wbd_ext_dat_o;  
  repeat (1) @(posedge clock);
  #1;
  wbd_ext_cyc_i ='h0;  // strobe/request
  wbd_ext_stb_i ='h0;  // strobe/request
  wbd_ext_adr_i ='h0;  // address
  wbd_ext_we_i  ='h0;  // write
  wbd_ext_dat_i ='h0;  // data output
  wbd_ext_sel_i ='h0;  // byte enable
  if(data !== cmp_data) begin
     $display("ERROR : WB USER ACCESS READ  Address : 0x%x, Exd: 0x%x Rxd: 0x%x ",address,cmp_data,data);
     user_spi_tb.test_fail = 1;
  end else begin
     $display("STATUS: WB USER ACCESS READ  Address : 0x%x, Data : 0x%x",address,data);
  end
  repeat (2) @(posedge clock);
end
endtask


`ifdef GL

wire        wbd_spi_stb_i   = u_top.u_spi_master.wbd_stb_i;
wire        wbd_spi_ack_o   = u_top.u_spi_master.wbd_ack_o;
wire        wbd_spi_we_i    = u_top.u_spi_master.wbd_we_i;
wire [31:0] wbd_spi_adr_i   = u_top.u_spi_master.wbd_adr_i;
wire [31:0] wbd_spi_dat_i   = u_top.u_spi_master.wbd_dat_i;
wire [31:0] wbd_spi_dat_o   = u_top.u_spi_master.wbd_dat_o;
wire [3:0]  wbd_spi_sel_i   = u_top.u_spi_master.wbd_sel_i;

wire        wbd_sdram_stb_i = u_top.u_sdram_ctrl.wb_stb_i;
wire        wbd_sdram_ack_o = u_top.u_sdram_ctrl.wb_ack_o;
wire        wbd_sdram_we_i  = u_top.u_sdram_ctrl.wb_we_i;
wire [31:0] wbd_sdram_adr_i = u_top.u_sdram_ctrl.wb_addr_i;
wire [31:0] wbd_sdram_dat_i = u_top.u_sdram_ctrl.wb_dat_i;
wire [31:0] wbd_sdram_dat_o = u_top.u_sdram_ctrl.wb_dat_o;
wire [3:0]  wbd_sdram_sel_i = u_top.u_sdram_ctrl.wb_sel_i;

wire        wbd_uart_stb_i  = u_top.u_uart_i2c_usb.reg_cs;
wire        wbd_uart_ack_o  = u_top.u_uart_i2c_usb.reg_ack;
wire        wbd_uart_we_i   = u_top.u_uart_i2c_usb.reg_wr;
wire [7:0]  wbd_uart_adr_i  = u_top.u_uart_i2c_usb.reg_addr;
wire [7:0]  wbd_uart_dat_i  = u_top.u_uart_i2c_usb.reg_wdata;
wire [7:0]  wbd_uart_dat_o  = u_top.u_uart_i2c_usb.reg_rdata;
wire        wbd_uart_sel_i  = u_top.u_uart_i2c_usb.reg_be;

`endif

/**
`ifdef GL
//-----------------------------------------------------------------------------
// RISC IMEM amd DMEM Monitoring TASK
//-----------------------------------------------------------------------------

`define RISC_CORE  user_uart_tb.u_top.u_core.u_riscv_top

always@(posedge `RISC_CORE.wb_clk) begin
    if(`RISC_CORE.wbd_imem_ack_i)
          $display("RISCV-DEBUG => IMEM ADDRESS: %x Read Data : %x", `RISC_CORE.wbd_imem_adr_o,`RISC_CORE.wbd_imem_dat_i);
    if(`RISC_CORE.wbd_dmem_ack_i && `RISC_CORE.wbd_dmem_we_o)
          $display("RISCV-DEBUG => DMEM ADDRESS: %x Write Data: %x Resonse: %x", `RISC_CORE.wbd_dmem_adr_o,`RISC_CORE.wbd_dmem_dat_o);
    if(`RISC_CORE.wbd_dmem_ack_i && !`RISC_CORE.wbd_dmem_we_o)
          $display("RISCV-DEBUG => DMEM ADDRESS: %x READ Data : %x Resonse: %x", `RISC_CORE.wbd_dmem_adr_o,`RISC_CORE.wbd_dmem_dat_i);
end

`endif
**/
endmodule
`default_nettype wire
