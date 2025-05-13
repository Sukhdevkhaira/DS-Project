`timescale 1ns / 1ps

module QEA_Controller 
#(
    parameter PE_NUM_WIDTH     = 2,
    parameter PE_NUM           = 4,
    parameter DATA_WIDTH       = 32,
    parameter MAX_QBIT_WIDTH   = 6,
    parameter STATE_ADDR_WIDTH = 16
)
(  
    input                                clk,
    input                                rst_n,

    // From outside
	input                                i_start, 
	input [MAX_QBIT_WIDTH-1:0]		     i_qbit_num, 

    // From COO
    input [1:0]                          i_matrix_type,
    input [MAX_QBIT_WIDTH-1:0]           i_cx_ctrl_pos_from_gate_coo,
    input [MAX_QBIT_WIDTH-1:0]           i_cx_target_pos_from_gate_coo,
    input                                i_done_temporality_from_gate_coo,
	input                                i_done_from_gate_coo,

    // From PE Controller
    input                                i_done_pe_copmutation,

    // From CX Swapper
	input                                i_done_cx_computation,

    // Too COO
    output                               o_start_coo,
    output                               o_continue_coo,
    output [MAX_QBIT_WIDTH-1:0]          o_qbit_num_coo,

    // To PE Controller
    output                               o_start_pe,
    output                               o_gate_transfer_done,
    output                               o_state_transfer_done,
    output                               o_cx_computation_done,
    output [MAX_QBIT_WIDTH-1:0]		     o_qbit_num, 
	output [STATE_ADDR_WIDTH-1:0]        o_exe_num, 
	output [PE_NUM*STATE_ADDR_WIDTH-1:0] o_start_state_pos,
	output [1:0]                         o_op_mode,
    
    // To CX Swapper
    output [MAX_QBIT_WIDTH-1:0]          o_cx_ctrl_pos,
    output [MAX_QBIT_WIDTH-1:0]          o_cx_target_pos,
	output                               o_start_cx_computation,
    output [MAX_QBIT_WIDTH-1:0]			 o_qbit_num_cx,

    output                               o_done
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

    reg [2:0]                         system_state;
    reg                               in_process_rg, in_sub_process_rg;
    reg [MAX_QBIT_WIDTH-1:0]          qbit_num_reg;
    reg [1:0]                         matrix_type_rg;

    // To COO
    reg                               start_coo_rg;
    reg                               continue_coo_rg;
    reg [MAX_QBIT_WIDTH-1:0]          qbit_num_coo_rg;

    // To PE Controller
    reg                                 start_pe;
    reg                                 gate_transfer_done_rg;
    reg                                 state_transfer_done_rg;
    reg                                 cx_computation_done_rg;
    reg [MAX_QBIT_WIDTH-1:0]		    qbit_num_rg; 
	reg [STATE_ADDR_WIDTH-1:0]          exe_num_rg; 
	reg [PE_NUM*STATE_ADDR_WIDTH-1:0]   start_state_pos_rg;
	reg [1:0]                           op_mode_rg;
    
    // To CX Swapper
    reg [MAX_QBIT_WIDTH-1:0]            cx_ctrl_pos_rg;
    reg [MAX_QBIT_WIDTH-1:0]            cx_target_pos_rg;
	reg                                 start_cx_computation_rg;

    // To Outside
    reg                                 done_rg;

    reg                                 coo_cont_rg;
    reg                                 system_start_rg;

    assign o_start_coo            = start_coo_rg;
    assign o_continue_coo         = continue_coo_rg;
    assign o_qbit_num_coo         = qbit_num_coo_rg;

    assign o_start_pe             = start_pe;
    assign o_gate_transfer_done   = gate_transfer_done_rg;
    assign o_state_transfer_done  = state_transfer_done_rg;
    assign o_cx_computation_done  = cx_computation_done_rg;
    assign o_qbit_num             = qbit_num_rg;
    assign o_exe_num              = exe_num_rg;
    assign o_start_state_pos      = start_state_pos_rg;
    assign o_op_mode              = op_mode_rg;

    assign o_cx_ctrl_pos          = cx_ctrl_pos_rg;
    assign o_cx_target_pos        = cx_target_pos_rg;
    assign o_start_cx_computation = start_cx_computation_rg;
    assign o_qbit_num_cx          = qbit_num_rg;

    assign o_done                 = done_rg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n || (!in_process_rg && !i_start)) begin
            system_state            <= IDLE;
            in_process_rg           <= 0;
            in_sub_process_rg       <= 0;
            qbit_num_reg            <= 0;
            exe_num_rg              <= 0;
            start_state_pos_rg      <= 0;
            coo_cont_rg             <= 0;
            system_start_rg         <= 0;
            matrix_type_rg          <= 0;

            start_coo_rg            <= 0;
            continue_coo_rg         <= 0;
            qbit_num_coo_rg         <= 0;

            start_pe                <= 0;
            gate_transfer_done_rg   <= 0;
            state_transfer_done_rg  <= 0;
            cx_computation_done_rg  <= 0;
            qbit_num_rg             <= 0;
            exe_num_rg              <= 0;
            op_mode_rg              <= 0;

            cx_ctrl_pos_rg          <= 0;
            cx_target_pos_rg        <= 0;
            start_cx_computation_rg <= 0;
            done_rg                 <= 0;
        end 
        else if(!in_process_rg && i_start) begin
            system_state    <= GEN_MATRIX;
            in_process_rg   <= 1;
            qbit_num_reg    <= i_qbit_num;
            system_start_rg <= 1;

            start_coo_rg           <= 1;
            continue_coo_rg        <= 0;
            qbit_num_coo_rg        <= i_qbit_num;
        end
        else if(in_process_rg) begin
            system_start_rg <= 0;

            if(system_state == GEN_MATRIX) begin
                if(!in_sub_process_rg) begin
                    if(system_start_rg) begin
                        start_coo_rg    <= 0;
                        continue_coo_rg <= 0;
                    end
                    else begin
                        start_coo_rg           <= 0;
                        continue_coo_rg        <= 1;
                        state_transfer_done_rg <= 0;
                    end

                    in_sub_process_rg <= 1;
                end
                else begin
                    if(i_done_temporality_from_gate_coo) begin
                        // continue_coo_rg <= 1;
                        in_sub_process_rg <= 0;
                        system_state <= LOAD_STATE;
                        gate_transfer_done_rg <= 1;
                        matrix_type_rg <= i_matrix_type;

                        if(i_done_from_gate_coo) coo_cont_rg <= 0;
                        else coo_cont_rg <= 1;
                    end
                    else begin
                        start_coo_rg           <= 0;
                        continue_coo_rg        <= 0;
                    end
                end
            end
            else if(system_state == LOAD_STATE) begin
                gate_transfer_done_rg  <= 0;
                state_transfer_done_rg <= 1;
                system_state           <= EXE;
            end
            else if(system_state == EXE) begin
                state_transfer_done_rg <= 0;

                if(matrix_type_rg == SPARSE || matrix_type_rg == DENSE) begin 
                    if(!in_sub_process_rg) begin
                        start_pe           <= 1;
                        qbit_num_rg        <= qbit_num_reg;
                        exe_num_rg         <= 1 << (qbit_num_reg-PE_NUM_WIDTH);
                        start_state_pos_rg <= {
                                                  {{(STATE_ADDR_WIDTH-2){1'b0}}, 2'b0}, 
                                                  {{(STATE_ADDR_WIDTH-2){1'b0}}, 2'd1}, 
                                                  {{(STATE_ADDR_WIDTH-2){1'b0}}, 2'd2},
                                                  {{(STATE_ADDR_WIDTH-2){1'b0}}, 2'd3}
                                              };
                        op_mode_rg         <= matrix_type_rg;
                        in_sub_process_rg  <= 1;
                    end
                    else begin
                        if(i_done_pe_copmutation) begin
                            in_sub_process_rg <= 0;
                            system_state      <= STORE_STATE;
                        end

                        start_pe <= 0;
                    end
                end
                else if(matrix_type_rg == CX) begin
                    if(!in_sub_process_rg) begin
                        start_cx_computation_rg            <= 1;
                        {cx_ctrl_pos_rg, cx_target_pos_rg} <= {i_cx_ctrl_pos_from_gate_coo, i_cx_target_pos_from_gate_coo};
                        in_sub_process_rg                  <= 1;
                    end
                    else begin
                        if(i_done_cx_computation) begin
                            in_sub_process_rg <= 0;
                            system_state      <= STORE_STATE;
                            cx_computation_done_rg <= 1;
                        end
                        else begin
                            start_cx_computation_rg <= 0;
                        end
                    end
                end
            end
            else if(system_state == STORE_STATE) begin
                cx_computation_done_rg <= 0;
                state_transfer_done_rg <= 1;

                if(coo_cont_rg) system_state <= GEN_MATRIX;
                else system_state <= DONE;
            end
            else if(system_state == DONE) begin
                state_transfer_done_rg <= 0;
                in_process_rg          <= 0;
                done_rg                <= 1;
            end
       end
   end
endmodule