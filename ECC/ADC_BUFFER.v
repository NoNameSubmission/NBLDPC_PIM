module ADC_BUFFER #(
		parameter INPUT_BIT = 3,
		parameter MACRO_NUM = 1,
		parameter PARALLEL = 10,
		parameter PERIOD = 32,
		parameter COUNTER_BIT = 5
	)(
		CLK,
		RST,
		CE,
		INPUT,
		SYMBOL_BUFFER
	);
	input wire CLK;
	input wire RST;
	input wire [PARALLEL * INPUT_BIT - 1:0] INPUT;
	input wire CE;
	output wire [PERIOD * PARALLEL * INPUT_BIT - 1:0] SYMBOL_BUFFER;
	reg [COUNTER_BIT - 1:0] COUNTER;
	wire [PARALLEL - 1:0][INPUT_BIT - 1:0] INPUT_LOC;
	reg [PERIOD - 1:0][PARALLEL - 1:0][INPUT_BIT - 1:0] SYMBOL_BUFFER_LOC;
	generate
		genvar i, j, k, l;
		for (j = 0; j < PARALLEL; j = j + 1) begin
			for (k = 0; k < INPUT_BIT; k = k + 1) begin
				assign INPUT_LOC[j][k] = INPUT[j * INPUT_BIT + k];
			end
		end
		for (i = 0; i < PERIOD; i = i + 1) begin
			for (k = 0; k < PARALLEL; k = k + 1) begin
				for (l = 0; l < INPUT_BIT; l = l + 1) begin
					assign SYMBOL_BUFFER[i * PARALLEL * INPUT_BIT + k * INPUT_BIT + l] = SYMBOL_BUFFER_LOC[i][k][l];
				end
			end
		end
	endgenerate
	always @(posedge CLK) begin
		if (CE) begin
			if (RST) begin
				SYMBOL_BUFFER_LOC <= 0;
				COUNTER <= 0;
			end
			else begin
				SYMBOL_BUFFER_LOC[COUNTER] <= INPUT_LOC;
				if (COUNTER == 5'b11111) begin
					COUNTER <= 5'b0;
				end
				else begin
					COUNTER <= COUNTER + 1'b1;
				end
			end
		end
	end
endmodule