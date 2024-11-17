module MESSAGE_TRANS #(
		parameter INPUT_BIT = 3,
		parameter LLR_BIT = 3,
		parameter FIELD = 3
	) (
		INPUT,
		CIM_E,
		OUTPUT_LLR
	);
	input wire [INPUT_BIT - 1:0] INPUT;
	input wire CIM_E;
	output wire [FIELD * LLR_BIT - 1:0] OUTPUT_LLR;
	reg [FIELD - 1:0][LLR_BIT - 1:0] OUTPUT_LLR_LOC;
	generate
		genvar i, j;
		for (i = 0; i < FIELD; i = i + 1) begin
			for (j = 0; j < LLR_BIT; j = j + 1) begin
				assign OUTPUT_LLR[i * LLR_BIT + j] = OUTPUT_LLR_LOC[i][j];
			end
		end
	endgenerate
	always @(*) begin
		case (INPUT)
			3'b000: begin
				OUTPUT_LLR_LOC[0] <= 3'b010;
				OUTPUT_LLR_LOC[1] <= 3'b001;
				OUTPUT_LLR_LOC[2] <= 3'b000;
			end
			3'b001: begin
				OUTPUT_LLR_LOC[0] <= 3'b001;
				OUTPUT_LLR_LOC[1] <= 3'b010;
				if (CIM_E == 0) begin
					OUTPUT_LLR_LOC[2] <= 3'b000;
				end
				else begin
					OUTPUT_LLR_LOC[2] <= 3'b001;
				end
			end
			3'b010: begin
				OUTPUT_LLR_LOC[0] <= 3'b001;
				OUTPUT_LLR_LOC[1] <= 3'b001;
				OUTPUT_LLR_LOC[2] <= 3'b010;
			end
			3'b011: begin
				OUTPUT_LLR_LOC[0] <= 3'b010;
				OUTPUT_LLR_LOC[1] <= 3'b001;
				OUTPUT_LLR_LOC[2] <= 3'b001;
			end
			3'b100: begin
				OUTPUT_LLR_LOC[0] <= 3'b001;
				OUTPUT_LLR_LOC[1] <= 3'b010;
				OUTPUT_LLR_LOC[2] <= 3'b000;
			end
			default: begin
				OUTPUT_LLR_LOC[0] <= 3'b000;
				OUTPUT_LLR_LOC[1] <= 3'b000;
				OUTPUT_LLR_LOC[2] <= 3'b000;
			end
		endcase
	end
endmodule

