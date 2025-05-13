`timescale 1ns / 1ps

module CX_Swapper
#(
    parameter PE_NUM_WIDTH     = 2,
	parameter PE_NUM           = 4,

	parameter DATA_WIDTH       = 32,
	parameter MAX_QBIT_WIDTH   = 6,

	parameter STATE_DATA_WIDTH = DATA_WIDTH*2,
	parameter STATE_ADDR_WIDTH = 16,
	parameter GATE_DATA_WIDTH  = DATA_WIDTH*2,
	parameter GATE_ADDR_WIDTH  = 10
)
(
    ///*** Basic signals ***///
    input                                                   clk,
    input                                                   rst_n,

    ///*** Control Signal From The Global Controller ***///
    input                                                   i_start,

    ///*** For CX ***///
    input [MAX_QBIT_WIDTH-1:0]				                i_qbit_num,
    input [MAX_QBIT_WIDTH-1:0]				                i_cx_ctrl_pos, i_cx_target_pos,

    ///*** Local Data Memory ***///
	input [STATE_DATA_WIDTH*PE_NUM-1 : 0]                   i_ldm_rdata,

    ///*** Local Data Memory ***///							
    output reg [STATE_ADDR_WIDTH-1:0]                       o_ldm_addr,
	output reg [PE_NUM*STATE_DATA_WIDTH-1:0]                o_ldm_din,
	output reg [PE_NUM-1:0]				                    o_ldm_en,
	output reg [PE_NUM-1:0]				                    o_ldm_we,

    output                                                  o_done
);
    localparam [2:0] CX_IDLE           = 3'b000, // Do nothing
					 CX_LOAD           = 3'b001, // Load the partial state vector from HBM to LDM
					 CX_SWAP_AND_STORE = 3'b010, // Execute swap operations to the partial state vector (CX)
					 CX_STORE_STATE    = 3'b011; // Store the partial state vector into HBM

    ///*** Control Signal ***///
    reg [MAX_QBIT_WIDTH-1:0]	               qbit_num_rg;
    reg [MAX_QBIT_WIDTH-1:0]	               cx_ctrl_pos_rg, cx_target_pos_rg;
    reg                                        in_process_rg;
    reg [PE_NUM_WIDTH+STATE_ADDR_WIDTH-1 : 0]  current_cx_addr_rg, swap_addr_0_rg, swap_addr_1_rg;
    wire [PE_NUM_WIDTH+STATE_ADDR_WIDTH-1 : 0] swap_addr_0_tmp_wr, swap_addr_1_tmp_wr, tmp_0, tmp_1, tmp_2;
    reg [2:0]                                  cx_swap_flow_rg;
    reg                                        track_rg;
    wire [PE_NUM_WIDTH+STATE_ADDR_WIDTH-1:0]   ldm_addr_0_wr, ldm_addr_1_wr, ldm_real_width_wr;

    reg [PE_NUM_WIDTH-1:0] sel_pe_0_rg, sel_pe_1_rg;

    reg done_rg;

    assign o_done = done_rg;

    assign swap_addr_0_tmp_wr = current_cx_addr_rg;
    assign tmp_0 = (current_cx_addr_rg >> (qbit_num_rg-cx_target_pos_rg)) << (qbit_num_rg-cx_target_pos_rg);
    assign tmp_1 = {(current_cx_addr_rg[qbit_num_rg-cx_target_pos_rg-1] == 1'b0) ? 1'b1 : 1'b0} << (qbit_num_rg-cx_target_pos_rg-1);
    assign tmp_2 = (current_cx_addr_rg << (PE_NUM_WIDTH+STATE_ADDR_WIDTH-(qbit_num_rg+cx_target_pos_rg+1))) >> (PE_NUM_WIDTH+STATE_ADDR_WIDTH-(qbit_num_rg+cx_target_pos_rg+1));
    // assign swap_addr_1_tmp_wr[qbit_num_rg-cx_target_pos_rg-1] = tmp_0 | tmp_1 | tmp_2;
    assign swap_addr_1_tmp_wr = current_cx_addr_rg ^ (1 << (qbit_num_rg-cx_target_pos_rg-1));

    assign ldm_real_width_wr = PE_NUM_WIDTH+STATE_ADDR_WIDTH-(qbit_num_rg-PE_NUM_WIDTH);
    assign ldm_addr_0_wr = (swap_addr_0_rg << ldm_real_width_wr) >> ldm_real_width_wr;
    assign ldm_addr_1_wr = (swap_addr_1_rg << ldm_real_width_wr) >> ldm_real_width_wr;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n || (!in_process_rg && !i_start)) begin
            qbit_num_rg        <= 0;
            cx_ctrl_pos_rg     <= 0;
            cx_target_pos_rg   <= 0;
            cx_swap_flow_rg    <= CX_IDLE;
            current_cx_addr_rg <= 0;
            swap_addr_0_rg     <= 0;
            swap_addr_1_rg     <= 0;
            in_process_rg      <= 0;
            track_rg           <= 0;
            sel_pe_0_rg        <= 0;
            sel_pe_1_rg        <= 0;
            done_rg            <= 0;

            o_ldm_addr         <= 0;
            o_ldm_din          <= 0;
            o_ldm_en           <= 0;
            o_ldm_we           <= 0;
        end
        else if(!in_process_rg && i_start) begin
            qbit_num_rg        <= i_qbit_num;
            cx_ctrl_pos_rg     <= i_cx_ctrl_pos;
            cx_target_pos_rg   <= i_cx_target_pos;
            cx_swap_flow_rg    <= CX_IDLE;
            current_cx_addr_rg <= 1 << (i_qbit_num - i_cx_ctrl_pos - 1);
            swap_addr_0_rg     <= 0;
            swap_addr_1_rg     <= 0;
            in_process_rg      <= 1;
            track_rg           <= 0;
            sel_pe_0_rg        <= 0;
            sel_pe_1_rg        <= 0;
            done_rg            <= 0;
        end
        else if(in_process_rg) begin
            if(cx_swap_flow_rg == CX_IDLE) begin
                if(current_cx_addr_rg == 1 << qbit_num_rg) begin
                    in_process_rg <= 0;
                    current_cx_addr_rg <= 0;
                    done_rg       <= 1;
                end
                else begin
                    if(current_cx_addr_rg[qbit_num_rg-cx_ctrl_pos_rg-1] == 1'b1 && swap_addr_0_tmp_wr < swap_addr_1_tmp_wr) begin
                        cx_swap_flow_rg <= CX_LOAD;
                        swap_addr_0_rg  <= swap_addr_0_tmp_wr; // (swap_addr_0_tmp_rg >> PE_NUM_WIDTH) | swap_addr_0_tmp_rg[PE_NUM_WIDTH-1:0] << (STATE_ADDR_WIDTH);
                        swap_addr_1_rg  <= swap_addr_1_tmp_wr; // (swap_addr_1_tmp_rg >> PE_NUM_WIDTH) | swap_addr_1_tmp_rg[PE_NUM_WIDTH-1:0] << (STATE_ADDR_WIDTH);
                        
                        sel_pe_0_rg <= swap_addr_0_tmp_wr >> (qbit_num_rg-PE_NUM_WIDTH); // swap_addr_0_tmp_rg[PE_NUM_WIDTH-1:0];
                        sel_pe_1_rg <= swap_addr_1_tmp_wr >> (qbit_num_rg-PE_NUM_WIDTH); // swap_addr_1_tmp_rg[PE_NUM_WIDTH-1:0];
                    end

                    current_cx_addr_rg <= current_cx_addr_rg + 1;
                    track_rg <= 0;
                end

                o_ldm_en <= 0;
                o_ldm_we <= 0;
            end 
            else if(cx_swap_flow_rg == CX_LOAD) begin
                if(!track_rg) begin
                    o_ldm_addr <= ldm_addr_0_wr; // << STATE_ADDR_WIDTH*(PE_NUM_WIDTH-sel_pe_0_rg-1);
                    o_ldm_en   <= 1 << (PE_NUM-sel_pe_0_rg-1);
                    o_ldm_we   <= 0;

                    track_rg <= 1;
                end
                else begin
                    o_ldm_addr <= ldm_addr_1_wr; // << STATE_ADDR_WIDTH*(PE_NUM_WIDTH-sel_pe_1_rg-1);
                    o_ldm_en   <= 1 << (PE_NUM-sel_pe_1_rg-1);
                    o_ldm_we   <= 0;

                    track_rg <= 0;
                    cx_swap_flow_rg <= CX_SWAP_AND_STORE;
                end
            end
            else if(cx_swap_flow_rg == CX_SWAP_AND_STORE) begin
                if(!track_rg) begin
                    o_ldm_addr <= ldm_addr_1_wr; // << STATE_ADDR_WIDTH*(PE_NUM_WIDTH-sel_pe_1_rg-1);
                    o_ldm_din  <= {PE_NUM{i_ldm_rdata[STATE_DATA_WIDTH*(PE_NUM-sel_pe_0_rg)-1 -: STATE_DATA_WIDTH]}};
                    o_ldm_en   <= 1 << (PE_NUM-sel_pe_1_rg-1);
                    o_ldm_we   <= 1 << (PE_NUM-sel_pe_1_rg-1);

                    track_rg <= 1;
                end
                else begin
                    o_ldm_addr <= ldm_addr_0_wr; // << STATE_ADDR_WIDTH*(PE_NUM_WIDTH-sel_pe_0_rg-1);
                    o_ldm_din  <= {PE_NUM{i_ldm_rdata[STATE_DATA_WIDTH*(PE_NUM-sel_pe_1_rg)-1 -: STATE_DATA_WIDTH]}};
                    o_ldm_en   <= 1 << (PE_NUM-sel_pe_0_rg-1);
                    o_ldm_we   <= 1 << (PE_NUM-sel_pe_0_rg-1);

                    track_rg <= 0;
                    cx_swap_flow_rg <= CX_IDLE;
                end
            end
        end
    end
endmodule







// `timescale 1ns / 1ps

