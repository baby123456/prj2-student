`ifdef PRJ1_FPGA_IMPL
	// the board does not have enough GPIO, so we implement 4 4-bit registers
    `define DATA_WIDTH 4
	`define ADDR_WIDTH 2
`else
    `define DATA_WIDTH 32
	`define ADDR_WIDTH 5
`endif

`timescale 10 ns / 1 ns

module reg_file(
	input clk,
	input rst,
	input [`ADDR_WIDTH - 1:0] waddr,
	input [`ADDR_WIDTH - 1:0] raddr1,
	input [`ADDR_WIDTH - 1:0] raddr2,
	input wen,
	input [`DATA_WIDTH - 1:0] wdata,
	output [`DATA_WIDTH - 1:0] rdata1,
	output [`DATA_WIDTH - 1:0] rdata2
);

	// TODO: insert your code
	reg [`DATA_WIDTH - 1:0] regfile [2 ** `ADDR_WIDTH - 1:0];

	always@(posedge clk) begin
		if(rst) begin
			regfile[0] <= {`DATA_WIDTH{1'b0}};
		end
		else begin
			if(wen & waddr != {`ADDR_WIDTH{1'b0}}) begin
				regfile[waddr] <= wdata;
			end
		end
	end

	assign rdata1 = regfile[raddr1];
	assign rdata2 = regfile[raddr2];

endmodule
