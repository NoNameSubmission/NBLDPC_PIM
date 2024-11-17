// `include "Signed_CheckNode_onlypos.v"
// `include "Signed_Variable.v"
// `include "LLR_TRANS.v"
// `include "LLR_REFLECT.v"
// `include "Signed_Quant.v"
// `include "Signed_Propagate.v"
// `include "Signed_Comparator.v"
module ECC_TOP #(
		parameter SYMBOL_BIT = 3,
		parameter CHECK_BIT = 2,
		parameter LLR_BIT = 3,
		parameter SYMBOL_NUM = 288,
		parameter INFO_NUM = 256,
		parameter CHECK_NUM = 32,
		parameter ITER_BIT = 2,
		parameter CHECK_DEGREE = 18,
		parameter VARIABLE_DEGREE = 2,
		parameter FIELD = 3
	)(
		CLK,
		RST,
		BYPASS,
		ENABLE,
		INPUT_LLR,
		INPUT_SYMBOL,
		MIDOUT_DEBUG,
		OUTPUT_SYMBOL,
		READY
	);
	input wire CLK;
	input wire RST;
	input wire ENABLE;
	input wire BYPASS;
	input wire [SYMBOL_NUM * FIELD * LLR_BIT - 1:0] INPUT_LLR;
	input wire [INFO_NUM * SYMBOL_BIT - 1:0] INPUT_SYMBOL;
	output wire [INFO_NUM * SYMBOL_BIT - 1:0] OUTPUT_SYMBOL;
	//output wire [CHECK_DEGREE * FIELD * LLR_BIT - 1:0] LLR_CHECK_DEBUG;
	//output wire [SYMBOL_NUM * VARIABLE_DEGREE * FIELD * LLR_BIT - 1:0] LLR_VARI_DEBUG;
	//output wire [SYMBOL_NUM * FIELD * LLR_BIT - 1:0] LLR_PRIOR_DEBUG;
	output wire [INFO_NUM * SYMBOL_BIT - 1:0] MIDOUT_DEBUG;
	output reg READY;
	reg [ITER_BIT + 7 - 1:0] FSM;
	wire [4:0] NODE_STATE;
	wire STATE;
	wire [SYMBOL_NUM - 1:0][FIELD - 1:0][LLR_BIT - 1:0] INPUT_LLR_LOC;
	reg [SYMBOL_NUM - 1:0][FIELD - 1:0][LLR_BIT - 1:0] PRIOR_LLR;
	reg [SYMBOL_NUM - 1:0][FIELD - 1:0][LLR_BIT - 1:0] PRIOR_LLR_FIRST;
	reg [INFO_NUM - 1:0][SYMBOL_BIT - 1:0] PRIOR_SYMBOL;
	reg [INFO_NUM - 1:0][SYMBOL_BIT - 1:0] PRIOR_SYMBOL_FIRST;
	reg [CHECK_NUM - 1:0][CHECK_DEGREE - 1:0][FIELD - 1:0][LLR_BIT - 1:0] LLR_CHECK_STORE;
	reg [CHECK_NUM - 2:0][CHECK_DEGREE - 1:0][FIELD - 1:0][LLR_BIT - 1:0] LLR_CHECK_STORE_FIRST;
	reg FIRST;
	wire [CHECK_DEGREE - 1:0][FIELD - 1:0][LLR_BIT - 1:0] LLR_CHECK_INPUT;
	wire [CHECK_DEGREE - 1:0][CHECK_BIT - 1:0] MAT_CHECK_INPUT;
	wire [CHECK_DEGREE - 1:0][FIELD - 1:0][LLR_BIT - 1:0] LLR_CHECK_OUTPUT;
	wire [SYMBOL_NUM - 1:0][VARIABLE_DEGREE - 1:0][FIELD - 1:0][LLR_BIT - 1:0] LLR_VARI_INPUT;
	wire [SYMBOL_NUM - 1:0][FIELD - 1:0][LLR_BIT - 1:0] LLR_VARI_OUTPUT;
	wire [SYMBOL_NUM - 1:0][FIELD - 1:0][LLR_BIT - 1:0] LLR_TRUE_INPUT;
	wire [SYMBOL_NUM - 1:0][CHECK_BIT - 1:0] LLR_VARI_SYMBOL;
	wire [CHECK_NUM - 1:0][CHECK_DEGREE - 1:0][CHECK_BIT - 1:0] H;
	wire [INFO_NUM - 1:0][SYMBOL_BIT - 1:0] MIDOUT_SYMBOL;
	wire [INFO_NUM - 1:0][SYMBOL_BIT - 1:0] INPUT_SYMBOL_LOC;
	reg [INFO_NUM - 1:0][SYMBOL_BIT - 1:0] OUTPUT_SYMBOL_LOC;
	reg CLK_STATE;
	assign NODE_STATE = FSM[6:2];
	assign STATE = FSM[1];
	generate
		genvar IN1, IN2, IN3, IN4;
		for (IN1 = 0; IN1 < SYMBOL_NUM; IN1 = IN1 + 1) begin
			for (IN2 = 0; IN2 < FIELD; IN2 = IN2 + 1) begin
				for (IN3 = 0; IN3 < LLR_BIT; IN3 = IN3 + 1) begin
					assign INPUT_LLR_LOC[IN1][IN2][IN3] = INPUT_LLR[IN1 * FIELD * LLR_BIT + IN2 * LLR_BIT + IN3];
				end
			end
		end
		for (IN1 = 0; IN1 < INFO_NUM; IN1 = IN1 + 1) begin
			for (IN2 = 0; IN2 < SYMBOL_BIT; IN2 = IN2 + 1) begin
				assign INPUT_SYMBOL_LOC[IN1][IN2] = INPUT_SYMBOL[IN1 * SYMBOL_BIT + IN2];
				assign OUTPUT_SYMBOL[IN1 * SYMBOL_BIT + IN2] = OUTPUT_SYMBOL_LOC[IN1][IN2];
			end
		end
		for (IN1 = 0; IN1 < INFO_NUM; IN1 = IN1 + 1) begin
			for (IN2 = 0; IN2 < SYMBOL_BIT; IN2 = IN2 + 1) begin
				assign MIDOUT_DEBUG[IN1 * SYMBOL_BIT + IN2] = MIDOUT_SYMBOL[IN1][IN2];
			end
		end
	//	for (IN1 = 0; IN1 < SYMBOL_NUM; IN1 = IN1 + 1) begin
	//		for (IN3 = 0; IN3 < FIELD; IN3 = IN3 + 1) begin
	//			for (IN4 = 0; IN4 < LLR_BIT; IN4 = IN4 + 1) begin
	//				assign LLR_PRIOR_DEBUG[IN1 * FIELD * LLR_BIT + IN3 * LLR_BIT + IN4] = PRIOR_LLR[IN1][IN3][IN4];
	//			end
	//		end
	//	end
	//	for (IN1 = 0; IN1 < SYMBOL_NUM; IN1 = IN1 + 1) begin
	//		for (IN2 = 0; IN2 < VARIABLE_DEGREE; IN2 = IN2 + 1) begin
	//			for (IN3 = 0; IN3 < FIELD; IN3 = IN3 + 1) begin
	//				for (IN4 = 0; IN4 < LLR_BIT; IN4 = IN4 + 1) begin
	//					assign LLR_VARI_DEBUG[IN1 * VARIABLE_DEGREE * FIELD * LLR_BIT + IN2 * FIELD * LLR_BIT + IN3 * LLR_BIT + IN4] = LLR_VARI_INPUT[IN1][IN2][IN3][IN4];
	//				end
	//			end
	//		end
	//	end
	//	for (IN1 = 0; IN1 < CHECK_DEGREE; IN1 = IN1 + 1) begin
	//		for (IN2 = 0; IN2 < FIELD; IN2 = IN2 + 1) begin
	//			for (IN3 = 0; IN3 < LLR_BIT; IN3 = IN3 + 1) begin
	//				assign LLR_CHECK_DEBUG[IN1 * FIELD * LLR_BIT + IN2 * LLR_BIT + IN3] = LLR_CHECK_OUTPUT[IN1][IN2][IN3];
	//			end
	//		end
	//	end
	endgenerate
	assign H[0] = {2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01};
	assign H[1] = {2'b01, 2'b01, 2'b10, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01};
	assign H[2] = {2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01};
	assign H[3] = {2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01};
	assign H[4] = {2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01};
	assign H[5] = {2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01};
	assign H[6] = {2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01};
	assign H[7] = {2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01};
	assign H[8] = {2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01};
	assign H[9] = {2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01};
	assign H[10] = {2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01};
	assign H[11] = {2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01};
	assign H[12] = {2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01};
	assign H[13] = {2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01};
	assign H[14] = {2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01};
	assign H[15] = {2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b10, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01};
	assign H[16] = {2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01};
	assign H[17] = {2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b10, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01};
	assign H[18] = {2'b01, 2'b01, 2'b01, 2'b01, 2'b10, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01};
	assign H[19] = {2'b01, 2'b01, 2'b10, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b10, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01};
	assign H[20] = {2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b10, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b10, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01};
	assign H[21] = {2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b10, 2'b01, 2'b01, 2'b01, 2'b01, 2'b10};
	assign H[22] = {2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b10, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b10};
	assign H[23] = {2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b10, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b10, 2'b01};
	assign H[24] = {2'b01, 2'b01, 2'b01, 2'b10, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b10, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01};
	assign H[25] = {2'b01, 2'b01, 2'b01, 2'b10, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b10, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01};
	assign H[26] = {2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b10, 2'b01, 2'b01, 2'b01, 2'b01, 2'b10, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01};
	assign H[27] = {2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b10};
	assign H[28] = {2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b10, 2'b01, 2'b01, 2'b10, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01};
	assign H[29] = {2'b01, 2'b01, 2'b10, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b10, 2'b01, 2'b01, 2'b01};
	assign H[30] = {2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b01, 2'b10, 2'b01, 2'b01, 2'b01, 2'b01, 2'b10, 2'b01, 2'b01, 2'b10, 2'b01, 2'b01, 2'b01};
	assign H[31] = {2'b01, 2'b10, 2'b01, 2'b01, 2'b01, 2'b10, 2'b01, 2'b01, 2'b10, 2'b01, 2'b01, 2'b10, 2'b01, 2'b01, 2'b01, 2'b10, 2'b01, 2'b10};
	// Input Arrangement
	generate
		genvar o_v, f_v, lb_v;
		for (o_v = 0; o_v < SYMBOL_NUM; o_v = o_v + 1)
		begin:INPUT_ARRANGE
			for (f_v = 0; f_v < FIELD; f_v = f_v + 1) begin
				for (lb_v = 0; lb_v < LLR_BIT; lb_v = lb_v + 1) begin
					assign LLR_TRUE_INPUT[o_v][f_v][lb_v] = (FIRST) ? (((NODE_STATE == 5'b0) && (STATE == 1'b0)) ? (INPUT_LLR_LOC[o_v][f_v][lb_v]) : (PRIOR_LLR_FIRST[o_v][f_v][lb_v])) : (LLR_VARI_OUTPUT[o_v][f_v][lb_v]);
				end
			end
		end
	endgenerate
	// Input Matrix Connection Definition
	generate
		genvar cki, ckf;
		for (ckf = 0; ckf < CHECK_DEGREE; ckf = ckf + 1) begin
			for (cki = 0; cki < CHECK_BIT; cki = cki + 1) begin
				assign MAT_CHECK_INPUT[ckf][cki] = ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (H[0][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (H[1][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (H[2][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (H[3][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (H[4][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (H[5][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (H[6][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (H[7][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (H[8][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (H[9][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (H[10][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (H[11][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (H[12][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (H[13][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (H[14][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (H[15][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (H[16][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (H[17][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (H[18][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (H[19][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (H[20][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (H[21][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (H[22][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (H[23][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (H[24][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (H[25][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (H[26][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (H[27][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (H[28][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (H[29][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (H[30][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (H[31][ckf][cki]));
			end
		end
		for (ckf = 0; ckf < FIELD; ckf = ckf + 1) begin
			for (cki = 0; cki < LLR_BIT; cki = cki + 1) begin
				assign LLR_CHECK_INPUT[0][ckf][cki] = ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[0][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[20][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[0][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[53][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[70][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[6][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[104][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[121][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[138][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[155][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[172][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[189][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[13][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[222][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[239][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[1][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[8][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[8][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[15][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[7][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[3][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[5][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[11][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[1][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[2][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[26][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[9][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[4][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[14][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[16][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[31][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[33][ckf][cki]));
				assign LLR_CHECK_INPUT[1][ckf][cki] = ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[6][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[21][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[37][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[54][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[71][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[88][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[105][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[122][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[139][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[156][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[173][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[190][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[206][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[223][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[240][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[2][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[9][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[32][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[19][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[20][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[21][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[22][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[18][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[12][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[25][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[30][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[27][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[10][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[29][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[36][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[51][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[43][ckf][cki]));
				assign LLR_CHECK_INPUT[2][ckf][cki] = ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[13][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[22][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[38][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[55][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[72][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[89][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[106][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[123][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[140][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[157][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[174][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[191][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[207][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[224][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[241][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[3][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[10][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[34][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[35][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[49][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[39][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[47][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[23][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[24][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[37][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[42][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[40][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[28][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[50][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[41][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[58][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[46][ckf][cki]));
				assign LLR_CHECK_INPUT[3][ckf][cki] = ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[17][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[23][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[39][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[56][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[73][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[90][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[107][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[124][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[141][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[158][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[175][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[192][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[208][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[225][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[242][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[4][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[11][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[45][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[52][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[61][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[53][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[63][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[44][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[38][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[66][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[60][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[56][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[68][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[64][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[48][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[65][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[59][ckf][cki]));
				assign LLR_CHECK_INPUT[4][ckf][cki] = ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[19][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[24][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[40][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[57][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[74][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[91][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[108][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[125][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[142][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[159][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[176][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[193][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[209][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[226][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[243][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[5][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[12][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[54][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[62][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[80][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[73][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[77][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[57][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[69][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[70][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[86][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[75][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[72][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[82][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[55][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[74][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[87][ckf][cki]));
				assign LLR_CHECK_INPUT[5][ckf][cki] = ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[32][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[25][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[41][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[58][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[75][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[92][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[109][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[126][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[143][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[160][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[177][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[194][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[210][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[227][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[244][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[7][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[14][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[76][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[81][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[99][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[78][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[79][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[71][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[85][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[88][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[96][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[100][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[90][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[95][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[84][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[92][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[89][ckf][cki]));
				assign LLR_CHECK_INPUT[6][ckf][cki] = ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[257][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[26][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[42][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[59][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[76][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[93][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[110][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[127][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[144][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[161][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[178][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[195][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[211][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[228][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[245][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[17][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[15][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[93][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[102][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[113][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[120][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[91][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[83][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[94][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[105][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[109][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[106][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[115][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[119][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[101][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[103][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[97][ckf][cki]));
				assign LLR_CHECK_INPUT[7][ckf][cki] = ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[267][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[27][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[43][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[60][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[77][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[94][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[111][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[128][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[145][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[162][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[179][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[196][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[212][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[229][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[246][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[256][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[16][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[110][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[118][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[124][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[129][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[107][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[98][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[114][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[111][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[116][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[112][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[133][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[128][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[108][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[104][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[137][ckf][cki]));
				assign LLR_CHECK_INPUT[8][ckf][cki] = ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[270][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[28][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[44][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[61][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[78][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[95][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[112][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[129][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[146][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[163][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[180][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[197][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[213][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[230][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[247][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[258][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[18][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[122][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[135][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[126][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[150][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[123][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[117][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[130][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[136][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[125][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[121][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[138][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[141][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[127][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[132][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[147][ckf][cki]));
				assign LLR_CHECK_INPUT[9][ckf][cki] = ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[275][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[29][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[45][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[62][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[79][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[96][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[113][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[130][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[147][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[164][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[181][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[198][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[214][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[231][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[248][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[259][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[30][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[143][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[142][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[145][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[164][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[139][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[131][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[134][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[149][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[152][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[154][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[162][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[146][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[153][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[140][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[148][ckf][cki]));
				assign LLR_CHECK_INPUT[10][ckf][cki] = ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[276][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[31][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[46][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[63][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[80][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[97][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[114][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[131][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[148][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[165][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[182][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[199][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[215][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[232][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[249][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[260][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[67][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[161][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[171][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[163][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[176][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[165][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[151][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[144][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[160][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[169][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[168][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[172][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[158][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[170][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[155][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[159][ckf][cki]));
				assign LLR_CHECK_INPUT[11][ckf][cki] = ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[277][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[33][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[47][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[64][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[81][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[98][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[115][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[132][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[149][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[166][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[183][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[200][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[216][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[233][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[250][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[261][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[247][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[166][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[188][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[175][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[187][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[183][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[156][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[157][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[179][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[173][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[177][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[201][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[174][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[185][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[167][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[189][ckf][cki]));
				assign LLR_CHECK_INPUT[12][ckf][cki] = ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[278][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[34][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[48][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[65][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[82][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[99][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[116][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[133][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[150][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[167][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[184][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[201][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[217][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[234][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[251][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[262][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[268][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[186][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[194][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[204][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[191][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[192][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[180][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[182][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[203][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[197][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[184][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[212][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[178][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[200][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[181][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[190][ckf][cki]));
				assign LLR_CHECK_INPUT[13][ckf][cki] = ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[279][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[35][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[49][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[66][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[83][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[100][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[117][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[134][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[151][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[168][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[185][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[202][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[218][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[235][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[252][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[263][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[271][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[198][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[199][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[210][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[221][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[208][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[196][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[193][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[206][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[215][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[205][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[226][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[195][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[220][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[202][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[209][ckf][cki]));
				assign LLR_CHECK_INPUT[14][ckf][cki] = ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[280][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[36][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[50][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[67][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[84][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[101][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[118][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[135][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[152][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[169][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[186][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[203][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[219][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[236][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[253][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[264][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[272][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[207][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[214][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[230][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[229][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[236][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[217][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[218][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[213][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[219][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[211][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[240][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[225][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[227][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[216][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[222][ckf][cki]));
				assign LLR_CHECK_INPUT[15][ckf][cki] = ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[281][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[87][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[51][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[68][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[85][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[102][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[119][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[136][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[153][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[170][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[187][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[204][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[220][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[237][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[254][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[265][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[273][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[237][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[231][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[233][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[254][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[241][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[228][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[234][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[235][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[223][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[238][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[256][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[251][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[232][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[224][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[243][ckf][cki]));
				assign LLR_CHECK_INPUT[16][ckf][cki] = ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[282][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[257][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[52][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[69][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[86][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[103][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[120][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[137][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[154][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[171][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[188][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[205][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[221][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[238][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[255][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[266][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[274][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[244][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[248][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[242][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[273][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[260][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[239][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[249][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[245][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[255][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[246][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[261][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[265][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[253][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[252][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[250][ckf][cki]));
				assign LLR_CHECK_INPUT[17][ckf][cki] = ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[283][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[284][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[285][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[267][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[270][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[286][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[275][ckf][cki])) | ((~NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[276][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[277][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[278][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[279][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[280][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[287][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[282][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[283][ckf][cki])) | ((~NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[269][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[281][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[264][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[258][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[271][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[286][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[268][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[266][ckf][cki])) | ((NODE_STATE[4]) & (~NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[272][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[274][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[269][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[262][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (~NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[285][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[287][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (~NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[263][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (~NODE_STATE[0]) & (LLR_TRUE_INPUT[259][ckf][cki])) | ((NODE_STATE[4]) & (NODE_STATE[3]) & (NODE_STATE[2]) & (NODE_STATE[1]) & (NODE_STATE[0]) & (LLR_TRUE_INPUT[284][ckf][cki]));
			end
		end
	endgenerate
	CheckNode CHECK_NODES (
		.INPUT_MATRIX(MAT_CHECK_INPUT),
		.BUF_LLR(LLR_CHECK_INPUT),
		.OUTPUT_LLR(LLR_CHECK_OUTPUT),
		.CLK(CLK),
		.RST(RST),
		.CLK_STATE(FSM[0])
	);
	// Check Nodes & Variable Nodes Connection
	generate
		genvar vf, vi;
		for (vf = 0; vf < FIELD; vf = vf + 1) begin
			for (vi = 0; vi < LLR_BIT; vi = vi + 1) begin
				assign LLR_VARI_INPUT[0][0][vf][vi] = LLR_CHECK_STORE[0][0][vf][vi];
				assign LLR_VARI_INPUT[0][1][vf][vi] = LLR_CHECK_STORE[2][0][vf][vi];
				assign LLR_VARI_INPUT[1][0][vf][vi] = LLR_CHECK_STORE[15][0][vf][vi];
				assign LLR_VARI_INPUT[1][1][vf][vi] = LLR_CHECK_STORE[23][0][vf][vi];
				assign LLR_VARI_INPUT[2][0][vf][vi] = LLR_CHECK_STORE[15][1][vf][vi];
				assign LLR_VARI_INPUT[2][1][vf][vi] = LLR_CHECK_STORE[24][0][vf][vi];
				assign LLR_VARI_INPUT[3][0][vf][vi] = LLR_CHECK_STORE[15][2][vf][vi];
				assign LLR_VARI_INPUT[3][1][vf][vi] = LLR_CHECK_STORE[20][0][vf][vi];
				assign LLR_VARI_INPUT[4][0][vf][vi] = LLR_CHECK_STORE[15][3][vf][vi];
				assign LLR_VARI_INPUT[4][1][vf][vi] = LLR_CHECK_STORE[27][0][vf][vi];
				assign LLR_VARI_INPUT[5][0][vf][vi] = LLR_CHECK_STORE[15][4][vf][vi];
				assign LLR_VARI_INPUT[5][1][vf][vi] = LLR_CHECK_STORE[21][0][vf][vi];
				assign LLR_VARI_INPUT[6][0][vf][vi] = LLR_CHECK_STORE[0][1][vf][vi];
				assign LLR_VARI_INPUT[6][1][vf][vi] = LLR_CHECK_STORE[5][0][vf][vi];
				assign LLR_VARI_INPUT[7][0][vf][vi] = LLR_CHECK_STORE[15][5][vf][vi];
				assign LLR_VARI_INPUT[7][1][vf][vi] = LLR_CHECK_STORE[19][0][vf][vi];
				assign LLR_VARI_INPUT[8][0][vf][vi] = LLR_CHECK_STORE[16][0][vf][vi];
				assign LLR_VARI_INPUT[8][1][vf][vi] = LLR_CHECK_STORE[17][0][vf][vi];
				assign LLR_VARI_INPUT[9][0][vf][vi] = LLR_CHECK_STORE[16][1][vf][vi];
				assign LLR_VARI_INPUT[9][1][vf][vi] = LLR_CHECK_STORE[26][0][vf][vi];
				assign LLR_VARI_INPUT[10][0][vf][vi] = LLR_CHECK_STORE[16][2][vf][vi];
				assign LLR_VARI_INPUT[10][1][vf][vi] = LLR_CHECK_STORE[27][1][vf][vi];
				assign LLR_VARI_INPUT[11][0][vf][vi] = LLR_CHECK_STORE[16][3][vf][vi];
				assign LLR_VARI_INPUT[11][1][vf][vi] = LLR_CHECK_STORE[22][0][vf][vi];
				assign LLR_VARI_INPUT[12][0][vf][vi] = LLR_CHECK_STORE[16][4][vf][vi];
				assign LLR_VARI_INPUT[12][1][vf][vi] = LLR_CHECK_STORE[23][1][vf][vi];
				assign LLR_VARI_INPUT[13][0][vf][vi] = LLR_CHECK_STORE[0][2][vf][vi];
				assign LLR_VARI_INPUT[13][1][vf][vi] = LLR_CHECK_STORE[12][0][vf][vi];
				assign LLR_VARI_INPUT[14][0][vf][vi] = LLR_CHECK_STORE[16][5][vf][vi];
				assign LLR_VARI_INPUT[14][1][vf][vi] = LLR_CHECK_STORE[28][0][vf][vi];
				assign LLR_VARI_INPUT[15][0][vf][vi] = LLR_CHECK_STORE[16][6][vf][vi];
				assign LLR_VARI_INPUT[15][1][vf][vi] = LLR_CHECK_STORE[18][0][vf][vi];
				assign LLR_VARI_INPUT[16][0][vf][vi] = LLR_CHECK_STORE[16][7][vf][vi];
				assign LLR_VARI_INPUT[16][1][vf][vi] = LLR_CHECK_STORE[29][0][vf][vi];
				assign LLR_VARI_INPUT[17][0][vf][vi] = LLR_CHECK_STORE[0][3][vf][vi];
				assign LLR_VARI_INPUT[17][1][vf][vi] = LLR_CHECK_STORE[15][6][vf][vi];
				assign LLR_VARI_INPUT[18][0][vf][vi] = LLR_CHECK_STORE[16][8][vf][vi];
				assign LLR_VARI_INPUT[18][1][vf][vi] = LLR_CHECK_STORE[22][1][vf][vi];
				assign LLR_VARI_INPUT[19][0][vf][vi] = LLR_CHECK_STORE[0][4][vf][vi];
				assign LLR_VARI_INPUT[19][1][vf][vi] = LLR_CHECK_STORE[18][1][vf][vi];
				assign LLR_VARI_INPUT[20][0][vf][vi] = LLR_CHECK_STORE[1][0][vf][vi];
				assign LLR_VARI_INPUT[20][1][vf][vi] = LLR_CHECK_STORE[19][1][vf][vi];
				assign LLR_VARI_INPUT[21][0][vf][vi] = LLR_CHECK_STORE[1][1][vf][vi];
				assign LLR_VARI_INPUT[21][1][vf][vi] = LLR_CHECK_STORE[20][1][vf][vi];
				assign LLR_VARI_INPUT[22][0][vf][vi] = LLR_CHECK_STORE[1][2][vf][vi];
				assign LLR_VARI_INPUT[22][1][vf][vi] = LLR_CHECK_STORE[21][1][vf][vi];
				assign LLR_VARI_INPUT[23][0][vf][vi] = LLR_CHECK_STORE[1][3][vf][vi];
				assign LLR_VARI_INPUT[23][1][vf][vi] = LLR_CHECK_STORE[22][2][vf][vi];
				assign LLR_VARI_INPUT[24][0][vf][vi] = LLR_CHECK_STORE[1][4][vf][vi];
				assign LLR_VARI_INPUT[24][1][vf][vi] = LLR_CHECK_STORE[23][2][vf][vi];
				assign LLR_VARI_INPUT[25][0][vf][vi] = LLR_CHECK_STORE[1][5][vf][vi];
				assign LLR_VARI_INPUT[25][1][vf][vi] = LLR_CHECK_STORE[24][1][vf][vi];
				assign LLR_VARI_INPUT[26][0][vf][vi] = LLR_CHECK_STORE[1][6][vf][vi];
				assign LLR_VARI_INPUT[26][1][vf][vi] = LLR_CHECK_STORE[25][0][vf][vi];
				assign LLR_VARI_INPUT[27][0][vf][vi] = LLR_CHECK_STORE[1][7][vf][vi];
				assign LLR_VARI_INPUT[27][1][vf][vi] = LLR_CHECK_STORE[26][1][vf][vi];
				assign LLR_VARI_INPUT[28][0][vf][vi] = LLR_CHECK_STORE[1][8][vf][vi];
				assign LLR_VARI_INPUT[28][1][vf][vi] = LLR_CHECK_STORE[27][2][vf][vi];
				assign LLR_VARI_INPUT[29][0][vf][vi] = LLR_CHECK_STORE[1][9][vf][vi];
				assign LLR_VARI_INPUT[29][1][vf][vi] = LLR_CHECK_STORE[28][1][vf][vi];
				assign LLR_VARI_INPUT[30][0][vf][vi] = LLR_CHECK_STORE[16][9][vf][vi];
				assign LLR_VARI_INPUT[30][1][vf][vi] = LLR_CHECK_STORE[25][1][vf][vi];
				assign LLR_VARI_INPUT[31][0][vf][vi] = LLR_CHECK_STORE[1][10][vf][vi];
				assign LLR_VARI_INPUT[31][1][vf][vi] = LLR_CHECK_STORE[30][0][vf][vi];
				assign LLR_VARI_INPUT[32][0][vf][vi] = LLR_CHECK_STORE[0][5][vf][vi];
				assign LLR_VARI_INPUT[32][1][vf][vi] = LLR_CHECK_STORE[17][1][vf][vi];
				assign LLR_VARI_INPUT[33][0][vf][vi] = LLR_CHECK_STORE[1][11][vf][vi];
				assign LLR_VARI_INPUT[33][1][vf][vi] = LLR_CHECK_STORE[31][0][vf][vi];
				assign LLR_VARI_INPUT[34][0][vf][vi] = LLR_CHECK_STORE[1][12][vf][vi];
				assign LLR_VARI_INPUT[34][1][vf][vi] = LLR_CHECK_STORE[17][2][vf][vi];
				assign LLR_VARI_INPUT[35][0][vf][vi] = LLR_CHECK_STORE[1][13][vf][vi];
				assign LLR_VARI_INPUT[35][1][vf][vi] = LLR_CHECK_STORE[18][2][vf][vi];
				assign LLR_VARI_INPUT[36][0][vf][vi] = LLR_CHECK_STORE[1][14][vf][vi];
				assign LLR_VARI_INPUT[36][1][vf][vi] = LLR_CHECK_STORE[29][1][vf][vi];
				assign LLR_VARI_INPUT[37][0][vf][vi] = LLR_CHECK_STORE[2][1][vf][vi];
				assign LLR_VARI_INPUT[37][1][vf][vi] = LLR_CHECK_STORE[24][2][vf][vi];
				assign LLR_VARI_INPUT[38][0][vf][vi] = LLR_CHECK_STORE[2][2][vf][vi];
				assign LLR_VARI_INPUT[38][1][vf][vi] = LLR_CHECK_STORE[23][3][vf][vi];
				assign LLR_VARI_INPUT[39][0][vf][vi] = LLR_CHECK_STORE[2][3][vf][vi];
				assign LLR_VARI_INPUT[39][1][vf][vi] = LLR_CHECK_STORE[20][2][vf][vi];
				assign LLR_VARI_INPUT[40][0][vf][vi] = LLR_CHECK_STORE[2][4][vf][vi];
				assign LLR_VARI_INPUT[40][1][vf][vi] = LLR_CHECK_STORE[26][2][vf][vi];
				assign LLR_VARI_INPUT[41][0][vf][vi] = LLR_CHECK_STORE[2][5][vf][vi];
				assign LLR_VARI_INPUT[41][1][vf][vi] = LLR_CHECK_STORE[29][2][vf][vi];
				assign LLR_VARI_INPUT[42][0][vf][vi] = LLR_CHECK_STORE[2][6][vf][vi];
				assign LLR_VARI_INPUT[42][1][vf][vi] = LLR_CHECK_STORE[25][2][vf][vi];
				assign LLR_VARI_INPUT[43][0][vf][vi] = LLR_CHECK_STORE[2][7][vf][vi];
				assign LLR_VARI_INPUT[43][1][vf][vi] = LLR_CHECK_STORE[31][1][vf][vi];
				assign LLR_VARI_INPUT[44][0][vf][vi] = LLR_CHECK_STORE[2][8][vf][vi];
				assign LLR_VARI_INPUT[44][1][vf][vi] = LLR_CHECK_STORE[22][3][vf][vi];
				assign LLR_VARI_INPUT[45][0][vf][vi] = LLR_CHECK_STORE[2][9][vf][vi];
				assign LLR_VARI_INPUT[45][1][vf][vi] = LLR_CHECK_STORE[17][3][vf][vi];
				assign LLR_VARI_INPUT[46][0][vf][vi] = LLR_CHECK_STORE[2][10][vf][vi];
				assign LLR_VARI_INPUT[46][1][vf][vi] = LLR_CHECK_STORE[31][2][vf][vi];
				assign LLR_VARI_INPUT[47][0][vf][vi] = LLR_CHECK_STORE[2][11][vf][vi];
				assign LLR_VARI_INPUT[47][1][vf][vi] = LLR_CHECK_STORE[21][2][vf][vi];
				assign LLR_VARI_INPUT[48][0][vf][vi] = LLR_CHECK_STORE[2][12][vf][vi];
				assign LLR_VARI_INPUT[48][1][vf][vi] = LLR_CHECK_STORE[29][3][vf][vi];
				assign LLR_VARI_INPUT[49][0][vf][vi] = LLR_CHECK_STORE[2][13][vf][vi];
				assign LLR_VARI_INPUT[49][1][vf][vi] = LLR_CHECK_STORE[19][2][vf][vi];
				assign LLR_VARI_INPUT[50][0][vf][vi] = LLR_CHECK_STORE[2][14][vf][vi];
				assign LLR_VARI_INPUT[50][1][vf][vi] = LLR_CHECK_STORE[28][2][vf][vi];
				assign LLR_VARI_INPUT[51][0][vf][vi] = LLR_CHECK_STORE[2][15][vf][vi];
				assign LLR_VARI_INPUT[51][1][vf][vi] = LLR_CHECK_STORE[30][1][vf][vi];
				assign LLR_VARI_INPUT[52][0][vf][vi] = LLR_CHECK_STORE[2][16][vf][vi];
				assign LLR_VARI_INPUT[52][1][vf][vi] = LLR_CHECK_STORE[18][3][vf][vi];
				assign LLR_VARI_INPUT[53][0][vf][vi] = LLR_CHECK_STORE[3][0][vf][vi];
				assign LLR_VARI_INPUT[53][1][vf][vi] = LLR_CHECK_STORE[20][3][vf][vi];
				assign LLR_VARI_INPUT[54][0][vf][vi] = LLR_CHECK_STORE[3][1][vf][vi];
				assign LLR_VARI_INPUT[54][1][vf][vi] = LLR_CHECK_STORE[17][4][vf][vi];
				assign LLR_VARI_INPUT[55][0][vf][vi] = LLR_CHECK_STORE[3][2][vf][vi];
				assign LLR_VARI_INPUT[55][1][vf][vi] = LLR_CHECK_STORE[29][4][vf][vi];
				assign LLR_VARI_INPUT[56][0][vf][vi] = LLR_CHECK_STORE[3][3][vf][vi];
				assign LLR_VARI_INPUT[56][1][vf][vi] = LLR_CHECK_STORE[26][3][vf][vi];
				assign LLR_VARI_INPUT[57][0][vf][vi] = LLR_CHECK_STORE[3][4][vf][vi];
				assign LLR_VARI_INPUT[57][1][vf][vi] = LLR_CHECK_STORE[22][4][vf][vi];
				assign LLR_VARI_INPUT[58][0][vf][vi] = LLR_CHECK_STORE[3][5][vf][vi];
				assign LLR_VARI_INPUT[58][1][vf][vi] = LLR_CHECK_STORE[30][2][vf][vi];
				assign LLR_VARI_INPUT[59][0][vf][vi] = LLR_CHECK_STORE[3][6][vf][vi];
				assign LLR_VARI_INPUT[59][1][vf][vi] = LLR_CHECK_STORE[31][3][vf][vi];
				assign LLR_VARI_INPUT[60][0][vf][vi] = LLR_CHECK_STORE[3][7][vf][vi];
				assign LLR_VARI_INPUT[60][1][vf][vi] = LLR_CHECK_STORE[25][3][vf][vi];
				assign LLR_VARI_INPUT[61][0][vf][vi] = LLR_CHECK_STORE[3][8][vf][vi];
				assign LLR_VARI_INPUT[61][1][vf][vi] = LLR_CHECK_STORE[19][3][vf][vi];
				assign LLR_VARI_INPUT[62][0][vf][vi] = LLR_CHECK_STORE[3][9][vf][vi];
				assign LLR_VARI_INPUT[62][1][vf][vi] = LLR_CHECK_STORE[18][4][vf][vi];
				assign LLR_VARI_INPUT[63][0][vf][vi] = LLR_CHECK_STORE[3][10][vf][vi];
				assign LLR_VARI_INPUT[63][1][vf][vi] = LLR_CHECK_STORE[21][3][vf][vi];
				assign LLR_VARI_INPUT[64][0][vf][vi] = LLR_CHECK_STORE[3][11][vf][vi];
				assign LLR_VARI_INPUT[64][1][vf][vi] = LLR_CHECK_STORE[28][3][vf][vi];
				assign LLR_VARI_INPUT[65][0][vf][vi] = LLR_CHECK_STORE[3][12][vf][vi];
				assign LLR_VARI_INPUT[65][1][vf][vi] = LLR_CHECK_STORE[30][3][vf][vi];
				assign LLR_VARI_INPUT[66][0][vf][vi] = LLR_CHECK_STORE[3][13][vf][vi];
				assign LLR_VARI_INPUT[66][1][vf][vi] = LLR_CHECK_STORE[24][3][vf][vi];
				assign LLR_VARI_INPUT[67][0][vf][vi] = LLR_CHECK_STORE[3][14][vf][vi];
				assign LLR_VARI_INPUT[67][1][vf][vi] = LLR_CHECK_STORE[16][10][vf][vi];
				assign LLR_VARI_INPUT[68][0][vf][vi] = LLR_CHECK_STORE[3][15][vf][vi];
				assign LLR_VARI_INPUT[68][1][vf][vi] = LLR_CHECK_STORE[27][3][vf][vi];
				assign LLR_VARI_INPUT[69][0][vf][vi] = LLR_CHECK_STORE[3][16][vf][vi];
				assign LLR_VARI_INPUT[69][1][vf][vi] = LLR_CHECK_STORE[23][4][vf][vi];
				assign LLR_VARI_INPUT[70][0][vf][vi] = LLR_CHECK_STORE[4][0][vf][vi];
				assign LLR_VARI_INPUT[70][1][vf][vi] = LLR_CHECK_STORE[24][4][vf][vi];
				assign LLR_VARI_INPUT[71][0][vf][vi] = LLR_CHECK_STORE[4][1][vf][vi];
				assign LLR_VARI_INPUT[71][1][vf][vi] = LLR_CHECK_STORE[22][5][vf][vi];
				assign LLR_VARI_INPUT[72][0][vf][vi] = LLR_CHECK_STORE[4][2][vf][vi];
				assign LLR_VARI_INPUT[72][1][vf][vi] = LLR_CHECK_STORE[27][4][vf][vi];
				assign LLR_VARI_INPUT[73][0][vf][vi] = LLR_CHECK_STORE[4][3][vf][vi];
				assign LLR_VARI_INPUT[73][1][vf][vi] = LLR_CHECK_STORE[20][4][vf][vi];
				assign LLR_VARI_INPUT[74][0][vf][vi] = LLR_CHECK_STORE[4][4][vf][vi];
				assign LLR_VARI_INPUT[74][1][vf][vi] = LLR_CHECK_STORE[30][4][vf][vi];
				assign LLR_VARI_INPUT[75][0][vf][vi] = LLR_CHECK_STORE[4][5][vf][vi];
				assign LLR_VARI_INPUT[75][1][vf][vi] = LLR_CHECK_STORE[26][4][vf][vi];
				assign LLR_VARI_INPUT[76][0][vf][vi] = LLR_CHECK_STORE[4][6][vf][vi];
				assign LLR_VARI_INPUT[76][1][vf][vi] = LLR_CHECK_STORE[17][5][vf][vi];
				assign LLR_VARI_INPUT[77][0][vf][vi] = LLR_CHECK_STORE[4][7][vf][vi];
				assign LLR_VARI_INPUT[77][1][vf][vi] = LLR_CHECK_STORE[21][4][vf][vi];
				assign LLR_VARI_INPUT[78][0][vf][vi] = LLR_CHECK_STORE[4][8][vf][vi];
				assign LLR_VARI_INPUT[78][1][vf][vi] = LLR_CHECK_STORE[20][5][vf][vi];
				assign LLR_VARI_INPUT[79][0][vf][vi] = LLR_CHECK_STORE[4][9][vf][vi];
				assign LLR_VARI_INPUT[79][1][vf][vi] = LLR_CHECK_STORE[21][5][vf][vi];
				assign LLR_VARI_INPUT[80][0][vf][vi] = LLR_CHECK_STORE[4][10][vf][vi];
				assign LLR_VARI_INPUT[80][1][vf][vi] = LLR_CHECK_STORE[19][4][vf][vi];
				assign LLR_VARI_INPUT[81][0][vf][vi] = LLR_CHECK_STORE[4][11][vf][vi];
				assign LLR_VARI_INPUT[81][1][vf][vi] = LLR_CHECK_STORE[18][5][vf][vi];
				assign LLR_VARI_INPUT[82][0][vf][vi] = LLR_CHECK_STORE[4][12][vf][vi];
				assign LLR_VARI_INPUT[82][1][vf][vi] = LLR_CHECK_STORE[28][4][vf][vi];
				assign LLR_VARI_INPUT[83][0][vf][vi] = LLR_CHECK_STORE[4][13][vf][vi];
				assign LLR_VARI_INPUT[83][1][vf][vi] = LLR_CHECK_STORE[22][6][vf][vi];
				assign LLR_VARI_INPUT[84][0][vf][vi] = LLR_CHECK_STORE[4][14][vf][vi];
				assign LLR_VARI_INPUT[84][1][vf][vi] = LLR_CHECK_STORE[29][5][vf][vi];
				assign LLR_VARI_INPUT[85][0][vf][vi] = LLR_CHECK_STORE[4][15][vf][vi];
				assign LLR_VARI_INPUT[85][1][vf][vi] = LLR_CHECK_STORE[23][5][vf][vi];
				assign LLR_VARI_INPUT[86][0][vf][vi] = LLR_CHECK_STORE[4][16][vf][vi];
				assign LLR_VARI_INPUT[86][1][vf][vi] = LLR_CHECK_STORE[25][4][vf][vi];
				assign LLR_VARI_INPUT[87][0][vf][vi] = LLR_CHECK_STORE[1][15][vf][vi];
				assign LLR_VARI_INPUT[87][1][vf][vi] = LLR_CHECK_STORE[31][4][vf][vi];
				assign LLR_VARI_INPUT[88][0][vf][vi] = LLR_CHECK_STORE[5][1][vf][vi];
				assign LLR_VARI_INPUT[88][1][vf][vi] = LLR_CHECK_STORE[24][5][vf][vi];
				assign LLR_VARI_INPUT[89][0][vf][vi] = LLR_CHECK_STORE[5][2][vf][vi];
				assign LLR_VARI_INPUT[89][1][vf][vi] = LLR_CHECK_STORE[31][5][vf][vi];
				assign LLR_VARI_INPUT[90][0][vf][vi] = LLR_CHECK_STORE[5][3][vf][vi];
				assign LLR_VARI_INPUT[90][1][vf][vi] = LLR_CHECK_STORE[27][5][vf][vi];
				assign LLR_VARI_INPUT[91][0][vf][vi] = LLR_CHECK_STORE[5][4][vf][vi];
				assign LLR_VARI_INPUT[91][1][vf][vi] = LLR_CHECK_STORE[21][6][vf][vi];
				assign LLR_VARI_INPUT[92][0][vf][vi] = LLR_CHECK_STORE[5][5][vf][vi];
				assign LLR_VARI_INPUT[92][1][vf][vi] = LLR_CHECK_STORE[30][5][vf][vi];
				assign LLR_VARI_INPUT[93][0][vf][vi] = LLR_CHECK_STORE[5][6][vf][vi];
				assign LLR_VARI_INPUT[93][1][vf][vi] = LLR_CHECK_STORE[17][6][vf][vi];
				assign LLR_VARI_INPUT[94][0][vf][vi] = LLR_CHECK_STORE[5][7][vf][vi];
				assign LLR_VARI_INPUT[94][1][vf][vi] = LLR_CHECK_STORE[23][6][vf][vi];
				assign LLR_VARI_INPUT[95][0][vf][vi] = LLR_CHECK_STORE[5][8][vf][vi];
				assign LLR_VARI_INPUT[95][1][vf][vi] = LLR_CHECK_STORE[28][5][vf][vi];
				assign LLR_VARI_INPUT[96][0][vf][vi] = LLR_CHECK_STORE[5][9][vf][vi];
				assign LLR_VARI_INPUT[96][1][vf][vi] = LLR_CHECK_STORE[25][5][vf][vi];
				assign LLR_VARI_INPUT[97][0][vf][vi] = LLR_CHECK_STORE[5][10][vf][vi];
				assign LLR_VARI_INPUT[97][1][vf][vi] = LLR_CHECK_STORE[31][6][vf][vi];
				assign LLR_VARI_INPUT[98][0][vf][vi] = LLR_CHECK_STORE[5][11][vf][vi];
				assign LLR_VARI_INPUT[98][1][vf][vi] = LLR_CHECK_STORE[22][7][vf][vi];
				assign LLR_VARI_INPUT[99][0][vf][vi] = LLR_CHECK_STORE[5][12][vf][vi];
				assign LLR_VARI_INPUT[99][1][vf][vi] = LLR_CHECK_STORE[19][5][vf][vi];
				assign LLR_VARI_INPUT[100][0][vf][vi] = LLR_CHECK_STORE[5][13][vf][vi];
				assign LLR_VARI_INPUT[100][1][vf][vi] = LLR_CHECK_STORE[26][5][vf][vi];
				assign LLR_VARI_INPUT[101][0][vf][vi] = LLR_CHECK_STORE[5][14][vf][vi];
				assign LLR_VARI_INPUT[101][1][vf][vi] = LLR_CHECK_STORE[29][6][vf][vi];
				assign LLR_VARI_INPUT[102][0][vf][vi] = LLR_CHECK_STORE[5][15][vf][vi];
				assign LLR_VARI_INPUT[102][1][vf][vi] = LLR_CHECK_STORE[18][6][vf][vi];
				assign LLR_VARI_INPUT[103][0][vf][vi] = LLR_CHECK_STORE[5][16][vf][vi];
				assign LLR_VARI_INPUT[103][1][vf][vi] = LLR_CHECK_STORE[30][6][vf][vi];
				assign LLR_VARI_INPUT[104][0][vf][vi] = LLR_CHECK_STORE[6][0][vf][vi];
				assign LLR_VARI_INPUT[104][1][vf][vi] = LLR_CHECK_STORE[30][7][vf][vi];
				assign LLR_VARI_INPUT[105][0][vf][vi] = LLR_CHECK_STORE[6][1][vf][vi];
				assign LLR_VARI_INPUT[105][1][vf][vi] = LLR_CHECK_STORE[24][6][vf][vi];
				assign LLR_VARI_INPUT[106][0][vf][vi] = LLR_CHECK_STORE[6][2][vf][vi];
				assign LLR_VARI_INPUT[106][1][vf][vi] = LLR_CHECK_STORE[26][6][vf][vi];
				assign LLR_VARI_INPUT[107][0][vf][vi] = LLR_CHECK_STORE[6][3][vf][vi];
				assign LLR_VARI_INPUT[107][1][vf][vi] = LLR_CHECK_STORE[21][7][vf][vi];
				assign LLR_VARI_INPUT[108][0][vf][vi] = LLR_CHECK_STORE[6][4][vf][vi];
				assign LLR_VARI_INPUT[108][1][vf][vi] = LLR_CHECK_STORE[29][7][vf][vi];
				assign LLR_VARI_INPUT[109][0][vf][vi] = LLR_CHECK_STORE[6][5][vf][vi];
				assign LLR_VARI_INPUT[109][1][vf][vi] = LLR_CHECK_STORE[25][6][vf][vi];
				assign LLR_VARI_INPUT[110][0][vf][vi] = LLR_CHECK_STORE[6][6][vf][vi];
				assign LLR_VARI_INPUT[110][1][vf][vi] = LLR_CHECK_STORE[17][7][vf][vi];
				assign LLR_VARI_INPUT[111][0][vf][vi] = LLR_CHECK_STORE[6][7][vf][vi];
				assign LLR_VARI_INPUT[111][1][vf][vi] = LLR_CHECK_STORE[24][7][vf][vi];
				assign LLR_VARI_INPUT[112][0][vf][vi] = LLR_CHECK_STORE[6][8][vf][vi];
				assign LLR_VARI_INPUT[112][1][vf][vi] = LLR_CHECK_STORE[26][7][vf][vi];
				assign LLR_VARI_INPUT[113][0][vf][vi] = LLR_CHECK_STORE[6][9][vf][vi];
				assign LLR_VARI_INPUT[113][1][vf][vi] = LLR_CHECK_STORE[19][6][vf][vi];
				assign LLR_VARI_INPUT[114][0][vf][vi] = LLR_CHECK_STORE[6][10][vf][vi];
				assign LLR_VARI_INPUT[114][1][vf][vi] = LLR_CHECK_STORE[23][7][vf][vi];
				assign LLR_VARI_INPUT[115][0][vf][vi] = LLR_CHECK_STORE[6][11][vf][vi];
				assign LLR_VARI_INPUT[115][1][vf][vi] = LLR_CHECK_STORE[27][6][vf][vi];
				assign LLR_VARI_INPUT[116][0][vf][vi] = LLR_CHECK_STORE[6][12][vf][vi];
				assign LLR_VARI_INPUT[116][1][vf][vi] = LLR_CHECK_STORE[25][7][vf][vi];
				assign LLR_VARI_INPUT[117][0][vf][vi] = LLR_CHECK_STORE[6][13][vf][vi];
				assign LLR_VARI_INPUT[117][1][vf][vi] = LLR_CHECK_STORE[22][8][vf][vi];
				assign LLR_VARI_INPUT[118][0][vf][vi] = LLR_CHECK_STORE[6][14][vf][vi];
				assign LLR_VARI_INPUT[118][1][vf][vi] = LLR_CHECK_STORE[18][7][vf][vi];
				assign LLR_VARI_INPUT[119][0][vf][vi] = LLR_CHECK_STORE[6][15][vf][vi];
				assign LLR_VARI_INPUT[119][1][vf][vi] = LLR_CHECK_STORE[28][6][vf][vi];
				assign LLR_VARI_INPUT[120][0][vf][vi] = LLR_CHECK_STORE[6][16][vf][vi];
				assign LLR_VARI_INPUT[120][1][vf][vi] = LLR_CHECK_STORE[20][6][vf][vi];
				assign LLR_VARI_INPUT[121][0][vf][vi] = LLR_CHECK_STORE[7][0][vf][vi];
				assign LLR_VARI_INPUT[121][1][vf][vi] = LLR_CHECK_STORE[26][8][vf][vi];
				assign LLR_VARI_INPUT[122][0][vf][vi] = LLR_CHECK_STORE[7][1][vf][vi];
				assign LLR_VARI_INPUT[122][1][vf][vi] = LLR_CHECK_STORE[17][8][vf][vi];
				assign LLR_VARI_INPUT[123][0][vf][vi] = LLR_CHECK_STORE[7][2][vf][vi];
				assign LLR_VARI_INPUT[123][1][vf][vi] = LLR_CHECK_STORE[21][8][vf][vi];
				assign LLR_VARI_INPUT[124][0][vf][vi] = LLR_CHECK_STORE[7][3][vf][vi];
				assign LLR_VARI_INPUT[124][1][vf][vi] = LLR_CHECK_STORE[19][7][vf][vi];
				assign LLR_VARI_INPUT[125][0][vf][vi] = LLR_CHECK_STORE[7][4][vf][vi];
				assign LLR_VARI_INPUT[125][1][vf][vi] = LLR_CHECK_STORE[25][8][vf][vi];
				assign LLR_VARI_INPUT[126][0][vf][vi] = LLR_CHECK_STORE[7][5][vf][vi];
				assign LLR_VARI_INPUT[126][1][vf][vi] = LLR_CHECK_STORE[19][8][vf][vi];
				assign LLR_VARI_INPUT[127][0][vf][vi] = LLR_CHECK_STORE[7][6][vf][vi];
				assign LLR_VARI_INPUT[127][1][vf][vi] = LLR_CHECK_STORE[29][8][vf][vi];
				assign LLR_VARI_INPUT[128][0][vf][vi] = LLR_CHECK_STORE[7][7][vf][vi];
				assign LLR_VARI_INPUT[128][1][vf][vi] = LLR_CHECK_STORE[28][7][vf][vi];
				assign LLR_VARI_INPUT[129][0][vf][vi] = LLR_CHECK_STORE[7][8][vf][vi];
				assign LLR_VARI_INPUT[129][1][vf][vi] = LLR_CHECK_STORE[20][7][vf][vi];
				assign LLR_VARI_INPUT[130][0][vf][vi] = LLR_CHECK_STORE[7][9][vf][vi];
				assign LLR_VARI_INPUT[130][1][vf][vi] = LLR_CHECK_STORE[23][8][vf][vi];
				assign LLR_VARI_INPUT[131][0][vf][vi] = LLR_CHECK_STORE[7][10][vf][vi];
				assign LLR_VARI_INPUT[131][1][vf][vi] = LLR_CHECK_STORE[22][9][vf][vi];
				assign LLR_VARI_INPUT[132][0][vf][vi] = LLR_CHECK_STORE[7][11][vf][vi];
				assign LLR_VARI_INPUT[132][1][vf][vi] = LLR_CHECK_STORE[30][8][vf][vi];
				assign LLR_VARI_INPUT[133][0][vf][vi] = LLR_CHECK_STORE[7][12][vf][vi];
				assign LLR_VARI_INPUT[133][1][vf][vi] = LLR_CHECK_STORE[27][7][vf][vi];
				assign LLR_VARI_INPUT[134][0][vf][vi] = LLR_CHECK_STORE[7][13][vf][vi];
				assign LLR_VARI_INPUT[134][1][vf][vi] = LLR_CHECK_STORE[23][9][vf][vi];
				assign LLR_VARI_INPUT[135][0][vf][vi] = LLR_CHECK_STORE[7][14][vf][vi];
				assign LLR_VARI_INPUT[135][1][vf][vi] = LLR_CHECK_STORE[18][8][vf][vi];
				assign LLR_VARI_INPUT[136][0][vf][vi] = LLR_CHECK_STORE[7][15][vf][vi];
				assign LLR_VARI_INPUT[136][1][vf][vi] = LLR_CHECK_STORE[24][8][vf][vi];
				assign LLR_VARI_INPUT[137][0][vf][vi] = LLR_CHECK_STORE[7][16][vf][vi];
				assign LLR_VARI_INPUT[137][1][vf][vi] = LLR_CHECK_STORE[31][7][vf][vi];
				assign LLR_VARI_INPUT[138][0][vf][vi] = LLR_CHECK_STORE[8][0][vf][vi];
				assign LLR_VARI_INPUT[138][1][vf][vi] = LLR_CHECK_STORE[27][8][vf][vi];
				assign LLR_VARI_INPUT[139][0][vf][vi] = LLR_CHECK_STORE[8][1][vf][vi];
				assign LLR_VARI_INPUT[139][1][vf][vi] = LLR_CHECK_STORE[21][9][vf][vi];
				assign LLR_VARI_INPUT[140][0][vf][vi] = LLR_CHECK_STORE[8][2][vf][vi];
				assign LLR_VARI_INPUT[140][1][vf][vi] = LLR_CHECK_STORE[30][9][vf][vi];
				assign LLR_VARI_INPUT[141][0][vf][vi] = LLR_CHECK_STORE[8][3][vf][vi];
				assign LLR_VARI_INPUT[141][1][vf][vi] = LLR_CHECK_STORE[28][8][vf][vi];
				assign LLR_VARI_INPUT[142][0][vf][vi] = LLR_CHECK_STORE[8][4][vf][vi];
				assign LLR_VARI_INPUT[142][1][vf][vi] = LLR_CHECK_STORE[18][9][vf][vi];
				assign LLR_VARI_INPUT[143][0][vf][vi] = LLR_CHECK_STORE[8][5][vf][vi];
				assign LLR_VARI_INPUT[143][1][vf][vi] = LLR_CHECK_STORE[17][9][vf][vi];
				assign LLR_VARI_INPUT[144][0][vf][vi] = LLR_CHECK_STORE[8][6][vf][vi];
				assign LLR_VARI_INPUT[144][1][vf][vi] = LLR_CHECK_STORE[23][10][vf][vi];
				assign LLR_VARI_INPUT[145][0][vf][vi] = LLR_CHECK_STORE[8][7][vf][vi];
				assign LLR_VARI_INPUT[145][1][vf][vi] = LLR_CHECK_STORE[19][9][vf][vi];
				assign LLR_VARI_INPUT[146][0][vf][vi] = LLR_CHECK_STORE[8][8][vf][vi];
				assign LLR_VARI_INPUT[146][1][vf][vi] = LLR_CHECK_STORE[28][9][vf][vi];
				assign LLR_VARI_INPUT[147][0][vf][vi] = LLR_CHECK_STORE[8][9][vf][vi];
				assign LLR_VARI_INPUT[147][1][vf][vi] = LLR_CHECK_STORE[31][8][vf][vi];
				assign LLR_VARI_INPUT[148][0][vf][vi] = LLR_CHECK_STORE[8][10][vf][vi];
				assign LLR_VARI_INPUT[148][1][vf][vi] = LLR_CHECK_STORE[31][9][vf][vi];
				assign LLR_VARI_INPUT[149][0][vf][vi] = LLR_CHECK_STORE[8][11][vf][vi];
				assign LLR_VARI_INPUT[149][1][vf][vi] = LLR_CHECK_STORE[24][9][vf][vi];
				assign LLR_VARI_INPUT[150][0][vf][vi] = LLR_CHECK_STORE[8][12][vf][vi];
				assign LLR_VARI_INPUT[150][1][vf][vi] = LLR_CHECK_STORE[20][8][vf][vi];
				assign LLR_VARI_INPUT[151][0][vf][vi] = LLR_CHECK_STORE[8][13][vf][vi];
				assign LLR_VARI_INPUT[151][1][vf][vi] = LLR_CHECK_STORE[22][10][vf][vi];
				assign LLR_VARI_INPUT[152][0][vf][vi] = LLR_CHECK_STORE[8][14][vf][vi];
				assign LLR_VARI_INPUT[152][1][vf][vi] = LLR_CHECK_STORE[25][9][vf][vi];
				assign LLR_VARI_INPUT[153][0][vf][vi] = LLR_CHECK_STORE[8][15][vf][vi];
				assign LLR_VARI_INPUT[153][1][vf][vi] = LLR_CHECK_STORE[29][9][vf][vi];
				assign LLR_VARI_INPUT[154][0][vf][vi] = LLR_CHECK_STORE[8][16][vf][vi];
				assign LLR_VARI_INPUT[154][1][vf][vi] = LLR_CHECK_STORE[26][9][vf][vi];
				assign LLR_VARI_INPUT[155][0][vf][vi] = LLR_CHECK_STORE[9][0][vf][vi];
				assign LLR_VARI_INPUT[155][1][vf][vi] = LLR_CHECK_STORE[30][10][vf][vi];
				assign LLR_VARI_INPUT[156][0][vf][vi] = LLR_CHECK_STORE[9][1][vf][vi];
				assign LLR_VARI_INPUT[156][1][vf][vi] = LLR_CHECK_STORE[22][11][vf][vi];
				assign LLR_VARI_INPUT[157][0][vf][vi] = LLR_CHECK_STORE[9][2][vf][vi];
				assign LLR_VARI_INPUT[157][1][vf][vi] = LLR_CHECK_STORE[23][11][vf][vi];
				assign LLR_VARI_INPUT[158][0][vf][vi] = LLR_CHECK_STORE[9][3][vf][vi];
				assign LLR_VARI_INPUT[158][1][vf][vi] = LLR_CHECK_STORE[28][10][vf][vi];
				assign LLR_VARI_INPUT[159][0][vf][vi] = LLR_CHECK_STORE[9][4][vf][vi];
				assign LLR_VARI_INPUT[159][1][vf][vi] = LLR_CHECK_STORE[31][10][vf][vi];
				assign LLR_VARI_INPUT[160][0][vf][vi] = LLR_CHECK_STORE[9][5][vf][vi];
				assign LLR_VARI_INPUT[160][1][vf][vi] = LLR_CHECK_STORE[24][10][vf][vi];
				assign LLR_VARI_INPUT[161][0][vf][vi] = LLR_CHECK_STORE[9][6][vf][vi];
				assign LLR_VARI_INPUT[161][1][vf][vi] = LLR_CHECK_STORE[17][10][vf][vi];
				assign LLR_VARI_INPUT[162][0][vf][vi] = LLR_CHECK_STORE[9][7][vf][vi];
				assign LLR_VARI_INPUT[162][1][vf][vi] = LLR_CHECK_STORE[27][9][vf][vi];
				assign LLR_VARI_INPUT[163][0][vf][vi] = LLR_CHECK_STORE[9][8][vf][vi];
				assign LLR_VARI_INPUT[163][1][vf][vi] = LLR_CHECK_STORE[19][10][vf][vi];
				assign LLR_VARI_INPUT[164][0][vf][vi] = LLR_CHECK_STORE[9][9][vf][vi];
				assign LLR_VARI_INPUT[164][1][vf][vi] = LLR_CHECK_STORE[20][9][vf][vi];
				assign LLR_VARI_INPUT[165][0][vf][vi] = LLR_CHECK_STORE[9][10][vf][vi];
				assign LLR_VARI_INPUT[165][1][vf][vi] = LLR_CHECK_STORE[21][10][vf][vi];
				assign LLR_VARI_INPUT[166][0][vf][vi] = LLR_CHECK_STORE[9][11][vf][vi];
				assign LLR_VARI_INPUT[166][1][vf][vi] = LLR_CHECK_STORE[17][11][vf][vi];
				assign LLR_VARI_INPUT[167][0][vf][vi] = LLR_CHECK_STORE[9][12][vf][vi];
				assign LLR_VARI_INPUT[167][1][vf][vi] = LLR_CHECK_STORE[30][11][vf][vi];
				assign LLR_VARI_INPUT[168][0][vf][vi] = LLR_CHECK_STORE[9][13][vf][vi];
				assign LLR_VARI_INPUT[168][1][vf][vi] = LLR_CHECK_STORE[26][10][vf][vi];
				assign LLR_VARI_INPUT[169][0][vf][vi] = LLR_CHECK_STORE[9][14][vf][vi];
				assign LLR_VARI_INPUT[169][1][vf][vi] = LLR_CHECK_STORE[25][10][vf][vi];
				assign LLR_VARI_INPUT[170][0][vf][vi] = LLR_CHECK_STORE[9][15][vf][vi];
				assign LLR_VARI_INPUT[170][1][vf][vi] = LLR_CHECK_STORE[29][10][vf][vi];
				assign LLR_VARI_INPUT[171][0][vf][vi] = LLR_CHECK_STORE[9][16][vf][vi];
				assign LLR_VARI_INPUT[171][1][vf][vi] = LLR_CHECK_STORE[18][10][vf][vi];
				assign LLR_VARI_INPUT[172][0][vf][vi] = LLR_CHECK_STORE[10][0][vf][vi];
				assign LLR_VARI_INPUT[172][1][vf][vi] = LLR_CHECK_STORE[27][10][vf][vi];
				assign LLR_VARI_INPUT[173][0][vf][vi] = LLR_CHECK_STORE[10][1][vf][vi];
				assign LLR_VARI_INPUT[173][1][vf][vi] = LLR_CHECK_STORE[25][11][vf][vi];
				assign LLR_VARI_INPUT[174][0][vf][vi] = LLR_CHECK_STORE[10][2][vf][vi];
				assign LLR_VARI_INPUT[174][1][vf][vi] = LLR_CHECK_STORE[28][11][vf][vi];
				assign LLR_VARI_INPUT[175][0][vf][vi] = LLR_CHECK_STORE[10][3][vf][vi];
				assign LLR_VARI_INPUT[175][1][vf][vi] = LLR_CHECK_STORE[19][11][vf][vi];
				assign LLR_VARI_INPUT[176][0][vf][vi] = LLR_CHECK_STORE[10][4][vf][vi];
				assign LLR_VARI_INPUT[176][1][vf][vi] = LLR_CHECK_STORE[20][10][vf][vi];
				assign LLR_VARI_INPUT[177][0][vf][vi] = LLR_CHECK_STORE[10][5][vf][vi];
				assign LLR_VARI_INPUT[177][1][vf][vi] = LLR_CHECK_STORE[26][11][vf][vi];
				assign LLR_VARI_INPUT[178][0][vf][vi] = LLR_CHECK_STORE[10][6][vf][vi];
				assign LLR_VARI_INPUT[178][1][vf][vi] = LLR_CHECK_STORE[28][12][vf][vi];
				assign LLR_VARI_INPUT[179][0][vf][vi] = LLR_CHECK_STORE[10][7][vf][vi];
				assign LLR_VARI_INPUT[179][1][vf][vi] = LLR_CHECK_STORE[24][11][vf][vi];
				assign LLR_VARI_INPUT[180][0][vf][vi] = LLR_CHECK_STORE[10][8][vf][vi];
				assign LLR_VARI_INPUT[180][1][vf][vi] = LLR_CHECK_STORE[22][12][vf][vi];
				assign LLR_VARI_INPUT[181][0][vf][vi] = LLR_CHECK_STORE[10][9][vf][vi];
				assign LLR_VARI_INPUT[181][1][vf][vi] = LLR_CHECK_STORE[30][12][vf][vi];
				assign LLR_VARI_INPUT[182][0][vf][vi] = LLR_CHECK_STORE[10][10][vf][vi];
				assign LLR_VARI_INPUT[182][1][vf][vi] = LLR_CHECK_STORE[23][12][vf][vi];
				assign LLR_VARI_INPUT[183][0][vf][vi] = LLR_CHECK_STORE[10][11][vf][vi];
				assign LLR_VARI_INPUT[183][1][vf][vi] = LLR_CHECK_STORE[21][11][vf][vi];
				assign LLR_VARI_INPUT[184][0][vf][vi] = LLR_CHECK_STORE[10][12][vf][vi];
				assign LLR_VARI_INPUT[184][1][vf][vi] = LLR_CHECK_STORE[26][12][vf][vi];
				assign LLR_VARI_INPUT[185][0][vf][vi] = LLR_CHECK_STORE[10][13][vf][vi];
				assign LLR_VARI_INPUT[185][1][vf][vi] = LLR_CHECK_STORE[29][11][vf][vi];
				assign LLR_VARI_INPUT[186][0][vf][vi] = LLR_CHECK_STORE[10][14][vf][vi];
				assign LLR_VARI_INPUT[186][1][vf][vi] = LLR_CHECK_STORE[17][12][vf][vi];
				assign LLR_VARI_INPUT[187][0][vf][vi] = LLR_CHECK_STORE[10][15][vf][vi];
				assign LLR_VARI_INPUT[187][1][vf][vi] = LLR_CHECK_STORE[20][11][vf][vi];
				assign LLR_VARI_INPUT[188][0][vf][vi] = LLR_CHECK_STORE[10][16][vf][vi];
				assign LLR_VARI_INPUT[188][1][vf][vi] = LLR_CHECK_STORE[18][11][vf][vi];
				assign LLR_VARI_INPUT[189][0][vf][vi] = LLR_CHECK_STORE[11][0][vf][vi];
				assign LLR_VARI_INPUT[189][1][vf][vi] = LLR_CHECK_STORE[31][11][vf][vi];
				assign LLR_VARI_INPUT[190][0][vf][vi] = LLR_CHECK_STORE[11][1][vf][vi];
				assign LLR_VARI_INPUT[190][1][vf][vi] = LLR_CHECK_STORE[31][12][vf][vi];
				assign LLR_VARI_INPUT[191][0][vf][vi] = LLR_CHECK_STORE[11][2][vf][vi];
				assign LLR_VARI_INPUT[191][1][vf][vi] = LLR_CHECK_STORE[20][12][vf][vi];
				assign LLR_VARI_INPUT[192][0][vf][vi] = LLR_CHECK_STORE[11][3][vf][vi];
				assign LLR_VARI_INPUT[192][1][vf][vi] = LLR_CHECK_STORE[21][12][vf][vi];
				assign LLR_VARI_INPUT[193][0][vf][vi] = LLR_CHECK_STORE[11][4][vf][vi];
				assign LLR_VARI_INPUT[193][1][vf][vi] = LLR_CHECK_STORE[23][13][vf][vi];
				assign LLR_VARI_INPUT[194][0][vf][vi] = LLR_CHECK_STORE[11][5][vf][vi];
				assign LLR_VARI_INPUT[194][1][vf][vi] = LLR_CHECK_STORE[18][12][vf][vi];
				assign LLR_VARI_INPUT[195][0][vf][vi] = LLR_CHECK_STORE[11][6][vf][vi];
				assign LLR_VARI_INPUT[195][1][vf][vi] = LLR_CHECK_STORE[28][13][vf][vi];
				assign LLR_VARI_INPUT[196][0][vf][vi] = LLR_CHECK_STORE[11][7][vf][vi];
				assign LLR_VARI_INPUT[196][1][vf][vi] = LLR_CHECK_STORE[22][13][vf][vi];
				assign LLR_VARI_INPUT[197][0][vf][vi] = LLR_CHECK_STORE[11][8][vf][vi];
				assign LLR_VARI_INPUT[197][1][vf][vi] = LLR_CHECK_STORE[25][12][vf][vi];
				assign LLR_VARI_INPUT[198][0][vf][vi] = LLR_CHECK_STORE[11][9][vf][vi];
				assign LLR_VARI_INPUT[198][1][vf][vi] = LLR_CHECK_STORE[17][13][vf][vi];
				assign LLR_VARI_INPUT[199][0][vf][vi] = LLR_CHECK_STORE[11][10][vf][vi];
				assign LLR_VARI_INPUT[199][1][vf][vi] = LLR_CHECK_STORE[18][13][vf][vi];
				assign LLR_VARI_INPUT[200][0][vf][vi] = LLR_CHECK_STORE[11][11][vf][vi];
				assign LLR_VARI_INPUT[200][1][vf][vi] = LLR_CHECK_STORE[29][12][vf][vi];
				assign LLR_VARI_INPUT[201][0][vf][vi] = LLR_CHECK_STORE[11][12][vf][vi];
				assign LLR_VARI_INPUT[201][1][vf][vi] = LLR_CHECK_STORE[27][11][vf][vi];
				assign LLR_VARI_INPUT[202][0][vf][vi] = LLR_CHECK_STORE[11][13][vf][vi];
				assign LLR_VARI_INPUT[202][1][vf][vi] = LLR_CHECK_STORE[30][13][vf][vi];
				assign LLR_VARI_INPUT[203][0][vf][vi] = LLR_CHECK_STORE[11][14][vf][vi];
				assign LLR_VARI_INPUT[203][1][vf][vi] = LLR_CHECK_STORE[24][12][vf][vi];
				assign LLR_VARI_INPUT[204][0][vf][vi] = LLR_CHECK_STORE[11][15][vf][vi];
				assign LLR_VARI_INPUT[204][1][vf][vi] = LLR_CHECK_STORE[19][12][vf][vi];
				assign LLR_VARI_INPUT[205][0][vf][vi] = LLR_CHECK_STORE[11][16][vf][vi];
				assign LLR_VARI_INPUT[205][1][vf][vi] = LLR_CHECK_STORE[26][13][vf][vi];
				assign LLR_VARI_INPUT[206][0][vf][vi] = LLR_CHECK_STORE[12][1][vf][vi];
				assign LLR_VARI_INPUT[206][1][vf][vi] = LLR_CHECK_STORE[24][13][vf][vi];
				assign LLR_VARI_INPUT[207][0][vf][vi] = LLR_CHECK_STORE[12][2][vf][vi];
				assign LLR_VARI_INPUT[207][1][vf][vi] = LLR_CHECK_STORE[17][14][vf][vi];
				assign LLR_VARI_INPUT[208][0][vf][vi] = LLR_CHECK_STORE[12][3][vf][vi];
				assign LLR_VARI_INPUT[208][1][vf][vi] = LLR_CHECK_STORE[21][13][vf][vi];
				assign LLR_VARI_INPUT[209][0][vf][vi] = LLR_CHECK_STORE[12][4][vf][vi];
				assign LLR_VARI_INPUT[209][1][vf][vi] = LLR_CHECK_STORE[31][13][vf][vi];
				assign LLR_VARI_INPUT[210][0][vf][vi] = LLR_CHECK_STORE[12][5][vf][vi];
				assign LLR_VARI_INPUT[210][1][vf][vi] = LLR_CHECK_STORE[19][13][vf][vi];
				assign LLR_VARI_INPUT[211][0][vf][vi] = LLR_CHECK_STORE[12][6][vf][vi];
				assign LLR_VARI_INPUT[211][1][vf][vi] = LLR_CHECK_STORE[26][14][vf][vi];
				assign LLR_VARI_INPUT[212][0][vf][vi] = LLR_CHECK_STORE[12][7][vf][vi];
				assign LLR_VARI_INPUT[212][1][vf][vi] = LLR_CHECK_STORE[27][12][vf][vi];
				assign LLR_VARI_INPUT[213][0][vf][vi] = LLR_CHECK_STORE[12][8][vf][vi];
				assign LLR_VARI_INPUT[213][1][vf][vi] = LLR_CHECK_STORE[24][14][vf][vi];
				assign LLR_VARI_INPUT[214][0][vf][vi] = LLR_CHECK_STORE[12][9][vf][vi];
				assign LLR_VARI_INPUT[214][1][vf][vi] = LLR_CHECK_STORE[18][14][vf][vi];
				assign LLR_VARI_INPUT[215][0][vf][vi] = LLR_CHECK_STORE[12][10][vf][vi];
				assign LLR_VARI_INPUT[215][1][vf][vi] = LLR_CHECK_STORE[25][13][vf][vi];
				assign LLR_VARI_INPUT[216][0][vf][vi] = LLR_CHECK_STORE[12][11][vf][vi];
				assign LLR_VARI_INPUT[216][1][vf][vi] = LLR_CHECK_STORE[30][14][vf][vi];
				assign LLR_VARI_INPUT[217][0][vf][vi] = LLR_CHECK_STORE[12][12][vf][vi];
				assign LLR_VARI_INPUT[217][1][vf][vi] = LLR_CHECK_STORE[22][14][vf][vi];
				assign LLR_VARI_INPUT[218][0][vf][vi] = LLR_CHECK_STORE[12][13][vf][vi];
				assign LLR_VARI_INPUT[218][1][vf][vi] = LLR_CHECK_STORE[23][14][vf][vi];
				assign LLR_VARI_INPUT[219][0][vf][vi] = LLR_CHECK_STORE[12][14][vf][vi];
				assign LLR_VARI_INPUT[219][1][vf][vi] = LLR_CHECK_STORE[25][14][vf][vi];
				assign LLR_VARI_INPUT[220][0][vf][vi] = LLR_CHECK_STORE[12][15][vf][vi];
				assign LLR_VARI_INPUT[220][1][vf][vi] = LLR_CHECK_STORE[29][13][vf][vi];
				assign LLR_VARI_INPUT[221][0][vf][vi] = LLR_CHECK_STORE[12][16][vf][vi];
				assign LLR_VARI_INPUT[221][1][vf][vi] = LLR_CHECK_STORE[20][13][vf][vi];
				assign LLR_VARI_INPUT[222][0][vf][vi] = LLR_CHECK_STORE[13][0][vf][vi];
				assign LLR_VARI_INPUT[222][1][vf][vi] = LLR_CHECK_STORE[31][14][vf][vi];
				assign LLR_VARI_INPUT[223][0][vf][vi] = LLR_CHECK_STORE[13][1][vf][vi];
				assign LLR_VARI_INPUT[223][1][vf][vi] = LLR_CHECK_STORE[25][15][vf][vi];
				assign LLR_VARI_INPUT[224][0][vf][vi] = LLR_CHECK_STORE[13][2][vf][vi];
				assign LLR_VARI_INPUT[224][1][vf][vi] = LLR_CHECK_STORE[30][15][vf][vi];
				assign LLR_VARI_INPUT[225][0][vf][vi] = LLR_CHECK_STORE[13][3][vf][vi];
				assign LLR_VARI_INPUT[225][1][vf][vi] = LLR_CHECK_STORE[28][14][vf][vi];
				assign LLR_VARI_INPUT[226][0][vf][vi] = LLR_CHECK_STORE[13][4][vf][vi];
				assign LLR_VARI_INPUT[226][1][vf][vi] = LLR_CHECK_STORE[27][13][vf][vi];
				assign LLR_VARI_INPUT[227][0][vf][vi] = LLR_CHECK_STORE[13][5][vf][vi];
				assign LLR_VARI_INPUT[227][1][vf][vi] = LLR_CHECK_STORE[29][14][vf][vi];
				assign LLR_VARI_INPUT[228][0][vf][vi] = LLR_CHECK_STORE[13][6][vf][vi];
				assign LLR_VARI_INPUT[228][1][vf][vi] = LLR_CHECK_STORE[22][15][vf][vi];
				assign LLR_VARI_INPUT[229][0][vf][vi] = LLR_CHECK_STORE[13][7][vf][vi];
				assign LLR_VARI_INPUT[229][1][vf][vi] = LLR_CHECK_STORE[20][14][vf][vi];
				assign LLR_VARI_INPUT[230][0][vf][vi] = LLR_CHECK_STORE[13][8][vf][vi];
				assign LLR_VARI_INPUT[230][1][vf][vi] = LLR_CHECK_STORE[19][14][vf][vi];
				assign LLR_VARI_INPUT[231][0][vf][vi] = LLR_CHECK_STORE[13][9][vf][vi];
				assign LLR_VARI_INPUT[231][1][vf][vi] = LLR_CHECK_STORE[18][15][vf][vi];
				assign LLR_VARI_INPUT[232][0][vf][vi] = LLR_CHECK_STORE[13][10][vf][vi];
				assign LLR_VARI_INPUT[232][1][vf][vi] = LLR_CHECK_STORE[29][15][vf][vi];
				assign LLR_VARI_INPUT[233][0][vf][vi] = LLR_CHECK_STORE[13][11][vf][vi];
				assign LLR_VARI_INPUT[233][1][vf][vi] = LLR_CHECK_STORE[19][15][vf][vi];
				assign LLR_VARI_INPUT[234][0][vf][vi] = LLR_CHECK_STORE[13][12][vf][vi];
				assign LLR_VARI_INPUT[234][1][vf][vi] = LLR_CHECK_STORE[23][15][vf][vi];
				assign LLR_VARI_INPUT[235][0][vf][vi] = LLR_CHECK_STORE[13][13][vf][vi];
				assign LLR_VARI_INPUT[235][1][vf][vi] = LLR_CHECK_STORE[24][15][vf][vi];
				assign LLR_VARI_INPUT[236][0][vf][vi] = LLR_CHECK_STORE[13][14][vf][vi];
				assign LLR_VARI_INPUT[236][1][vf][vi] = LLR_CHECK_STORE[21][14][vf][vi];
				assign LLR_VARI_INPUT[237][0][vf][vi] = LLR_CHECK_STORE[13][15][vf][vi];
				assign LLR_VARI_INPUT[237][1][vf][vi] = LLR_CHECK_STORE[17][15][vf][vi];
				assign LLR_VARI_INPUT[238][0][vf][vi] = LLR_CHECK_STORE[13][16][vf][vi];
				assign LLR_VARI_INPUT[238][1][vf][vi] = LLR_CHECK_STORE[26][15][vf][vi];
				assign LLR_VARI_INPUT[239][0][vf][vi] = LLR_CHECK_STORE[14][0][vf][vi];
				assign LLR_VARI_INPUT[239][1][vf][vi] = LLR_CHECK_STORE[22][16][vf][vi];
				assign LLR_VARI_INPUT[240][0][vf][vi] = LLR_CHECK_STORE[14][1][vf][vi];
				assign LLR_VARI_INPUT[240][1][vf][vi] = LLR_CHECK_STORE[27][14][vf][vi];
				assign LLR_VARI_INPUT[241][0][vf][vi] = LLR_CHECK_STORE[14][2][vf][vi];
				assign LLR_VARI_INPUT[241][1][vf][vi] = LLR_CHECK_STORE[21][15][vf][vi];
				assign LLR_VARI_INPUT[242][0][vf][vi] = LLR_CHECK_STORE[14][3][vf][vi];
				assign LLR_VARI_INPUT[242][1][vf][vi] = LLR_CHECK_STORE[19][16][vf][vi];
				assign LLR_VARI_INPUT[243][0][vf][vi] = LLR_CHECK_STORE[14][4][vf][vi];
				assign LLR_VARI_INPUT[243][1][vf][vi] = LLR_CHECK_STORE[31][15][vf][vi];
				assign LLR_VARI_INPUT[244][0][vf][vi] = LLR_CHECK_STORE[14][5][vf][vi];
				assign LLR_VARI_INPUT[244][1][vf][vi] = LLR_CHECK_STORE[17][16][vf][vi];
				assign LLR_VARI_INPUT[245][0][vf][vi] = LLR_CHECK_STORE[14][6][vf][vi];
				assign LLR_VARI_INPUT[245][1][vf][vi] = LLR_CHECK_STORE[24][16][vf][vi];
				assign LLR_VARI_INPUT[246][0][vf][vi] = LLR_CHECK_STORE[14][7][vf][vi];
				assign LLR_VARI_INPUT[246][1][vf][vi] = LLR_CHECK_STORE[26][16][vf][vi];
				assign LLR_VARI_INPUT[247][0][vf][vi] = LLR_CHECK_STORE[14][8][vf][vi];
				assign LLR_VARI_INPUT[247][1][vf][vi] = LLR_CHECK_STORE[16][11][vf][vi];
				assign LLR_VARI_INPUT[248][0][vf][vi] = LLR_CHECK_STORE[14][9][vf][vi];
				assign LLR_VARI_INPUT[248][1][vf][vi] = LLR_CHECK_STORE[18][16][vf][vi];
				assign LLR_VARI_INPUT[249][0][vf][vi] = LLR_CHECK_STORE[14][10][vf][vi];
				assign LLR_VARI_INPUT[249][1][vf][vi] = LLR_CHECK_STORE[23][16][vf][vi];
				assign LLR_VARI_INPUT[250][0][vf][vi] = LLR_CHECK_STORE[14][11][vf][vi];
				assign LLR_VARI_INPUT[250][1][vf][vi] = LLR_CHECK_STORE[31][16][vf][vi];
				assign LLR_VARI_INPUT[251][0][vf][vi] = LLR_CHECK_STORE[14][12][vf][vi];
				assign LLR_VARI_INPUT[251][1][vf][vi] = LLR_CHECK_STORE[28][15][vf][vi];
				assign LLR_VARI_INPUT[252][0][vf][vi] = LLR_CHECK_STORE[14][13][vf][vi];
				assign LLR_VARI_INPUT[252][1][vf][vi] = LLR_CHECK_STORE[30][16][vf][vi];
				assign LLR_VARI_INPUT[253][0][vf][vi] = LLR_CHECK_STORE[14][14][vf][vi];
				assign LLR_VARI_INPUT[253][1][vf][vi] = LLR_CHECK_STORE[29][16][vf][vi];
				assign LLR_VARI_INPUT[254][0][vf][vi] = LLR_CHECK_STORE[14][15][vf][vi];
				assign LLR_VARI_INPUT[254][1][vf][vi] = LLR_CHECK_STORE[20][15][vf][vi];
				assign LLR_VARI_INPUT[255][0][vf][vi] = LLR_CHECK_STORE[14][16][vf][vi];
				assign LLR_VARI_INPUT[255][1][vf][vi] = LLR_CHECK_STORE[25][16][vf][vi];
				assign LLR_VARI_INPUT[256][0][vf][vi] = LLR_CHECK_STORE[15][7][vf][vi];
				assign LLR_VARI_INPUT[256][1][vf][vi] = LLR_CHECK_STORE[27][15][vf][vi];
				assign LLR_VARI_INPUT[257][0][vf][vi] = LLR_CHECK_STORE[0][6][vf][vi];
				assign LLR_VARI_INPUT[257][1][vf][vi] = LLR_CHECK_STORE[1][16][vf][vi];
				assign LLR_VARI_INPUT[258][0][vf][vi] = LLR_CHECK_STORE[15][8][vf][vi];
				assign LLR_VARI_INPUT[258][1][vf][vi] = LLR_CHECK_STORE[18][17][vf][vi];
				assign LLR_VARI_INPUT[259][0][vf][vi] = LLR_CHECK_STORE[15][9][vf][vi];
				assign LLR_VARI_INPUT[259][1][vf][vi] = LLR_CHECK_STORE[30][17][vf][vi];
				assign LLR_VARI_INPUT[260][0][vf][vi] = LLR_CHECK_STORE[15][10][vf][vi];
				assign LLR_VARI_INPUT[260][1][vf][vi] = LLR_CHECK_STORE[21][16][vf][vi];
				assign LLR_VARI_INPUT[261][0][vf][vi] = LLR_CHECK_STORE[15][11][vf][vi];
				assign LLR_VARI_INPUT[261][1][vf][vi] = LLR_CHECK_STORE[27][16][vf][vi];
				assign LLR_VARI_INPUT[262][0][vf][vi] = LLR_CHECK_STORE[15][12][vf][vi];
				assign LLR_VARI_INPUT[262][1][vf][vi] = LLR_CHECK_STORE[26][17][vf][vi];
				assign LLR_VARI_INPUT[263][0][vf][vi] = LLR_CHECK_STORE[15][13][vf][vi];
				assign LLR_VARI_INPUT[263][1][vf][vi] = LLR_CHECK_STORE[29][17][vf][vi];
				assign LLR_VARI_INPUT[264][0][vf][vi] = LLR_CHECK_STORE[15][14][vf][vi];
				assign LLR_VARI_INPUT[264][1][vf][vi] = LLR_CHECK_STORE[17][17][vf][vi];
				assign LLR_VARI_INPUT[265][0][vf][vi] = LLR_CHECK_STORE[15][15][vf][vi];
				assign LLR_VARI_INPUT[265][1][vf][vi] = LLR_CHECK_STORE[28][16][vf][vi];
				assign LLR_VARI_INPUT[266][0][vf][vi] = LLR_CHECK_STORE[15][16][vf][vi];
				assign LLR_VARI_INPUT[266][1][vf][vi] = LLR_CHECK_STORE[22][17][vf][vi];
				assign LLR_VARI_INPUT[267][0][vf][vi] = LLR_CHECK_STORE[0][7][vf][vi];
				assign LLR_VARI_INPUT[267][1][vf][vi] = LLR_CHECK_STORE[3][17][vf][vi];
				assign LLR_VARI_INPUT[268][0][vf][vi] = LLR_CHECK_STORE[16][12][vf][vi];
				assign LLR_VARI_INPUT[268][1][vf][vi] = LLR_CHECK_STORE[21][17][vf][vi];
				assign LLR_VARI_INPUT[269][0][vf][vi] = LLR_CHECK_STORE[15][17][vf][vi];
				assign LLR_VARI_INPUT[269][1][vf][vi] = LLR_CHECK_STORE[25][17][vf][vi];
				assign LLR_VARI_INPUT[270][0][vf][vi] = LLR_CHECK_STORE[0][8][vf][vi];
				assign LLR_VARI_INPUT[270][1][vf][vi] = LLR_CHECK_STORE[4][17][vf][vi];
				assign LLR_VARI_INPUT[271][0][vf][vi] = LLR_CHECK_STORE[16][13][vf][vi];
				assign LLR_VARI_INPUT[271][1][vf][vi] = LLR_CHECK_STORE[19][17][vf][vi];
				assign LLR_VARI_INPUT[272][0][vf][vi] = LLR_CHECK_STORE[16][14][vf][vi];
				assign LLR_VARI_INPUT[272][1][vf][vi] = LLR_CHECK_STORE[23][17][vf][vi];
				assign LLR_VARI_INPUT[273][0][vf][vi] = LLR_CHECK_STORE[16][15][vf][vi];
				assign LLR_VARI_INPUT[273][1][vf][vi] = LLR_CHECK_STORE[20][16][vf][vi];
				assign LLR_VARI_INPUT[274][0][vf][vi] = LLR_CHECK_STORE[16][16][vf][vi];
				assign LLR_VARI_INPUT[274][1][vf][vi] = LLR_CHECK_STORE[24][17][vf][vi];
				assign LLR_VARI_INPUT[275][0][vf][vi] = LLR_CHECK_STORE[0][9][vf][vi];
				assign LLR_VARI_INPUT[275][1][vf][vi] = LLR_CHECK_STORE[6][17][vf][vi];
				assign LLR_VARI_INPUT[276][0][vf][vi] = LLR_CHECK_STORE[0][10][vf][vi];
				assign LLR_VARI_INPUT[276][1][vf][vi] = LLR_CHECK_STORE[7][17][vf][vi];
				assign LLR_VARI_INPUT[277][0][vf][vi] = LLR_CHECK_STORE[0][11][vf][vi];
				assign LLR_VARI_INPUT[277][1][vf][vi] = LLR_CHECK_STORE[8][17][vf][vi];
				assign LLR_VARI_INPUT[278][0][vf][vi] = LLR_CHECK_STORE[0][12][vf][vi];
				assign LLR_VARI_INPUT[278][1][vf][vi] = LLR_CHECK_STORE[9][17][vf][vi];
				assign LLR_VARI_INPUT[279][0][vf][vi] = LLR_CHECK_STORE[0][13][vf][vi];
				assign LLR_VARI_INPUT[279][1][vf][vi] = LLR_CHECK_STORE[10][17][vf][vi];
				assign LLR_VARI_INPUT[280][0][vf][vi] = LLR_CHECK_STORE[0][14][vf][vi];
				assign LLR_VARI_INPUT[280][1][vf][vi] = LLR_CHECK_STORE[11][17][vf][vi];
				assign LLR_VARI_INPUT[281][0][vf][vi] = LLR_CHECK_STORE[0][15][vf][vi];
				assign LLR_VARI_INPUT[281][1][vf][vi] = LLR_CHECK_STORE[16][17][vf][vi];
				assign LLR_VARI_INPUT[282][0][vf][vi] = LLR_CHECK_STORE[0][16][vf][vi];
				assign LLR_VARI_INPUT[282][1][vf][vi] = LLR_CHECK_STORE[13][17][vf][vi];
				assign LLR_VARI_INPUT[283][0][vf][vi] = LLR_CHECK_STORE[0][17][vf][vi];
				assign LLR_VARI_INPUT[283][1][vf][vi] = LLR_CHECK_STORE[14][17][vf][vi];
				assign LLR_VARI_INPUT[284][0][vf][vi] = LLR_CHECK_STORE[1][17][vf][vi];
				assign LLR_VARI_INPUT[284][1][vf][vi] = LLR_CHECK_STORE[31][17][vf][vi];
				assign LLR_VARI_INPUT[285][0][vf][vi] = LLR_CHECK_STORE[2][17][vf][vi];
				assign LLR_VARI_INPUT[285][1][vf][vi] = LLR_CHECK_STORE[27][17][vf][vi];
				assign LLR_VARI_INPUT[286][0][vf][vi] = LLR_CHECK_STORE[5][17][vf][vi];
				assign LLR_VARI_INPUT[286][1][vf][vi] = LLR_CHECK_STORE[20][17][vf][vi];
				assign LLR_VARI_INPUT[287][0][vf][vi] = LLR_CHECK_STORE[12][17][vf][vi];
				assign LLR_VARI_INPUT[287][1][vf][vi] = LLR_CHECK_STORE[28][17][vf][vi];
			end
		end
	endgenerate
	// Variable Connection
	generate
		genvar j;
		for (j = 0; j < SYMBOL_NUM; j = j + 1)
		begin:VARI_NODES
			VariableNode #(
				.INPUT_BIT(LLR_BIT),
				.OUTPUT_BIT(LLR_BIT),
				.VARIABLE_DEGREE(VARIABLE_DEGREE),
				.FIELD(FIELD)
			)  VARI_NODES (
				.INPUT_LLR(LLR_VARI_INPUT[j]),
				.PRIOR_LLR(PRIOR_LLR[j]),
				.OUTPUT_SYMBOL(LLR_VARI_SYMBOL[j]),
				.BUF_LLR_OUT(LLR_VARI_OUTPUT[j]),
				.CLK(CLK),
				.RST(RST)
			);
		end
	endgenerate
	// Output Symbol Recover from Galois Field to Integer Field
	generate
		genvar k;
		for (k = 0; k < INFO_NUM; k = k + 1)
		begin:RECOVERY
			SYMBOL_RECOVER #(
				.GF_BIT(CHECK_BIT),
				.SYMBOL_BIT(SYMBOL_BIT)
			) RECOVERY (
				.ORIGIN(PRIOR_SYMBOL[k]),
				.GF_OUT(LLR_VARI_SYMBOL[k]),
				.TRUE_OUT(MIDOUT_SYMBOL[k])
			);
		end
	endgenerate
	always @(posedge CLK) begin
		if (ENABLE == 1'b1) begin
			if (RST == 1) begin
				// STATE <= 1'b0;
				// NODE_STATE <= 5'b00000;
				// COUNTER <= 2'b11;
				FSM <= 9'b0;
				READY <= 1'b1;
				OUTPUT_SYMBOL_LOC <= 0;
				PRIOR_LLR <= 0;
				PRIOR_SYMBOL <= 0;
				PRIOR_LLR_FIRST <= 0;
				PRIOR_SYMBOL_FIRST <= 0;
				// CLK_STATE <= 0;
				LLR_CHECK_STORE_FIRST <= 0;
				LLR_CHECK_STORE <= 0;
				FIRST <= 1'b1;
			end
			else if (BYPASS) begin
				OUTPUT_SYMBOL_LOC <= INPUT_SYMBOL_LOC;
				// STATE <= 1'b0;
				// NODE_STATE <= 5'b00000;
				// COUNTER <= 2'b11;
				FSM <= 9'b0;
				READY <= 1'b1;
				LLR_CHECK_STORE_FIRST <= 0;
				LLR_CHECK_STORE <= 0;
				PRIOR_LLR <= 0;
				PRIOR_SYMBOL <= 0;
				PRIOR_LLR_FIRST <= 0;
				PRIOR_SYMBOL_FIRST <= 0;
				// CLK_STATE <= 0;
				FIRST <= 1'b1;
			end
			else begin
				case (FSM)
					9'b0_0000_0000: begin
						PRIOR_SYMBOL_FIRST <= INPUT_SYMBOL_LOC;
						OUTPUT_SYMBOL_LOC <= MIDOUT_SYMBOL;
						PRIOR_LLR_FIRST <= INPUT_LLR_LOC;
						READY <= 1'b1;
						FSM <= FSM + 1'b1;
					end
					9'b0_0111_1111:begin
						FIRST <= 1'b0;
						READY <= 1'b0;
						PRIOR_LLR <= PRIOR_LLR_FIRST;
						PRIOR_SYMBOL <= PRIOR_SYMBOL_FIRST;
						LLR_CHECK_STORE[CHECK_NUM - 2:0] <= LLR_CHECK_STORE_FIRST;
						LLR_CHECK_STORE[CHECK_NUM - 1] <= LLR_CHECK_OUTPUT;
						FSM <= FSM + 1'b1;
					end
					9'b1_0111_1111:begin
						FIRST <= 1'b1;
						LLR_CHECK_STORE[CHECK_NUM - 2:0] <= LLR_CHECK_STORE_FIRST;
						LLR_CHECK_STORE[CHECK_NUM - 1] <= LLR_CHECK_OUTPUT;
						FSM <= 9'b0_0000_0000;
					end
					9'b0_1111_1111:begin
						LLR_CHECK_STORE[CHECK_NUM - 2:0] <= LLR_CHECK_STORE_FIRST;
						LLR_CHECK_STORE[CHECK_NUM - 1] <= LLR_CHECK_OUTPUT;
						FSM <= FSM + 1'b1;
					end
					default: begin
						if (FSM[1:0] == 2'b11) begin
							LLR_CHECK_STORE_FIRST[FSM[6:2]] <= LLR_CHECK_OUTPUT;
						end
						FSM <= FSM + 1'b1;
					end
				endcase
			end
		end
	end
endmodule
