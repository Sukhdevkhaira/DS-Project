`timescale 1ns / 1ps

module FX_Sub
#(
	parameter DATA_WIDTH = 32
)
(
	input                       clk,         
	input                       rst_n,     
	input [DATA_WIDTH-1:0]      i_data_0,    
	input [DATA_WIDTH-1:0]      i_data_1,
	output reg [DATA_WIDTH-1:0] o_result 
);
	always @(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
			o_result <= 0;
		end
		else begin
			o_result <= i_data_0 - i_data_1;
		end
	end
endmodule