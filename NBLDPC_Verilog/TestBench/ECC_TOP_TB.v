`timescale 1ns/100ps
//`include "ECC_TOP_onlypos.v"
// `include "../synthesis/ECC_TOP.v"
// `include "../synthesis/scc40nll_hdc40_rvt.v"
module ECC_TOP_TB;
	parameter SYMBOL_BIT = 3;
	parameter CHECK_BIT = 2;
	parameter LLR_BIT = 3;
	parameter SYMBOL_NUM = 288;
	parameter INFO_NUM = 256;
	parameter CHECK_NUM = 32;
	parameter ITER_BIT = 2;
	parameter CHECK_DEGREE = 18;
	parameter VARIABLE_DEGREE = 2;
	parameter PROCESS_BIT = 4;
	parameter FIELD = 3;
	reg CLK;
	reg RST;
	reg signed [SYMBOL_NUM - 1:0][FIELD - 1:0][LLR_BIT - 1:0] INPUT_LLR;
	reg [INFO_NUM - 1:0][SYMBOL_BIT - 1:0] INPUT_SYMBOL;
	wire [INFO_NUM - 1:0][SYMBOL_BIT - 1:0] OUTPUT_SYMBOL;
	wire [INFO_NUM - 1:0][SYMBOL_BIT - 1:0] OUTPUT_SYMBOL_REF;
	wire signed [SYMBOL_NUM - 1:0][VARIABLE_DEGREE - 1:0][FIELD - 1:0][LLR_BIT - 1:0] VARIABLE_DEBUG;
	reg signed [VARIABLE_DEGREE - 1:0][FIELD - 1:0][LLR_BIT - 1:0] VARIABLE_TEMP;
	reg signed [FIELD - 1:0][LLR_BIT - 1:0] VARIABLE_TEMP2;
	wire signed [CHECK_DEGREE - 1:0][FIELD - 1:0][LLR_BIT - 1:0] CHECK_DEBUG;
	reg signed [CHECK_DEGREE - 1:0][FIELD - 1:0][LLR_BIT - 1:0] LLR_STORE_TEMP1;
	reg signed [FIELD - 1:0][LLR_BIT - 1:0] LLR_STORE_TEMP2;
	reg signed [LLR_BIT - 1:0] TEMP_INPUT1;
	reg signed [LLR_BIT - 1:0] TEMP_INPUT2;
	reg signed [LLR_BIT - 1:0] TEMP_INPUT3;
	wire [CHECK_NUM / 2 - 1:0][CHECK_DEGREE - 1:0][2 - 1:0] MAT_DEBUG;
	reg [SYMBOL_BIT - 1:0] TEMP_SYMBOL;
	reg ENABLE;
	integer count;
	wire READY;
	integer i, j, TEMP, INPUT_LLR_FILE, INPUT_SYMBOL_FILE, TEST_OUTPUT_FILE;
	integer o1, o2, o3;
	initial begin
		count = 0;
		#45;
		forever begin
			CLK = ~CLK;
			#5;
	//		if (CLK == 1) begin
	//			if (count == 127) begin
	//				count = 0;
	//			end
	//			else begin
	//				count = count + 1;
	//			end
	//			if (count == 0) begin
				//	for (o1 = 0; o1 < SYMBOL_NUM; o1 = o1 + 1) begin
				//		VARIABLE_TEMP = VARIABLE_DEBUG[o1];
				//		for (o2 = 0; o2 < VARIABLE_DEGREE; o2 = o2 + 1) begin
				//			VARIABLE_TEMP2 = VARIABLE_TEMP[o2];
				//			for (o3 = 0; o3 < FIELD; o3 = o3 + 1) begin
				//				$fdisplay(TEST_OUTPUT_FILE, "%d", $signed(VARIABLE_TEMP2[o3]));
				//			end
				//		end
				//	end
				//	for (o1 = 0; o1 < CHECK_DEGREE; o1 = o1 + 1) begin
				//		LLR_STORE_TEMP2 = CHECK_DEBUG[o1];
				//		for (o2 = 0; o2 < FIELD; o2 = o2 + 1) begin
				//			$fdisplay(TEST_OUTPUT_FILE, "%d", $signed(LLR_STORE_TEMP2[o2]));
				//		end
				//	end
				//end
	//		end
		end
	end
	initial begin
		$dumpfile("ECC_TOP_TB_single.vcd");
	    	$dumpvars(0, ECC_TOP_TB);
	    	INPUT_LLR_FILE = $fopen("/data/home2/daijings/Verilog/NBLDPC_TEST/DATA/INPUT_LLR_DATA.txt", "r");
	    	INPUT_SYMBOL_FILE = $fopen("/data/home2/daijings/Verilog/NBLDPC_TEST/DATA/INPUT_REF_DATA.txt", "r");
	    	TEST_OUTPUT_FILE = $fopen("/data/home2/daijings/Verilog/NBLDPC_TEST/DATA/OUTPUT_SYMBOL_DATA.txt", "w");
		CLK = 0;
		RST = 0;
		ENABLE = 1;
		#10;
		RST = 1;
		#10;
	    	CLK = 1;
	    	#10;
	    	CLK = 0;
	    	#5;
	    	RST = 0;
	    	#5;
	    	for (i = 0; i < 2; i = i + 1) begin
		    	$display(i);
		    	for (j = 0; j < INFO_NUM; j = j + 1) begin
				TEMP = $fscanf(INPUT_SYMBOL_FILE, "%d", TEMP_SYMBOL);
	    			INPUT_SYMBOL[j] = TEMP_SYMBOL;
		    	end
	    		for (j = 0; j < SYMBOL_NUM; j = j + 1) begin
				TEMP = $fscanf(INPUT_LLR_FILE, "%d", TEMP_INPUT1);
				TEMP = $fscanf(INPUT_LLR_FILE, "%d", TEMP_INPUT2);
				TEMP = $fscanf(INPUT_LLR_FILE, "%d", TEMP_INPUT3);
	    			INPUT_LLR[j] = {TEMP_INPUT3, TEMP_INPUT2, TEMP_INPUT1};
	    		end
			if (i == 0) begin
				#3840;
			end
			else begin
				#40;
				for (j = 0; j < INFO_NUM; j = j + 1) begin
					$fdisplay(TEST_OUTPUT_FILE, "%d", OUTPUT_SYMBOL_REF[j]);
				end
				#3800;
			end
	    	end
	    	#50;
		$finish;
	end
	// ECC_TOP_syn Element(
	// 	.CLK(CLK),
	// 	.RST(RST),
	// 	.INPUT_LLR(INPUT_LLR),
	// 	.INPUT_SYMBOL(INPUT_SYMBOL),
	// 	.OUTPUT_SYMBOL(OUTPUT_SYMBOL),
	// 	.ENABLE(ENABLE),
	// 	.READY(READY),
	// 	.BYPASS(1'b0)
	// );
	ECC_TOP Element_REF (
		.CLK(CLK),
		.RST(RST),
		.INPUT_LLR(INPUT_LLR),
		.INPUT_SYMBOL(INPUT_SYMBOL),
		.OUTPUT_SYMBOL(OUTPUT_SYMBOL_REF),
		.ENABLE(ENABLE),
		.READY(READY),
		//.LLR_VARI_DEBUG(VARIABLE_DEBUG),
		.BYPASS(1'b0)
	);
endmodule
