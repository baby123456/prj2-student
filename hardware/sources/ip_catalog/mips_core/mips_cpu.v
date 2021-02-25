`timescale 10ns / 1ns
`include"define.h"

module mips_cpu(
	input  rst,
	input  clk,

	output [31:0] PC,
	input  [31:0] Instruction,

	output [31:0] Address,
	output MemWrite,
	output [31:0] Write_data,
	output [3:0] Write_strb,

	input  [31:0] Read_data,
	output MemRead
);
  wire [4:0] reg_waddr;
  wire [31:0] reg_rdata1;
  wire [31:0] reg_rdata2;
  wire	[31:0]	ALU_A;
  wire	[31:0]	ALU_B;
  wire [31:0] reg_wdata;
  wire [31:0] alu1_result;
  wire [31:0] PC1;
  wire [31:0] PC2;
  wire	[31:0]	PC_j;
  wire [31:0] jump_ind;
  wire [15:0] extend_op;
  wire [5:0] ALUop;
  wire	[31:0]	read_data;
  wire	[7:0]	read_data_byte;
  wire	[15:0]	read_data_half;
  wire	[31:0]	read_data_lwlr;
  wire	[3:0]	Write_strb_swlr;
  wire	[31:0]	Write_data_swlr;
  wire	[31:0]	Write_data_sbh;
  wire Zero;
  wire BNE;
  wire	BEQ;
  wire BLEZ;
  wire J;
  wire	JR;
  wire	is_signed;
  wire	LB;
  wire	LH;
  wire	LWR;
  wire	LWL;
  wire	SB;
  wire	SH;
  wire	SWL;
  wire	SWR;
  wire	REGIMM;
  wire [1:0] RegDst;
  wire [1:0] MemtoReg;
  wire [1:0] ALUSrc_B;
  wire ALUSrc_A;
  wire RegWrite;
  //wire	[63:0]	mul_result;
  //wire	Mult_en;
  reg [31:0] PC3;
  //reg	[31:0]	Hi;
  //reg	[31:0]	Lo;
  
  assign Write_data = (SWL || SWR) ? Write_data_swlr : 
									((SB || SH) ? Write_data_sbh : reg_rdata2);
  assign Write_data_sbh = SB ? ((alu1_result[1:0] == 2'b11) ? {reg_rdata2[7:0],24'd0} : 
															((alu1_result[1:0] == 2'b10) ? {8'd0,reg_rdata2[7:0],16'd0} : 
																						((alu1_result[1:0] == 2'b01) ? {16'd0,reg_rdata2[7:0],8'd0} : 
																													{24'd0,reg_rdata2[7:0]}))) :
							((alu1_result[1:0] == 2'b10) ? {reg_rdata2[15:0],16'd0} : 
																{16'd0,reg_rdata2[15:0]});
  assign	Write_strb = SB ? ((alu1_result[1:0] == 2'b11) ? {MemWrite,3'd0} : 
															((alu1_result[1:0] == 2'b10) ? {1'b0,MemWrite,2'd0} : 
																						((alu1_result[1:0] == 2'b01) ? {2'd0,MemWrite,1'b0} : 
																													{3'd0,MemWrite}))) :
							(SH ? ((alu1_result[1:0] == 2'b10) ? {{2{MemWrite}},2'b00} : 
																{2'b00,{2{MemWrite}}}) :
								((SWL || SWR) ? Write_strb_swlr :
												{4{MemWrite}}));
  assign reg_waddr = (RegDst[0]) ? Instruction[15:11] : 
						(RegDst[1] ? 'd31 : Instruction[20:16]);
  assign extend_op =  {16{Instruction[15]}};
  assign  ALU_B = (ALUSrc_B[0]) ? (ALUSrc_B[1] ? {16'd0,Instruction[15:0]} : {extend_op,Instruction[15:0]}):
						(ALUSrc_B[1] ? 'd4 : reg_rdata2);
  assign ALU_A = (ALUSrc_A) ? PC1 : reg_rdata1;
  assign	read_data_byte = (alu1_result[1:0] == 2'b11) ? Read_data[31:24] : 
								((alu1_result[1:0] == 2'b10) ? Read_data[23:16] : 
								((alu1_result[1:0] == 2'b01) ? Read_data[15:8] : Read_data[7:0]));
  assign	read_data_half = (alu1_result[1:0] == 2'b10) ? Read_data[31:16] : Read_data[15:0];
  assign	read_data = LB ? (is_signed ? {24'd0,read_data_byte} : {{24{read_data_byte[7]}},read_data_byte}):
							(LH ? (is_signed ? {16'd0,read_data_half} : {{16{read_data_half[15]}},read_data_half}):
									((LWL || LWR) ? read_data_lwlr :
													Read_data));
 // assign reg_wdata = (MemtoReg[0]) ? (MemtoReg[1] ? Lo : read_data) : 
 //									(MemtoReg[1] ? Hi : alu1_result);
  assign reg_wdata = (MemtoReg[0]) ? read_data :  alu1_result;
  assign jump_ind = {extend_op,Instruction[15:0]}<<2;
  assign Address = {alu1_result[31:2],2'd0};
  assign PC1 = PC + 32'd4;
  assign PC2 = PC1 + jump_ind;
  assign	PC_j = {PC[31:28],Instruction[25:0],2'b00};
  assign PC = PC3;
  //assign	mul_result = (ALUop == 6'b011000 && Instruction[31:26] == 6'd0) ? ALU_A * ALU_B : {1'b0,ALU_A} * {1'b0,ALU_B};
  
  always @(posedge clk)
  begin
    if(rst)
      PC3 <= 'd0;
    else
      PC3 <= ((~Zero&BNE) || (Zero & BEQ) || ((alu1_result[31] || Zero) & BLEZ) || (REGIMM && (Instruction[20:16] == `BGEZ) && ~reg_rdata1[31]) 
				|| (REGIMM && (Instruction[20:16] == `BLTZ) && reg_rdata1[31])) ? PC2 :
				( J ? PC_j :
				(JR ? reg_rdata1 : PC1));
  end

 /* always @(posedge clk)
  begin
	if(rst)
		Hi <= 'd0;
	else if(ALUop == 6'b011010 && Instruction[31:26] == 6'd0)
		Hi <= reg_rdata1 % reg_rdata2;
	else if(Mult_en == 1'b1)
		Hi <= mul_result[63:32];
	else
		Hi <= Hi;
  end
  
  always @(posedge clk)
  begin
	if(rst)
		Lo <= 'd0;
	else if(ALUop == 6'b011010 && Instruction[31:26] == 6'd0)
		Lo <= reg_rdata1 / reg_rdata2;
	else if(Mult_en == 1'b1)
		Lo <= mul_result[31:0];
	else
		Lo <= Lo;
  end*/


	control_unit cu(
		.op(Instruction[31:26]),
		.func(Instruction[5:0]),
		.RegDst(RegDst),
		.BNE(BNE),
		.BEQ(BEQ),
		.BLEZ(BLEZ),
		.J(J),
		.JR(JR),
		.MemRead(MemRead),
		.MemtoReg(MemtoReg),
		.ALUop(ALUop),
		.MemWrite(MemWrite),
		.ALUSrc_B(ALUSrc_B),
		.ALUSrc_A(ALUSrc_A),
		.RegWrite(RegWrite),
		.Zero(Zero),
		//.Mult_en(Mult_en),
		.LH(LH),
		.LB(LB),
		.is_signed(is_signed),
		.SB(SB),
		.SH(SH),
		.SWL(SWL),
		.SWR(SWR),
		.LWL(LWL),
		.LWR(LWR),
		.REGIMM(REGIMM)
	);

	reg_file rf_i(
		.clk(clk),
		.rst(rst),
		.waddr(reg_waddr),
		.raddr1(Instruction[25:21]),
		.raddr2(Instruction[20:16]),
		.wen(RegWrite),
		.wdata(reg_wdata),
		.rdata1(reg_rdata1),
		.rdata2(reg_rdata2)
	);

	alu alu_i(
		.A(ALU_A),
		.B(ALU_B),
		.ALUop(ALUop),
		.sa(Instruction[10:6]),
		.Overflow(),
		.CarryOut(),
		.Zero(Zero),
		.Result(alu1_result)
	);
	
	mux8 #(36) mux_swlr (
		.mux8_out	({Write_strb_swlr,Write_data_swlr}	),
		.m0_in		({4'b0001, 24'b0, reg_rdata2[31:24]}),
		.m1_in		({4'b0011, 16'b0, reg_rdata2[31:16]}),
		.m2_in		({4'b0111, 8'b0, reg_rdata2[31:8]}),
		.m3_in		({4'b1111, reg_rdata2[31:0]}),
		.m4_in		({4'b1111, reg_rdata2[31:0]}),
		.m5_in		({4'b1110, reg_rdata2[23:0], 8'b0}),
		.m6_in		({4'b1100, reg_rdata2[15:0], 16'b0}),
		.m7_in		({4'b1000, reg_rdata2[7:0], 24'b0}),
		.sel_in		({SWR, alu1_result[1:0]})
	);

	mux8 #(32) mux_lwlr (
		.mux8_out	(read_data_lwlr	),
		.m0_in		({Read_data[7:0], reg_rdata2[23:0]}),
		.m1_in		({Read_data[15:0], reg_rdata2[15:0]}),
		.m2_in		({Read_data[23:0], reg_rdata2[7:0]}),
		.m3_in		(Read_data),
		.m4_in		(Read_data),
		.m5_in		({reg_rdata2[31:24], Read_data[31:8]}),
		.m6_in		({reg_rdata2[31:16], Read_data[31:16]}),
		.m7_in		({reg_rdata2[31:8], Read_data[31:24]}),
		.sel_in		({LWR, alu1_result[1:0]})
	);


endmodule
