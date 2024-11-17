`timescale 1ns/100ps
`include "ECC_BUFFER.v"
module ECC_BUFFER_TB;
	parameter SYMBOL_BIT = 3;
	parameter CHECK_BIT = 2;
	parameter LLR_BIT = 3;
	parameter SYMBOL_NUM = 288;
	parameter INFO_NUM = 256;
	parameter CHECK_NUM = 32;
	parameter ITER_BIT = 5;
	parameter CHECK_DEGREE = 18;
	parameter VARIABLE_DEGREE = 2;
	parameter PROCESS_BIT = 4;
	parameter PARALLEL = 10;
	parameter ADC_BIT = 3;
	parameter FIELD = 3;
	parameter PERIOD = 32;
	reg [PARALLEL - 1:0][ADC_BIT - 1:0] ADC_OUT;
	reg CE;
	reg SYS_RST;
	reg ADC_CLK;
	reg CIM_E;
	reg [ADC_BIT - 1:0] TEMP_SYMBOL;
	reg [FIELD - 1:0][LLR_BIT - 1:0] TEMP_LLR;
	wire [INFO_NUM - 1:0][ADC_BIT - 1:0] ECC_SYMBOL_IN;
	wire [SYMBOL_NUM - 1:0][FIELD - 1:0][LLR_BIT - 1:0] ECC_LLR_IN;
	integer i, j, TEMP, INPUT_LLR_FILE, INPUT_SYMBOL_FILE, TEST_OUTPUT_FILE;
	integer o1, o2, o3;
	initial begin
		#55;
		forever begin
			ADC_CLK = ~ADC_CLK;
			#5;
		end
	end
	initial begin
		$dumpfile("ECC_BUFFER_TB_single.vcd");
    	$dumpvars(0, ECC_BUFFER_TB);
    	INPUT_SYMBOL_FILE = $fopen("/Users/xxxx/Desktop/Workplace/NBLDPC_TEST/DATA/BUFFER_INPUT_SYMBOL_DATA.txt", "r");
    	TEST_OUTPUT_FILE = $fopen("/Users/xxxx/Desktop/Workplace/NBLDPC_TEST/DATA/OUTPUT_DATA.txt", "w");
		ADC_CLK = 0;
		SYS_RST = 0;
		CIM_E = 1;
		CE = 1;
		#10;
		SYS_RST = 1;
		#10;
    	ADC_CLK = 1;
    	#10;
    	ADC_CLK = 0;
    	#10;
    	SYS_RST = 0;
	    #10;
	    for (i = 0; i < PERIOD; i = i + 1) begin
	    	$display(i);
	    	for (j = 0; j < PARALLEL; j = j + 1) begin
	    		TEMP = $fscanf(INPUT_SYMBOL_FILE, "%d", TEMP_SYMBOL);
	    		ADC_OUT[j] = TEMP_SYMBOL;
	    	end
	    	#10;
	    end
	    for (i = 0; i < INFO_NUM; i = i + 1) begin
	    	$fdisplay(TEST_OUTPUT_FILE, "%d", ECC_SYMBOL_IN[i]);
	    end
	    // for (i = 0; i < SYMBOL_NUM; i = i + 1) begin
	    // 	TEMP_LLR = ECC_LLR_IN[i];
	    // 	for (j = 0; j < FIELD; j = j + 1) begin
	    // 		$fdisplay(TEST_OUTPUT_FILE, "%d", TEMP_LLR[j]);
	    // 	end
	    // end
		$finish;
	end
	ECC_BUFFER Element_BUFFER (
		.ADC_CLK(ADC_CLK),
		.SYS_RST(SYS_RST),
		.CE(CE),
		.CIM_E(CIM_E),
		.ADC_OUT(ADC_OUT),
		.ECC_SYMBOL_IN(ECC_SYMBOL_IN),
		.ECC_LLR_IN(ECC_LLR_IN)
	);
endmodule