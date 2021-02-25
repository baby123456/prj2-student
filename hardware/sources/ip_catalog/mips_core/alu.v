`timescale 10 ns / 1 ns
`include"define.h"
`define DATA_WIDTH 32

module alu(
	input [`DATA_WIDTH - 1:0] A,
	input [`DATA_WIDTH - 1:0] B,
	input [5:0] ALUop,
	input	[4:0]	sa,
	output Overflow,
	output CarryOut,
	output Zero,
	output reg [`DATA_WIDTH - 1:0] Result
);

	// TODO: insert your code

	parameter 
		ALUOP_MUL = 6'b011110;

	wire is_sub = (ALUop == `SUB) | (ALUop == `SLT) | (ALUop == `SLTU) | (ALUop == `SUBU);
	wire [`DATA_WIDTH - 1:0] B_inv = (is_sub ? ~B : B);

	wire [`DATA_WIDTH - 1:0] sum;
	wire add_carry;
	
	wire [31:0] sr1;
    wire [31:0] sr2;

	assign {add_carry, sum} = A + B_inv + is_sub;
	assign CarryOut = add_carry ^ is_sub;

	assign cin_msb = sum[`DATA_WIDTH - 1] ^ A[`DATA_WIDTH - 1] ^ B_inv[`DATA_WIDTH - 1];
	assign Overflow = add_carry ^ cin_msb;

	assign Zero = (ALUop == `MOVZ) || (ALUop == `MOVN) ? ~(|B) : ~(|Result);
	
	assign sr1 = {32{B[31]}} << (32 - sa);
    assign sr2 = {32{B[31]}} << (32 - A[4:0]);
   
	always@(*) begin
		case(ALUop)
			`AND: Result = A & B;
			`OR: Result = A | B;
			`ADD,`ADDU,`ADDIU: Result = sum;
			`SUB: Result = sum;
			`SUBU: Result = sum;
			`SLT: Result = {{(`DATA_WIDTH - 1){1'b0}}, (Overflow ^ sum[`DATA_WIDTH - 1])};
			`SLTU: Result = {{(`DATA_WIDTH - 1){1'b0}},CarryOut};
			`LUI : Result = {B[15:0],16'd0};
			`SLL : Result = B << sa;
			`MOVN,`MOVZ : Result = A;
			//ALUOP_MUL: Result = A * B;
			`XOR: Result = A ^ B;
			`NOR: Result = ~(A | B);
			`SLLV: Result = B << A[4:0];
			`SRA: Result = sr1 | (B >> sa);
			`SRAV: Result = sr2 | (B >> A[4:0]);
			`SRL: Result = B >> sa;
			`SRLV: Result = B >> A[4:0];
			default: Result = {`DATA_WIDTH{1'b0}};
		endcase
	end

endmodule