module CHECK_TRANS #(
		parameter INPUT_BIT = 3,
		parameter LLR_BIT = 3,
		parameter FIELD = 3
	) (
		INPUT_A,
		INPUT_B,
		CIM_E,
		OUTPUT_LLR
	);
	input wire [INPUT_BIT - 1:0] INPUT_A;
	input wire [INPUT_BIT - 1:0] INPUT_B;
	input wire CIM_E;
	output wire [FIELD * LLR_BIT - 1:0] OUTPUT_LLR;
	reg [FIELD - 1:0][LLR_BIT - 1:0] OUTPUT_LLR_LOC;
	generate
		genvar i, j;
		for (i = 0; i < FIELD; i = i + 1) begin
			for (j = 0; j < LLR_BIT; j = j + 1) begin
				assign OUTPUT_LLR[i * LLR_BIT + j] = OUTPUT_LLR_LOC[i][j];
			end
		end
	endgenerate
	always @(*) begin
		case ({INPUT_A, INPUT_B})
			6'b000000: begin
				OUTPUT_LLR_LOC[0] <= 3'b010;
				OUTPUT_LLR_LOC[1] <= 3'b001;
				OUTPUT_LLR_LOC[2] <= 3'b000;
			end
			6'b000001: begin
				OUTPUT_LLR_LOC[0] <= 3'b001;
				OUTPUT_LLR_LOC[1] <= 3'b010;
				if (CIM_E == 0) begin
					OUTPUT_LLR_LOC[2] <= 3'b000;
				end
				else begin
					OUTPUT_LLR_LOC[2] <= 3'b001;
				end
			end
			6'b000010: begin
				OUTPUT_LLR_LOC[0] <= 3'b001;
				OUTPUT_LLR_LOC[1] <= 3'b001;
				OUTPUT_LLR_LOC[2] <= 3'b010;
			end
			6'b000011: begin
				OUTPUT_LLR_LOC[0] <= 3'b010;
				OUTPUT_LLR_LOC[1] <= 3'b001;
				OUTPUT_LLR_LOC[2] <= 3'b001;
			end
			6'b000100: begin
				OUTPUT_LLR_LOC[0] <= 3'b001;
				OUTPUT_LLR_LOC[1] <= 3'b010;
				OUTPUT_LLR_LOC[2] <= 3'b000;
			end
			6'b001000: begin
				if (CIM_E == 0) begin
					OUTPUT_LLR_LOC[0] <= 3'b000;
				end
				else begin
					OUTPUT_LLR_LOC[0] <= 3'b001;
				end
				OUTPUT_LLR_LOC[1] <= 3'b001;
				OUTPUT_LLR_LOC[2] <= 3'b010;
			end
			6'b001001: begin
				OUTPUT_LLR_LOC[0] <= 3'b010;
				if (CIM_E == 0) begin
					OUTPUT_LLR_LOC[1] <= 3'b000;
				end
				else begin
					OUTPUT_LLR_LOC[1] <= 3'b001;
				end
				OUTPUT_LLR_LOC[2] <= 3'b001;
			end
			6'b001010: begin
				OUTPUT_LLR_LOC[0] <= 3'b001;
				OUTPUT_LLR_LOC[1] <= 3'b010;
				OUTPUT_LLR_LOC[2] <= 3'b000;
			end
			6'b001011: begin
				OUTPUT_LLR_LOC[0] <= 3'b000;
				OUTPUT_LLR_LOC[1] <= 3'b001;
				OUTPUT_LLR_LOC[2] <= 3'b010;
			end
			6'b001100: begin
				OUTPUT_LLR_LOC[0] <= 3'b010;
				OUTPUT_LLR_LOC[1] <= 3'b000;
				OUTPUT_LLR_LOC[2] <= 3'b001;
			end
			6'b010000: begin
				OUTPUT_LLR_LOC[0] <= 3'b001;
				OUTPUT_LLR_LOC[1] <= 3'b010;
				OUTPUT_LLR_LOC[2] <= 3'b000;
			end
			6'b010001: begin
				OUTPUT_LLR_LOC[0] <= 3'b000;
				OUTPUT_LLR_LOC[1] <= 3'b001;
				OUTPUT_LLR_LOC[2] <= 3'b010;
			end
			6'b010010: begin
				OUTPUT_LLR_LOC[0] <= 3'b010;
				OUTPUT_LLR_LOC[1] <= 3'b000;
				OUTPUT_LLR_LOC[2] <= 3'b001;
			end
			6'b010011: begin
				OUTPUT_LLR_LOC[0] <= 3'b001;
				OUTPUT_LLR_LOC[1] <= 3'b010;
				OUTPUT_LLR_LOC[2] <= 3'b000;
			end
			6'b010100: begin
				OUTPUT_LLR_LOC[0] <= 3'b000;
				OUTPUT_LLR_LOC[1] <= 3'b001;
				OUTPUT_LLR_LOC[2] <= 3'b010;
			end
			6'b011000: begin
				OUTPUT_LLR_LOC[0] <= 3'b010;
				OUTPUT_LLR_LOC[1] <= 3'b000;
				OUTPUT_LLR_LOC[2] <= 3'b001;
			end
			6'b011001: begin
				OUTPUT_LLR_LOC[0] <= 3'b001;
				OUTPUT_LLR_LOC[1] <= 3'b010;
				OUTPUT_LLR_LOC[2] <= 3'b000;
			end
			6'b011010: begin
				OUTPUT_LLR_LOC[0] <= 3'b000;
				OUTPUT_LLR_LOC[1] <= 3'b001;
				OUTPUT_LLR_LOC[2] <= 3'b010;
			end
			6'b011011: begin
				OUTPUT_LLR_LOC[0] <= 3'b010;
				OUTPUT_LLR_LOC[1] <= 3'b000;
				OUTPUT_LLR_LOC[2] <= 3'b001;
			end
			6'b011100: begin
				OUTPUT_LLR_LOC[0] <= 3'b001;
				OUTPUT_LLR_LOC[1] <= 3'b010;
				OUTPUT_LLR_LOC[2] <= 3'b000;
			end
			6'b100000: begin
				OUTPUT_LLR_LOC[0] <= 3'b000;
				OUTPUT_LLR_LOC[1] <= 3'b001;
				OUTPUT_LLR_LOC[2] <= 3'b010;
			end
			6'b100001: begin
				OUTPUT_LLR_LOC[0] <= 3'b010;
				OUTPUT_LLR_LOC[1] <= 3'b000;
				OUTPUT_LLR_LOC[2] <= 3'b001;
			end
			6'b100010: begin
				OUTPUT_LLR_LOC[0] <= 3'b001;
				OUTPUT_LLR_LOC[1] <= 3'b010;
				OUTPUT_LLR_LOC[2] <= 3'b000;
			end
			6'b100011: begin
				OUTPUT_LLR_LOC[0] <= 3'b000;
				OUTPUT_LLR_LOC[1] <= 3'b001;
				OUTPUT_LLR_LOC[2] <= 3'b010;
			end
			6'b100100: begin
				OUTPUT_LLR_LOC[0] <= 3'b010;
				OUTPUT_LLR_LOC[1] <= 3'b000;
				OUTPUT_LLR_LOC[2] <= 3'b001;
			end
			default: begin
				OUTPUT_LLR_LOC[0] <= 3'b000;
				OUTPUT_LLR_LOC[1] <= 3'b000;
				OUTPUT_LLR_LOC[2] <= 3'b000;
			end
		endcase
	end
