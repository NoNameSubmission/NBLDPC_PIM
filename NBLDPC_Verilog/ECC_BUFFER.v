`include "ADC_BUFFER.v"
`include "LLR_TRANS.v"
module ECC_BUFFER #(
		parameter MACRO = 1,
		parameter PARALLEL = 10,
		parameter INFO_GROUP = 8,
		parameter ADC_BIT = 3,
		parameter LLR_BIT = 3,
		parameter SYMBOL_NUM = 288,
		parameter INFO_NUM = 256,
		parameter FIELD = 3,
		parameter PERIOD = 32,
		parameter COUNTER_BIT = 5
	) (
		ADC_OUT,
		CIM_E,
		CE,
		SYS_RST,
		ADC_CLK,
		ECC_SYMBOL_IN,
		ECC_LLR_IN
	);
	input wire [PARALLEL * ADC_BIT - 1:0] ADC_OUT;
	input wire CE;
	input wire SYS_RST;
	input wire ADC_CLK;
	input wire CIM_E;
	output wire [INFO_NUM * ADC_BIT - 1:0] ECC_SYMBOL_IN;
	output wire [SYMBOL_NUM * FIELD * LLR_BIT - 1:0] ECC_LLR_IN;
	wire [PARALLEL - 1:0][ADC_BIT - 1:0] BUFFER_IN;
	wire [PARALLEL - 1:0][ADC_BIT - 1:0] SA_SUB_BUF;
	wire [PERIOD - 1:0][PARALLEL - 1:0][ADC_BIT - 1:0] BUFFER_OUT;
	wire [PARALLEL - 1:0] SA_OUT_LOC;
	wire [PARALLEL - 1:0][ADC_BIT - 1:0] ADC_OUT_LOC;
	wire [INFO_NUM - 1:0][ADC_BIT - 1:0] ECC_SYMBOL_IN_LOC;
	wire signed [SYMBOL_NUM - 1:0][FIELD - 1:0][LLR_BIT - 1:0] ECC_LLR_IN_LOC;
	generate
		genvar SA2, SA3;
		for (SA2 = 0; SA2 < PARALLEL; SA2 = SA2 + 1) begin
			assign SA_OUT_LOC[SA2] = ADC_OUT[SA2 * ADC_BIT];
			for (SA3 = 0; SA3 < ADC_BIT; SA3 = SA3 + 1) begin
				assign ADC_OUT_LOC[SA2][SA3] = ADC_OUT[SA2 * ADC_BIT + SA3];
			end
		end
	endgenerate
	generate
		genvar i, j, k;
		for (i = 0; i < PARALLEL; i = i + 1) begin
			assign SA_SUB_BUF[i] = {2'b0, SA_OUT_LOC[i]};
		end
	endgenerate
	assign BUFFER_IN = (CIM_E) ? ADC_OUT_LOC:SA_SUB_BUF;
	ADC_BUFFER # (
		.INPUT_BIT(ADC_BIT),
		.MACRO_NUM(MACRO),
		.PARALLEL(PARALLEL),
		.PERIOD(PERIOD),
		.COUNTER_BIT(COUNTER_BIT)
	) INPUT_BUFFER (
		.CLK(ADC_CLK),
		.RST(SYS_RST),
		.INPUT(BUFFER_IN),
		.SYMBOL_BUFFER(BUFFER_OUT),
		.CE(CE)
	);
	generate
		genvar e, g;
		for (e = 0; e < PERIOD; e = e + 1) begin
			for (g = 0; g < INFO_GROUP; g = g + 1) begin
				MESSAGE_TRANS #(
					.INPUT_BIT(ADC_BIT),
					.LLR_BIT(LLR_BIT),
					.FIELD(FIELD)
				) MESSAGE_BITS (
					.INPUT(BUFFER_OUT[e][g]),
					.CIM_E(CIM_E),
					.OUTPUT_LLR(ECC_LLR_IN_LOC[e * INFO_GROUP + g])
				);
				assign ECC_SYMBOL_IN_LOC[e * INFO_GROUP + g] = BUFFER_OUT[e][g];
			end
			CHECK_TRANS #(
				.INPUT_BIT(ADC_BIT),
				.LLR_BIT(LLR_BIT),
				.FIELD(FIELD)
			) CHECK_BITS (
				.INPUT_A(BUFFER_OUT[e][INFO_GROUP]),
				.INPUT_B(BUFFER_OUT[e][INFO_GROUP + 1]),
				.CIM_E(CIM_E),
				.OUTPUT_LLR(ECC_LLR_IN_LOC[INFO_NUM + e])
			);
		end
	endgenerate
	generate
		genvar OP1, OP2, OP3;
		for (OP1 = 0; OP1 < INFO_NUM; OP1 = OP1 + 1) begin
			for (OP2 = 0; OP2 < ADC_BIT; OP2 = OP2 + 1) begin
				assign ECC_SYMBOL_IN[OP1 * ADC_BIT + OP2] = ECC_SYMBOL_IN_LOC[OP1][OP2];
			end
		end
		for (OP1 = 0; OP1 < SYMBOL_NUM; OP1 = OP1 + 1) begin
			for (OP2 = 0; OP2 < FIELD; OP2 = OP2 + 1) begin
				for (OP3 = 0; OP3 < LLR_BIT; OP3 = OP3 + 1) begin
					assign ECC_LLR_IN[OP1 * FIELD * LLR_BIT + OP2 * LLR_BIT + OP3] = ECC_LLR_IN_LOC[OP1][OP2][OP3];
				end
			end
		end
	endgenerate
endmodule