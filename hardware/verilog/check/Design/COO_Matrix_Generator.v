`timescale 1ns / 1ps

module COO_Matrix_Generator
#(
    parameter DATA_WIDTH      = 32,
    parameter PE_NUM_WIDTH    = 2,
    parameter GATE_DATA_WIDTH = DATA_WIDTH*2, // 64
    parameter GATE_ADDR_WIDTH = 6, // 64
	parameter MAX_QBIT_WIDTH  = 6,
    parameter GATE_CONTEXT_DATA_WIDTH = DATA_WIDTH*2, // GATE_NUM_WIDTH + MAX_QBIT_WIDTH + DATA_WIDTH*2,   // 4 + 5 + 32 + 32
    parameter GATE_CONTEXT_ADDR_WIDTH = 6
)
( 
    input                                clk,
    input                                rst_n,

    input                                i_start,
    input                                i_continue,
    input [MAX_QBIT_WIDTH-1:0]           i_qbit_num,

    input [GATE_CONTEXT_DATA_WIDTH-1:0]  i_ctx_rdata,
    
    output                               o_ctx_en,
    output                               o_ctx_we,
    output [GATE_CONTEXT_ADDR_WIDTH-1:0] o_ctx_addr,
    
    output [1:0]                         o_matrix_type,
    output [MAX_QBIT_WIDTH-1:0]          o_cx_ctrl_pos,
    output [MAX_QBIT_WIDTH-1:0]          o_cx_target_pos,

    output                               o_done_temporality,
    
    // For storing the gate information into the local state memory in each PE
    output      		                 o_gate_valid,   
    output [GATE_ADDR_WIDTH-1 : 0]       o_gate_addr,
    output [GATE_DATA_WIDTH-1 : 0]       o_gate,

    output o_done
); 
    localparam [1:0] SPARSE = 2'b00,
					 DENSE  = 2'b01, 
					 CX     = 2'b10;

    localparam [3:0] RZ_GATE = 3'b000,
                     S_GATE  = 3'b001,
                     I_GATE  = 3'b010,
                     RX_GATE = 3'b011,
                     RY_GATE = 3'b100,
                     H_GATE  = 3'b101;

    reg                               in_process_rg, in_sub_process_rg;

    reg [MAX_QBIT_WIDTH-1:0]          qbit_num_rg;
    reg      		                  gate_valid_rg;   
    reg [GATE_DATA_WIDTH-1 : 0]       gate_rg;
    reg [GATE_ADDR_WIDTH-1 : 0]       gate_addr_rg;

    reg                               ctx_en_rg;
    reg                               ctx_we_rg;
    reg [GATE_CONTEXT_ADDR_WIDTH-1:0] ctx_addr_rg;
    
    reg [GATE_CONTEXT_ADDR_WIDTH-1:0] u_num_rg, current_u_rg, current_gate_ctx_addr_rg;
    reg [2*(2**(MAX_QBIT_WIDTH-1))-1:0]     init_counter;
    reg [1:0]                         matrix_type_rg; // Sparse: 0 || Dense: 1 || CX: 2
    reg [MAX_QBIT_WIDTH-1:0]          cx_ctrl_pos_rg;
    reg [MAX_QBIT_WIDTH-1:0]          cx_target_pos_rg;
    reg                               done_rg, done_temporality_rg;

    reg [2:0]                         transfer_counter;
    reg                               first_u;

    assign o_gate_valid       = gate_valid_rg;
    assign o_gate_addr        = gate_addr_rg;
    assign o_gate             = gate_rg;

    assign o_ctx_en           = ctx_en_rg;
    assign o_ctx_we           = ctx_we_rg;
    assign o_ctx_addr         = ctx_addr_rg;

    assign o_matrix_type      = matrix_type_rg;
    assign o_cx_ctrl_pos      = cx_ctrl_pos_rg;
    assign o_cx_target_pos    = cx_target_pos_rg;

    assign o_done_temporality = done_temporality_rg;
    assign o_done             = done_rg;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n || (!in_process_rg && !i_start)) begin
            in_process_rg            <= 0;
            in_sub_process_rg        <= 0;

            ctx_en_rg                <= 0;
            ctx_we_rg                <= 0;
            ctx_addr_rg              <= 0;

            gate_valid_rg            <= 0;
            gate_rg                  <= 0;
            gate_addr_rg             <= 0;

            done_rg                  <= 0;
            done_temporality_rg      <= 0;

            u_num_rg                 <= 0;
            current_u_rg             <= 0;
            current_gate_ctx_addr_rg <= 0;
            init_counter             <= 0;
            matrix_type_rg           <= 0;

            transfer_counter         <= 0;
            first_u                  <= 0;
        end
        else begin
            if(!in_process_rg && i_start) begin
                in_process_rg     <= 1;
                qbit_num_rg       <= i_qbit_num;
                first_u           <= 1;

                ctx_en_rg         <= 1;
                ctx_we_rg         <= 0;
                ctx_addr_rg       <= 0; // Start from the first address to get the number of U matrices in the quantum circuit

                in_sub_process_rg <= 1;
            end
            else begin
                if(in_sub_process_rg) begin
                    init_counter <= init_counter + 1;

                    if(init_counter == 0) begin
                        ctx_en_rg    <= 1;
                        ctx_we_rg    <= 0;
                        ctx_addr_rg  <= ctx_addr_rg + 1; // Get the type of the matrix
                    end
                    else if(init_counter == 1) begin
                        if(first_u) begin
                            first_u       <= 0;
                            u_num_rg      <= i_ctx_rdata[GATE_CONTEXT_ADDR_WIDTH-1:0];
                        end
                        
                        ctx_en_rg         <= 1;
                        ctx_we_rg         <= 0;
                        ctx_addr_rg       <= ctx_addr_rg + 1; // Position of Dense gate ||  Get the information of the first Sparse gate
                    end
                    else if(init_counter == 2) begin
                        matrix_type_rg <= i_ctx_rdata[1:0];

                        if(i_ctx_rdata[1:0] == SPARSE || i_ctx_rdata[1:0] == DENSE) begin
                            ctx_en_rg   <= 1;
                            ctx_we_rg   <= 0;
                            ctx_addr_rg <= ctx_addr_rg + 1; // Get the first val (Dense) || Get the information of the second Sparse gate
                        end
                        else if(i_ctx_rdata[1:0] == CX) begin
                            ctx_en_rg   <= 0;
                            ctx_we_rg   <= 0;
                        end
                    end
                    else if(init_counter > 2) begin
                        if(matrix_type_rg == SPARSE) begin
                            if(init_counter < (qbit_num_rg << 1)-1) begin
                                if(init_counter == 3) begin
                                    gate_valid_rg <= 1;
                                    gate_addr_rg  <= 0;
                                    gate_rg       <= i_ctx_rdata;
                                end
                                else begin
                                    gate_valid_rg <= 1;
                                    gate_addr_rg  <= gate_addr_rg + 1;
                                    gate_rg       <= i_ctx_rdata;
                                end

                                ctx_en_rg    <= 1;
                                ctx_we_rg    <= 0;
                                ctx_addr_rg  <= ctx_addr_rg + 1;
                            end
                            else if(init_counter == ((qbit_num_rg << 1)-1) || init_counter == ((qbit_num_rg << 1))) begin
                                gate_valid_rg <= 1;
                                gate_addr_rg  <= gate_addr_rg + 1;
                                gate_rg       <= i_ctx_rdata; 

                                ctx_en_rg    <= 0;
                                ctx_we_rg    <= 0;

                                if(init_counter == ((qbit_num_rg << 1))) begin
                                    if(current_u_rg == u_num_rg - 1) begin
                                        done_rg       <= 1;
                                        in_process_rg <= 0;
                                    end

                                    // ctx_addr_rg   <= ctx_addr_rg + 1;
                                    done_temporality_rg <= 1;
                                    in_sub_process_rg   <= 0;
                                    current_u_rg        <= current_u_rg + 1;
                                    init_counter        <= 0;
                                    // gate_addr_rg        <= 0;
                                end
                            end
                        end
                        else if(matrix_type_rg == DENSE) begin
                            if(init_counter > 2 && init_counter < 6) begin // if(init_counter == 3) begin
                                if(init_counter == 3) begin
                                    gate_valid_rg <= 1;
                                    gate_addr_rg  <= 0;
                                    gate_rg       <= i_ctx_rdata;
                                end
                                else begin
                                    gate_valid_rg <= 1;
                                    gate_addr_rg  <= gate_addr_rg + 1;
                                    gate_rg       <= i_ctx_rdata;
                                end

                                ctx_en_rg     <= 1;
                                ctx_we_rg     <= 0;
                                ctx_addr_rg   <= ctx_addr_rg + 1;
                            end
                            else if(init_counter == 6 || init_counter == 7) begin // else if(init_counter == 4 || init_counter == 5) begin
                                gate_valid_rg <= 1;
                                gate_addr_rg  <= gate_addr_rg + 1;
                                gate_rg       <= i_ctx_rdata; 

                                ctx_en_rg    <= 0;
                                ctx_we_rg    <= 0;

                                if(init_counter == 7) begin // if(init_counter == 5) begin
                                    if(current_u_rg == u_num_rg - 1) begin
                                        done_rg       <= 1;
                                        in_process_rg <= 0;
                                    end

                                    // ctx_addr_rg   <= ctx_addr_rg + 1;
                                    done_temporality_rg <= 1;
                                    in_sub_process_rg   <= 0;
                                    current_u_rg        <= current_u_rg + 1;
                                    init_counter        <= 0;
                                end
                            end
                        end
                        else if(matrix_type_rg == CX) begin
                            {cx_ctrl_pos_rg, cx_target_pos_rg} <= {i_ctx_rdata[DATA_WIDTH*2-1 -: DATA_WIDTH], i_ctx_rdata[DATA_WIDTH-1 : 0]};

                            if(current_u_rg == u_num_rg - 1) begin
                                done_rg <= 1;
                                in_process_rg <= 0;
                            end

                            ctx_en_rg    <= 0;
                            ctx_we_rg    <= 0;

                            // ctx_addr_rg   <= ctx_addr_rg + 1;
                            gate_valid_rg       <= 0;
                            done_temporality_rg <= 1;
                            in_sub_process_rg   <= 0;
                            current_u_rg        <= current_u_rg + 1;
                            init_counter        <= 0;
                            gate_addr_rg        <= 0;
                        end
                    end
                end
                else begin
                    done_temporality_rg <= 0;
                    gate_valid_rg       <= 0;
                    gate_addr_rg        <= 0;
                    init_counter        <= 0;

                    if(i_continue) begin
                        in_sub_process_rg <= 1;
                        // ctx_en_rg    <= 1;
                        // ctx_we_rg    <= 0;
                        // ctx_addr_rg   <= ctx_addr_rg + 1;
                    end
                end
            end
        end
    end
endmodule


// `timescale 1ns / 1ps

