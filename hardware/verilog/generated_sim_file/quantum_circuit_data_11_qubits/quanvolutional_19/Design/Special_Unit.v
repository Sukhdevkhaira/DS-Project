`timescale 1ns / 1ps

module Special_Unit 
#(
    parameter DATA_WIDTH   = 32,
    parameter NUM_FRAC_BIT = 30
)
(  
    input                     clk,
    input                     rst_n,

    input                     i_start,
    input                     i_op_mode, // 0: Sparse || 1: Dense
    input [DATA_WIDTH*2-1:0]  i_data_0,  // {Real_Value, Imaginary_Value}
    input [DATA_WIDTH*2-1:0]  i_data_1,  // {Real_Value, Imaginary_Value}
    input [DATA_WIDTH*2-1:0]  i_data_2,  // {Real_Value, Imaginary_Value}
    input [DATA_WIDTH*2-1:0]  i_data_3,  // {Real_Value, Imaginary_Value}
    
    output [DATA_WIDTH*2-1:0] o_data 
);
    localparam [0:0] SPARSE = 1'b0,
					 DENSE  = 1'b1;
    wire [DATA_WIDTH*2-1:0] comp_mul_0_in_0_wr, 
                            comp_mul_0_in_1_wr,
                            comp_mul_1_in_0_wr, 
                            comp_mul_1_in_1_wr,
                            comp_mul_0_out_wr, 
                            comp_mul_1_out_wr,
                            comp_add_in_0_wr,
                            comp_add_in_1_wr,
                            comp_add_out_wr;
    reg [2:0]               start_rg;
    reg                     op_mode_rg;

    assign comp_mul_0_in_0_wr = i_data_0;
    assign comp_mul_0_in_1_wr = i_data_1;
    assign comp_mul_1_in_0_wr = (op_mode_rg == SPARSE) ? comp_mul_0_out_wr : i_data_2;
    assign comp_mul_1_in_1_wr = (op_mode_rg == SPARSE) ? {(start_rg[1] == 1 || start_rg[2] == 1) ? {1 << NUM_FRAC_BIT, 0 << DATA_WIDTH} : comp_mul_1_out_wr} : i_data_3;
    assign comp_add_in_0_wr   = comp_mul_0_out_wr;
    assign comp_add_in_1_wr   = comp_mul_1_out_wr;
    assign o_data             = (op_mode_rg == SPARSE) ? comp_mul_1_out_wr : comp_add_out_wr; // Sparse || Dense

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            start_rg          <= 0;
            op_mode_rg        <= 0;
        end
        else begin
            start_rg[0] <= i_start;
            start_rg[1] <= start_rg[0];
            start_rg[2] <= start_rg[1];

            if(i_start) begin
                op_mode_rg <= i_op_mode;
            end
        end
    end

    Comp_Mul
    #(
        .DATA_WIDTH(DATA_WIDTH),
        .NUM_FRAC_BIT(NUM_FRAC_BIT)
    )
    Comp_Mul_inst_0
    (
        .clk(clk),
        .rst_n(rst_n),
        .i_num_0(comp_mul_0_in_0_wr),
        .i_num_1(comp_mul_0_in_1_wr),
        .o_res(comp_mul_0_out_wr)
    );

    Comp_Mul
    #(
        .DATA_WIDTH(DATA_WIDTH),
        .NUM_FRAC_BIT(NUM_FRAC_BIT)
    )
    Comp_Mul_inst_1
    (
        .clk(clk),
        .rst_n(rst_n),
        .i_num_0(comp_mul_1_in_0_wr),
        .i_num_1(comp_mul_1_in_1_wr),
        .o_res(comp_mul_1_out_wr)
    ); 

    Comp_Add
    #(
        .DATA_WIDTH(DATA_WIDTH)
    )
    Comp_Add_inst_0
    (
        .clk(clk),
        .rst_n(rst_n),
        .i_num_0(comp_add_in_0_wr),
        .i_num_1(comp_add_in_1_wr),
        .o_res(comp_add_out_wr)
    );
endmodule



// `timescale 1ns / 1ps

