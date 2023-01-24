// SPDX-FileCopyrightText: 2020 Efabless Corporation
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

`default_nettype none
/*	
	StriVe housekeeping SPI testbench.
*/

`timescale 1 ns / 1 ps

`include "uart_agent.v"
`include "uart2spi/msg_hand/uart_msg_handler.v"
`include "uart2spi/top/top.v"
`include "uart2spi/top/led_driver.v"
`include "uart2spi/spi/spi_if.v"
`include "uart2spi/spi/spi_core.v"
`include "uart2spi/spi/spi_ctl.v"
`include "uart2spi/spi/spi_cfg.v"
`include "uart2spi/uart_core/uartm_rxfsm.v"
`include "uart2spi/uart_core/uartm_txfsm.v"
`include "uart2spi/uart_core/uartm_core.v"



module hkspi_tb;

`include "uart_master_tasks.sv"

	reg clock;
	reg RSTB;
	wire SDI, CSB, SCK;
	wire SDO;
	reg power1, power2;

	wire gpio;
	wire [15:0] checkbits;
	wire [37:0] mprj_io;
	wire uart_tx;
	wire uart_rx;

	wire flash_csb;
	wire flash_clk;
	wire flash_io0;
	wire flash_io1;
	wire flash_io2;
	wire flash_io3;

    wire uartm_rxd;
    wire uartm_txd;

    reg  test_fail;

     //----------------------------------
     // Uart Configuration
     // ---------------------------------
     reg [1:0]      uart_data_bit        ;
     reg	       uart_stop_bits       ; // 0: 1 stop bit; 1: 2 stop bit;
     reg	       uart_stick_parity    ; // 1: force even parity
     reg	       uart_parity_en       ; // parity enable
     reg	       uart_even_odd_parity ; // 0: odd parity; 1: even parity
     
     reg [7:0]      uart_data            ;
     reg [15:0]     uart_divisor         ;	// divided by n * 16
     reg [15:0]     uart_timeout         ;// wait time limit
     
     reg [15:0]     uart_rx_nu           ;
     reg [15:0]     uart_tx_nu           ;
     reg [7:0]      uart_write_data [0:39];
     reg 	       uart_fifo_enable     ;	// fifo mode disable

     reg [7:0]     read_data     ;
     reg            flag;


	always #10 clock <= (clock === 1'b0);

	initial begin
		clock = 0;
	end

	initial begin		// Power-up sequence
		power1 <= 1'b0;
		power2 <= 1'b0;
		#200;
		power1 <= 1'b1;
		#200;
		power2 <= 1'b1;
	end

	
	integer i;

    // Now drive the digital signals on the housekeeping SPI
	reg [7:0] tbdata;

	initial begin
	    $dumpfile("hkspi.vcd");
	    $dumpvars(0, hkspi_tb);
    end

    initial begin

        test_fail = 0;
	    RSTB = 1'b0;

	    // Delay, then bring chip out of reset
	    #1000;
	    RSTB = 1'b1;
	    #2000;

        tb_master_uart.uart_init;
        uart_data_bit           = 2'b11;
        uart_stop_bits          = 0; // 0: 1 stop bit; 1: 2 stop bit;
        uart_stick_parity       = 0; // 1: force even parity
        uart_parity_en          = 0; // parity enable
        uart_even_odd_parity    = 1; // 0: odd parity; 1: even parity
        uart_divisor            = 127;// divided by n * 16
        uart_timeout            = 200;// wait time limit
        uart_fifo_enable        = 0;	// fifo mode disable
        tb_master_uart.debug_mode = 0; // disable debug display

        tb_master_uart.control_setup (uart_data_bit, uart_stop_bits, uart_parity_en, uart_even_odd_parity, 
	                          uart_stick_parity, uart_timeout, uart_divisor);


       // Wait for command flush
       flag = 0;
       while(flag == 0)
       begin
           tb_master_uart.read_char(read_data,flag);
           $write ("%c",read_data);
       end

            // First do a normal read from the housekeeping SPI to
	    // make sure the housekeeping SPI works.

	    //start_csb();
	    //write_byte(8'h40);	// Read stream command
	    //write_byte(8'h03);	// Address (register 3 = product ID)
	    //read_byte(tbdata);
	    //end_csb();
	    //#10;
	    //$display("Read data = 0x%02x (should be 0x11)", tbdata);
        uartm_reg_read_check(8'h03,8'h11);

	    // Toggle external reset
	    //start_csb();
	    //write_byte(8'h80);	// Write stream command
	    //write_byte(8'h0b);	// Address (register 7 = external reset)
	    //write_byte(8'h01);	// Data = 0x01 (apply external reset)
	    //end_csb();
        uartm_reg_write(8'h0b,8'h01);

	    //start_csb();
	    //write_byte(8'h80);	// Write stream command
	    //write_byte(8'h0b);	// Address (register 7 = external reset)
	    //write_byte(8'h00);	// Data = 0x00 (release external reset)
	    //end_csb();
        uartm_reg_write(8'h0b,8'h00);

	    // Read all registers (0 to 18)
	    //start_csb();
	    //write_byte(8'h40);	// Read stream command
	    //write_byte(8'h00);	// Address (register 3 = product ID)
	    //read_byte(tbdata);

        uartm_reg_read(8'h00,tbdata);
	    $display("Read register 0 = 0x%02x (should be 0x00)", tbdata);
		if(tbdata !== 8'h00) begin 
			`ifdef GL
				$display("Monitor: Test HK SPI (GL) Failed"); $finish; 
			`else
				$display("Monitor: Test HK SPI (RTL) Failed"); $finish; 
			`endif
		end
	    //read_byte(tbdata);
        uartm_reg_read(8'h01,tbdata);
	    $display("Read register 1 = 0x%02x (should be 0x04)", tbdata);
		if(tbdata !== 8'h04) begin 
			`ifdef GL
				$display("Monitor: Test HK SPI (GL) Failed"); $finish; 
			`else
				$display("Monitor: Test HK SPI (RTL) Failed"); $finish; 
			`endif
		end
	    //read_byte(tbdata);
        uartm_reg_read(8'h02,tbdata);
	    $display("Read register 2 = 0x%02x (should be 0x56)", tbdata);
		if(tbdata !== 8'h56) begin
			`ifdef GL
				$display("Monitor: Test HK SPI (GL) Failed, %02x", tbdata); $finish; 
			`else
				$display("Monitor: Test HK SPI (RTL) Failed, %02x", tbdata); $finish; 
			`endif
		end
	    //read_byte(tbdata);
        uartm_reg_read(8'h03,tbdata);
	    $display("Read register 3 = 0x%02x (should be 0x11)", tbdata);
		if(tbdata !== 8'h11) begin 
			`ifdef GL
				$display("Monitor: Test HK SPI (GL) Failed, %02x", tbdata); $finish; 
			`else
				$display("Monitor: Test HK SPI (RTL) Failed, %02x", tbdata); $finish; 
			`endif
		end
	    //read_byte(tbdata);
        uartm_reg_read(8'h04,tbdata);
	    $display("Read register 4 = 0x%02x (should be 0x00)", tbdata);
		if(tbdata !== 8'h00) begin 
			`ifdef GL
				$display("Monitor: Test HK SPI (GL) Failed"); $finish; 
			`else
				$display("Monitor: Test HK SPI (RTL) Failed"); $finish; 
			`endif
		end
	    //read_byte(tbdata);
        uartm_reg_read(8'h05,tbdata);
	    $display("Read register 5 = 0x%02x (should be 0x00)", tbdata);
		if(tbdata !== 8'h00) begin 
			`ifdef GL
				$display("Monitor: Test HK SPI (GL) Failed"); $finish; 
			`else
				$display("Monitor: Test HK SPI (RTL) Failed"); $finish; 
			`endif
		end
	    //read_byte(tbdata);
        uartm_reg_read(8'h06,tbdata);
	    $display("Read register 6 = 0x%02x (should be 0x00)", tbdata);
		if(tbdata !== 8'h00) begin 
			`ifdef GL
				$display("Monitor: Test HK SPI (GL) Failed"); $finish; 
			`else
				$display("Monitor: Test HK SPI (RTL) Failed"); $finish; 
			`endif
		end
	    //read_byte(tbdata);
        uartm_reg_read(8'h07,tbdata);
	    $display("Read register 7 = 0x%02x (should be 0x00)", tbdata);
		if(tbdata !== 8'h00) begin 
			`ifdef GL
				$display("Monitor: Test HK SPI (GL) Failed"); $finish; 
			`else
				$display("Monitor: Test HK SPI (RTL) Failed"); $finish; 
			`endif
		end
	    //read_byte(tbdata);
        uartm_reg_read(8'h08,tbdata);
	    $display("Read register 8 = 0x%02x (should be 0x02)", tbdata);
		if(tbdata !== 8'h02) begin 
			`ifdef GL
				$display("Monitor: Test HK SPI (GL) Failed"); $finish; 
			`else
				$display("Monitor: Test HK SPI (RTL) Failed"); $finish; 
			`endif
		end
	    //read_byte(tbdata);
        uartm_reg_read(8'h09,tbdata);
	    $display("Read register 9 = 0x%02x (should be 0x01)", tbdata);
		if(tbdata !== 8'h01) begin 
			`ifdef GL
				$display("Monitor: Test HK SPI (GL) Failed"); $finish; 
			`else
				$display("Monitor: Test HK SPI (RTL) Failed"); $finish; 
			`endif
		end
	    //read_byte(tbdata);
        uartm_reg_read(8'h0A,tbdata);
	    $display("Read register 10 = 0x%02x (should be 0x00)", tbdata);
		if(tbdata !== 8'h00) begin 
			`ifdef GL
				$display("Monitor: Test HK SPI (GL) Failed"); $finish; 
			`else
				$display("Monitor: Test HK SPI (RTL) Failed"); $finish; 
			`endif
		end
	    //read_byte(tbdata);
        uartm_reg_read(8'h0B,tbdata);
	    $display("Read register 11 = 0x%02x (should be 0x00)", tbdata);
		if(tbdata !== 8'h00) begin 
			`ifdef GL
				$display("Monitor: Test HK SPI (GL) Failed"); $finish; 
			`else
				$display("Monitor: Test HK SPI (RTL) Failed"); $finish; 
			`endif
		end
	    //read_byte(tbdata);
        uartm_reg_read(8'h0C,tbdata);
	    $display("Read register 12 = 0x%02x (should be 0x00)", tbdata);
		if(tbdata !== 8'h00) begin 
			`ifdef GL
				$display("Monitor: Test HK SPI (GL) Failed"); $finish; 
			`else
				$display("Monitor: Test HK SPI (RTL) Failed"); $finish; 
			`endif
		end
	    //read_byte(tbdata);
        uartm_reg_read(8'h0D,tbdata);
	    $display("Read register 13 = 0x%02x (should be 0xff)", tbdata);
		if(tbdata !== 8'hff) begin 
			`ifdef GL
				$display("Monitor: Test HK SPI (GL) Failed"); $finish; 
			`else
				$display("Monitor: Test HK SPI (RTL) Failed"); $finish; 
			`endif
		end
	    //read_byte(tbdata);
        uartm_reg_read(8'h0E,tbdata);
	    $display("Read register 14 = 0x%02x (should be 0xef)", tbdata);
		if(tbdata !== 8'hef) begin 
			`ifdef GL
				$display("Monitor: Test HK SPI (GL) Failed"); $finish; 
			`else
				$display("Monitor: Test HK SPI (RTL) Failed"); $finish; 
			`endif
		end
	    //read_byte(tbdata);
        uartm_reg_read(8'h0F,tbdata);
	    $display("Read register 15 = 0x%02x (should be 0xff)", tbdata);
		if(tbdata !== 8'hff) begin 
			`ifdef GL
				$display("Monitor: Test HK SPI (GL) Failed"); $finish; 
			`else
				$display("Monitor: Test HK SPI (RTL) Failed"); $finish; 
			`endif
		end
	    //read_byte(tbdata);
        uartm_reg_read(8'h10,tbdata);
	    $display("Read register 16 = 0x%02x (should be 0x03)", tbdata);
		if(tbdata !== 8'h03) begin 
			`ifdef GL
				$display("Monitor: Test HK SPI (GL) Failed"); $finish; 
			`else
				$display("Monitor: Test HK SPI (RTL) Failed"); $finish; 
			`endif
		end
	    //read_byte(tbdata);
        uartm_reg_read(8'h11,tbdata);
	    $display("Read register 17 = 0x%02x (should be 0x12)", tbdata);
		if(tbdata !== 8'h12) begin 
			`ifdef GL
				$display("Monitor: Test HK SPI (GL) Failed"); $finish; 
			`else
				$display("Monitor: Test HK SPI (RTL) Failed"); $finish; 
			`endif
		end
	    //read_byte(tbdata);
        uartm_reg_read(8'h12,tbdata);
	    $display("Read register 18 = 0x%02x (should be 0x04)", tbdata);
		if(tbdata !== 8'h04) begin 
			`ifdef GL
				$display("Monitor: Test HK SPI (GL) Failed"); $finish; 
			`else
				$display("Monitor: Test HK SPI (RTL) Failed"); $finish; 
			`endif
		end
		
        //end_csb();

		`ifdef GL
			$display("Monitor: Test HK SPI (GL) Passed");
		`else
			$display("Monitor: Test HK SPI (RTL) Passed");
		`endif

	    #10000;
 	    $finish;
	end

	wire VDD3V3;
	wire VDD1V8;
	wire VSS;

	assign VDD3V3 = power1;
	assign VDD1V8 = power2;
	assign VSS = 1'b0;

	wire hk_sck;
	wire hk_csb;
	wire hk_sdi;

	assign hk_sck = SCK;
	assign hk_csb = CSB;
	assign hk_sdi = SDI;

	assign checkbits = mprj_io[31:16];
	assign uart_tx = mprj_io[6];
	assign mprj_io[5] = uart_rx;
	assign mprj_io[4] = hk_sck;
	assign mprj_io[3] = hk_csb;
	assign mprj_io[2] = hk_sdi;
	assign SDO = mprj_io[1];



    wire [3:0] spi_csn;
    assign CSB = spi_csn[0];

    uart2spi u_uart2spi(
        .line_reset_n  (RSTB ) ,
        .line_clk      (clock),


       // Line Interface
        .uart_rxd     (uartm_rxd),
        .uart_txd     (uartm_txd),

      // Spi I/F
        .spi_sck    (SCK),
        .spi_so     (SDO),
        .spi_si     (SDI),
        .spi_csn    (spi_csn),

        .Switch     (4'h0),
        .LED        ()

     );

	
	caravel uut (
		.vddio	  (VDD3V3),
		.vssio	  (VSS),
		.vdda	  (VDD3V3),
		.vssa	  (VSS),
		.vccd	  (VDD1V8),
		.vssd	  (VSS),
		.vdda1    (VDD3V3),
		.vdda2    (VDD3V3),
		.vssa1	  (VSS),
		.vssa2	  (VSS),
		.vccd1	  (VDD1V8),
		.vccd2	  (VDD1V8),
		.vssd1	  (VSS),
		.vssd2	  (VSS),
		.clock	  (clock),
		.gpio     (gpio),
		.mprj_io  (mprj_io),
		.flash_csb(flash_csb),
		.flash_clk(flash_clk),
		.flash_io0(flash_io0),
		.flash_io1(flash_io1),
		.resetb	  (RSTB)
	);

	spiflash #(
		.FILENAME("hkspi.hex")
	) spiflash (
		.csb(flash_csb),
		.clk(flash_clk),
		.io0(flash_io0),
		.io1(flash_io1),
		.io2(),			// not used
		.io3()			// not used
	);

	tbuart tbuart (
		.ser_rx(uart_tx)
	);


uart_agent tb_master_uart(
	.mclk                (clock              ),
	.txd                 (uartm_rxd          ),
	.rxd                 (uartm_txd          )
	);

		
endmodule
`default_nettype wire
