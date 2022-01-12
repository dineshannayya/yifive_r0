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
////      in to  user register from 0x1003_0058 to 0x1003_006C    ////
////   4. Through the External Wishbone Interface we read back    ////
////       from 0x3003_0058 to 0x3003_006C                        ////
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

`include "uprj_netlists.v"

`define ADDR_SPACE_UART  32'h1001_0000
`define ADDR_SPACE_I2C   32'h1001_0000
`define ADDR_SPACE_GLBL  32'h1002_0000

module user_risc_soft_boot_tb;
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
	reg         test_fail;
	reg [31:0] read_data;
	logic  [7:0]           tem_mem[0:4095];
	logic  [31:0]          tem_mem_32b[0:511];

	`ifdef VERILATOR
	 logic [255:0]          test_ram_file;
         `else // VERILATOR
	 
	    string                 test_ram_file;

         `endif // VERILATOR

         integer i;


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
	   	$dumpfile("simx.vcd");
	   	$dumpvars(4, user_risc_soft_boot_tb);
	   end
       `endif

	initial begin

		#200; // Wait for reset removal
	        repeat (10) @(posedge clock);
		$display("Monitor: Standalone User Risc Boot Test Started");

		// Remove Wb Reset
		wb_user_core_write('h3080_0000,'h1);

		$readmemh("user_risc_boot.hex",tem_mem);
		// convert 8 bit 32 mem format
		for(i =0; i < 511; i = i+1)
		   tem_mem_32b[i] = {tem_mem[(i*4)+3],tem_mem[(i*4)+2],tem_mem[(i*4)+1],tem_mem[(i*4)]};

	        $writememh("sram_bank0.hex",tem_mem_32b,0,511);
	        $readmemh("sram_bank0.hex",u_top.u_sram0_2kb.mem,0,511);

		for(i =512; i < 1023; i = i+1)
		   tem_mem_32b[i-512] = {tem_mem[(i*4)+3],tem_mem[(i*4)+2],tem_mem[(i*4)+1],tem_mem[(i*4)]};

	        $writememh("sram_bank1.hex",tem_mem_32b,0,511);
	        $readmemh("sram_bank1.hex",u_top.u_sram1_2kb.mem,0,511);

		// Enable the SRAM Remap to boot region and keep bank sel=0x10
		wb_user_core_write('h3080_0004,{20'h0,4'b1111,8'h10});
	        repeat (2) @(posedge clock);
		#1;
		// Remove the reset, mbist, wishbone, riscv
                wb_user_core_write('h3080_0000,'h4F);


		// Repeat cycles of 1000 clock edges as needed to complete testbench
		repeat (10) begin
			repeat (400) @(posedge clock);
			// $display("+1000 cycles");
		end


		$display("Monitor: Reading Back the expected value");
		// User RISC core expect to write these value in global
		// register, read back and decide on pass fail
		// 0x30000018  = 0x11223344; 
                // 0x3000001C  = 0x22334455; 
                // 0x30000020  = 0x33445566; 
                // 0x30000024  = 0x44556677; 
                // 0x30000028 =  0x55667788; 
                // 0x3000002C =  0x66778899; 

                test_fail = 0;
		wb_user_core_read_check(`ADDR_SPACE_GLBL+8'h18,read_data,32'h11223344);
		wb_user_core_read_check(`ADDR_SPACE_GLBL+8'h1C,read_data,32'h22334455);
		wb_user_core_read_check(`ADDR_SPACE_GLBL+8'h20,read_data,32'h33445566);
		wb_user_core_read_check(`ADDR_SPACE_GLBL+8'h24,read_data,32'h44556677);
		wb_user_core_read_check(`ADDR_SPACE_GLBL+8'h28,read_data,32'h55667788);
		wb_user_core_read_check(`ADDR_SPACE_GLBL+8'h2C,read_data,32'h66778899);

	   
	    	$display("###################################################");
          	if(test_fail == 0) begin
		   `ifdef GL
	    	       $display("Monitor: Standalone User Risc Boot (GL) Passed");
		   `else
		       $display("Monitor: Standalone User Risc Boot (RTL) Passed");
		   `endif
	        end else begin
		    `ifdef GL
	    	        $display("Monitor: Standalone User Risc Boot (GL) Failed");
		    `else
		        $display("Monitor: Standalone User Risc Boot (RTL) Failed");
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
  $display("DEBUG WB USER ACCESS WRITE Address : %x, Data : %x",address,data);
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
  $display("DEBUG WB USER ACCESS READ Address : %x, Data : %x",address,data);
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
     test_fail = 1;
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