// module COO_Matrix_Generator
// #(
//     parameter DATA_WIDTH      = 32,
//     parameter PE_NUM_WIDTH    = 2,
//     parameter GATE_DATA_WIDTH = DATA_WIDTH*2, // 64
//     parameter GATE_ADDR_WIDTH = 6, // 64
// 	parameter MAX_QBIT_WIDTH  = 6,
// 	parameter GATE_NUM_WIDTH  = 4,
//     parameter GATE_CONTEXT_DATA_WIDTH  = GATE_NUM_WIDTH + MAX_QBIT_WIDTH + DATA_WIDTH*2   // 4 + 5 + 32 + 32
// )
// ( 
//     input                               clk,
//     input                               rst_n,

//     input                               i_start,
//     input                               i_done,
//     input [GATE_CONTEXT_DATA_WIDTH-1:0] i_ctx,
    
//     output      		                o_gate_valid,   
//     output [GATE_ADDR_WIDTH-1 : 0]      o_gate_addr,
//     output [GATE_DATA_WIDTH-1 : 0]      o_gate
// ); 
//     localparam [1:0] SPARSE = 2'b00,
// 					 DENSE  = 2'b01, 
// 					 CX     = 2'b10;

//     localparam [3:0] RZ_GATE = 3'b000,
//                      S_GATE  = 3'b001,
//                      I_GATE  = 3'b010,
//                      RX_GATE = 3'b011,
//                      RY_GATE = 3'b100,
//                      H_GATE  = 3'b101;

