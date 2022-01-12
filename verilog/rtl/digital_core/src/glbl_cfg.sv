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
////  Global confg register                                       ////
////                                                              ////
////  This file is part of the YIFive cores project               ////
////  https://github.com/dineshannayya/yifive_r0.git              ////
////  http://www.opencores.org/cores/yifive/                      ////
////                                                              ////
////  Description                                                 ////
////      This block generate all the global config and status    ////
////                                                              ////
////  To Do:                                                      ////
////    nothing                                                   ////
////                                                              ////
////  Author(s):                                                  ////
////      - Dinesh Annayya, dinesha@opencores.org                 ////
////                                                              ////
////  Revision :                                                  ////
////    0.1 - 08 June 2021  Dinesh A                              ////
////          Initial version                                     ////
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

module glbl_cfg (
`ifdef USE_POWER_PINS
        input logic            vccd1,// User area 1 1.8V supply
        input logic            vssd1,// User area 1 digital ground
`endif
        input logic [3:0]      cfg_cska_glbl,
	input logic            wbd_clk_int,
	output logic           wbd_clk_glbl,


        input logic             mclk,
        input logic             reset_n,

        // Reg Bus Interface Signal
        input logic             reg_cs,
        input logic             reg_wr,
        input logic [7:0]       reg_addr,
        input logic [31:0]      reg_wdata,
        input logic [3:0]       reg_be,

       // Outputs
        output logic [31:0]     reg_rdata,
        output logic            reg_ack,

       // Risc configuration
       output logic [31:0]     fuse_mhartid,
       output logic [15:0]     irq_lines,
       output logic            soft_irq,
       output logic [2:0]      user_irq,

       // SDRAM Config
       input logic             sdr_init_done       , // Indicate SDRAM Initialisation Done
       output logic [1:0]      cfg_sdr_width       , // 2'b00 - 32 Bit SDR, 2'b01 - 16 Bit SDR, 2'b1x - 8 Bit
       output logic [1:0]      cfg_colbits         , // 2'b00 - 8 Bit column address, 
       output logic [3:0]      cfg_sdr_tras_d      , // Active to precharge delay
       output logic [3:0]      cfg_sdr_trp_d       , // Precharge to active delay
       output logic [3:0]      cfg_sdr_trcd_d      , // Active to R/W delay
       output logic 	       cfg_sdr_en          , // Enable SDRAM controller
       output logic [1:0]      cfg_req_depth       , // Maximum Request accepted by SDRAM controller
       output logic [12:0]     cfg_sdr_mode_reg    ,
       output logic [2:0]      cfg_sdr_cas         , // SDRAM CAS Latency
       output logic [3:0]      cfg_sdr_trcar_d     , // Auto-refresh period
       output logic [3:0]      cfg_sdr_twr_d       , // Write recovery delay
       output logic [11:0]     cfg_sdr_rfsh        ,
       output logic [2:0]      cfg_sdr_rfmax       ,

       // BIST I/F
       output logic             bist_en,
       output logic             bist_run,
       output logic             bist_load,

       output logic             bist_sdi,
       output logic             bist_shift,
       input  logic             bist_sdo,

       input logic              bist_done,
       input logic [3:0]        bist_error,
       input logic [3:0]        bist_correct,
       input logic [3:0]        bist_error_cnt0,
       input logic [3:0]        bist_error_cnt1,
       input logic [3:0]        bist_error_cnt2,
       input logic [3:0]        bist_error_cnt3

        );



//-----------------------------------------------------------------------
// Internal Wire Declarations
//-----------------------------------------------------------------------

logic           sw_rd_en;
logic           sw_wr_en;
logic  [4:0]    sw_addr ; // addressing 16 registers
logic  [3:0]    wr_be   ;
logic  [31:0]   sw_reg_wdata;

logic           reg_cs_l    ;
logic           reg_cs_2l    ;


