/* =========================================
* Top module for MIPS cores in the FPGA
* evaluation platform
*
* Author: Yisong Chang (changyisong@ict.ac.cn)
* Date: 19/03/2017
* Version: v0.0.1
*===========================================
*/

`timescale 10 ns / 1 ns

module mips_cpu_top (

`ifndef MIPS_CPU_FULL_SIMU
	//AXI AR Channel
    input  [13:0]	mips_cpu_axi_if_araddr,
    output			mips_cpu_axi_if_arready,
    input			mips_cpu_axi_if_arvalid,

	//AXI AW Channel
    input  [13:0]	mips_cpu_axi_if_awaddr,
    output			mips_cpu_axi_if_awready,
    input			mips_cpu_axi_if_awvalid,

	//AXI B Channel
    input			mips_cpu_axi_if_bready,
    output [1:0]	mips_cpu_axi_if_bresp,
    output			mips_cpu_axi_if_bvalid,

	//AXI R Channel
    output [31:0]	mips_cpu_axi_if_rdata,
    input			mips_cpu_axi_if_rready,
    output [1:0]	mips_cpu_axi_if_rresp,
    output			mips_cpu_axi_if_rvalid,

	//AXI W Channel
    input  [31:0]	mips_cpu_axi_if_wdata,
    output			mips_cpu_axi_if_wready,
    input  [3:0]	mips_cpu_axi_if_wstrb,
    input			mips_cpu_axi_if_wvalid,
`endif

`ifdef MIPS_CPU_FULL_SIMU
	output			mips_cpu_pc_sig,
`endif

	input			mips_cpu_clk,
    input			mips_cpu_reset
);

endmodule