// module CX_Swapper
// #(
//     parameter PE_NUM_WIDTH     = 2,
// 	parameter PE_NUM           = 4,

// 	parameter DATA_WIDTH       = 32,
// 	parameter MAX_QBIT_WIDTH   = 6,

// 	parameter STATE_DATA_WIDTH = DATA_WIDTH*2,
// 	parameter STATE_ADDR_WIDTH = 16,
// 	parameter GATE_DATA_WIDTH  = DATA_WIDTH*2,
// 	parameter GATE_ADDR_WIDTH  = 10
// )
// (
//     ///*** Basic signals ***///
//     input                                                   clk,
//     input                                                   rst_n,

//     ///*** Control Signal From The Global Controller ***///
//     input                                                   i_start,

//     ///*** For CX ***///
//     input [MAX_QBIT_WIDTH-1:0]				                i_qbit_num,
//     input [MAX_QBIT_WIDTH-1:0]				                i_cx_ctrl_pos, i_cx_target_pos,

//     ///*** Local Data Memory ***///
// 	input [STATE_DATA_WIDTH*PE_NUM-1 : 0]                   i_ldm_rdata,

//     ///*** Local Data Memory ***///							
//     output reg [STATE_ADDR_WIDTH-1:0]                       o_ldm_addr,
// 	output reg [PE_NUM*STATE_DATA_WIDTH-1:0]                o_ldm_din,
// 	output reg [PE_NUM-1:0]				                    o_ldm_en,
// 	output reg [PE_NUM-1:0]				                    o_ldm_we,

