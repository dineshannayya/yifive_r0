/*
 * SPDX-FileCopyrightText: 2020 Efabless Corporation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * SPDX-License-Identifier: Apache-2.0
 */

// This include is relative to $CARAVEL_PATH (see Makefile)
#include <defs.h>
#include <stub.c>

#define reg_wb_enable	  	(*(volatile uint32_t*) CSR_MPRJ_WB_IENA_OUT_ADDR)

// User Project Slaves (0x3000_0000)

#define reg_mprj_wbhost_reg0      (*(volatile uint32_t*)0x30800000)
#define reg_mprj_wbhost_reg1      (*(volatile uint32_t*)0x30800004)
#define reg_mprj_wbhost_clk_ctrl1 (*(volatile uint32_t*)0x30800008)
#define reg_mprj_wbhost_clk_ctrl2 (*(volatile uint32_t*)0x3080000C)


#define reg_mprj_globl_reg0  (*(volatile uint32_t*)0x30000000)
#define reg_mprj_globl_reg1  (*(volatile uint32_t*)0x30000004)
#define reg_mprj_globl_reg2  (*(volatile uint32_t*)0x30000008)
#define reg_mprj_globl_reg3  (*(volatile uint32_t*)0x3000000C)
#define reg_mprj_globl_reg4  (*(volatile uint32_t*)0x30000010)
#define reg_mprj_globl_reg5  (*(volatile uint32_t*)0x30000014)
#define reg_mprj_globl_reg6  (*(volatile uint32_t*)0x30000018)
#define reg_mprj_globl_reg7  (*(volatile uint32_t*)0x3000001C)
#define reg_mprj_globl_reg8  (*(volatile uint32_t*)0x30000020)
#define reg_mprj_globl_reg9  (*(volatile uint32_t*)0x30000024)
#define reg_mprj_globl_reg10 (*(volatile uint32_t*)0x30000028)
#define reg_mprj_globl_reg11 (*(volatile uint32_t*)0x3000002C)
#define reg_mprj_globl_reg12 (*(volatile uint32_t*)0x30000030)
#define reg_mprj_globl_reg13 (*(volatile uint32_t*)0x30000034)
#define reg_mprj_globl_reg14 (*(volatile uint32_t*)0x30000038)
#define reg_mprj_globl_reg15 (*(volatile uint32_t*)0x3000003C)

#define reg_mprj_uart_reg0 (*(volatile uint32_t*)0x30010000)
#define reg_mprj_uart_reg1 (*(volatile uint32_t*)0x30010004)
#define reg_mprj_uart_reg2 (*(volatile uint32_t*)0x30010008)
#define reg_mprj_uart_reg3 (*(volatile uint32_t*)0x3001000C)
#define reg_mprj_uart_reg4 (*(volatile uint32_t*)0x30010010)
#define reg_mprj_uart_reg5 (*(volatile uint32_t*)0x30010014)
#define reg_mprj_uart_reg6 (*(volatile uint32_t*)0x30010018)
#define reg_mprj_uart_reg7 (*(volatile uint32_t*)0x3001001C)
#define reg_mprj_uart_reg8 (*(volatile uint32_t*)0x30010020)

#define GPIO_MODE_USER_STD_BIDIRECTIONAL_PULLUP   0x1C00

#define GPIO_MODE_USER_STD_BIDIRECTIONAL          0x0800

#define SC_SIM_OUTPORT (0xf0000000)

/*
         RiscV Hello World test.
	        - Wake up the Risc V
		- Boot from SPI Flash
		- Riscv Write Hello World to SDRAM,
		- External Wishbone read back validation the data
*/
int i = 0; 
int clk = 0;