//     reg [1:0]                  matrix_type_rg; // Sparse: 0 || Dense: 1 || CX: 2
//     reg                        in_process_rg;

//     reg      		                  gate_valid_rg;   
//     reg [GATE_DATA_WIDTH-1 : 0]       gate_rg;
//     reg [GATE_ADDR_WIDTH-1 : 0]       gate_addr_rg;

//     wire [MAX_QBIT_WIDTH-1:0]   pos_wr;
//     wire [DATA_WIDTH*2-1:0]     cos_wr;
//     wire [DATA_WIDTH*2-1:0]     sin_wr;

//     reg [2:0] transfer_counter;

//     assign cos_wr = i_ctx[DATA_WIDTH*2*2-1 -: DATA_WIDTH*2];
//     assign sin_wr = i_ctx[DATA_WIDTH*2-1 : 0];
//     assign pos_wr = i_ctx[MAX_QBIT_WIDTH-1 + DATA_WIDTH*2*2-1 : DATA_WIDTH*2*2];

//     assign o_gate_valid     = gate_valid_rg;
//     assign o_gate_addr      = gate_addr_rg;
//     assign o_gate           = gate_rg;

//     always @(posedge clk or negedge rst_n) begin
//         if(!rst_n) begin
//             in_process_rg    <= 0;
//             in_process_rg    <= 0;
//             transfer_counter <= 0;

//             gate_valid_rg    <= 0;
//             gate_rg          <= 0;
//             gate_addr_rg     <= 0;
//         end
//         else begin
//             if(!in_process_rg) begin
//                 if(i_start) begin
//                     in_process_rg  <= 1;
//                 end

