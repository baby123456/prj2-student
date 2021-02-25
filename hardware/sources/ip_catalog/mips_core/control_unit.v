`timescale 10ns / 1ns
`include"define.h"

module control_unit(
	input [5:0] op,
	input [5:0] func,
	output [1:0] RegDst,
	output BNE,
	output	BEQ,
	output	BLEZ,
	output	J,
	output	JR,
	output MemRead,
	output [1:0] MemtoReg,
	output MemWrite,
	output ALUSrc_A,
	output [1:0] ALUSrc_B,
	output  RegWrite,
	output [5:0] ALUop,
	output	Mult_en,
	
	output	LH,
	output	LB,
	output	LWL,
	output	LWR,
	output	is_signed,
	
	output	SB,
	output	SH,
	output	SWL,
	output	SWR,
	
	output	REGIMM,
	
	input	Zero
);
	wire	MUL;
	
	assign	REGIMM = (op == `REGIMM);
	assign MUL = (op == `SPEC2) && (func == `MUL);
	assign  JR = ((func == `JR) || (func == `JALR)) && (op == `RTYPE) ;
	assign	J = (op == `J) || (op == `JAL);
	assign	BLEZ = (op == `BLEZ);
	assign	LH = (op == `LH) || (op == `LHU);
	assign	LB = (op == `LB) || (op == `LBU);
	assign	LWL = (op == `LWL);
	assign	LWR = (op == `LWR);
	assign	is_signed = (op == `LHU) || (op == `LBU);
	assign	SB = (op == `SB);
	assign	SH = (op == `SH);
	assign	SWL = (op == `SWL);
	assign	SWR = (op == `SWR);
	assign RegDst[0] = ~((op == `ADDIU) || (op == `LW) || (op == `JAL) || (op == `LUI) || (op == `SLTI) || (op == `SLTIU) || (op == `ANDI) || (op == `XORI) 
						|| (op == `ORI) || (LH == 1'b1) || (LB == 1'b1) || (op == `LWL) || (op == `LWR));
	assign	RegDst[1] = (op == `JAL);
	assign BNE = (op == `BNE);
	assign	BEQ = (op == `BEQ);
	assign MemRead = (op == `LW) || (LH == 1'b1) || (LB == 1'b1) || (op == `LWL) || (op == `LWR);
	assign MemtoReg = (op == `LW) || (LH == 1'b1) || (LB == 1'b1) || (op == `LWL) || (op == `LWR) ? 2'd1 :
						(((op == `RTYPE) && (func == `MFHI)) ? 2'd2 : 
						(((op == `RTYPE) && (func == `MFLO)) ? 2'd3 : 2'd0));
	assign MemWrite = (op == `SW) || (op == `SB) || (op == `SH) || (op == `SWL) || (op == `SWR);
	assign ALUSrc_B = (((op == `BNE) || ((op == `RTYPE) && (func != `JALR))|| (op == `BEQ) || (op == `BLEZ) || (MUL == 1'b1))? 2'b00 : 
						((op == `JAL) || ((op == `RTYPE) && (func == `JALR)) ? 2'b10 : 
						((op == `ANDI) || (op == `XORI) || (op == `ORI) ? 2'b11 : 2'b01)));
	assign	ALUSrc_A = (op == `JAL) || ((op == `RTYPE) && (func == `JALR)) ? 1'b1 : 1'b0;
	assign RegWrite = (op == `ADDIU) || (op == `LW) || ((op == `RTYPE) && ((func == `MOVN) && (~Zero)|| (func == `MOVZ) && (Zero) || (func != `MOVZ) && (func != `MOVN) && (func != `JR))) || 
						(op == `JAL) || (op == `LUI) || (op == `SLTI) || (op == `SLTIU) || (op == `ANDI) || (MUL == 1'b1) || (op == `XORI) || (op == `ORI) || (LH == 1'b1) 
						|| (LB == 1'b1) || (op == `LWL) || (op == `LWR);
	assign ALUop = ((op == `BNE) || (op == `BEQ) || (op == `BLEZ))? `SUB : 
					((op == `LUI) ? `LUI : 
					((op == `RTYPE) || (op == `SPEC2) ? (op | func) : 
					(((op == `SLTI) )? `SLT :
					((op == `SLTIU) ? `SLTU : 
					((op == `ANDI) ? `AND : 
					((op == `XORI) ? `XOR : 
					((op == `ORI) ? `OR : `ADD)))))));
	assign Mult_en = (op == `RTYPE) && ((func == `MULTU) || (func == `MULT));
	
endmodule
