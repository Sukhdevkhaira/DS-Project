`timescale 1ns / 1ps

module Comp_Mul
#(
    parameter DATA_WIDTH   = 32,
    parameter NUM_FRAC_BIT = 30
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

    wire [DATA_WIDTH-1:0] from_mul_0_to_sub_wr;
    wire [DATA_WIDTH-1:0] from_mul_1_to_sub_wr;
    wire [DATA_WIDTH-1:0] from_mul_2_to_add_wr;
    wire [DATA_WIDTH-1:0] from_mul_3_to_add_wr;

    assign re_num_0_wr = i_num_0[DATA_WIDTH*2-1:DATA_WIDTH];
    assign im_num_0_wr = i_num_0[DATA_WIDTH-1:0];

    assign re_num_1_wr = i_num_1[DATA_WIDTH*2-1:DATA_WIDTH];
    assign im_num_1_wr = i_num_1[DATA_WIDTH-1:0];

    assign o_res = {re_res_wr, im_res_wr};

    FX_Mul
    #(
        .DATA_WIDTH(DATA_WIDTH),
        .NUM_FRAC_BIT(NUM_FRAC_BIT)
    )
    FX_Mul_ins_0 
    (    
        .clk(clk),       
        .rst_n(rst_n),                      
        .i_data_0(re_num_0_wr),
        .i_data_1(re_num_1_wr),                                  
        .o_result(from_mul_0_to_sub_wr)             
    );
        
    FX_Mul  
    #(
        .DATA_WIDTH(DATA_WIDTH),
        .NUM_FRAC_BIT(NUM_FRAC_BIT)
    )
    FX_Mul_ins_1
    (
        .clk(clk),       
        .rst_n(rst_n),                           
        .i_data_0(im_num_0_wr),
        .i_data_1(im_num_1_wr),                                  
        .o_result(from_mul_1_to_sub_wr)             
    );
        
    FX_Sub
    #(
        .DATA_WIDTH(DATA_WIDTH)
    )
    FX_Sub_ins_0
    (
        .clk(clk),  
        .rst_n(rst_n),                                 
        .i_data_0(from_mul_0_to_sub_wr),
        .i_data_1(from_mul_1_to_sub_wr),                         
        .o_result(re_res_wr)             
    );  

    // Imaginay Tensor Product

    FX_Mul     
    #(
        .DATA_WIDTH(DATA_WIDTH),
        .NUM_FRAC_BIT(NUM_FRAC_BIT)
    )
    FX_Mul_ins_2 
    (
        .clk(clk),    
        .rst_n(rst_n),                         
        .i_data_0(re_num_0_wr),
        .i_data_1(im_num_1_wr),                                   
        .o_result(from_mul_2_to_add_wr)             
    );
        
    FX_Mul 
    #(
        .DATA_WIDTH(DATA_WIDTH),
        .NUM_FRAC_BIT(30)

    )
    FX_Mul_ins_3  
    ( 
        .clk(clk),             
        .rst_n(rst_n),                    
        .i_data_0(im_num_0_wr),
        .i_data_1(re_num_1_wr),                                   
        .o_result(from_mul_3_to_add_wr)             
    );
        
    FX_Add
    #(
        .DATA_WIDTH(DATA_WIDTH)
    )
    FX_Add_ins_0  
    (
        .clk(clk),     
        .rst_n(rst_n),                             
        .i_data_0(from_mul_2_to_add_wr),
        .i_data_1(from_mul_3_to_add_wr),                          
        .o_result(im_res_wr)             
    );  
endmodule