logic [31:0]    reg_0;  // Software_Reg_0
logic [31:0]    reg_1;  // Risc Fuse ID
logic [31:0]    reg_2;  // Software-Reg_2
logic [31:0]    reg_3;  // Interrup Control
logic [31:0]    reg_4;  // SDRAM_CTRL1
logic [31:0]    reg_5;  // SDRAM_CTRL2
logic [31:0]    reg_6;  // Software-Reg_6
logic [31:0]    reg_7;  // Software-Reg_7
logic [31:0]    reg_8;  // Software-Reg_8
logic [31:0]    reg_9;  // Software-Reg_9
logic [31:0]    reg_10; // Software-Reg_10
logic [31:0]    reg_11; // Software-Reg_11
logic [31:0]    reg_12; // Software-Reg_12
logic [31:0]    reg_13; // Software-Reg_13
logic [31:0]    reg_14; // Software-Reg_14
logic [31:0]    reg_15; // Software-Reg_15
logic [31:0]    reg_out;

// global clock skew control
clk_skew_adjust u_skew_glbl
       (
`ifdef USE_POWER_PINS
               .vccd1      (vccd1                     ),// User area 1 1.8V supply
               .vssd1      (vssd1                     ),// User area 1 digital ground
`endif
	       .clk_in     (wbd_clk_int               ), 
	       .sel        (cfg_cska_glbl             ), 
	       .clk_out    (wbd_clk_glbl              ) 
       );


//-----------------------------------------------------------------------
// Main code starts here
//-----------------------------------------------------------------------

assign       sw_addr       = reg_addr [6:2];
assign       sw_rd_en      = reg_cs & !reg_wr;
assign       sw_wr_en      = reg_cs & reg_wr;
assign       wr_be         = reg_be;
assign       sw_reg_wdata  = reg_wdata;

//-----------------------------------------------------------------------
// register read enable and write enable decoding logic
//-----------------------------------------------------------------------

