`timescale 10 ns / 1 ns

`define DATA_WIDTH 32

module user(
    input clk,
    input rst,
    // access PL memory AXI4 Master interface,32bit address
    // AXI4 AR channel
    output [31:0] axi4_ddr_araddr,
    output [1:0] axi4_ddr_arburst,
    output [3:0] axi4_ddr_arcache,
    output [7:0] axi4_ddr_arlen,
    output [0:0] axi4_ddr_arlock,
    output [2:0] axi4_ddr_arprot,
    output [3:0] axi4_ddr_arqos,
    input axi4_ddr_arready,
    output [3:0] axi4_ddr_arregion,
    output [2:0] axi4_ddr_arsize,
    output axi4_ddr_arvalid,
    // AXI4 AW channel
    output [31:0] axi4_ddr_awaddr,
    output [1:0] axi4_ddr_awburst,
    output [3:0] axi4_ddr_awcache,
    output [7:0] axi4_ddr_awlen,
    output [0:0] axi4_ddr_awlock,
    output [2:0] axi4_ddr_awprot,
    output [3:0] axi4_ddr_awqos,
    input axi4_ddr_awready,
    output [3:0] axi4_ddr_awregion,
    output [2:0] axi4_ddr_awsize,
    output axi4_ddr_awvalid,
    // AXI4 B channel
    output axi4_ddr_bready,
    input [1:0] axi4_ddr_bresp,
    input axi4_ddr_bvalid,
    // AXI4 R channel
    input [31:0] axi4_ddr_rdata,
    input axi4_ddr_rlast,
    output axi4_ddr_rready,
    input [1:0] axi4_ddr_rresp,
    input axi4_ddr_rvalid,
    // AXI4 W channel
    output [31:0] axi4_ddr_wdata,
    output axi4_ddr_wlast,
    input axi4_ddr_wready,
    output [3:0] axi4_ddr_wstrb,
    output axi4_ddr_wvalid,

    // acess uartlite reg AXI-lite master interface,12bit address
    // AXI-lite AR channel
    output [31:0] cpu_axi_uart_araddr,
    output [2:0] cpu_axi_uart_arprot,
    output [3:0] cpu_axi_uart_arqos,
    input cpu_axi_uart_arready,
    output [3:0] cpu_axi_uart_arregion,
    output cpu_axi_uart_arvalid,
    // AXI-lite AW channel
    output [31:0] cpu_axi_uart_awaddr,
    output [2:0] cpu_axi_uart_awprot,
    output [3:0] cpu_axi_uart_awqos,
    input cpu_axi_uart_awready,
    output [3:0] cpu_axi_uart_awregion,
    output cpu_axi_uart_awvalid,
    // AXI-lite B channel
    output cpu_axi_uart_bready,
    input [1:0] cpu_axi_uart_bresp,
    input cpu_axi_uart_bvalid,
    // AXI-lite R channel
    input [31:0] cpu_axi_uart_rdata,
    output cpu_axi_uart_rready,
    input [1:0] cpu_axi_uart_rresp,
    input cpu_axi_uart_rvalid,
    // AXI-lite W channel
    output [31:0] cpu_axi_uart_wdata,
    input cpu_axi_uart_wready,
    output [3:0] cpu_axi_uart_wstrb,
    output cpu_axi_uart_wvalid,

    // MMIO reg AXI-lite slave interface,26bit address,64MB
    // AXI-lite AR channel
    input [25:0] mips_cpu_axi_mmio_araddr,
    input [2:0] mips_cpu_axi_mmio_arprot,
    input [3:0] mips_cpu_axi_mmio_arqos,
    output mips_cpu_axi_mmio_arready,
    input [3:0] mips_cpu_axi_mmio_arregion,
    input mips_cpu_axi_mmio_arvalid,
    // AXI-lite AW channel
    input [25:0] mips_cpu_axi_mmio_awaddr,
    input [2:0] mips_cpu_axi_mmio_awprot,
    input [3:0] mips_cpu_axi_mmio_awqos,
    output mips_cpu_axi_mmio_awready,
    input [3:0] mips_cpu_axi_mmio_awregion,
    input mips_cpu_axi_mmio_awvalid,
    // AXI-lite B channel
    input mips_cpu_axi_mmio_bready,
    output [1:0] mips_cpu_axi_mmio_bresp,
    output mips_cpu_axi_mmio_bvalid,
    // AXI-lite R channel
    output [31:0] mips_cpu_axi_mmio_rdata,
    input mips_cpu_axi_mmio_rready,
    output [1:0] mips_cpu_axi_mmio_rresp,
    output mips_cpu_axi_mmio_rvalid,
    // AXI-lite W channel
    input [31:0] mips_cpu_axi_mmio_wdata,
    output mips_cpu_axi_mmio_wready,
    input [3:0] mips_cpu_axi_mmio_wstrb,
    input mips_cpu_axi_mmio_wvalid
);
	
	mips_cpu_fpga u_mips_cpu_fpga(
        	.mips_cpu_axi_if_araddr			(mips_cpu_axi_mmio_araddr),
        	.mips_cpu_axi_if_arready		(mips_cpu_axi_mmio_arready),
        	.mips_cpu_axi_if_arvalid		(mips_cpu_axi_mmio_arvalid),
        
		.mips_cpu_axi_if_awaddr			(mips_cpu_axi_mmio_awaddr),
        	.mips_cpu_axi_if_awready		(mips_cpu_axi_mmio_awready),
        	.mips_cpu_axi_if_awvalid		(mips_cpu_axi_mmio_awvalid),
        	
		.mips_cpu_axi_if_bready			(mips_cpu_axi_mmio_bready),
        	.mips_cpu_axi_if_bresp			(mips_cpu_axi_mmio_bresp),
        	.mips_cpu_axi_if_bvalid			(mips_cpu_axi_mmio_bvalid),
        	
		.mips_cpu_axi_if_rdata			(mips_cpu_axi_mmio_rdata),
        	.mips_cpu_axi_if_rready			(mips_cpu_axi_mmio_rready),
        	.mips_cpu_axi_if_rresp			(mips_cpu_axi_mmio_rresp),
		.mips_cpu_axi_if_rvalid			(mips_cpu_axi_mmio_rvalid),

        	.mips_cpu_axi_if_wdata			(mips_cpu_axi_mmio_wdata),
        	.mips_cpu_axi_if_wready			(mips_cpu_axi_mmio_wready),
        	.mips_cpu_axi_if_wstrb			(mips_cpu_axi_mmio_wstrb),
        	.mips_cpu_axi_if_wvalid			(mips_cpu_axi_mmio_wvalid),

        	.mips_cpu_clk				(clk),
        	.mips_cpu_reset_n			(),
        	.ps_user_reset_n			(rst)
);

endmodule