//                 gate_valid_rg     <= 0;
//                 gate_rg           <= 0;
//                 gate_addr_rg      <= 0-1;
//                 transfer_counter  <= 0;
//             end
//             else begin
//                 if(i_done) begin
//                     in_process_rg <= 0;
//                     gate_valid_rg <= 0;
//                 end
//                 else begin
//                     if(i_ctx[GATE_CONTEXT_DATA_WIDTH-1] == 1) begin
//                         transfer_counter <= transfer_counter + 1;
//                         gate_addr_rg     <= gate_addr_rg + 1;

//                         if(matrix_type_rg == SPARSE) begin
//                             gate_valid_rg     <= 1;

//                             case(i_ctx[GATE_CONTEXT_DATA_WIDTH-2 : GATE_CONTEXT_DATA_WIDTH-5])
//                                 RZ_GATE: begin
//                                     if(transfer_counter == 0) begin
//                                         gate_rg <= i_ctx[DATA_WIDTH*2*2-1 -: DATA_WIDTH*2];
//                                     end
//                                     else if(transfer_counter == 1) begin 
//                                         gate_rg          <= i_ctx[DATA_WIDTH*2-1 : 0];
//                                         transfer_counter <= 0;
//                                     end
//                                 end
//                                 S_GATE: begin
//                                     if(transfer_counter == 0) begin
//                                         gate_rg <= {32'b1, 32'b0};
//                                     end
//                                     else if(transfer_counter == 1) begin 
//                                         gate_rg <= {32'b0, 32'b1};
//                                         transfer_counter <= 0;
//                                     end
//                                 end
//                                 I_GATE: begin
//                                     gate_rg <= {32'b1, 32'b0};
//                                     if(transfer_counter == 1) transfer_counter <= 0;
//                                 end
//                                 default: begin
//                                     gate_rg <= {32'b1, 32'b0};
//                                     if(transfer_counter == 1) transfer_counter <= 0;
//                                 end
//                             endcase
//                         end
//                         else if(matrix_type_rg == DENSE) begin
//                             if(transfer_counter < 3) begin
//                                 gate_valid_rg             <= 1;

//                                 case(i_ctx[GATE_CONTEXT_DATA_WIDTH-2 : GATE_CONTEXT_DATA_WIDTH-5])
//                                     RX_GATE: begin
//                                         if(transfer_counter == 0) begin
//                                             gate_rg <= {32'b0, pos_wr[MAX_QBIT_WIDTH-1:0]};
//                                         end
//                                         else if(transfer_counter == 1) begin 
//                                             gate_rg <= {cos_wr, 0-sin_wr};
//                                         end
//                                         else if(transfer_counter == 2) begin 
//                                             gate_rg <= {cos_wr, 0-sin_wr};
//                                             transfer_counter <= 0;
//                                         end
//                                     end
//                                     RY_GATE: begin
//                                         if(transfer_counter == 0) begin
//                                             gate_rg <= {32'b0, pos_wr[MAX_QBIT_WIDTH-1:0]};
//                                         end
//                                         else if(transfer_counter == 1) begin 
//                                             gate_rg <= {cos_wr-sin_wr, 32'b0};
//                                         end
//                                         else if(transfer_counter == 2) begin 
//                                             gate_rg <= {cos_wr+sin_wr, 32'b0};
//                                             transfer_counter <= 0;
//                                         end
//                                     end
//                                     H_GATE: begin
//                                         if(transfer_counter == 0) begin
//                                             gate_rg <= {32'b0, pos_wr[MAX_QBIT_WIDTH-1:0]};
//                                         end
//                                         else if(transfer_counter == 1) begin 
//                                             gate_rg <= {32'h5A82799A, 32'b0}; // {square_root(2), 32'b0}
//                                         end
//                                         else if(transfer_counter == 2) begin 
//                                             gate_rg <= {32'b0, 32'b0};
//                                             transfer_counter <= 0;
//                                         end
//                                     end
//                                     default: begin
//                                         if(transfer_counter == 0) begin
//                                             gate_rg <= {32'b0, pos_wr[MAX_QBIT_WIDTH-1:0]};
//                                         end
//                                         else if(transfer_counter == 1) begin 
//                                             gate_rg <= {32'h5A82799A, 32'b0}; // {square_root(2), 32'b0}
//                                         end
//                                         else if(transfer_counter == 2) begin 
//                                             gate_rg <= {32'b0, 32'b0};
//                                             transfer_counter <= 0;
//                                         end
//                                     end
//                                 endcase
//                             end
//                         end
//                         else if(matrix_type_rg == CX) begin
//                             if(transfer_counter == 0) begin
//                                 gate_rg <= {i_ctx[DATA_WIDTH*2*2-1 -: DATA_WIDTH*2], i_ctx[DATA_WIDTH*2-1 : 0]};
//                             end
//                         end
//                     end
//                     else begin
//                         gate_valid_rg   <= 0;
//                         in_process_rg   <= 0;
//                     end
//                 end
//             end
//         end
//     end
// endmodule