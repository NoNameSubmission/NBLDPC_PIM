// `include "Signed_Quant.v"
module VariableNode #(parameter INPUT_BIT = 3, parameter OUTPUT_BIT = 3, parameter VARIABLE_DEGREE = 2, parameter FIELD = 3)
(INPUT_LLR, PRIOR_LLR, OUTPUT_SYMBOL, CLK, RST, BUF_LLR_OUT);
	input wire [VARIABLE_DEGREE * FIELD * INPUT_BIT - 1:0] INPUT_LLR;
	input wire [FIELD * INPUT_BIT - 1:0] PRIOR_LLR;
	input wire CLK;
	input wire RST;
	output wire [1:0] OUTPUT_SYMBOL;
	output wire [FIELD * OUTPUT_BIT - 1:0] BUF_LLR_OUT;
	wire signed [FIELD - 1:0][INPUT_BIT:0] MID_OUT;
	wire signed [FIELD - 1:0][INPUT_BIT + 1:0] BUF_OUT;
	wire signed [VARIABLE_DEGREE - 1:0][FIELD - 1:0][INPUT_BIT:0] INPUT_LLR_LOC;
	wire signed [FIELD - 1:0][INPUT_BIT - 1:0] PRIOR_LLR_LOC;
	wire signed [FIELD - 1:0][INPUT_BIT:0] EXPAND_PRIOR;
	wire signed [FIELD - 1:0][OUTPUT_BIT - 1:0] BUF_LLR_OUT_LOC;
	generate
		genvar IN1, IN2, IN3;
		for (IN1 = 0; IN1 < VARIABLE_DEGREE; IN1 = IN1 + 1) begin
			for (IN2 = 0; IN2 < FIELD; IN2 = IN2 + 1) begin
				for (IN3 = 0; IN3 < INPUT_BIT; IN3 = IN3 + 1) begin
					assign INPUT_LLR_LOC[IN1][IN2][IN3] = INPUT_LLR[IN1 * FIELD * INPUT_BIT + IN2 * INPUT_BIT + IN3];
				end
				assign INPUT_LLR_LOC[IN1][IN2][INPUT_BIT] = INPUT_LLR[IN1 * FIELD * INPUT_BIT + IN2 * INPUT_BIT + INPUT_BIT - 1];
			end
		end
		for (IN1 = 0; IN1 < FIELD; IN1 = IN1 + 1) begin
			for (IN2 = 0; IN2 < INPUT_BIT; IN2 = IN2 + 1) begin
				assign PRIOR_LLR_LOC[IN1][IN2] = PRIOR_LLR[IN1 * INPUT_BIT + IN2];
			end
			for (IN2 = 0; IN2 < OUTPUT_BIT; IN2 = IN2 + 1) begin
				assign BUF_LLR_OUT[IN1 * OUTPUT_BIT + IN2] = BUF_LLR_OUT_LOC[IN1][IN2];
			end
		end
	endgenerate
	generate
		genvar i;
		for (i = 0; i < FIELD; i = i + 1)
		begin:AddLLR
			assign MID_OUT[i] = $signed(INPUT_LLR_LOC[0][i]) + $signed(INPUT_LLR_LOC[1][i]);
		end
	endgenerate
	generate
		genvar k;
		for (k = 0; k < FIELD; k = k + 1)
		begin:AddPRIOR
			assign BUF_OUT[k] = $signed(PRIOR_LLR_LOC[k]) + $signed(MID_OUT[k]);
		end
	endgenerate
	OutQuant OUTQUANT (.INPUT(BUF_OUT), .OUTPUT(BUF_LLR_OUT_LOC));
	assign OUTPUT_SYMBOL[0] = ($signed(BUF_LLR_OUT_LOC[1]) > $signed(BUF_LLR_OUT_LOC[0])) && ($signed(BUF_LLR_OUT_LOC[1]) >= $signed(BUF_LLR_OUT_LOC[2]))? 1'b1:1'b0;
	assign OUTPUT_SYMBOL[1] = ($signed(BUF_LLR_OUT_LOC[2]) > $signed(BUF_LLR_OUT_LOC[0])) && ($signed(BUF_LLR_OUT_LOC[2]) > $signed(BUF_LLR_OUT_LOC[1]))? 1'b1:1'b0;
endmodule