endmodule

module SYMBOL_RECOVER #(
		parameter GF_BIT = 2,
		parameter SYMBOL_BIT = 3
	) (
		ORIGIN,
		GF_OUT,
		TRUE_OUT
	);
	input wire [SYMBOL_BIT - 1:0] ORIGIN;
	input wire [GF_BIT - 1:0] GF_OUT;
	output reg [SYMBOL_BIT - 1:0] TRUE_OUT;
	always @(*) begin
		case ({ORIGIN, GF_OUT})
			5'b000_00: begin
				TRUE_OUT <= 3'b000;
			end
			5'b000_01: begin
				TRUE_OUT <= 3'b001;
			end
			5'b000_10: begin
				TRUE_OUT <= 3'b010;
			end
			5'b001_00: begin
				TRUE_OUT <= 3'b000;
			end
			5'b001_01: begin
				TRUE_OUT <= 3'b001;
			end

			5'b001_10: begin
				TRUE_OUT <= 3'b010;
			end
			5'b010_00: begin
				TRUE_OUT <= 3'b011;
			end
			5'b010_01: begin
				TRUE_OUT <= 3'b001;
			end
			5'b010_10: begin
				TRUE_OUT <= 3'b010;
			end
			5'b011_00: begin
				TRUE_OUT <= 3'b011;
			end
			5'b011_01: begin
				TRUE_OUT <= 3'b100;
			end
			5'b011_10: begin
				TRUE_OUT <= 3'b010;
			end
			5'b100_00: begin
				TRUE_OUT <= 3'b011;
			end
			5'b100_01: begin
				TRUE_OUT <= 3'b100;
			end
			5'b100_10: begin
				TRUE_OUT <= 3'b010;
			end
		endcase
	end
endmodule