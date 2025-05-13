`timescale 1ns / 1ps

module PE_Controller
#(
	parameter PE_IDX		   = 0,
	parameter DATA_WIDTH       = 32,
	parameter MAX_QBIT_WIDTH   = 6,
	parameter STATE_ADDR_WIDTH = 16,
	parameter GATE_DATA_WIDTH  = DATA_WIDTH*2,
	parameter GATE_ADDR_WIDTH  = 6
)
(  
	///*** Input ***///
	// Clock and Reset
	input                           clk,
	input                           rst_n,

	// QEA Controller
	input                           i_start, // Start PE operations
	input [MAX_QBIT_WIDTH-1:0]      i_qbit_num,   // The qubit number of the quantum circuit
	input [STATE_ADDR_WIDTH-1:0]	i_exe_num,    // The number of consecutive values in charge in the state vector
	input [STATE_ADDR_WIDTH-1:0]	i_start_state_pos,  // The start position to calculate
	input [1:0]                     i_op_mode,    // 0: Sparse || 1: Dense || 2: CX

	input                           i_done_gate_coo_transfer,
	input                           i_done_state_transfer,
	input                           i_done_cx_computation,

	// Gate information
	input [GATE_DATA_WIDTH*2-1:0]   i_gate,

	///*** Output ***///
	// Local Data Memory - State
	output [1:0]                    o_state_en,
	output [1:0]                    o_state_we,
	output [STATE_ADDR_WIDTH*2-1:0] o_state_addr,

	// Local Data Memory - Gate
	output [1:0]                    o_gate_en,
	output [1:0]                    o_gate_we,
	output [GATE_ADDR_WIDTH*2-1:0]  o_gate_addr,

	// ALU
	output [1:0]                    o_start_alu,
	output [1:0]                    o_alu_mode,
	output [1:0]                    o_dense_data_out_from_lsu,
	output [7:0]					o_sel_dense_val,
	output [1:0]                    o_which_swap_val,
	output [1:0]                    o_produce_new_state,
	output [1:0]                    o_produce_last_gate,

	output                          o_done
);
	localparam [2:0] IDLE        = 3'b000, 
					 EXE         = 3'b001, // Execute
				 	 DONE        = 3'b010; // Done when complete the matrix multiplication of an U matrix with a state vector

	localparam [1:0] SPARSE = 2'b00,
					 DENSE  = 2'b01, 
					 CX     = 2'b10;

	// Local Data Memory - Gate
	reg [1:0]                     gate_en_rg;
	reg [1:0]                     gate_we_rg;
	reg [GATE_ADDR_WIDTH*2-1:0]   gate_addr_rg;

	reg [MAX_QBIT_WIDTH-1:0]   dense_gate_position_rg;

	// Local Data Memory - State
	reg [1:0]                     state_en_rg;
	reg [1:0]                     state_we_rg;
	reg [STATE_ADDR_WIDTH*2-1:0]  state_addr_rg;
	reg [STATE_ADDR_WIDTH-1:0]    state_addr_tmp_0_0_rg, state_addr_tmp_0_1_rg, state_addr_tmp_0_2_rg, state_addr_tmp_0_3_rg, state_addr_tmp_0_4_rg, state_addr_tmp_0_5_rg, last_state_addr_tmp_0_rg;
	reg [STATE_ADDR_WIDTH-1:0]    state_addr_tmp_1_0_rg, state_addr_tmp_1_1_rg, state_addr_tmp_1_2_rg, state_addr_tmp_1_3_rg, state_addr_tmp_1_4_rg, state_addr_tmp_1_5_rg, last_state_addr_tmp_1_rg;

	// Signals for managing FSM
	reg [2:0] working_state_rg;
	reg       done_exe_rg;

    // Required information from QEA Controller
	reg [MAX_QBIT_WIDTH-1:0]   qbit_num_rg;   // The qubit number of the quantum circuit
	reg [STATE_ADDR_WIDTH-1:0] exe_num_rg;    // The number of consecutive values in charge in the state vector
	// reg [STATE_ADDR_WIDTH-1:0] start_state_pos_rg;  // The start position to calculate
	reg [1:0]                  op_mode_rg;

	// Signals for managing the execution of the PE
	reg [1:0]                  start_alu_rg;
	reg [7:0]				   sel_dense_val_0_rg, sel_dense_val_1_rg;
	reg [1:0]                  which_swap_val_rg;
	reg [STATE_ADDR_WIDTH-1:0] computed_state_value_counter_rg;
	reg [GATE_ADDR_WIDTH-1:0]  computed_gate_counter_0_rg, computed_gate_counter_1_rg; // For sparse gates
	reg [STATE_ADDR_WIDTH-1:0] current_state_pos_0_rg, current_state_pos_1_rg;
	reg [5:0]                  produce_new_state_0_rg, produce_new_state_1_rg;

	// Sparse gate execution
	reg add_0_or_1_0, add_0_or_1_1;

	// Dense gate execution
	reg [DATA_WIDTH-1:0]  dense_step_counter_rg;
	reg [1:0]             dense_data_out_from_lsu_rg;

	wire [DATA_WIDTH-1:0] package_num_bit_wr;
	wire [DATA_WIDTH-1:0] package_len_wr;
	reg [DATA_WIDTH-1:0]  start_pkg_addr, current_ptr_in_pkg_rg;
	wire                  which_package_wr; // Even or odd package

	reg even_bit_rg;
	reg done_rg;

	assign o_done = done_rg;

	// Local Data Memory - State
	assign o_state_en   = state_en_rg;
	assign o_state_we   = state_we_rg;
	assign o_state_addr = state_addr_rg;

	// Local Data Memory - Gate
	assign o_gate_en   = gate_en_rg;
	assign o_gate_we   = gate_we_rg;
	assign o_gate_addr = gate_addr_rg;

	// ALU
	assign o_alu_mode                = op_mode_rg;
	assign o_start_alu               = start_alu_rg;
	assign o_dense_data_out_from_lsu = dense_data_out_from_lsu_rg[1:0];
	assign o_sel_dense_val           = sel_dense_val_1_rg;
	assign o_which_swap_val          = which_swap_val_rg;

	// Finite State Machine for PE working
	always @(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
			working_state_rg <= IDLE;
			op_mode_rg	   <= 0;
			qbit_num_rg	<= 0;
			exe_num_rg	 <= 0;
			// start_state_pos_rg <= 0;
		end
		else begin
			if(working_state_rg == IDLE) begin
				if(working_state_rg == IDLE && i_start) begin
					working_state_rg   <= EXE;
					
					qbit_num_rg        <= i_qbit_num;
					exe_num_rg         <= i_exe_num;
					// start_state_pos_rg <= i_start_state_pos; // PE_IDX * (1 << (i_qbit_num - 2));
					op_mode_rg         <= i_op_mode;
				end
				else begin
					working_state_rg <= working_state_rg;
				end
			end
			else begin
				if(working_state_rg == EXE && (done_exe_rg || i_done_cx_computation)) begin
					working_state_rg <= DONE;
				end
				else if(working_state_rg == DONE) begin
					working_state_rg <= IDLE;
				end
			end
		end
	end

	// For dense gate
	assign package_num_bit_wr = qbit_num_rg - (dense_gate_position_rg + 1);
	assign package_len_wr     = (1 << package_num_bit_wr);
	assign which_package_wr   = (current_state_pos_0_rg >> package_num_bit_wr) & 1;

	assign o_produce_new_state = (op_mode_rg == SPARSE) ? {produce_new_state_0_rg[1], produce_new_state_1_rg[1]} : {produce_new_state_0_rg[0], produce_new_state_1_rg[0]};
	assign o_produce_last_gate = (op_mode_rg == SPARSE && qbit_num_rg[0] == 1) ? {produce_new_state_0_rg[1], produce_new_state_1_rg[1]} : 0;

	always @(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
			start_alu_rg                    <= 0;
			sel_dense_val_0_rg <= 0;
			sel_dense_val_1_rg <= 0;
			dense_data_out_from_lsu_rg	    <= 0;
			current_state_pos_0_rg            <= 0;
			current_state_pos_1_rg            <= 0;
			computed_gate_counter_0_rg        <= 0;
			computed_gate_counter_1_rg        <= 0;
			computed_state_value_counter_rg <= 0;
			done_exe_rg                     <= 0;
			produce_new_state_0_rg	        <= 0;
			produce_new_state_1_rg	        <= 0;
			dense_step_counter_rg 			<= 0;
			even_bit_rg					    <= 0;
			done_rg                            <= 0;
		end
		else begin
			produce_new_state_0_rg[5:1] <= produce_new_state_0_rg[4:0];
			produce_new_state_1_rg[5:1] <= produce_new_state_1_rg[4:0];

			state_addr_tmp_0_1_rg <= state_addr_tmp_0_0_rg;
			state_addr_tmp_0_2_rg <= state_addr_tmp_0_1_rg;
			state_addr_tmp_0_3_rg <= state_addr_tmp_0_2_rg;
			state_addr_tmp_0_4_rg <= state_addr_tmp_0_3_rg;
			state_addr_tmp_0_5_rg <= state_addr_tmp_0_4_rg;

			state_addr_tmp_1_1_rg <= state_addr_tmp_1_0_rg;
			state_addr_tmp_1_2_rg <= state_addr_tmp_1_1_rg;
			state_addr_tmp_1_3_rg <= state_addr_tmp_1_2_rg;
			state_addr_tmp_1_4_rg <= state_addr_tmp_1_3_rg;
			state_addr_tmp_1_5_rg <= state_addr_tmp_1_4_rg;

			dense_data_out_from_lsu_rg[1] <= dense_data_out_from_lsu_rg[0];

			sel_dense_val_1_rg <= sel_dense_val_0_rg;

			if(done_rg == 1) begin
				state_en_rg <= 0;
				state_we_rg <= 0;
				done_rg     <= 0;
			end
			else begin
				case(op_mode_rg)
					// SPARSE: begin
					// 	if(!done_exe_rg && working_state_rg == EXE) begin
					// 		if(computed_gate_counter_0_rg == 0 && computed_state_value_counter_rg == 0) begin
					// 			start_alu_rg[0] <= 1;
					// 			start_alu_rg[1] <= 0;
					// 		end
					// 		else begin
					// 			start_alu_rg[0] <= 0;
					// 			start_alu_rg[1] <= start_alu_rg[0];
					// 		end

					// 		even_bit_rg <= ~even_bit_rg;

					// 		gate_en_rg   <= 2'b11;
					// 		gate_we_rg   <= 2'b00;

					// 		if(even_bit_rg == 0) begin
					// 			add_0_or_1_0 = current_state_pos_0_rg >> (qbit_num_rg - (computed_gate_counter_0_rg+1));
					// 			add_0_or_1_1 = current_state_pos_0_rg >> (qbit_num_rg - (computed_gate_counter_0_rg+2));
					// 			gate_addr_rg[GATE_ADDR_WIDTH*2-1 -: GATE_ADDR_WIDTH] <= (computed_gate_counter_0_rg<<1)+add_0_or_1_0;
					// 			gate_addr_rg[GATE_ADDR_WIDTH-1:0] <= ((computed_gate_counter_0_rg+1)<<1)+add_0_or_1_1;

					// 			if(computed_gate_counter_0_rg <= qbit_num_rg-2) begin
					// 				computed_gate_counter_0_rg <= computed_gate_counter_0_rg + 2;
					// 				produce_new_state_0_rg[0]  <= 0;
					// 			end
					// 			else if(computed_gate_counter_0_rg == qbit_num_rg || computed_gate_counter_0_rg == qbit_num_rg-1) begin
					// 				computed_gate_counter_0_rg <= 0;
					// 				produce_new_state_0_rg[0]  <= 1;

					// 				if(computed_state_value_counter_rg < exe_num_rg - 2) begin
					// 					state_en_rg[0]   <= 1;
					// 					state_we_rg[0]   <= 0;
					// 					state_addr_rg[STATE_ADDR_WIDTH*2-1 -: STATE_ADDR_WIDTH] <= computed_state_value_counter_rg;
					// 					state_addr_tmp_0_0_rg <= computed_state_value_counter_rg;

					// 					computed_state_value_counter_rg <= computed_state_value_counter_rg + 1;
					// 					current_state_pos_0_rg            <= current_state_pos_0_rg + 1;
					// 				end
					// 				else begin
					// 					computed_state_value_counter_rg <= 0;
					// 					// done_exe_rg                     <= 1;
					// 				end
					// 			end
					// 		end
					// 		else begin
					// 			add_0_or_1_0 = current_state_pos_1_rg >> (qbit_num_rg - (computed_gate_counter_1_rg+1));
					// 			add_0_or_1_1 = current_state_pos_1_rg >> (qbit_num_rg - (computed_gate_counter_1_rg+2));
					// 			gate_addr_rg[GATE_ADDR_WIDTH*2-1 -: GATE_ADDR_WIDTH] <= (computed_gate_counter_1_rg<<1)+add_0_or_1_0;
					// 			gate_addr_rg[GATE_ADDR_WIDTH-1:0] <= ((computed_gate_counter_1_rg+1)<<1)+add_0_or_1_1;

					// 			if(computed_gate_counter_1_rg <= qbit_num_rg-1) begin
					// 				computed_gate_counter_1_rg <= computed_gate_counter_1_rg + 2;
					// 				produce_new_state_1_rg[0]  <= 0;
					// 			end
					// 			else if(computed_gate_counter_1_rg == qbit_num_rg || computed_gate_counter_1_rg == qbit_num_rg-1) begin
					// 				computed_gate_counter_1_rg <= 0;
					// 				produce_new_state_1_rg[0]  <= 1;

					// 				if(computed_state_value_counter_rg < exe_num_rg - 2) begin
					// 					state_en_rg[0]   <= 1;
					// 					state_we_rg[0]   <= 0;
					// 					state_addr_rg[STATE_ADDR_WIDTH*2-1 -: STATE_ADDR_WIDTH] <= computed_state_value_counter_rg;
					// 					state_addr_tmp_1_0_rg <= computed_state_value_counter_rg;

					// 					computed_state_value_counter_rg <= computed_state_value_counter_rg + 1;
					// 					current_state_pos_1_rg            <= current_state_pos_1_rg + 1;
					// 				end
					// 				else begin
					// 					computed_state_value_counter_rg <= 0;
					// 					done_exe_rg                     <= 1;
					// 				end
					// 			end
					// 		end
					// 	end
					// 	else if(done_exe_rg) begin
					// 		gate_en_rg   <= 2'b00;
					// 		gate_we_rg   <= 2'b00;
					// 		produce_new_state_0_rg[0]  <= 0;
					// 		produce_new_state_1_rg[0]  <= 0;
					// 	end

					// 	if(produce_new_state_0_rg[4] == 1) begin
					// 		state_en_rg[1] <= 1;
					// 		state_we_rg[1] <= 1;

					// 		if(state_addr_tmp_0_5_rg == last_state_addr_tmp_0_rg && state_addr_tmp_0_5_rg != 0) begin
					// 			state_addr_rg[STATE_ADDR_WIDTH-1:0] <= state_addr_tmp_0_5_rg + 1;
					// 			done_rg <= 1;
					// 		end
					// 		else begin
					// 			state_addr_rg[STATE_ADDR_WIDTH-1:0] <= state_addr_tmp_0_5_rg;
					// 		end

					// 		last_state_addr_tmp_0_rg <= state_addr_tmp_0_5_rg;
					// 	end
					// 	else if(produce_new_state_1_rg[5] == 1) begin
					// 		state_en_rg[1] <= 1;
					// 		state_we_rg[1] <= 1;

					// 		if(state_addr_tmp_1_5_rg == last_state_addr_tmp_1_rg && state_addr_tmp_1_5_rg != 0) begin
					// 			state_addr_rg[STATE_ADDR_WIDTH-1:0] <= state_addr_tmp_1_5_rg + 1;
					// 			done_rg <= 1;
					// 		end
					// 		else begin
					// 			state_addr_rg[STATE_ADDR_WIDTH-1:0] <= state_addr_tmp_1_5_rg;
					// 		end

					// 		last_state_addr_tmp_1_rg <= state_addr_tmp_1_5_rg;
					// 	end
					// 	else begin
					// 		state_en_rg[1] <= 0;
					// 		state_we_rg[1] <= 0;
					// 	end
					// end
					DENSE: begin
						if(!done_exe_rg && working_state_rg == EXE) begin
							if(dense_step_counter_rg == 0) begin
								start_alu_rg[0]       <= 1;
								current_ptr_in_pkg_rg <= 0;
								start_pkg_addr		  <= 0;
							end
							else begin
								start_alu_rg[0] <= 0;
								start_alu_rg[1] <= start_alu_rg[0];
							end

							dense_step_counter_rg <= dense_step_counter_rg + 1;

							if(dense_step_counter_rg == 0) begin // Read the dense gate position
								gate_en_rg[0]    <= 1;
								gate_we_rg[0]    <= 0;
								gate_addr_rg[GATE_ADDR_WIDTH*2-1 -: GATE_ADDR_WIDTH] <= 0;

								gate_en_rg[1]    <= 0;
								gate_we_rg[1]    <= 0;
								gate_addr_rg[GATE_ADDR_WIDTH-1 -: GATE_ADDR_WIDTH] <= 0;
							end
							else if(dense_step_counter_rg == 1) begin // Read the 1st and 2nd values of the dense gate
								gate_en_rg    <= 2'b11;
								gate_we_rg    <= 0;
								gate_addr_rg[GATE_ADDR_WIDTH*2-1 -: GATE_ADDR_WIDTH] <= 1;
								gate_addr_rg[GATE_ADDR_WIDTH-1 -: GATE_ADDR_WIDTH] <= 2;
							end
							else if(dense_step_counter_rg == 2) begin // Read the 3rd and 4th values of the dense gate
								dense_data_out_from_lsu_rg[0] <= 1;

								gate_en_rg    <= 2'b11;
								gate_we_rg    <= 0;
								gate_addr_rg[GATE_ADDR_WIDTH*2-1 -: GATE_ADDR_WIDTH] <= 3;
								gate_addr_rg[GATE_ADDR_WIDTH-1 -: GATE_ADDR_WIDTH] <= 4;

								dense_gate_position_rg <= i_gate[GATE_DATA_WIDTH+MAX_QBIT_WIDTH-1:GATE_DATA_WIDTH]; // Receive dense gate position

								if(i_gate[GATE_DATA_WIDTH+MAX_QBIT_WIDTH-1:GATE_DATA_WIDTH] > 1)       which_swap_val_rg <= 0;
								if(i_gate[GATE_DATA_WIDTH+MAX_QBIT_WIDTH-1:GATE_DATA_WIDTH] == 1)      which_swap_val_rg <= 1; // Receive which swap value from the next to PE
								else if(i_gate[GATE_DATA_WIDTH+MAX_QBIT_WIDTH-1:GATE_DATA_WIDTH] == 0) which_swap_val_rg <= 2;
							end
							else if(dense_step_counter_rg == 3) begin
								dense_data_out_from_lsu_rg[0] <= 0;

								gate_en_rg   <= 0;
								gate_we_rg   <= 0;
								gate_addr_rg <= 0;

								even_bit_rg <= 0;
							end
							else if(dense_step_counter_rg > 4) begin
								even_bit_rg <= ~even_bit_rg;

								if(even_bit_rg == 0) begin
									if(which_swap_val_rg == 0) begin
										sel_dense_val_0_rg <= {2'b00, 2'b01, 2'b10, 2'b11};
									end
									else if(which_swap_val_rg == 1) begin
										if(PE_IDX == 0 || PE_IDX == 2) begin
											sel_dense_val_0_rg <= {2'b00, 2'b01, 2'b00, 2'b01};
										end
										else if(PE_IDX == 1 || PE_IDX == 3) begin
											sel_dense_val_0_rg <= {2'b10, 2'b11, 2'b10, 2'b11};
										end
									end
									else if(which_swap_val_rg == 2) begin
										if(PE_IDX == 0 || PE_IDX == 1) begin
											sel_dense_val_0_rg <= {2'b00, 2'b01, 2'b00, 2'b01};
										end
										else if(PE_IDX == 2 || PE_IDX == 3) begin
											sel_dense_val_0_rg <= {2'b10, 2'b11, 2'b10, 2'b11};
										end
									end

									if(dense_gate_position_rg > 1) begin
										state_en_rg   <= 2'b11;
										state_we_rg   <= 2'b00;
										state_addr_rg[STATE_ADDR_WIDTH*2-1 -: STATE_ADDR_WIDTH] <= (which_swap_val_rg == 0) ? start_pkg_addr+current_ptr_in_pkg_rg : computed_state_value_counter_rg;
										state_addr_rg[STATE_ADDR_WIDTH-1 -: STATE_ADDR_WIDTH]   <= (which_swap_val_rg == 0) ? start_pkg_addr+current_ptr_in_pkg_rg+package_len_wr : computed_state_value_counter_rg+1;
										
										state_addr_tmp_0_0_rg <= (which_swap_val_rg == 0) ? start_pkg_addr+current_ptr_in_pkg_rg : computed_state_value_counter_rg;
										state_addr_tmp_1_0_rg <= (which_swap_val_rg == 0) ? start_pkg_addr+current_ptr_in_pkg_rg+package_len_wr : computed_state_value_counter_rg+1;
										
										produce_new_state_0_rg[0] <= 1;
										produce_new_state_1_rg[0] <= 1;

										if(current_ptr_in_pkg_rg < package_len_wr-1) begin
											current_ptr_in_pkg_rg           <= current_ptr_in_pkg_rg + 1;
											computed_state_value_counter_rg <= computed_state_value_counter_rg + 2;
											current_state_pos_0_rg		    <= current_state_pos_0_rg + 1;
										end
										else begin
											if(computed_state_value_counter_rg < exe_num_rg-2) begin
												current_ptr_in_pkg_rg           <= 0;
												computed_state_value_counter_rg <= computed_state_value_counter_rg + 2;
												start_pkg_addr				    <= computed_state_value_counter_rg + 2;
												current_state_pos_0_rg		    <= current_state_pos_0_rg + package_len_wr;
											end
											else begin
												current_ptr_in_pkg_rg           <= 0;
												dense_step_counter_rg		    <= 0;
												computed_state_value_counter_rg <= 0;
												current_state_pos_0_rg		    <= 0;
												done_exe_rg                     <= 1;
											end
										end
									end
									else begin
										state_en_rg   <= 2'b11;
										state_we_rg   <= 2'b00;
										state_addr_rg[STATE_ADDR_WIDTH*2-1 -: STATE_ADDR_WIDTH] <= computed_state_value_counter_rg;
										state_addr_rg[STATE_ADDR_WIDTH-1 -: STATE_ADDR_WIDTH]   <= computed_state_value_counter_rg + 1;

										state_addr_tmp_0_0_rg <= computed_state_value_counter_rg;
										state_addr_tmp_1_0_rg <= computed_state_value_counter_rg + 1;
										
										produce_new_state_0_rg[0] <= 1;
										produce_new_state_1_rg[0] <= 1;

										if(computed_state_value_counter_rg < exe_num_rg-2) begin
											current_ptr_in_pkg_rg           <= 0;
											computed_state_value_counter_rg <= computed_state_value_counter_rg + 2;
											current_state_pos_0_rg		    <= current_state_pos_0_rg + package_len_wr;
										end
										else begin
											current_ptr_in_pkg_rg           <= 0;
											dense_step_counter_rg		    <= 0;
											computed_state_value_counter_rg <= 0;
											current_state_pos_0_rg		    <= 0;
											done_exe_rg                     <= 1;
										end
									end
								end
								else begin
									if(produce_new_state_0_rg[4] == 1) begin
										state_en_rg                                             <= 2'b11;
										state_we_rg                                             <= 2'b11;
										state_addr_rg[STATE_ADDR_WIDTH*2-1 -: STATE_ADDR_WIDTH] <= state_addr_tmp_0_4_rg;
										state_addr_rg[STATE_ADDR_WIDTH-1 -: STATE_ADDR_WIDTH]   <= state_addr_tmp_1_4_rg;
									end
									else begin
										state_en_rg               <= 0;
										state_we_rg               <= 0;
									end

									produce_new_state_0_rg[0] <= 0;

									if(state_addr_tmp_1_4_rg == exe_num_rg-1) begin
										done_rg <= 1;
									end
								end																																													
							end
						end
						else if(done_exe_rg) begin
							state_en_rg               <= 0;
							state_we_rg               <= 0;
							state_addr_rg             <= 0;
							produce_new_state_0_rg[0] <= 0;
							produce_new_state_1_rg[0] <= 0;

							even_bit_rg <= ~even_bit_rg;

							even_bit_rg <= ~even_bit_rg;
							if(produce_new_state_0_rg[4] == 1) begin
								state_en_rg                                             <= 2'b11;
								state_we_rg                                             <= 2'b11;
								state_addr_rg[STATE_ADDR_WIDTH*2-1 -: STATE_ADDR_WIDTH] <= state_addr_tmp_0_4_rg;
								state_addr_rg[STATE_ADDR_WIDTH-1 -: STATE_ADDR_WIDTH]   <= state_addr_tmp_1_4_rg;
																					
								if(state_addr_tmp_1_4_rg == exe_num_rg-1) begin
									done_rg <= 1;
								end
							end
							else begin
								state_en_rg               <= 0;
								state_we_rg               <= 0;
							end
						end

						if(working_state_rg != EXE) begin
							even_bit_rg <= ~even_bit_rg;
							if(produce_new_state_0_rg[4] == 1) begin
								state_en_rg                                             <= 2'b11;
								state_we_rg                                             <= 2'b11;
								state_addr_rg[STATE_ADDR_WIDTH*2-1 -: STATE_ADDR_WIDTH] <= state_addr_tmp_0_4_rg;
								state_addr_rg[STATE_ADDR_WIDTH-1 -: STATE_ADDR_WIDTH]   <= state_addr_tmp_1_4_rg;
																					
								if(state_addr_tmp_1_4_rg == exe_num_rg-1) begin
									done_rg <= 1;
								end
							end
							else begin
								state_en_rg               <= 0;
								state_we_rg               <= 0;
							end
						end
					end
					CX: begin
						if(i_done_cx_computation) done_exe_rg <= 1;
						else done_exe_rg <= 0;
					end
					default: begin
						// done_exe_rg <= 1;
					end
				endcase
			end
			
			if(working_state_rg == IDLE && i_start) begin
				if(op_mode_rg == SPARSE) begin
					current_state_pos_0_rg <= i_start_state_pos; // PE_IDX * (1 << (i_qbit_num - 2));
					current_state_pos_1_rg <= i_start_state_pos + 1; // + 4
				end
				else if(op_mode_rg == DENSE) begin
					current_state_pos_0_rg <= i_start_state_pos;
					current_state_pos_1_rg <= i_start_state_pos;
				end

				start_alu_rg                    <= 0;
				sel_dense_val_0_rg				<= 0;
				sel_dense_val_1_rg				<= 0;
				dense_data_out_from_lsu_rg	    <= 0;
				current_ptr_in_pkg_rg		    <= 0;
				start_pkg_addr				    <= 0;
				which_swap_val_rg			   <= 0;
				computed_state_value_counter_rg <= 0;
				computed_gate_counter_0_rg        <= 0;
				computed_gate_counter_1_rg        <= 0;
				done_exe_rg                     <= 0;
				produce_new_state_0_rg            <= 0;
				produce_new_state_1_rg            <= 0;
				dense_step_counter_rg	        <= 0;
				even_bit_rg					    <= 0;
				// dense_gate_position_rg		    <= 0;
				state_addr_tmp_0_0_rg			    <= 0;
				state_addr_tmp_0_1_rg			    <= 0;
				state_addr_tmp_0_2_rg			    <= 0;
				state_addr_tmp_0_3_rg			    <= 0;
				state_addr_tmp_0_4_rg			    <= 0;
				state_addr_tmp_0_5_rg			    <= 0;
				last_state_addr_tmp_0_rg		    <= 0;

				state_addr_tmp_1_0_rg			    <= 0;
				state_addr_tmp_1_1_rg			    <= 0;
				state_addr_tmp_1_2_rg			    <= 0;
				state_addr_tmp_1_3_rg			    <= 0;
				state_addr_tmp_1_4_rg			    <= 0;
				state_addr_tmp_1_5_rg			    <= 0;
				last_state_addr_tmp_1_rg		    <= 0;
				
				gate_en_rg                      <= 0;
				gate_we_rg                      <= 0;
				gate_addr_rg                    <= 0;
				
				state_en_rg                     <= 0;
				state_we_rg                     <= 0;
				state_addr_rg                   <= 0;

				// o_produce_last_gate			    <= 0;
				done_rg		 				    <= 0;
			end
			else if(working_state_rg == EXE && (done_exe_rg || i_done_cx_computation)) begin
				done_exe_rg <= 0;
			end
		end
	end
endmodule