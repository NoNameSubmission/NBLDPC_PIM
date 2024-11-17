//`include "Signed_Comparator.v"
module HalfPropagate #(parameter LLRA_BIT = 4, parameter LLRB_BIT = 3) (LLRA, LLRB, OUTPUT_LLR);
	input wire signed [LLRA_BIT - 1:0] LLRA;
	input wire signed [LLRB_BIT - 1:0] LLRB;
	output wire signed [LLRA_BIT:0] OUTPUT_LLR;
	wire signed [LLRA_BIT:0] BUF_LLR;
	wire FLOW_OUT;
	assign OUTPUT_LLR = $signed(LLRA) + $signed(LLRB);
endmodule

module HalfPropagateFromA #(parameter FIELD = 3, parameter LLRA_BIT = 4, parameter LLRB_BIT = 4) (LLRA, LLRB, OUTPUT_LLR);
	input wire signed [LLRA_BIT - 1:0] LLRA;
	input wire signed [FIELD * LLRB_BIT - 1:0] LLRB;
	output wire signed [FIELD * (LLRA_BIT + 1) - 1:0] OUTPUT_LLR;
	generate
		genvar i;
		for (i = 0; i < FIELD; i = i + 1)
		begin:Adder
			HalfPropagate #(.LLRA_BIT(LLRA_BIT), .LLRB_BIT(LLRB_BIT)) Adder(
				.LLRA(LLRA),
				.LLRB(LLRB[LLRB_BIT * (i + 1) - 1: LLRB_BIT * i]),
				.OUTPUT_LLR(OUTPUT_LLR[(LLRA_BIT + 1) * (i + 1) - 1:(LLRA_BIT + 1) * i])
			);
		end
	endgenerate
endmodule

module Propagate #(parameter FIELD = 3, parameter LLRA_BIT = 4, parameter LLRB_BIT = 3) (LLRA, LLRB, OUTPUT_LLR);
	input wire [FIELD * LLRA_BIT - 1:0] LLRA;
	input wire [FIELD * LLRB_BIT - 1:0] LLRB;
	output wire [FIELD * LLRA_BIT - 1:0] OUTPUT_LLR;
	wire signed [FIELD - 1:0][LLRA_BIT:0] MID_OUTPUT_LLR;
	wire signed [FIELD - 1:0][FIELD - 1:0][LLRA_BIT:0] MID_LLR;
	wire signed [FIELD - 1:0][LLRA_BIT - 1:0] LLRA_LOC;
	wire signed [FIELD - 1:0][LLRB_BIT - 1:0] LLRB_LOC;
	wire signed [FIELD - 1:0][LLRA_BIT - 1:0] OUTPUT_LLR_LOC;
	wire signed [FIELD - 1:0][LLRA_BIT:0] OUTPUT_LLR_MID;
	generate
		genvar IN1, IN2;
		for (IN1 = 0; IN1 < FIELD; IN1 = IN1 + 1) begin
			for (IN2 = 0; IN2 < LLRA_BIT; IN2 = IN2 + 1) begin
				assign LLRA_LOC[IN1][IN2] = LLRA[IN1 * LLRA_BIT + IN2];
				assign OUTPUT_LLR[IN1 * LLRA_BIT + IN2] = OUTPUT_LLR_LOC[IN1][IN2];
			end
			for (IN2 = 0; IN2 < LLRB_BIT; IN2 = IN2 + 1) begin
				assign LLRB_LOC[IN1][IN2] = LLRB[IN1 * LLRB_BIT + IN2];
			end
		end
	endgenerate
	generate
		genvar i;
		for (i = 0; i < FIELD; i = i + 1)
		begin:Adder
			HalfPropagateFromA #(.FIELD(FIELD), .LLRA_BIT(LLRA_BIT), .LLRB_BIT(LLRB_BIT)) Adder(
				.LLRA(LLRA_LOC[i]),
				.LLRB(LLRB_LOC),
				.OUTPUT_LLR(MID_LLR[i])
			);
		end
	endgenerate
	generate
		genvar j;
		for (j = 0; j < FIELD; j = j + 1)
		begin:Compare
			if (j == 0) begin
				Maximize #(.LLR_BIT(LLRA_BIT + 1)) Compare(
					.LLRA(MID_LLR[0][0]),
					.LLRB(MID_LLR[1][2]),
					.LLRC(MID_LLR[2][1]),
					.MAX(MID_OUTPUT_LLR[j])
				);
			end
			else if (j == 1) begin
				Maximize #(.LLR_BIT(LLRA_BIT + 1)) Compare(
					.LLRA(MID_LLR[0][1]),
					.LLRB(MID_LLR[1][0]),
					.LLRC(MID_LLR[2][2]),
					.MAX(MID_OUTPUT_LLR[j])
				);
			end
			else begin
				Maximize #(.LLR_BIT(LLRA_BIT + 1)) Compare(
					.LLRA(MID_LLR[0][2]),
					.LLRB(MID_LLR[1][1]),
					.LLRC(MID_LLR[2][0]),
					.MAX(MID_OUTPUT_LLR[j])
				);
			end
		end
	endgenerate
	generate
		genvar k;
		for (k = 0; k < FIELD; k = k + 1)
		begin:TRUE_OUT
			assign OUTPUT_LLR_LOC[k] = $signed(MID_OUTPUT_LLR[k]) - $signed(MID_OUTPUT_LLR[0]);
		end
	endgenerate
endmodule



















