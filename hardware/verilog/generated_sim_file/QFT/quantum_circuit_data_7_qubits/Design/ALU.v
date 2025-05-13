`timescale 1ns / 1ps

module ALU 
#(
    parameter DATA_WIDTH   = 32,
    parameter NUM_FRAC_BIT = 30
)
(  
    input                     clk,
    input                     rst_n,

    input [1:0]               i_start,
    input                     i_op_mode, // 0: Sparse || 1: Dense
    input [DATA_WIDTH*2-1:0]  i_data_0,  // {Real_Value, Imaginary_Value}
    input [DATA_WIDTH*2-1:0]  i_data_1,  // {Real_Value, Imaginary_Value}
    input [DATA_WIDTH*2-1:0]  i_data_2,  // {Real_Value, Imaginary_Value}
    input [DATA_WIDTH*2-1:0]  i_data_3,  // {Real_Value, Imaginary_Value}
    input [DATA_WIDTH*2-1:0]  i_data_4,  // {Real_Value, Imaginary_Value}
    input [DATA_WIDTH*2-1:0]  i_data_5,  // {Real_Value, Imaginary_Value}
    input [DATA_WIDTH*2-1:0]  i_data_6,  // {Real_Value, Imaginary_Value}
    input [DATA_WIDTH*2-1:0]  i_data_7,  // {Real_Value, Imaginary_Value}
    
    output [DATA_WIDTH*2-1:0] o_data_0,
    output [DATA_WIDTH*2-1:0] o_data_1
);
    Special_Unit 
    #(
        .DATA_WIDTH(DATA_WIDTH),
        .NUM_FRAC_BIT(NUM_FRAC_BIT)
    )
    inst_0
    (  
        .clk(clk),
        .rst_n(rst_n),

        .i_start(i_start[0]),
        .i_op_mode(i_op_mode),
        .i_data_0(i_data_0),
        .i_data_1(i_data_1),
        .i_data_2(i_data_2),
        .i_data_3(i_data_3),
        
        .o_data(o_data_0)
    );

    Special_Unit 
    #(
        .DATA_WIDTH(DATA_WIDTH),
        .NUM_FRAC_BIT(NUM_FRAC_BIT)
    )
    inst_1
    (  
        .clk(clk),
        .rst_n(rst_n),

        .i_start(i_start[1]),
        .i_op_mode(i_op_mode),
        .i_data_0(i_data_4),
        .i_data_1(i_data_5),
        .i_data_2(i_data_6),
        .i_data_3(i_data_7),
        
        .o_data(o_data_1)
    );
endmodule