`timescale 1ns / 1ps

module PEA
#(
	parameter PE_NUM_WIDTH     = 2,
	parameter PE_NUM           = 4,
	parameter DATA_WIDTH       = 32,
	parameter MAX_QBIT_WIDTH   = 6,
	parameter STATE_ADDR_WIDTH = 16,
	parameter STATE_DATA_WIDTH = DATA_WIDTH*2,
	parameter GATE_ADDR_WIDTH  = 6,
	parameter GATE_DATA_WIDTH  = DATA_WIDTH*2,
	parameter ALU_DATA_WIDTH   = DATA_WIDTH,
	parameter NUM_FRAC_BIT     = 30
)
(
    input                                              clk,
    input                                              rst_n,

	input                                              i_start,
	input [MAX_QBIT_WIDTH-1:0]		                   i_qbit_num, 
	input [STATE_ADDR_WIDTH-1:0]                       i_exe_num,
	input [PE_NUM*STATE_ADDR_WIDTH-1:0]                i_start_state_pos,
	input [1:0]                                        i_op_mode, 

	input                                              i_done_gate_coo_transfer,
	input                                              i_done_state_transfer,
	input                                              i_done_cx_computation,

	input                                              i_gate_coo_valid,
    input [GATE_ADDR_WIDTH-1 : 0]                      i_gate_coo_addr,
	input [GATE_DATA_WIDTH-1:0]                        i_gate_coo, 
	
	input [PE_NUM*STATE_ADDR_WIDTH-1:0]                i_ldm_addr,
	input [PE_NUM*STATE_DATA_WIDTH-1:0]                i_ldm_data,
	input [PE_NUM-1:0]				                   i_ldm_en,
	input [PE_NUM-1:0]				                   i_ldm_we,

	output [PE_NUM*STATE_DATA_WIDTH-1:0]               o_ldm_data,

    output                                             o_done
);
    wire [PE_NUM-1:0]             done_wr;
    wire [STATE_DATA_WIDTH*2*4-1:0] state_data_for_dense_o_wr;
    wire [STATE_DATA_WIDTH*4*4-1:0] state_data_for_dense_i_wr;

    assign state_data_for_dense_i_wr[STATE_DATA_WIDTH*4*4-1 -: STATE_DATA_WIDTH*4] = {state_data_for_dense_o_wr[STATE_DATA_WIDTH*2*3-1 -: STATE_DATA_WIDTH*2], state_data_for_dense_o_wr[STATE_DATA_WIDTH*2*2-1 -: STATE_DATA_WIDTH*2]};
    assign state_data_for_dense_i_wr[STATE_DATA_WIDTH*4*3-1 -: STATE_DATA_WIDTH*4] = {state_data_for_dense_o_wr[STATE_DATA_WIDTH*2*4-1 -: STATE_DATA_WIDTH*2], state_data_for_dense_o_wr[STATE_DATA_WIDTH*2*1-1 -: STATE_DATA_WIDTH*2]};
    assign state_data_for_dense_i_wr[STATE_DATA_WIDTH*4*2-1 -: STATE_DATA_WIDTH*4] = {state_data_for_dense_o_wr[STATE_DATA_WIDTH*2*1-1 -: STATE_DATA_WIDTH*2], state_data_for_dense_o_wr[STATE_DATA_WIDTH*2*4-1 -: STATE_DATA_WIDTH*2]};
    assign state_data_for_dense_i_wr[STATE_DATA_WIDTH*4*1-1 -: STATE_DATA_WIDTH*4] = {state_data_for_dense_o_wr[STATE_DATA_WIDTH*2*2-1 -: STATE_DATA_WIDTH*2], state_data_for_dense_o_wr[STATE_DATA_WIDTH*2*3-1 -: STATE_DATA_WIDTH*2]};

    assign o_done = &done_wr;

    genvar i;
    generate
		for (i = 0; i < PE_NUM; i = i + 1) begin: gen_PE
            PE
            #(
                .PE_IDX(i),
                .PE_NUM_WIDTH(PE_NUM_WIDTH),
                .PE_NUM(PE_NUM),
                .DATA_WIDTH(DATA_WIDTH),
                .MAX_QBIT_WIDTH(MAX_QBIT_WIDTH),
                .STATE_DATA_WIDTH(STATE_DATA_WIDTH),
                .STATE_ADDR_WIDTH(STATE_ADDR_WIDTH),
                .GATE_DATA_WIDTH(GATE_DATA_WIDTH),
                .GATE_ADDR_WIDTH(GATE_ADDR_WIDTH),
                .ALU_DATA_WIDTH(ALU_DATA_WIDTH),
                .NUM_FRAC_BIT(NUM_FRAC_BIT)
            )
            PE_inst
            (  
                .clk(clk),
                .rst_n(rst_n),

                .i_start(i_start), 
                .i_qbit_num(i_qbit_num),
                .i_exe_num(i_exe_num), 
                .i_start_state_pos(i_start_state_pos[(PE_NUM-i)*STATE_ADDR_WIDTH-1 -: STATE_ADDR_WIDTH]),
                .i_op_mode(i_op_mode), 

                .i_done_gate_coo_transfer(i_done_gate_coo_transfer),
                .i_done_state_transfer(i_done_state_transfer),
                .i_done_cx_computation(i_done_cx_computation),

                .i_gate_coo_valid(i_gate_coo_valid),
                .i_gate_coo_addr(i_gate_coo_addr),
                .i_gate_coo(i_gate_coo), 
		
                .i_ldm_addr({i, i_ldm_addr[(PE_NUM-i)*STATE_ADDR_WIDTH-1 -: STATE_ADDR_WIDTH]}),
                .i_ldm_data(i_ldm_data[(PE_NUM-i)*STATE_DATA_WIDTH-1 -: STATE_DATA_WIDTH]),
                .i_ldm_en(i_ldm_en[PE_NUM-1-i]),
                .i_ldm_we(i_ldm_we[PE_NUM-1-i]),

                .i_state_data_for_dense(state_data_for_dense_i_wr[(PE_NUM-i)*STATE_DATA_WIDTH*4-1 -: STATE_DATA_WIDTH*4]),
                .o_state_data_for_dense(state_data_for_dense_o_wr[(PE_NUM-i)*STATE_DATA_WIDTH*2-1 -: STATE_DATA_WIDTH*2]),

                .o_ldm_data(o_ldm_data[(PE_NUM-i)*STATE_DATA_WIDTH-1 -: STATE_DATA_WIDTH]),
                .o_done(done_wr[PE_NUM-1-i])
            );
		end
	endgenerate 
endmodule