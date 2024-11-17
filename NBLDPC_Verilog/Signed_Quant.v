module Quant #(parameter INPUT_BIT = 4, parameter OUTPUT_BIT = 3) (INPUT_LLR, OUTPUT_LLR);
	input wire signed [INPUT_BIT - 1:0] INPUT_LLR;
	output wire signed [OUTPUT_BIT - 1:0] OUTPUT_LLR;
	wire FLOW_OUT;
	assign FLOW_OUT = INPUT_LLR[INPUT_BIT - 1] ^ INPUT_LLR[INPUT_BIT - 2];
	assign OUTPUT_LLR[OUTPUT_BIT - 1] = INPUT_LLR[INPUT_BIT - 1];
	generate
		genvar i;
		for (i = 0; i < OUTPUT_BIT - 1; i = i + 1)
		begin:Quant_Process
			assign OUTPUT_LLR[i] = (FLOW_OUT) ? (INPUT_LLR[INPUT_BIT - 2]):(INPUT_LLR[i]);
		end
	endgenerate
endmodule

module OutQuant #(parameter INPUT_BIT = 5, parameter OUTPUT_BIT = 3, parameter GROUP_NUM = 3) (INPUT, OUTPUT);
	input wire [GROUP_NUM * INPUT_BIT - 1:0] INPUT;
	output wire [GROUP_NUM * OUTPUT_BIT - 1:0] OUTPUT;
	wire signed [GROUP_NUM - 1:0][INPUT_BIT - 1:0] INPUT_LOC;
	wire signed [GROUP_NUM - 1:0][OUTPUT_BIT - 1:0] OUTPUT_LOC;
	generate
		genvar i, j;
		for (i = 0; i < GROUP_NUM; i = i + 1) begin
			for (j = 0; j < INPUT_BIT; j = j + 1) begin
				assign INPUT_LOC[i][j] = INPUT[i * INPUT_BIT + j];
			end
			for (j = 0; j < OUTPUT_BIT; j = j + 1) begin
				assign OUTPUT[i * OUTPUT_BIT + j] = OUTPUT_LOC[i][j];
			end
		end
	endgenerate
	wire signed [GROUP_NUM - 1:0][INPUT_BIT:0] NORM_INPUT;
	wire FLOW_OUT_A, FLOW_OUT_B, FLOW_OUT_C;
	assign NORM_INPUT[0] = 0;
	assign NORM_INPUT[1] = $signed(INPUT_LOC[1]) - $signed(INPUT_LOC[0]);
	assign NORM_INPUT[2] = $signed(INPUT_LOC[2]) - $signed(INPUT_LOC[0]);
	assign FLOW_OUT_A = (NORM_INPUT[1][INPUT_BIT] ^ NORM_INPUT[1][INPUT_BIT - 1]) | (NORM_INPUT[2][INPUT_BIT] ^ NORM_INPUT[2][INPUT_BIT - 1]);
	assign FLOW_OUT_B = (NORM_INPUT[1][INPUT_BIT - 1] ^ NORM_INPUT[1][INPUT_BIT - 2]) | (NORM_INPUT[2][INPUT_BIT - 1] ^ NORM_INPUT[2][INPUT_BIT - 2]);
	assign FLOW_OUT_C = (NORM_INPUT[1][INPUT_BIT - 2] ^ NORM_INPUT[1][INPUT_BIT - 3]) | (NORM_INPUT[2][INPUT_BIT - 2] ^ NORM_INPUT[2][INPUT_BIT - 3]);
	assign OUTPUT_LOC[0] = 0;
	assign OUTPUT_LOC[1][OUTPUT_BIT - 1] = NORM_INPUT[1][INPUT_BIT];
	assign OUTPUT_LOC[2][OUTPUT_BIT - 1] = NORM_INPUT[2][INPUT_BIT];
	assign OUTPUT_LOC[1][OUTPUT_BIT - 2:0] = (FLOW_OUT_A) ? (NORM_INPUT[1][INPUT_BIT - 1:INPUT_BIT - OUTPUT_BIT + 1]):((FLOW_OUT_B) ? (NORM_INPUT[1][INPUT_BIT - 2:INPUT_BIT - OUTPUT_BIT]):((FLOW_OUT_C) ? (NORM_INPUT[1][INPUT_BIT - 3:INPUT_BIT - OUTPUT_BIT - 1]):(NORM_INPUT[1][OUTPUT_BIT - 2:0])));
	assign OUTPUT_LOC[2][OUTPUT_BIT - 2:0] = (FLOW_OUT_A) ? (NORM_INPUT[2][INPUT_BIT - 1:INPUT_BIT - OUTPUT_BIT + 1]):((FLOW_OUT_B) ? (NORM_INPUT[2][INPUT_BIT - 2:INPUT_BIT - OUTPUT_BIT]):((FLOW_OUT_C) ? (NORM_INPUT[2][INPUT_BIT - 3:INPUT_BIT - OUTPUT_BIT - 1]):(NORM_INPUT[2][OUTPUT_BIT - 2:0])));
endmodule