//     output                                                  o_done
// );
//     localparam [2:0] CX_IDLE           = 3'b000, // Do nothing
// 					 CX_LOAD           = 3'b001, // Load the partial state vector from HBM to LDM
// 					 CX_SWAP_AND_STORE = 3'b010, // Execute swap operations to the partial state vector (CX)
// 					 CX_STORE_STATE    = 3'b011; // Store the partial state vector into HBM

//     ///*** Control Signal ***///
//     reg [MAX_QBIT_WIDTH-1:0]	               qbit_num_rg;
//     reg [MAX_QBIT_WIDTH-1:0]	               cx_ctrl_pos_rg, cx_target_pos_rg;
//     reg                                        in_process_rg;
//     reg [PE_NUM_WIDTH+STATE_ADDR_WIDTH-1 : 0]  current_cx_addr_rg, swap_addr_0_rg, swap_addr_1_rg;
//     wire [PE_NUM_WIDTH+STATE_ADDR_WIDTH-1 : 0] swap_addr_0_tmp_wr, swap_addr_1_tmp_wr;
//     reg [2:0]                                  cx_swap_flow_rg;
//     reg                                        track_rg;
//     wire [PE_NUM_WIDTH+STATE_ADDR_WIDTH-1:0]   ldm_addr_0_wr, ldm_addr_1_wr, ldm_real_width_wr;

