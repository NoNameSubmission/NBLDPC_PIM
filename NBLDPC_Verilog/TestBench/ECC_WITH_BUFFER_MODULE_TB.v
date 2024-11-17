//`timescale 1ns/100ps
`include "ECC_BUFFER.v"
`include "ECC_TOP.v"
`include "../synthesis/ECC_TOP.v"
`include "../synthesis/scc40nll_hdc40_rvt.v"
module ECC_WITH_BUFFER_TB;
	parameter MACRO = 4;
	parameter PARALLEL = 10;
	parameter INFO_GROUP = 8;
	parameter ADC_BIT = 3;
	parameter CHECK_BIT = 2;
	parameter LLR_BIT = 3;
	parameter SYMBOL_NUM = 288;
	parameter INFO_NUM = 256;
	parameter CHECK_NUM = 32;
	parameter ITER_BIT = 2;
	parameter CHECK_DEGREE = 18;
	parameter VARIABLE_DEGREE = 2;
	parameter FIELD = 3;
	parameter PERIOD = 8;
	parameter COUNTER_BIT = 3;
	reg [MACRO - 1:0][PARALLEL - 1:0] SA_OUT;
	reg [MACRO - 1:0][PARALLEL - 1:0][ADC_BIT - 1:0] ADC_OUT;
	reg BYPASS;
	reg CE;
	reg SYS_RST;
	reg ADC_CLK;
	reg ECC_CLK;
	reg CIM_E;
	reg CLK;
	reg [ADC_BIT - 1:0] TEMP_SYMBOL;
	reg [PARALLEL - 1:0][ADC_BIT - 1:0] TEMP_GROUP;
	wire [INFO_NUM - 1:0][ADC_BIT - 1:0] OUTPUT_SYMBOL;
	wire [INFO_NUM - 1:0][ADC_BIT - 1:0] OUTPUT_SYMBOL_TEST;
	wire READY;
	integer i, j, k, TEMP, INPUT_LLR_FILE, INPUT_SYMBOL_FILE, TEST_OUTPUT_FILE;
	integer p, COUNTER, BUF_INPUT_ROUND, ECC_INPUT_ROUND, FIRST, o1, o2;
	wire [INFO_NUM - 1:0][ADC_BIT - 1:0] ECC_SYMBOL_IN;
	wire signed [SYMBOL_NUM - 1:0][FIELD - 1:0][LLR_BIT - 1:0] ECC_LLR_IN;
	reg signed [FIELD - 1:0][LLR_BIT - 1:0] ECC_LLR_IN_TEMP;
	// initial $sdf_annotate("ECC_BUFFER.sdf", BUFFER_PART);
	// initial $sdf_annotate("ECC_TOP.sdf", ECC_PART);
	initial begin
		#1500;
		COUNTER = 0;
		FIRST = 0;
    	BUF_INPUT_ROUND = 0;
    	ECC_INPUT_ROUND = 0;
    	ADC_CLK = 0;
    	ECC_CLK = 0;
    	#1000;
    	ADC_CLK = 1;
    	ECC_CLK = 1;
		forever begin
			if (COUNTER == 0) begin
				ADC_CLK = 1;
				ECC_CLK = 1;
				#500;
				if (FIRST < 2) begin
					FIRST = FIRST + 1;
				end
				else begin
					// for (o1 = 0; o1 < INFO_NUM; o1 = o1 + 1) begin
					// 	$fdisplay(TEST_OUTPUT_FILE, "%d", OUTPUT_SYMBOL[o1]);
					// end
					for (o1 = 0; o1 < INFO_NUM; o1 = o1 + 1) begin
						// ECC_LLR_IN_TEMP = ECC_LLR_IN[o1];
						// for (o2 = 0; o2 < FIELD; o2 = o2 + 1) begin
						$fdisplay(TEST_OUTPUT_FILE, "%d", OUTPUT_SYMBOL_TEST[o1]);
						// end
					end
				end
			end
			if (COUNTER % 5 == 3) begin
				ECC_CLK = 0;
			end
			if (COUNTER % 5 == 4) begin
				ECC_CLK = 1;
				ECC_INPUT_ROUND = ECC_INPUT_ROUND + 1;
			end
			if (COUNTER % 6 == 2) begin
				ADC_CLK = 0;
			end
			if ((COUNTER % 6 == 5)) begin
				if (BUF_INPUT_ROUND < 7) begin
					ADC_CLK = 1;
					BUF_INPUT_ROUND = BUF_INPUT_ROUND + 1;
				end
			end
			COUNTER = COUNTER + 1;
			if (ECC_INPUT_ROUND == 11) begin
				COUNTER = 0;
				ECC_INPUT_ROUND = 0;
				BUF_INPUT_ROUND = 0;
				#2000;
				ECC_CLK = 0;
			end
			#500;
		end
	end
	initial begin
		$dumpfile("ECC_WITH_BUFFER_TB.vcd");
    	$dumpvars(0, ECC_WITH_BUFFER_TB);
    	INPUT_LLR_FILE = $fopen("/Users/xxxx/Desktop/Workplace/NBLDPC_TEST/DATA/INPUT_LLR_DATA.txt", "r");
    	INPUT_SYMBOL_FILE = $fopen("/Users/xxxx/Desktop/Workplace/NBLDPC_TEST/DATA/INPUT_SYMBOL_DATA.txt", "r");
    	TEST_OUTPUT_FILE = $fopen("/Users/xxxx/Desktop/Workplace/NBLDPC_TEST/DATA/OUTPUT_SYMBOL_DATA.txt", "w");
    	ADC_CLK = 0;
    	ECC_CLK = 0;
    	BYPASS = 0;
    	SA_OUT = 0;
    	CE = 1;
    	CIM_E = 1;
    	SYS_RST = 1;
    	#500;
    	ADC_CLK = 1;
    	ECC_CLK = 1;
    	#500;
    	ADC_CLK = 0;
    	ECC_CLK = 0;
    	#500;
    	SYS_RST = 0;
    	for (i = 0; i < 3; i = i + 1) begin
	    	$display(i);
	    	for (p = 0; p < PERIOD; p = p + 1) begin
	    		for (j = 0; j < MACRO; j = j + 1) begin
	    			for (k = 0; k < PARALLEL; k = k + 1) begin
						TEMP = $fscanf(INPUT_SYMBOL_FILE, "%d", TEMP_SYMBOL);
		    			TEMP_GROUP[k] = TEMP_SYMBOL;
	    			end
	    			ADC_OUT[j] = TEMP_GROUP;
	    		end
	    		#3000;
	    	end
	    	#6000;
    	end
		$finish;
	end
	ECC_BUFFER BUFFER_PART (
		.CIM_E(CIM_E),
		.CE(CE),
		.SYS_RST(SYS_RST),
		.ADC_CLK(ADC_CLK),
		.SA_OUT(SA_OUT),
		.ADC_OUT(ADC_OUT),
		.ECC_SYMBOL_IN(ECC_SYMBOL_IN),
		.ECC_LLR_IN(ECC_LLR_IN)
	);
	ECC_TOP ECC_PART (
		.CLK(ECC_CLK),
		.RST(SYS_RST),
		.BYPASS(BYPASS),
		.ENABLE(CE),
		.READY(READY),
		.INPUT_LLR(ECC_LLR_IN),
		.INPUT_SYMBOL(ECC_SYMBOL_IN),
		.OUTPUT_SYMBOL(OUTPUT_SYMBOL)
	);

	ECC_TOP_syn ECC_PART_TEST (
		.CLK(ECC_CLK),
		.RST(SYS_RST),
		.BYPASS(BYPASS),
		.ENABLE(CE),
		.READY(READY),
		.INPUT_LLR(ECC_LLR_IN),
		.INPUT_SYMBOL(ECC_SYMBOL_IN),
		.OUTPUT_SYMBOL(OUTPUT_SYMBOL_TEST)
	);
endmodule