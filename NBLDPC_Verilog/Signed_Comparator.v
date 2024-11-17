module Maximize #(parameter LLR_BIT = 6) (LLRA, LLRB, LLRC, MAX);
	input wire signed [LLR_BIT - 1:0] LLRA;
	input wire signed [LLR_BIT - 1:0] LLRB;
	input wire signed [LLR_BIT - 1:0] LLRC;
	output wire signed [LLR_BIT - 1:0] MAX;
	assign MAX = ((LLRA > LLRB) & (LLRA > LLRC)) ? LLRA:((LLRB > LLRC) ? LLRB:LLRC);
endmodule

module Minimum #(parameter LLR_BIT = 6) (LLRA, LLRB, LLRC, MIN);
	input wire signed [LLR_BIT - 1:0] LLRA;
	input wire signed [LLR_BIT - 1:0] LLRB;
	input wire signed [LLR_BIT - 1:0] LLRC;
	output wire signed [LLR_BIT - 1:0] MIN;
	assign MIN = ((LLRA < LLRB) & (LLRA < LLRC)) ? LLRA:((LLRB < LLRC) ? LLRB:LLRC);
endmodule

module Comparator #(parameter LLR_BIT = 6) (LLRA, LLRB, LLRC, MAX, MIN);
	input wire signed [LLR_BIT - 1:0] LLRA;
	input wire signed [LLR_BIT - 1:0] LLRB;
	input wire signed [LLR_BIT - 1:0] LLRC;
	output wire signed [LLR_BIT - 1:0] MAX;
	output wire signed [LLR_BIT - 1:0] MIN;
	assign MAX = ((LLRA > LLRB) & (LLRA > LLRC)) ? LLRA:((LLRB > LLRC) ? LLRB:LLRC);
	assign MIN = ((LLRA < LLRB) & (LLRA < LLRC)) ? LLRA:((LLRB < LLRC) ? LLRB:LLRC);
endmodule