//     reg [PE_NUM_WIDTH-1:0] sel_pe_0_rg, sel_pe_1_rg;

//     reg done_rg;

//     assign o_done = done_rg;

//     assign swap_addr_0_tmp_wr = current_cx_addr_rg;
//     assign swap_addr_1_tmp_wr = current_cx_addr_rg ^ (1 << (qbit_num_rg-cx_target_pos_rg-1));

//     assign ldm_real_width_wr = PE_NUM_WIDTH+STATE_ADDR_WIDTH-(qbit_num_rg-PE_NUM_WIDTH);
//     assign ldm_addr_0_wr = (swap_addr_0_rg << ldm_real_width_wr) >> ldm_real_width_wr;
//     assign ldm_addr_1_wr = (swap_addr_1_rg << ldm_real_width_wr) >> ldm_real_width_wr;

//     always @(posedge clk or negedge rst_n) begin
//         if(!rst_n || (!in_process_rg && !i_start)) begin
//             qbit_num_rg        <= 0;
//             cx_ctrl_pos_rg     <= 0;
//             cx_target_pos_rg   <= 0;
//             cx_swap_flow_rg    <= CX_IDLE;
//             current_cx_addr_rg <= 0;
//             swap_addr_0_rg     <= 0;
//             swap_addr_1_rg     <= 0;
//             in_process_rg      <= 0;
//             track_rg           <= 0;
//             sel_pe_0_rg        <= 0;
//             sel_pe_1_rg        <= 0;
//             done_rg            <= 0;

//             o_ldm_addr         <= 0;
//             o_ldm_din          <= 0;
//             o_ldm_en           <= 0;
//             o_ldm_we           <= 0;
//         end
//         else if(!in_process_rg && i_start) begin
//             qbit_num_rg        <= i_qbit_num;
//             cx_ctrl_pos_rg     <= i_cx_ctrl_pos;
//             cx_target_pos_rg   <= i_cx_target_pos;
//             cx_swap_flow_rg    <= CX_IDLE;
//             current_cx_addr_rg <= 0;
//             swap_addr_0_rg     <= 0;
//             swap_addr_1_rg     <= 0;
//             in_process_rg      <= 1;
//             track_rg           <= 0;
//             sel_pe_0_rg        <= 0;
//             sel_pe_1_rg        <= 0;
//             done_rg            <= 0;
//         end
//         else if(in_process_rg) begin
//             if(cx_swap_flow_rg == CX_IDLE) begin
//                 if(current_cx_addr_rg == 1 << qbit_num_rg) begin
//                     in_process_rg <= 0;
//                     current_cx_addr_rg <= 0;
//                     done_rg       <= 1;
//                 end
//                 else begin
//                     if(current_cx_addr_rg[qbit_num_rg-cx_ctrl_pos_rg-1] == 1'b1 && swap_addr_0_tmp_wr < swap_addr_1_tmp_wr) begin
//                         cx_swap_flow_rg <= CX_LOAD;
//                         swap_addr_0_rg  <= swap_addr_0_tmp_wr; // (swap_addr_0_tmp_rg >> PE_NUM_WIDTH) | swap_addr_0_tmp_rg[PE_NUM_WIDTH-1:0] << (STATE_ADDR_WIDTH);
//                         swap_addr_1_rg  <= swap_addr_1_tmp_wr; // (swap_addr_1_tmp_rg >> PE_NUM_WIDTH) | swap_addr_1_tmp_rg[PE_NUM_WIDTH-1:0] << (STATE_ADDR_WIDTH);
                        
