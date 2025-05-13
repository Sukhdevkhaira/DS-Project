`timescale 1ns / 1ps

module PE
#(
	parameter PE_IDX		   = 0,
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
	input                                     clk,
	input                                     rst_n,

	// QEA Controller
	input                                     i_start,		    // Start PE operations
	input [MAX_QBIT_WIDTH-1:0]                i_qbit_num,   // The qubit number of the quantum circuit
	input [STATE_ADDR_WIDTH-1:0]		      i_exe_num,    // The number of consecutive values in charge in the state vector
	input [STATE_ADDR_WIDTH-1:0]		      i_start_state_pos,  // The start position to calculate
	input [1:0]                               i_op_mode,    // 0: Sparse || 1: Dense || 2: CX
	
	input                                     i_done_gate_coo_transfer,
	input                                     i_done_state_transfer,
	input                                     i_done_cx_computation,

	// Gate information
	input                                     i_gate_coo_valid,
    input [GATE_ADDR_WIDTH-1 : 0]             i_gate_coo_addr,
	input [GATE_DATA_WIDTH-1:0]               i_gate_coo,       // Gate data from COO Matrix Generator {Real_Value, Imaginary_Value}

    ///*** Local Data Memory ***///			
	input [PE_NUM_WIDTH+STATE_ADDR_WIDTH-1:0] i_ldm_addr,
	input [STATE_DATA_WIDTH-1:0]              i_ldm_data, // State vector from HBM
	input 					                  i_ldm_en,
	input 					                  i_ldm_we,
	
	input [STATE_DATA_WIDTH*4-1:0]            i_state_data_for_dense,

	output [STATE_DATA_WIDTH*2-1:0]           o_state_data_for_dense,

	output [STATE_DATA_WIDTH-1:0]             o_ldm_data,
	
	output									  o_done
);
	localparam [2:0] IDLE        = 3'b000, // 
					 GEN_MATRIX  = 3'b001, // Generate gate matrices
					 LOAD_STATE  = 3'b010, // Import state vector from off-chip memory
					 EXE         = 3'b011, // Execute
					 STORE_STATE = 3'b100, // Store the partial state vector
				 	 DONE        = 3'b101; // Done when complete the matrix multiplication of an U matrix with a state vector

	localparam [1:0] SPARSE = 2'b00,
					 DENSE  = 2'b01, 
					 CX     = 2'b10;

	// ALU signals
	wire [DATA_WIDTH*2-1:0] alu_out_0_wr, alu_out_1_wr;  // {Real_Value, Imaginary_Value}
	reg [DATA_WIDTH*2-1:0]  alu_in_0_rg, alu_in_1_rg, alu_in_2_rg, alu_in_3_rg, alu_in_4_rg, alu_in_5_rg, alu_in_6_rg, alu_in_7_rg;
	wire [1:0]              start_alu_wr, produce_new_state_wr, produce_last_gate_wr;
	reg start_alu_rg;
	wire [1:0]                    dense_data_out_from_lsu_wr;
	wire [7:0]					  sel_dense_val_wr;
	wire [1:0]                    which_swap_val_wr;

	// LSU signals
	wire [1:0]                    gate_en_wr;
	wire [1:0]                    gate_we_wr;
	wire [GATE_ADDR_WIDTH*2-1:0]  gate_addr_wr;

	wire [1:0]                    state_en_wr;
	wire [1:0]                    state_we_wr;
	wire [STATE_ADDR_WIDTH*2-1:0] state_addr_wr;

	wire [GATE_DATA_WIDTH*2-1:0]  gate_data_out_from_lsu_wr;
	wire [STATE_DATA_WIDTH*2-1:0] state_data_out_from_lsu_wr;

	wire [1:0]                   op_mode_wr;
	reg [1:0]                    op_mode_rg;

	reg [GATE_DATA_WIDTH-1:0]    dense_val_0_rg, dense_val_1_rg, dense_val_2_rg, dense_val_3_rg;

	assign o_state_data_for_dense = state_data_out_from_lsu_wr;

	assign o_ldm_data = state_data_out_from_lsu_wr[STATE_DATA_WIDTH*2-1 -: STATE_DATA_WIDTH];

	always @(posedge clk or negedge rst_n) begin
		if (!rst_n) begin
			op_mode_rg   <= 0;
			start_alu_rg <= 0;
		end
		else begin
			op_mode_rg   <= op_mode_wr;
			start_alu_rg <= start_alu_wr;
		end
	end


	always @(posedge clk or negedge rst_n) begin
		if (!rst_n) begin
			dense_val_0_rg <= 0;
			dense_val_1_rg <= 0;
			dense_val_2_rg <= 0;
			dense_val_3_rg <= 0;
		end
		else begin
			if(dense_data_out_from_lsu_wr[0] == 1'b1) begin
				dense_val_0_rg <= gate_data_out_from_lsu_wr[GATE_DATA_WIDTH*2-1 : GATE_DATA_WIDTH];
				dense_val_1_rg <= gate_data_out_from_lsu_wr[GATE_DATA_WIDTH-1:0];
			end
			else if(dense_data_out_from_lsu_wr[1] == 1'b1) begin
				dense_val_2_rg <= gate_data_out_from_lsu_wr[GATE_DATA_WIDTH*2-1 : GATE_DATA_WIDTH];
				dense_val_3_rg <= gate_data_out_from_lsu_wr[GATE_DATA_WIDTH-1:0];
			end
		end
	end

	always @(posedge clk or negedge rst_n) begin
		if (!rst_n) begin
			alu_in_0_rg <= 0;
			alu_in_1_rg <= 0;
			alu_in_2_rg <= 0;
			alu_in_3_rg <= 0;
			alu_in_4_rg <= 0;
			alu_in_5_rg <= 0;
			alu_in_6_rg <= 0;
			alu_in_7_rg <= 0;
		end
		else begin
			if(op_mode_wr == SPARSE) begin
				if(produce_new_state_wr) begin
					if(produce_last_gate_wr) begin
						alu_in_0_rg <= gate_data_out_from_lsu_wr[GATE_DATA_WIDTH*2-1 -: GATE_DATA_WIDTH];
						alu_in_4_rg <= gate_data_out_from_lsu_wr[GATE_DATA_WIDTH*2-1 -: GATE_DATA_WIDTH];
					end
					else begin
						alu_in_0_rg <= {32'd1, 32'd0};
						alu_in_4_rg <= {32'd1, 32'd0};
					end

					alu_in_1_rg <= state_data_out_from_lsu_wr[STATE_DATA_WIDTH*2-1 -: STATE_DATA_WIDTH];
					alu_in_5_rg <= state_data_out_from_lsu_wr[STATE_DATA_WIDTH*2-1 -: STATE_DATA_WIDTH];
				end
				else begin
					alu_in_0_rg <= gate_data_out_from_lsu_wr[GATE_DATA_WIDTH*2-1 -: GATE_DATA_WIDTH];
					alu_in_1_rg <= gate_data_out_from_lsu_wr[GATE_DATA_WIDTH-1:0];
					alu_in_4_rg <= gate_data_out_from_lsu_wr[GATE_DATA_WIDTH*2-1 -: GATE_DATA_WIDTH];
					alu_in_5_rg <= gate_data_out_from_lsu_wr[GATE_DATA_WIDTH-1:0];
				end

				alu_in_2_rg <= 0;
				alu_in_3_rg <= 0;
				alu_in_6_rg <= 0;
				alu_in_7_rg <= 0;
			end
			else if (op_mode_wr == DENSE) begin
				alu_in_0_rg <= (sel_dense_val_wr[7:6] == 0) ? dense_val_0_rg : {(sel_dense_val_wr[7:6] == 1) ? dense_val_1_rg : {(sel_dense_val_wr[7:6] == 2) ? dense_val_2_rg : dense_val_3_rg}};
				alu_in_2_rg <= (sel_dense_val_wr[5:4] == 0) ? dense_val_0_rg : {(sel_dense_val_wr[5:4] == 1) ? dense_val_1_rg : {(sel_dense_val_wr[5:4] == 2) ? dense_val_2_rg : dense_val_3_rg}};
				alu_in_4_rg <= (sel_dense_val_wr[3:2] == 0) ? dense_val_0_rg : {(sel_dense_val_wr[3:2] == 1) ? dense_val_1_rg : {(sel_dense_val_wr[3:2] == 2) ? dense_val_2_rg : dense_val_3_rg}};
				alu_in_6_rg <= (sel_dense_val_wr[1:0] == 0) ? dense_val_0_rg : {(sel_dense_val_wr[1:0] == 1) ? dense_val_1_rg : {(sel_dense_val_wr[1:0] == 2) ? dense_val_2_rg : dense_val_3_rg}};

				if(which_swap_val_wr == 0) begin
					alu_in_1_rg <= state_data_out_from_lsu_wr[STATE_DATA_WIDTH*2-1 -: STATE_DATA_WIDTH];
					alu_in_3_rg <= state_data_out_from_lsu_wr[STATE_DATA_WIDTH-1:0];
					alu_in_5_rg <= state_data_out_from_lsu_wr[STATE_DATA_WIDTH*2-1 -: STATE_DATA_WIDTH];
					alu_in_7_rg <= state_data_out_from_lsu_wr[STATE_DATA_WIDTH-1:0];
				end
				else if(which_swap_val_wr == 1) begin
					if(PE_IDX == 0 || PE_IDX == 2) begin
						alu_in_1_rg <= state_data_out_from_lsu_wr[STATE_DATA_WIDTH*2-1 -: STATE_DATA_WIDTH];
						alu_in_3_rg <= i_state_data_for_dense[STATE_DATA_WIDTH*4-1 -: STATE_DATA_WIDTH];

						alu_in_5_rg <= state_data_out_from_lsu_wr[STATE_DATA_WIDTH-1:0];
						alu_in_7_rg <= i_state_data_for_dense[STATE_DATA_WIDTH*3-1 -: STATE_DATA_WIDTH];
					end
					else if(PE_IDX == 1 || PE_IDX == 3) begin
						alu_in_1_rg <= i_state_data_for_dense[STATE_DATA_WIDTH*4-1 -: STATE_DATA_WIDTH];
						alu_in_3_rg <= state_data_out_from_lsu_wr[STATE_DATA_WIDTH*2-1 -: STATE_DATA_WIDTH];

						alu_in_5_rg <= i_state_data_for_dense[STATE_DATA_WIDTH*3-1 -: STATE_DATA_WIDTH];
						alu_in_7_rg <= state_data_out_from_lsu_wr[STATE_DATA_WIDTH-1:0];
					end
				end
				else if(which_swap_val_wr == 2) begin
					if(PE_IDX == 0 || PE_IDX == 1) begin
						alu_in_1_rg <= state_data_out_from_lsu_wr[STATE_DATA_WIDTH*2-1 -: STATE_DATA_WIDTH];
						alu_in_3_rg <= i_state_data_for_dense[STATE_DATA_WIDTH*2-1 -: STATE_DATA_WIDTH];

						alu_in_5_rg <= state_data_out_from_lsu_wr[STATE_DATA_WIDTH-1:0];
						alu_in_7_rg <= i_state_data_for_dense[STATE_DATA_WIDTH-1:0];
					end
					else if(PE_IDX == 2 || PE_IDX == 3) begin
						alu_in_1_rg <= i_state_data_for_dense[STATE_DATA_WIDTH*2-1 -: STATE_DATA_WIDTH];
						alu_in_3_rg <= state_data_out_from_lsu_wr[STATE_DATA_WIDTH*2-1 -: STATE_DATA_WIDTH];

						alu_in_5_rg <= i_state_data_for_dense[STATE_DATA_WIDTH-1:0];
						alu_in_7_rg <= state_data_out_from_lsu_wr[STATE_DATA_WIDTH-1:0];
					end
				end
			end
		end
	end

	PE_Controller
	#(
		.PE_IDX(PE_IDX),
		.DATA_WIDTH(DATA_WIDTH),
		.MAX_QBIT_WIDTH(MAX_QBIT_WIDTH),
		.STATE_ADDR_WIDTH(STATE_ADDR_WIDTH),
		.GATE_DATA_WIDTH(GATE_DATA_WIDTH),
		.GATE_ADDR_WIDTH(GATE_ADDR_WIDTH)
	)
	PE_Controller_inst
	(  
		.clk(clk),
		.rst_n(rst_n),

		// QEA Controller
		.i_start(i_start), // Start PE operations
		.i_qbit_num(i_qbit_num),   // The qubit number of the quantum circuit
		.i_exe_num(i_exe_num),    // The number of consecutive values in charge in the state vector
		.i_start_state_pos(i_start_state_pos),  // The start position to calculate
		.i_op_mode(i_op_mode),    // 0: Sparse || 1: Dense || 2: CX

		.i_done_gate_coo_transfer(i_done_gate_coo_transfer),
		.i_done_state_transfer(i_done_state_transfer),
		.i_done_cx_computation(i_done_cx_computation),

		// Gate information
		.i_gate(gate_data_out_from_lsu_wr),

		
		///*** Output ***///
		// Local Data Memory - State
		.o_state_en(state_en_wr),
		.o_state_we(state_we_wr),
		.o_state_addr(state_addr_wr),

		// Local Data Memory - Gate
		.o_gate_en(gate_en_wr),
		.o_gate_we(gate_we_wr),
		.o_gate_addr(gate_addr_wr),

		// ALU
		.o_start_alu(start_alu_wr),
		.o_alu_mode(op_mode_wr),
		.o_dense_data_out_from_lsu(dense_data_out_from_lsu_wr),
		.o_sel_dense_val(sel_dense_val_wr),
		.o_which_swap_val(which_swap_val_wr),
		.o_produce_new_state(produce_new_state_wr),
		.o_produce_last_gate(produce_last_gate_wr),

		.o_done(o_done)
	);

	LSU
	#(
		.PE_IDX(PE_IDX),
		.STATE_DATA_WIDTH(STATE_DATA_WIDTH),
		.STATE_ADDR_WIDTH(STATE_ADDR_WIDTH),
		.GATE_DATA_WIDTH(GATE_DATA_WIDTH),
		.GATE_ADDR_WIDTH(GATE_ADDR_WIDTH),
		.PE_NUM_WIDTH(PE_NUM_WIDTH)
	)
	lsu_ins
	(
		.clk(clk),         
		.rst_n(rst_n), 

		.i_state_ram_off_chip_en(i_ldm_en),  
		.i_state_ram_off_chip_we(i_ldm_we),  
		.i_state_ram_off_chip_addr(i_ldm_addr),
		.i_state_ram_off_chip_data(i_ldm_data),
		
		.i_gate_coo_en(i_gate_coo_valid),  
		.i_gate_coo_we(i_gate_coo_valid),  
		.i_gate_coo_addr(i_gate_coo_addr),
		.i_gate_coo_data(i_gate_coo),

		.i_state_en(state_en_wr),  
		.i_state_we(state_we_wr),  
		.i_state_addr(state_addr_wr),
		.i_state_data((op_mode_wr == SPARSE) ? {64'b0, alu_out_0_wr} : {alu_out_0_wr, alu_out_1_wr}),

		.i_gate_en(gate_en_wr),  
		.i_gate_we(gate_we_wr),  
		.i_gate_addr(gate_addr_wr), 
		.i_gate_data(128'b0),

		.o_state_data(state_data_out_from_lsu_wr), 
		.o_gate_data(gate_data_out_from_lsu_wr) 
	);

	ALU 
	#(
		.DATA_WIDTH(ALU_DATA_WIDTH)
	)
	alu_ins
	(  
		.clk(clk),
		.rst_n(rst_n),
		.i_start(start_alu_wr),
		.i_op_mode(op_mode_wr[0]),
		.i_data_0(alu_in_0_rg),
		.i_data_1(alu_in_1_rg),
		.i_data_2(alu_in_2_rg),
		.i_data_3(alu_in_3_rg),
		.i_data_4(alu_in_4_rg),
		.i_data_5(alu_in_5_rg),
		.i_data_6(alu_in_6_rg),
		.i_data_7(alu_in_7_rg),
		.o_data_0(alu_out_0_wr),
		.o_data_1(alu_out_1_wr)
	);
endmodule