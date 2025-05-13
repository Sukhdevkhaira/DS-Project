`timescale 1ns / 1ps

module Comp_Add
#(
    parameter DATA_WIDTH   = 32
)
(
    input                     clk,
    input                     rst_n,

    input [DATA_WIDTH*2-1:0]  i_num_0,
    input [DATA_WIDTH*2-1:0]  i_num_1,

    output [DATA_WIDTH*2-1:0] o_res
);
    wire [DATA_WIDTH-1:0] re_num_0_wr;
    wire [DATA_WIDTH-1:0] im_num_0_wr;
    wire [DATA_WIDTH-1:0] re_num_1_wr;
    wire [DATA_WIDTH-1:0] im_num_1_wr;
    wire [DATA_WIDTH-1:0] re_res_wr;
    wire [DATA_WIDTH-1:0] im_res_wr;

    assign re_num_0_wr = i_num_0[DATA_WIDTH*2-1:DATA_WIDTH];
    assign im_num_0_wr = i_num_0[DATA_WIDTH-1:0];

    assign re_num_1_wr = i_num_1[DATA_WIDTH*2-1:DATA_WIDTH];
    assign im_num_1_wr = i_num_1[DATA_WIDTH-1:0];

    assign o_res = {re_res_wr, im_res_wr};

    FX_Add
    #(
        .DATA_WIDTH(DATA_WIDTH)
    )
    FX_Add_ins_0  
    (
        .clk(clk),     
        .rst_n(rst_n),                             
        .i_data_0(re_num_0_wr),
        .i_data_1(re_num_1_wr),                          
        .o_result(re_res_wr)             
    );  

    FX_Add
    #(
        .DATA_WIDTH(DATA_WIDTH)
    )
    FX_Add_ins_1  
    (
        .clk(clk),     
        .rst_n(rst_n),                             
        .i_data_0(im_num_0_wr),
        .i_data_1(im_num_1_wr),                          
        .o_result(im_res_wr)             
    );  
endmodule
