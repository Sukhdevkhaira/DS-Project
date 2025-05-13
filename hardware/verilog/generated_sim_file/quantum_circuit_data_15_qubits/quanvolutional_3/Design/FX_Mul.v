`timescale 1ns / 1ps

module FX_Mul
#(
	parameter DATA_WIDTH   = 32,
	parameter NUM_FRAC_BIT = 30
)
(
	input                         clk,         
	input                         rst_n,    
	input signed [DATA_WIDTH-1:0] i_data_0,    
	input signed [DATA_WIDTH-1:0] i_data_1,
	output [DATA_WIDTH-1:0]       o_result 
);
	reg signed [DATA_WIDTH*2-1:0] result_tmp_rg;

	// assign o_result = result_tmp_rg[61:30];
	assign o_result = result_tmp_rg[DATA_WIDTH+NUM_FRAC_BIT-1:NUM_FRAC_BIT];

	always @(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
			result_tmp_rg <= 0;
		end
		else begin
			result_tmp_rg <= (i_data_0 * i_data_1); // >>> NUM_FRAC_BIT;
		end
	end
endmodule






// `timescale 1ns / 1ps

// module FX_Mul
// #(
// 	parameter DATA_WIDTH   = 32,
// 	parameter NUM_FRAC_BIT = 30
// )
// (
// 	input                         clk,         
// 	input                         rst_n,    
// 	input signed [DATA_WIDTH-1:0] i_data_0,    
// 	input signed [DATA_WIDTH-1:0] i_data_1,
// 	output [DATA_WIDTH-1:0]       o_result 
// );
// 	reg signed [DATA_WIDTH*2-1:0] result_tmp_rg;

// 	// assign o_result = result_tmp_rg[61:30];
// 	assign o_result = result_tmp_rg[DATA_WIDTH+NUM_FRAC_BIT-1:NUM_FRAC_BIT];

// 	always @(posedge clk or negedge rst_n) begin
// 		if(!rst_n) begin
// 			result_tmp_rg <= 0;
// 		end
// 		else begin
// 			result_tmp_rg <= i_data_0 * i_data_1;
// 		end
// 	end
// endmodule