void main()
{

	int bFail = 0;
	/* 
	IO Control Registers
	| DM     | VTRIP | SLOW  | AN_POL | AN_SEL | AN_EN | MOD_SEL | INP_DIS | HOLDH | OEB_N | MGMT_EN |
	| 3-bits | 1-bit | 1-bit | 1-bit  | 1-bit  | 1-bit | 1-bit   | 1-bit   | 1-bit | 1-bit | 1-bit   |
	Output: 0000_0110_0000_1110  (0x1808) = GPIO_MODE_USER_STD_OUTPUT
	| DM     | VTRIP | SLOW  | AN_POL | AN_SEL | AN_EN | MOD_SEL | INP_DIS | HOLDH | OEB_N | MGMT_EN |
	| 110    | 0     | 0     | 0      | 0      | 0     | 0       | 1       | 0     | 0     | 0       |
	
	 
	Input: 0000_0001_0000_1111 (0x0402) = GPIO_MODE_USER_STD_INPUT_NOPULL
	| DM     | VTRIP | SLOW  | AN_POL | AN_SEL | AN_EN | MOD_SEL | INP_DIS | HOLDH | OEB_N | MGMT_EN |
	| 001    | 0     | 0     | 0      | 0      | 0     | 0       | 0       | 0     | 1     | 0       |

	Input: 0000_0001_0000_1111 (0x1800) = GPIO_MODE_USER_STD_BIDIRECTIONAL
	| DM     | VTRIP | SLOW  | AN_POL | AN_SEL | AN_EN | MOD_SEL | INP_DIS | HOLDH | OEB_N | MGMT_EN |
	| 110    | 0     | 0     | 0      | 0      | 0     | 0       | 0       | 0     | 0     | 0       |
	*/

	/* Set up the housekeeping SPI to be connected internally so	*/
	/* that external pin changes don't affect it.			*/

        reg_spi_enable = 0;
        reg_wb_enable = 1;
	// reg_spimaster_config = 0xa002;	// Enable, prescaler = 2,
                                        // connect to housekeeping SPI

	// Connect the housekeeping SPI to the SPI master
	// so that the CSB line is not left floating.  This allows
	// all of the GPIO pins to be used for user functions.
        reg_mprj_io_31 = GPIO_MODE_MGMT_STD_OUTPUT;
        reg_mprj_io_30 = GPIO_MODE_MGMT_STD_OUTPUT;
        reg_mprj_io_29 = GPIO_MODE_MGMT_STD_OUTPUT;
        reg_mprj_io_28 = GPIO_MODE_MGMT_STD_OUTPUT;
        reg_mprj_io_27 = GPIO_MODE_MGMT_STD_OUTPUT;
        reg_mprj_io_26 = GPIO_MODE_MGMT_STD_OUTPUT;
        reg_mprj_io_25 = GPIO_MODE_MGMT_STD_OUTPUT;
        reg_mprj_io_24 = GPIO_MODE_MGMT_STD_OUTPUT;
        reg_mprj_io_23 = GPIO_MODE_MGMT_STD_OUTPUT;
        reg_mprj_io_22 = GPIO_MODE_MGMT_STD_OUTPUT;
        reg_mprj_io_21 = GPIO_MODE_MGMT_STD_OUTPUT;
        reg_mprj_io_20 = GPIO_MODE_MGMT_STD_OUTPUT;
        reg_mprj_io_19 = GPIO_MODE_MGMT_STD_OUTPUT;
        reg_mprj_io_18 = GPIO_MODE_MGMT_STD_OUTPUT;
        reg_mprj_io_17 = GPIO_MODE_MGMT_STD_OUTPUT;
        reg_mprj_io_16 = GPIO_MODE_MGMT_STD_OUTPUT;


     /* Apply configuration */
    reg_mprj_xfer = 1;
    while (reg_mprj_xfer == 1);

    //reg_la2_oenb = reg_la2_iena = 0xFFFFFFFF;    // [95:64]

    // Flag start of the test
	reg_mprj_datal = 0xAB600000;

    //-----------------------------------------------------
    // Start of User Functionality and take over the GPIO Pins
    // ------------------------------------------------------
    // User block decide on the GPIO function
    reg_mprj_io_37 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_36 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_35 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_34 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_33 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_32 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_31 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_30 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_29 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_28 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_27 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_26 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_25 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_24 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_23 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_22 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_21 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_20 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_19 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_18 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_17 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_16 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_15 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_14 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_13 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_12 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_11 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_10 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_9  = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_8  = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_7  = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_6 =  GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_5 =  GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_4 =  GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_3 =  GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_2 =  GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_1 =  GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_0 =  GPIO_MODE_USER_STD_BIDIRECTIONAL;

     /* Apply configuration */
    reg_mprj_xfer = 1;
    while (reg_mprj_xfer == 1);

    reg_mprj_wbhost_clk_ctrl1 = 0x084868c2;

    reg_mprj_wbhost_clk_ctrl2 = 0x00;

    // Remove All Reset
    reg_mprj_wbhost_reg0 = 0x000001F;


}
