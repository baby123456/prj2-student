/* =========================================
* Top module of FPGA evaluation platform for
* MIPS CPU cores
*
* Author: Yisong Chang (changyisong@ict.ac.cn)
* Date: 19/03/2017
* Version: v0.0.1
*===========================================
*/

`timescale 1 ps / 1 ps

module mips_cpu_fpga (
	input [25:0]		mips_cpu_axi_if_araddr,
  	output			mips_cpu_axi_if_arready,
  	input			mips_cpu_axi_if_arvalid,
  	
	input [25:0]		mips_cpu_axi_if_awaddr,
  	output			mips_cpu_axi_if_awready,
  	input			mips_cpu_axi_if_awvalid,
  	
	input			mips_cpu_axi_if_bready,
  	output [1:0]		mips_cpu_axi_if_bresp,
  	output			mips_cpu_axi_if_bvalid,
  	
	output [31:0]		mips_cpu_axi_if_rdata,
  	input			mips_cpu_axi_if_rready,
  	output [1:0]		mips_cpu_axi_if_rresp,
  	output 			mips_cpu_axi_if_rvalid,
  	
	input [31:0]		mips_cpu_axi_if_wdata,
  	output			mips_cpu_axi_if_wready,
  	input [3:0]		mips_cpu_axi_if_wstrb,
  	input			mips_cpu_axi_if_wvalid,
	
  	input			mips_cpu_clk,
	input			mips_cpu_reset_n,
  	input			ps_user_reset_n

);

  reg [1:0]			mips_cpu_reset_n_i = 2'b00;

  //generate positive reset signal for MIPS CPU core
  always @ (posedge mips_cpu_clk)
	  mips_cpu_reset_n_i <= {mips_cpu_reset_n_i[0], ps_user_reset_n};

  assign mips_cpu_reset_n = mips_cpu_reset_n_i[1];
 
  //Instantiation of MIPS CPU core
  mips_cpu_top		u_mips_cpu_top (
	  .mips_cpu_clk					(mips_cpu_clk),
	  .mips_cpu_reset				(~mips_cpu_reset_n),
	  
	  .mips_cpu_axi_if_araddr		(mips_cpu_axi_if_araddr[13:0]),
	  .mips_cpu_axi_if_arready		(mips_cpu_axi_if_arready),
	  .mips_cpu_axi_if_arvalid		(mips_cpu_axi_if_arvalid),
	  .mips_cpu_axi_if_awaddr		(mips_cpu_axi_if_awaddr[13:0]),
	  .mips_cpu_axi_if_awready		(mips_cpu_axi_if_awready),
	  .mips_cpu_axi_if_awvalid		(mips_cpu_axi_if_awvalid),
	  .mips_cpu_axi_if_bready		(mips_cpu_axi_if_bready),
	  .mips_cpu_axi_if_bresp		(mips_cpu_axi_if_bresp),
	  .mips_cpu_axi_if_bvalid		(mips_cpu_axi_if_bvalid),
	  .mips_cpu_axi_if_rdata		(mips_cpu_axi_if_rdata),
	  .mips_cpu_axi_if_rready		(mips_cpu_axi_if_rready),
	  .mips_cpu_axi_if_rresp		(mips_cpu_axi_if_rresp),
	  .mips_cpu_axi_if_rvalid		(mips_cpu_axi_if_rvalid),
	  .mips_cpu_axi_if_wdata		(mips_cpu_axi_if_wdata),
	  .mips_cpu_axi_if_wready		(mips_cpu_axi_if_wready),
	  .mips_cpu_axi_if_wstrb		(mips_cpu_axi_if_wstrb),
	  .mips_cpu_axi_if_wvalid		(mips_cpu_axi_if_wvalid)
  );

endmodule