// module ALU 
// #(
//     parameter DATA_WIDTH   = 32,
//     parameter NUM_FRAC_BIT = 30
// )
// (  
//     input                     clk,
//     input                     rst_n,

//     input                     i_start,
//     input                     i_op_mode, // 0: Sparse || 1: Dense
//     input [DATA_WIDTH*2-1:0]  i_data_0,  // {Real_Value, Imaginary_Value}
//     input [DATA_WIDTH*2-1:0]  i_data_1,  // {Real_Value, Imaginary_Value}
//     input [DATA_WIDTH*2-1:0]  i_data_2,  // {Real_Value, Imaginary_Value}
//     input [DATA_WIDTH*2-1:0]  i_data_3,  // {Real_Value, Imaginary_Value}
    
//     output [DATA_WIDTH*2-1:0] o_data 
// );
//     localparam [0:0] SPARSE = 1'b0,
// 					 DENSE  = 1'b1;
//     wire [DATA_WIDTH*2-1:0] comp_mul_0_in_0_wr, 
//                             comp_mul_0_in_1_wr,
//                             comp_mul_1_in_0_wr, 
//                             comp_mul_1_in_1_wr,
//                             comp_mul_0_out_wr, 
//                             comp_mul_1_out_wr,
//                             comp_add_in_0_wr,
//                             comp_add_in_1_wr,
//                             comp_add_out_wr;
//     reg [2:0]               start_rg;
//     reg                     op_mode_rg;

//     assign comp_mul_0_in_0_wr = i_data_0;
//     assign comp_mul_0_in_1_wr = i_data_1;
//     assign comp_mul_1_in_0_wr = (op_mode_rg == SPARSE) ? comp_mul_0_out_wr : i_data_2;
//     assign comp_mul_1_in_1_wr = (op_mode_rg == SPARSE) ? {(start_rg[1] == 1 || start_rg[2] == 1) ? {1 << NUM_FRAC_BIT, 0 << DATA_WIDTH} : comp_mul_1_out_wr} : i_data_3;
//     assign comp_add_in_0_wr   = comp_mul_0_out_wr;
//     assign comp_add_in_1_wr   = comp_mul_1_out_wr;
//     assign o_data             = (op_mode_rg == SPARSE) ? comp_mul_1_out_wr : comp_add_out_wr; // Sparse || Dense

//     always @(posedge clk or negedge rst_n) begin
//         if (!rst_n) begin
//             start_rg          <= 0;
//             op_mode_rg        <= 0;
//         end 
//         else begin
//             start_rg[0] <= i_start;
//             start_rg[1] <= start_rg[0];
//             start_rg[2] <= start_rg[1];

//             if(i_start) begin
//                 op_mode_rg <= i_op_mode;
//             end
//         end
//     end

//     Comp_Mul
//     #(
//         .DATA_WIDTH(DATA_WIDTH),
//         .NUM_FRAC_BIT(NUM_FRAC_BIT)
//     )
//     Comp_Mul_inst_0
//     (
//         .clk(clk),
//         .rst_n(rst_n),
//         .i_num_0(i_data_0),
//         .i_num_1(i_data_1),
//         .o_res(comp_mul_0_out_wr)
//     );

//     Comp_Mul
//     #(
//         .DATA_WIDTH(DATA_WIDTH),
//         .NUM_FRAC_BIT(NUM_FRAC_BIT)
//     )
//     Comp_Mul_inst_1
//     (
//         .clk(clk),
//         .rst_n(rst_n),
//         .i_num_0(i_data_2),
//         .i_num_1(i_data_3),
//         .o_res(comp_mul_1_out_wr)
//     ); 

//     Comp_Add
//     #(
//         .DATA_WIDTH(DATA_WIDTH)
//     )
//     (
//         .clk(clk),
//         .rst_n(rst_n),
//         .i_num_0(comp_add_in_0_wr),
//         .i_num_1(comp_add_in_1_wr),
//         .o_res(comp_add_out_wr)
//     );
// endmodule