wire   sw_wr_en_0 = sw_wr_en  & (sw_addr == 5'h0);
wire   sw_wr_en_1 = sw_wr_en  & (sw_addr == 5'h1);
wire   sw_wr_en_2 = sw_wr_en  & (sw_addr == 5'h2);
wire   sw_wr_en_3 = sw_wr_en  & (sw_addr == 5'h3);
wire   sw_wr_en_4 = sw_wr_en  & (sw_addr == 5'h4);
wire   sw_wr_en_5 = sw_wr_en  & (sw_addr == 5'h5);
wire   sw_wr_en_6 = sw_wr_en  & (sw_addr == 5'h6);
wire   sw_wr_en_7 = sw_wr_en  & (sw_addr == 5'h7);
wire   sw_wr_en_8 = sw_wr_en  & (sw_addr == 5'h8);
wire   sw_wr_en_9 = sw_wr_en  & (sw_addr == 5'h9);
wire   sw_wr_en_10 = sw_wr_en & (sw_addr == 5'hA);
wire   sw_wr_en_11 = sw_wr_en & (sw_addr == 5'hB);
wire   sw_wr_en_12 = sw_wr_en & (sw_addr == 5'hC);
wire   sw_wr_en_13 = sw_wr_en & (sw_addr == 5'hD);
wire   sw_wr_en_14 = sw_wr_en & (sw_addr == 5'hE);
wire   sw_wr_en_15 = sw_wr_en & (sw_addr == 5'hF);

wire   sw_wr_en_16 = sw_wr_en & (sw_addr == 5'h10);
wire   sw_wr_en_17 = sw_wr_en & (sw_addr == 5'h11);
wire   sw_wr_en_18 = sw_wr_en & (sw_addr == 5'h12);
wire   sw_wr_en_19 = sw_wr_en & (sw_addr == 5'h13);
wire   sw_rd_en_19 = sw_rd_en & (sw_addr == 5'h13);
//-----------------------------------
// Edge detection for Logic Bist
// ----------------------------------

logic wb_req;
logic wb_req_d;
logic wb_req_pedge;

always_ff @(negedge reset_n or posedge mclk) begin
    if ( reset_n == 1'b0 ) begin
        wb_req    <= '0;
	wb_req_d  <= '0;
   end else begin
       wb_req   <= reg_cs && (reg_ack == 0) ;
       wb_req_d <= wb_req;
   end
end

// Detect pos edge of request
assign wb_req_pedge = (wb_req_d ==0) && (wb_req==1'b1);


//-----------------------------------------------------------------
// Bist Serial I/F register 18/19 and it takes minimum 32
// cycle to respond ACK back
// ----------------------------------------------------------------
wire ser_acc     = sw_wr_en_18 | sw_rd_en_19;
wire non_ser_acc = reg_cs ? !ser_acc : 1'b0;
wire serial_ack;

always @ (posedge mclk or negedge reset_n)
begin : preg_out_Seq
   if (reset_n == 1'b0) begin
      reg_rdata  <= 'h0;
      reg_ack    <= 1'b0;
   end else if (ser_acc && serial_ack)  begin
      reg_rdata <= serail_dout ;
      reg_ack   <= 1'b1;
   end else if (non_ser_acc && !reg_ack) begin
      reg_rdata <= reg_out ;
      reg_ack   <= 1'b1;
   end else begin
      reg_ack        <= 1'b0;
   end
end


//-----------------------------------------------------------------------
// Individual register assignments
//-----------------------------------------------------------------------
//-----------------------------------------------------------------------
//   reg-0
//   -----------------------------------------------------------------

gen_32b_reg  #(32'hAABB_CCDD) u_reg_0	(
	      //List of Inputs
	      .reset_n    (reset_n     ),
	      .clk        (mclk          ),
	      .cs         (sw_wr_en_0   ),
	      .we         (wr_be         ),		 
	      .data_in    (sw_reg_wdata  ),
	      
	      //List of Outs
	      .data_out   (reg_0       )
	      );


//-----------------------------------------------------------------------
//   reg-1, reset value = 32'hA55A_A55A
//   -----------------------------------------------------------------

assign  fuse_mhartid     = reg_1[31:0]; 

gen_32b_reg  #(32'hA55A_A55A) u_reg_1	(
	      //List of Inputs
	      .reset_n    (reset_n     ),
	      .clk        (mclk          ),
	      .cs         (sw_wr_en_1   ),
	      .we         (wr_be         ),		 
	      .data_in    (sw_reg_wdata  ),
	      
	      //List of Outs
	      .data_out   (reg_1       )
	      );

//-----------------------------------------------------------------------
//   reg-2, reset value = 32'hAABBCCDD
//-----------------------------------------------------------------

gen_32b_reg  #(32'hAABB_CCDD) u_reg_2	(
	      //List of Inputs
	      .reset_n    (reset_n     ),
	      .clk        (mclk          ),
	      .cs         (sw_wr_en_2   ),
	      .we         (wr_be         ),		 
	      .data_in    (sw_reg_wdata  ),
	      
	      //List of Outs
	      .data_out   (reg_2       )
	      );

//-----------------------------------------------------------------------
//   reg-3
//-----------------------------------------------------------------
assign  irq_lines     = reg_3[15:0]; 
assign  soft_irq      = reg_3[16]; 
assign  user_irq      = reg_3[19:17]; 

generic_register #(8,0  ) u_reg3_be0 (
	      .we            ({8{sw_wr_en_3 & 
                                 wr_be[0]   }}  ),		 
	      .data_in       (sw_reg_wdata[7:0]    ),
	      .reset_n       (reset_n           ),
	      .clk           (mclk              ),
	      
	      //List of Outs
	      .data_out      (reg_3[7:0]        )
          );

generic_register #(8,0  ) u_reg3_be1 (
	      .we            ({8{sw_wr_en_3 & 
                                 wr_be[1]   }}  ),		 
	      .data_in       (sw_reg_wdata[15:8]    ),
	      .reset_n       (reset_n           ),
	      .clk           (mclk              ),
	      
	      //List of Outs
	      .data_out      (reg_3[15:8]        )
          );
generic_register #(4,0  ) u_reg3_be2 (
	      .we            ({4{sw_wr_en_3 & 
                                 wr_be[2]   }}  ),		 
	      .data_in       (sw_reg_wdata[19:16]    ),
	      .reset_n       (reset_n           ),
	      .clk           (mclk              ),
	      
	      //List of Outs
	      .data_out      (reg_3[19:16]        )
          );

assign reg_3[31:20] = '0;


//-----------------------------------------------------------------------
//   reg-4
//   recommended Default value:
//   1'b1,3'h3,2'h3,4'h1,4'h7',4'h2,4'h2,4'h6,2'b01,2'b10 = 32'h2F17_2266
//-----------------------------------------------------------------
assign      cfg_sdr_width     = reg_4[1:0] ;  // 2'b10 // 2'b00 - 32 Bit SDR, 2'b01 - 16 Bit SDR, 2'b1x - 8 Bit
assign      cfg_colbits       = reg_4[3:2] ;  // 2'b00 8 Bit column address, 2'b01 -  9 Bit column address, 
assign      cfg_sdr_tras_d    = reg_4[7:4] ;  // 4'h4  // Active to precharge delay
assign      cfg_sdr_trp_d     = reg_4[11:8];  // 4'h2  // Precharge to active delay
assign      cfg_sdr_trcd_d    = reg_4[15:12]; // 4'h2  // Active to R/W delay
assign      cfg_sdr_trcar_d   = reg_4[19:16]; // 4'h7  // Auto-refresh period
assign      cfg_sdr_twr_d     = reg_4[23:20]; // 4'h1  // Write recovery delay
assign      cfg_req_depth     = reg_4[25:24]; // 2'h3  // Maximum Request accepted by SDRAM controller
assign      cfg_sdr_cas       = reg_4[28:26]; // 3'h3  // SDRAM CAS Latency
assign      cfg_sdr_en        = reg_4[29]   ; // 1'b1 // Enable SDRAM controller
assign      reg_4[30]         = sdr_init_done ; // Indicate SDRAM Initialisation Done
assign      reg_4[31]         = 1'b0;


generic_register #(8,0  ) u_reg4_be0 (
	      .we            ({8{sw_wr_en_4 & 
                                 wr_be[0]   }}  ),		 
	      .data_in       (sw_reg_wdata[7:0]    ),
	      .reset_n       (reset_n           ),
	      .clk           (mclk              ),
	      
	      //List of Outs
	      .data_out      (reg_4[7:0]        )
          );

generic_register #(8,0  ) u_reg4_be1 (
	      .we            ({8{sw_wr_en_4 & 
                                 wr_be[1]   }}  ),		 
	      .data_in       (sw_reg_wdata[15:8]    ),
	      .reset_n       (reset_n           ),
	      .clk           (mclk              ),
	      
	      //List of Outs
	      .data_out      (reg_4[15:8]        )
          );
generic_register #(8,0  ) u_reg4_be2 (
	      .we            ({8{sw_wr_en_4 & 
                                 wr_be[2]   }}  ),		 
	      .data_in       (sw_reg_wdata[23:16]    ),
	      .reset_n       (reset_n           ),
	      .clk           (mclk              ),
	      
	      //List of Outs
	      .data_out      (reg_4[23:16]        )
          );

generic_register #(6,0  ) u_reg4_be3 (
	      .we            ({6{sw_wr_en_4 & 
                                 wr_be[3]   }}  ),		 
	      .data_in       (sw_reg_wdata[29:24]    ),
	      .reset_n       (reset_n           ),
	      .clk           (mclk              ),
	      
	      //List of Outs
	      .data_out      (reg_4[29:24]        )
          );
//-----------------------------------------------------------------------
//   reg-5, recomended default value {12'h100,13'h33,3'h6} = 32'h100_019E
//-----------------------------------------------------------------
assign      cfg_sdr_rfmax     = reg_5[2:0] ;   // 3'h6
assign      cfg_sdr_mode_reg  = reg_5[15:3] ;  // 13'h033
assign      cfg_sdr_rfsh      = reg_5[27:16];  // 12'h100

gen_32b_reg  #(32'h100_019E) u_reg_5	(
	      //List of Inputs
	      .reset_n    (reset_n     ),
	      .clk        (mclk          ),
	      .cs         (sw_wr_en_5   ),
	      .we         (wr_be         ),		 
	      .data_in    (sw_reg_wdata  ),
	      
	      //List of Outs
	      .data_out   (reg_5       )
	      );


//-----------------------------------------------------------------
//   reg- 6
// Software Reg-1 : ASCI Representation of YFIV = 32'h5946_4956
//-----------------------------------------------------------------

gen_32b_reg  #(32'h5946_4956) u_reg_6	(
	      //List of Inputs
	      .reset_n    (reset_n     ),
	      .clk        (mclk          ),
	      .cs         (sw_wr_en_6   ),
	      .we         (wr_be         ),		 
	      .data_in    (sw_reg_wdata  ),
	      
	      //List of Outs
	      .data_out   (reg_6       )
	      );


//-----------------------------------------------------------------
//   reg- 7
// Software Reg-2, Release date: <DAY><MONTH><YEAR>
//-----------------------------------------------------------------

gen_32b_reg  #(32'h07012022) u_reg_7	(
	      //List of Inputs
	      .reset_n    (reset_n       ),
	      .clk        (mclk          ),
	      .cs         (sw_wr_en_7    ),
	      .we         (wr_be         ),		 
	      .data_in    (sw_reg_wdata  ),
	      
	      //List of Outs
	      .data_out   (reg_7         )
	      );


//-----------------------------------------------------------------
//   reg- 8
// Software Reg-3: Poject Revison 2.0 = 0002_0000
//-----------------------------------------------------------------

gen_32b_reg  #(32'h0002_0000) u_reg_8	(
	      //List of Inputs
	      .reset_n    (reset_n       ),
	      .clk        (mclk          ),
	      .cs         (sw_wr_en_8    ),
	      .we         (wr_be         ),		 
	      .data_in    (sw_reg_wdata  ),
	      
	      //List of Outs
	      .data_out   (reg_8         )
	      );


//-----------------------------------------------------------------
//   reg- 9
//-----------------------------------------------------------------

gen_32b_reg  #(32'h0) u_reg_9	(
	      //List of Inputs
	      .reset_n    (reset_n       ),
	      .clk        (mclk          ),
	      .cs         (sw_wr_en_9    ),
	      .we         (wr_be         ),		 
	      .data_in    (sw_reg_wdata  ),
	      
	      //List of Outs
	      .data_out   (reg_9         )
	      );

//-----------------------------------------------------------------
//   reg- 10
//-----------------------------------------------------------------

gen_32b_reg  #(32'h0) u_reg_10	(
	      //List of Inputs
	      .reset_n    (reset_n       ),
	      .clk        (mclk          ),
	      .cs         (sw_wr_en_10   ),
	      .we         (wr_be         ),		 
	      .data_in    (sw_reg_wdata  ),
	      
	      //List of Outs
	      .data_out   (reg_10        )
	      );


//-----------------------------------------------------------------
//   reg- 11
//-----------------------------------------------------------------

gen_32b_reg  #(32'h0) u_reg_11	(
	      //List of Inputs
	      .reset_n    (reset_n       ),
	      .clk        (mclk          ),
	      .cs         (sw_wr_en_11   ),
	      .we         (wr_be         ),		 
	      .data_in    (sw_reg_wdata  ),
	      
	      //List of Outs
	      .data_out   (reg_11        )
	      );


//-----------------------------------------------------------------
//   reg- 12
//-----------------------------------------------------------------

gen_32b_reg  #(32'h0) u_reg_12	(
	      //List of Inputs
	      .reset_n    (reset_n       ),
	      .clk        (mclk          ),
	      .cs         (sw_wr_en_12   ),
	      .we         (wr_be         ),		 
	      .data_in    (sw_reg_wdata  ),
	      
	      //List of Outs
	      .data_out   (reg_12        )
	      );


//-----------------------------------------------------------------
//   reg- 13
//-----------------------------------------------------------------

gen_32b_reg  #(32'h0) u_reg_13	(
	      //List of Inputs
	      .reset_n    (reset_n       ),
	      .clk        (mclk          ),
	      .cs         (sw_wr_en_13   ),
	      .we         (wr_be         ),		 
	      .data_in    (sw_reg_wdata  ),
	      
	      //List of Outs
	      .data_out   (reg_13        )
	      );



//-----------------------------------------------------------------
//   reg- 14
//-----------------------------------------------------------------

gen_32b_reg  #(32'h0) u_reg_14	(
	      //List of Inputs
	      .reset_n    (reset_n       ),
	      .clk        (mclk          ),
	      .cs         (sw_wr_en_14   ),
	      .we         (wr_be         ),		 
	      .data_in    (sw_reg_wdata  ),
	      
	      //List of Outs
	      .data_out   (reg_14        )
	      );


//-----------------------------------------------------------------
//   reg- 15
//-----------------------------------------------------------------

gen_32b_reg  #(32'h0) u_reg_15	(
	      //List of Inputs
	      .reset_n    (reset_n       ),
	      .clk        (mclk          ),
	      .cs         (sw_wr_en_15   ),
	      .we         (wr_be         ),		 
	      .data_in    (sw_reg_wdata  ),
	      
	      //List of Outs
	      .data_out   (reg_15        )
	      );



//-----------------------------------------------------------------------
//   reg-16
//   -----------------------------------------------------------------
logic [31:0] cfg_bist_ctrl_1;

gen_32b_reg  #(32'h0) u_reg_16	(
	      //List of Inputs
	      .reset_n    (reset_n     ),
	      .clk        (mclk          ),
	      .cs         (sw_wr_en_16   ),
	      .we         (wr_be         ),		 
	      .data_in    (sw_reg_wdata  ),
	      
	      //List of Outs
	      .data_out   (cfg_bist_ctrl_1[31:0]  )
	      );



assign bist_en             = cfg_bist_ctrl_1[0];
assign bist_run            = cfg_bist_ctrl_1[1];
assign bist_load           = cfg_bist_ctrl_1[2];


//-----------------------------------------------------------------------
//   reg-17
//-----------------------------------------------------------------
logic [31:0] cfg_bist_status_1;

assign cfg_bist_status_1 = {  bist_error_cnt3, 1'b0, bist_correct[3], bist_error[3], bist_done,
	                      bist_error_cnt2, 1'b0, bist_correct[2], bist_error[2], bist_done,
	                      bist_error_cnt1, 1'b0, bist_correct[1], bist_error[1], bist_done,
	                      bist_error_cnt0, 1'b0, bist_correct[0], bist_error[0], bist_done
			   };

//-----------------------------------------------------------------------
//   reg-18 => Write to Serail I/F
//   reg-19 => READ  from Serail I/F
//-----------------------------------------------------------------
logic        bist_sdi_int;
logic        bist_shift_int;
logic        bist_sdo_int;
logic [31:0] serail_dout;

assign  bist_sdo_int = bist_sdo;
assign  bist_shift   = bist_shift_int;
assign  bist_sdi     = bist_sdi_int ;

ser_inf_32b u_ser_intf
       (

    // Master Port
       .rst_n       (reset_n),  // Regular Reset signal
       .clk         (mclk),  // System clock
       .reg_wr      (sw_wr_en_18 & wb_req_pedge),  // Write Request
       .reg_rd      (sw_rd_en_19 & wb_req_pedge),  // Read Request
       .reg_wdata   (sw_reg_wdata) ,  // data output
       .reg_rdata   (serail_dout),  // data input
       .reg_ack     (serial_ack),  // acknowlegement

    // Slave Port
       .sdi         (bist_sdi_int),    // Serial SDI
       .shift       (bist_shift_int),  // Shift Signal
       .sdo         (bist_sdo_int) // Serial SDO

    );


always @( *)
begin : preg_sel_Com

  reg_out [31:0] = 32'd0;

  case (sw_addr [4:0])
    5'b00000 : reg_out [31:0] = reg_0 [31:0];     
    5'b00001 : reg_out [31:0] = reg_1 [31:0];    
    5'b00010 : reg_out [31:0] = reg_2 [31:0];     
    5'b00011 : reg_out [31:0] = reg_3 [31:0];    
    5'b00100 : reg_out [31:0] = reg_4 [31:0];    
    5'b00101 : reg_out [31:0] = reg_5 [31:0];    
    5'b00110 : reg_out [31:0] = reg_6 [31:0];    
    5'b00111 : reg_out [31:0] = reg_7 [31:0];    
    5'b01000 : reg_out [31:0] = reg_8 [31:0];    
    5'b01001 : reg_out [31:0] = reg_9 [31:0];    
    5'b01010 : reg_out [31:0] = reg_10 [31:0];   
    5'b01011 : reg_out [31:0] = reg_11 [31:0];   
    5'b01100 : reg_out [31:0] = reg_12 [31:0];   
    5'b01101 : reg_out [31:0] = reg_13 [31:0];
    5'b01110 : reg_out [31:0] = reg_14 [31:0];
    5'b01111 : reg_out [31:0] = reg_15 [31:0]; 
    5'b10000 : reg_out [31:0] = cfg_bist_ctrl_1 [31:0];
    5'b10001 : reg_out [31:0] = cfg_bist_status_1 [31:0];
    5'b10010 : reg_out [31:0] = serail_dout [31:0]; // Previous Shift Data
    5'b10011 : reg_out [31:0] = serail_dout [31:0]; // Latest Shift Data
  endcase
end

endmodule
