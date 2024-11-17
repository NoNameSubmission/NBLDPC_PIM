module LLR_REFLECT #(parameter FIELD = 3, parameter LLR_BIT = 3) (INPUT_LLR, INPUT_MATRIX, OUTPUT_LLR);
	input wire signed [FIELD * LLR_BIT - 1:0] INPUT_LLR;
	input wire [1:0] INPUT_MATRIX;
	output wire signed [FIELD * LLR_BIT - 1:0] OUTPUT_LLR;
	assign OUTPUT_LLR[LLR_BIT - 1:0] = INPUT_LLR[LLR_BIT - 1:0];
	generate
		genvar i,j;
		for (i = 1; i < FIELD; i = i + 1) begin
			for (j = 0; j < LLR_BIT; j = j + 1) begin
				if (i == 1) begin
					assign OUTPUT_LLR[i * LLR_BIT + j] = (INPUT_MATRIX[0] & INPUT_LLR[i * LLR_BIT + j]) | (INPUT_MATRIX[1] & INPUT_LLR[(i + 1) * LLR_BIT + j]);
				end
				else begin
					assign OUTPUT_LLR[i * LLR_BIT + j] = (INPUT_MATRIX[0] & INPUT_LLR[i * LLR_BIT + j]) | (INPUT_MATRIX[1] & INPUT_LLR[(i - 1) * LLR_BIT + j]);
				end
			end
		end
	endgenerate
endmodule

module OUT_REFLECT #(parameter FIELD = 3, parameter LLR_BIT = 3) (INPUT_LLR, INPUT_MATRIX, OUTPUT_LLR);
	input wire [FIELD * LLR_BIT - 1:0] INPUT_LLR;
	input wire [1:0] INPUT_MATRIX;
	output wire [FIELD * LLR_BIT - 1:0] OUTPUT_LLR;
	assign OUTPUT_LLR[LLR_BIT - 1:0] = INPUT_LLR[LLR_BIT - 1:0];
	generate
		genvar i,j;
		for (i = 1; i < FIELD; i = i + 1) begin
			for (j = 0; j < LLR_BIT; j = j + 1) begin
				if (i == 1) begin
					assign OUTPUT_LLR[i * LLR_BIT + j] = (INPUT_MATRIX[1] & INPUT_LLR[i * LLR_BIT + j]) | (INPUT_MATRIX[0] & INPUT_LLR[(i + 1) * LLR_BIT + j]);
				end
				else begin
					assign OUTPUT_LLR[i * LLR_BIT + j] = (INPUT_MATRIX[1] & INPUT_LLR[i * LLR_BIT + j]) | (INPUT_MATRIX[0] & INPUT_LLR[(i - 1) * LLR_BIT + j]);
				end
			end
		end
	endgenerate
endmodule