//`include "LLR_REFLECT.v"
//`include "Signed_Propagate.v"
//`include "Signed_Quant.v"
module CheckNode #(
	parameter CHECK_DEGREE = 18,
	parameter SYMBOL_BIT = 2,
	parameter LLR_BIT = 3,
 	parameter PROCESS_BIT = 4,
 	parameter FIELD = 3
 	) (INPUT_MATRIX, BUF_LLR, OUTPUT_LLR, CLK, RST, CLK_STATE);
	input wire CLK;
	input wire RST;
	input wire CLK_STATE;
	input wire [CHECK_DEGREE * SYMBOL_BIT - 1:0] INPUT_MATRIX;
	input wire [CHECK_DEGREE * FIELD * LLR_BIT - 1:0] BUF_LLR;
	output wire [CHECK_DEGREE * FIELD * LLR_BIT - 1:0] OUTPUT_LLR;
	reg STATE;
	reg [CHECK_DEGREE - 1:0][SYMBOL_BIT - 1:0] MATRIX_BUF;
	wire signed [CHECK_DEGREE - 1:0][FIELD - 1:0][PROCESS_BIT - 1:0] OUTPUT_BUF;
	wire signed [CHECK_DEGREE - 1:0][FIELD - 1:0][LLR_BIT - 1:0] BUF_QUANT_SORT;
	reg signed [CHECK_DEGREE - 1:0][FIELD - 1:0][LLR_BIT - 1:0] INPUT_LLR;
	wire signed [CHECK_DEGREE - 1:0][FIELD - 1:0][LLR_BIT - 1:0] INIT_LLR;
	wire signed [FIELD - 1:0][PROCESS_BIT - 1:0] FORWARD_LLR;
	wire signed [FIELD - 1:0][PROCESS_BIT - 1:0] BACKWARD_LLR;
	wire signed [FIELD - 1:0][PROCESS_BIT - 1:0] FORWARD_PROP_IN;
	wire signed [FIELD - 1:0][PROCESS_BIT - 1:0] BACKWARD_PROP_IN;
	wire signed [CHECK_DEGREE / 2 - 2:0][FIELD - 1:0][LLR_BIT - 1:0] FORWARD_INIT_IN;
	wire signed [CHECK_DEGREE / 2 - 2:0][FIELD - 1:0][LLR_BIT - 1:0] BACKWARD_INIT_IN;
	wire signed [CHECK_DEGREE / 2 - 2:0][FIELD - 1:0][PROCESS_BIT - 1:0] FORWARD_PROP_OUT;
	wire signed [CHECK_DEGREE / 2 - 2:0][FIELD - 1:0][PROCESS_BIT - 1:0] BACKWARD_PROP_OUT;
	reg signed [CHECK_DEGREE / 2 - 2:0][FIELD - 1:0][PROCESS_BIT - 1:0] FORWARD_LLR_FIRST;
	reg signed [CHECK_DEGREE / 2 - 2:0][FIELD - 1:0][PROCESS_BIT - 1:0] BACKWARD_LLR_FIRST;
	wire [CHECK_DEGREE - 1:0][SYMBOL_BIT - 1:0] INPUT_MATRIX_LOC;
	wire signed [CHECK_DEGREE - 1:0][FIELD - 1:0][LLR_BIT - 1:0] BUF_LLR_LOC;
	wire signed [CHECK_DEGREE - 1:0][FIELD - 1:0][LLR_BIT - 1:0] OUTPUT_LLR_LOC;
	generate
		genvar IN1, IN2, IN3;
		for (IN1 = 0; IN1 < CHECK_DEGREE; IN1 = IN1 + 1) begin
			for (IN2 = 0; IN2 < SYMBOL_BIT; IN2 = IN2 + 1) begin
				assign INPUT_MATRIX_LOC[IN1][IN2] = INPUT_MATRIX[IN1 * SYMBOL_BIT + IN2];
			end
			for (IN2 = 0; IN2 < FIELD; IN2 = IN2 + 1) begin
				for (IN3 = 0; IN3 < LLR_BIT; IN3 = IN3 + 1) begin
					assign BUF_LLR_LOC[IN1][IN2][IN3] = BUF_LLR[IN1 * FIELD * LLR_BIT + IN2 * LLR_BIT + IN3];
					assign OUTPUT_LLR[IN1 * FIELD * LLR_BIT + IN2 * LLR_BIT + IN3] = OUTPUT_LLR_LOC[IN1][IN2][IN3];
				end
			end
		end
	endgenerate
	// Rearrange Input LLR Begin
	generate
		genvar j;
		for (j = 0; j < CHECK_DEGREE; j = j + 1)
		begin:REFLECT
			LLR_REFLECT #(.FIELD(FIELD), .LLR_BIT(LLR_BIT)) REFLECT(
				.INPUT_LLR(INPUT_LLR[j]),
			 	.INPUT_MATRIX(MATRIX_BUF[j]),
			 	.OUTPUT_LLR(INIT_LLR[j])
			);
		end
	endgenerate
	// Rearrange Input LLR End
	generate
		genvar prop_F, prop_B;
		for (prop_F = 0; prop_F < FIELD; prop_F = prop_F + 1)
		begin:PropIn
			assign FORWARD_LLR[prop_F] = {INIT_LLR[0][prop_F][LLR_BIT - 1], INIT_LLR[0][prop_F][LLR_BIT - 1:0]};
			assign BACKWARD_LLR[prop_F] = {INIT_LLR[CHECK_DEGREE - 1][prop_F][LLR_BIT - 1], INIT_LLR[CHECK_DEGREE - 1][prop_F][LLR_BIT - 1:0]};
			for (prop_B = 0; prop_B < PROCESS_BIT; prop_B = prop_B + 1) begin
				assign FORWARD_PROP_IN[prop_F][prop_B] = (STATE & FORWARD_LLR[prop_F][prop_B]) | ((~STATE) & FORWARD_LLR_FIRST[CHECK_DEGREE / 2 - 2][prop_F][prop_B]);
				assign BACKWARD_PROP_IN[prop_F][prop_B] = (STATE & BACKWARD_LLR[prop_F][prop_B]) | ((~STATE) & BACKWARD_LLR_FIRST[0][prop_F][prop_B]);
			end
		end
	endgenerate
	generate
		genvar init_C, init_F, init_B;
		for (init_C = 0; init_C < CHECK_DEGREE / 2 - 1; init_C = init_C + 1)
		begin:InitSpread
			for (init_F = 0; init_F < FIELD; init_F = init_F + 1) begin
				for (init_B = 0; init_B < LLR_BIT; init_B = init_B + 1) begin
					assign FORWARD_INIT_IN[init_C][init_F][init_B] = (STATE & INIT_LLR[init_C + 1][init_F][init_B]) | ((~STATE) & INIT_LLR[init_C + CHECK_DEGREE / 2][init_F][init_B]);
					assign BACKWARD_INIT_IN[init_C][init_F][init_B] = (STATE & INIT_LLR[init_C + CHECK_DEGREE / 2][init_F][init_B]) | ((~STATE) & INIT_LLR[init_C + 1][init_F][init_B]);
				end
			end
		end
	endgenerate
	// Forward Propagation Module Connection
	generate
		genvar k;
		for (k = 0; k < CHECK_DEGREE / 2 - 1; k = k + 1)
		begin:PropagateUnitForward
			if  (k == 0) begin
				Propagate PropagateUnitForward(
					.LLRA(FORWARD_PROP_IN),
				 	.LLRB(FORWARD_INIT_IN[k]),
				 	.OUTPUT_LLR(FORWARD_PROP_OUT[k])
				);
			end
			else begin
				Propagate PropagateUnitForward(
					.LLRA(FORWARD_PROP_OUT[k - 1]),
					.LLRB(FORWARD_INIT_IN[k]),
					.OUTPUT_LLR(FORWARD_PROP_OUT[k])
				);
			end
		end
	endgenerate
	// Forward Propagation Module Connection End
	// Backward Propagation Module Connection
	generate
		genvar i;
		for (i = CHECK_DEGREE / 2 - 2; i >= 0; i = i - 1)
		begin:PropagateUnitBackward
			if (i == CHECK_DEGREE / 2 - 2) begin
				Propagate PropagateUnitBackward (
					.LLRA(BACKWARD_PROP_IN),
					.LLRB(BACKWARD_INIT_IN[i]),
					.OUTPUT_LLR(BACKWARD_PROP_OUT[i])
				);
			end
			else begin
				Propagate PropagateUnitBackward(
					.LLRA(BACKWARD_PROP_OUT[i + 1]), 
				 	.LLRB(BACKWARD_INIT_IN[i]),
				 	.OUTPUT_LLR(BACKWARD_PROP_OUT[i])
				);
			end
		end
	endgenerate
	// Backward Propagation Module Connection End
	// Output Generate Begin
	generate
		genvar m;
		for (m = 0; m < CHECK_DEGREE; m = m + 1)
		begin:PropagateOutput
			if (m == 0) begin
				assign OUTPUT_BUF[m] = BACKWARD_PROP_OUT[m];
			end
			else if (m == 1) begin
				Propagate #(.FIELD(FIELD), .LLRA_BIT(PROCESS_BIT), .LLRB_BIT(PROCESS_BIT)) PropagateOutput(
					.LLRA(FORWARD_LLR),
				 	.LLRB(BACKWARD_PROP_OUT[m]),
				 	.OUTPUT_LLR(OUTPUT_BUF[m])
				);
			end
			else if (m < CHECK_DEGREE / 2 - 1) begin
				Propagate #(.FIELD(FIELD), .LLRA_BIT(PROCESS_BIT), .LLRB_BIT(PROCESS_BIT)) PropagateOutput(
					.LLRA(FORWARD_LLR_FIRST[m - 2]),
				 	.LLRB(BACKWARD_PROP_OUT[m]),
				 	.OUTPUT_LLR(OUTPUT_BUF[m])
				);
			end
			else if (m < CHECK_DEGREE / 2 + 1) begin
				Propagate #(.FIELD(FIELD), .LLRA_BIT(PROCESS_BIT), .LLRB_BIT(PROCESS_BIT)) PropagateOutput(
					.LLRA(FORWARD_LLR_FIRST[m - 2]),
				 	.LLRB(BACKWARD_LLR_FIRST[m - CHECK_DEGREE / 2 + 1]),
				 	.OUTPUT_LLR(OUTPUT_BUF[m])
				);
			end
			else if (m < CHECK_DEGREE - 2) begin
				Propagate #(.FIELD(FIELD), .LLRA_BIT(PROCESS_BIT), .LLRB_BIT(PROCESS_BIT)) PropagateOutput(
					.LLRA(FORWARD_PROP_OUT[m - CHECK_DEGREE / 2 - 1]),
				 	.LLRB(BACKWARD_LLR_FIRST[m - CHECK_DEGREE / 2 + 1]),
				 	.OUTPUT_LLR(OUTPUT_BUF[m])
				);
			end
			else if (m == CHECK_DEGREE - 2) begin
				Propagate #(.FIELD(FIELD), .LLRA_BIT(PROCESS_BIT), .LLRB_BIT(PROCESS_BIT)) PropagateOutput(
					.LLRA(FORWARD_PROP_OUT[m - CHECK_DEGREE / 2 - 1]),
				 	.LLRB(BACKWARD_LLR),
				 	.OUTPUT_LLR(OUTPUT_BUF[m])
				);
			end
			else if (m == CHECK_DEGREE - 1) begin
				assign OUTPUT_BUF[m] = FORWARD_PROP_OUT[m - CHECK_DEGREE / 2 - 1];
			end
		end
	endgenerate
	// Output Generate End
	// Computing True Output Begin
	generate
		genvar c;
		for (c = 0; c < CHECK_DEGREE; c = c + 1)
		begin:FIND_INV
			Quant #(.INPUT_BIT(PROCESS_BIT), .OUTPUT_BIT(LLR_BIT)) FIND_INV_0 (
				.INPUT_LLR(OUTPUT_BUF[c][0]),
				.OUTPUT_LLR(BUF_QUANT_SORT[c][0])
			);
			Quant #(.INPUT_BIT(PROCESS_BIT), .OUTPUT_BIT(LLR_BIT)) FIND_INV_1 (
				.INPUT_LLR(OUTPUT_BUF[c][1]),
				.OUTPUT_LLR(BUF_QUANT_SORT[c][2])
			);
			Quant #(.INPUT_BIT(PROCESS_BIT), .OUTPUT_BIT(LLR_BIT)) FIND_INV_2 (
				.INPUT_LLR(OUTPUT_BUF[c][2]),
				.OUTPUT_LLR(BUF_QUANT_SORT[c][1])
			);
		end
	endgenerate
	// Computing True Output End
	// Output Rearrange Begin
	generate
		genvar b;
		for (b = 0; b < CHECK_DEGREE; b = b + 1)
		begin:SORT
			LLR_REFLECT #(.FIELD(FIELD), .LLR_BIT(LLR_BIT)) SORT (.INPUT_LLR(BUF_QUANT_SORT[b]), .INPUT_MATRIX(MATRIX_BUF[b]), .OUTPUT_LLR(OUTPUT_LLR_LOC[b]));
		end
	endgenerate
	// Output Rearrange End
	// Input Assignment Begin
	always @(posedge CLK) begin
		if (RST) begin
			INPUT_LLR <= 0;
			MATRIX_BUF <= 0;
			FORWARD_LLR_FIRST <= 0;
			BACKWARD_LLR_FIRST <= 0;
			STATE <= 1'b0;
		end
		else if (CLK_STATE == 0) begin
			if (STATE == 1'b0) begin
				INPUT_LLR <= BUF_LLR_LOC;
				MATRIX_BUF <= INPUT_MATRIX_LOC;
				STATE <= 1'b1;
			end
			else if (STATE == 1'b1) begin
				FORWARD_LLR_FIRST <= FORWARD_PROP_OUT;
				BACKWARD_LLR_FIRST <= BACKWARD_PROP_OUT;
				STATE <= 1'b0;
			end
		end
	end
	// Input Assignment End
endmodule