//                         sel_pe_0_rg <= swap_addr_0_tmp_wr >> (qbit_num_rg-PE_NUM_WIDTH); // swap_addr_0_tmp_rg[PE_NUM_WIDTH-1:0];
//                         sel_pe_1_rg <= swap_addr_1_tmp_wr >> (qbit_num_rg-PE_NUM_WIDTH); // swap_addr_1_tmp_rg[PE_NUM_WIDTH-1:0];
//                     end

//                     o_ldm_en <= 0;
//                     o_ldm_we <= 0;

//                     current_cx_addr_rg <= current_cx_addr_rg + 1;
//                     track_rg <= 0;
//                 end
//             end 
//             else if(cx_swap_flow_rg == CX_LOAD) begin
//                 if(!track_rg) begin
//                     o_ldm_addr <= ldm_addr_0_wr; // << STATE_ADDR_WIDTH*(PE_NUM_WIDTH-sel_pe_0_rg-1);
//                     o_ldm_en   <= 0 ^ (1 << (PE_NUM-sel_pe_0_rg-1));
//                     o_ldm_we   <= 0;

//                     track_rg <= 1;
//                 end
//                 else begin
//                     o_ldm_addr <= ldm_addr_1_wr; // << STATE_ADDR_WIDTH*(PE_NUM_WIDTH-sel_pe_1_rg-1);
//                     o_ldm_en   <= 0 ^ (1 << (PE_NUM-sel_pe_1_rg-1));
//                     o_ldm_we   <= 0;

//                     track_rg <= 0;
//                     cx_swap_flow_rg <= CX_SWAP_AND_STORE;
//                 end
//             end
//             else if(cx_swap_flow_rg == CX_SWAP_AND_STORE) begin
//                 if(!track_rg) begin
//                     o_ldm_addr <= ldm_addr_0_wr; // << STATE_ADDR_WIDTH*(PE_NUM_WIDTH-sel_pe_1_rg-1);
//                     o_ldm_din  <= {PE_NUM{i_ldm_rdata[STATE_DATA_WIDTH*(PE_NUM-sel_pe_0_rg)-1 -: STATE_DATA_WIDTH]}};
//                     o_ldm_en   <= 0 ^ (1 << (PE_NUM-sel_pe_1_rg-1));
//                     o_ldm_we   <= 0 ^ (1 << (PE_NUM-sel_pe_1_rg-1));

//                     track_rg <= 1;
//                 end
//                 else begin
//                     o_ldm_addr <= ldm_addr_1_wr; // << STATE_ADDR_WIDTH*(PE_NUM_WIDTH-sel_pe_0_rg-1);
//                     o_ldm_din  <= {PE_NUM{i_ldm_rdata[STATE_DATA_WIDTH*(PE_NUM-sel_pe_1_rg)-1 -: STATE_DATA_WIDTH]}};
//                     o_ldm_en   <= 0 ^ (1 << (PE_NUM-sel_pe_0_rg-1));
//                     o_ldm_we   <= 0 ^ (1 << (PE_NUM-sel_pe_0_rg-1));

//                     track_rg <= 0;
//                     cx_swap_flow_rg <= CX_IDLE;
//                 end
//             end
//         end
//     end
// endmodule