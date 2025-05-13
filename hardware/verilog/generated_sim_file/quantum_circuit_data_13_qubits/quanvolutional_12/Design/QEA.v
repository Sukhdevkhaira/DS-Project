`timescale 1ns / 1ps

module QEA
#(
    parameter PE_NUM_WIDTH            = 2,
    parameter PE_NUM                  = 4,
    parameter DATA_WIDTH              = 32,
    parameter MAX_QBIT_WIDTH          = 6,
    parameter ALU_DATA_WIDTH          = DATA_WIDTH,
    parameter STATE_DATA_WIDTH        = DATA_WIDTH*2,
    parameter STATE_ADDR_WIDTH        = 16,
    parameter GATE_DATA_WIDTH         = DATA_WIDTH*2,
    parameter GATE_ADDR_WIDTH         = 6,
    parameter GATE_CONTEXT_DATA_WIDTH = DATA_WIDTH*2,
    parameter GATE_CONTEXT_ADDR_WIDTH = 6,
	parameter NUM_FRAC_BIT            = 30
)
(
    input                                 clk,
    input                                 rst_n,

    input 					              i_start,
    input [MAX_QBIT_WIDTH-1:0]		      i_qbit_num,

    input                                 i_ctx_en,
    input                                 i_ctx_wea,
    input [GATE_CONTEXT_ADDR_WIDTH-1:0]   i_ctx_addr,
    input [GATE_CONTEXT_DATA_WIDTH-1:0]   i_ctx_data,
                            
    input                	              i_state_ena,
    input                	              i_state_wea,
    input [STATE_ADDR_WIDTH-1 : 0]        i_state_addra,
    input [PE_NUM*STATE_DATA_WIDTH-1 : 0] i_state_dina,

    output 						          o_complete,
    output [STATE_DATA_WIDTH*PE_NUM-1:0]  o_state_dout
);
    //***  Inputs of COO_Matrix_Generator ***//
    // From QEA_Controller
    wire                                 start_from_qea_ctrl_to_coo_gen_wr;
    wire                                 continue_from_qea_ctrl_to_coo_gen_wr;
    wire [MAX_QBIT_WIDTH-1:0]            qbit_num_from_qea_ctrl_to_coo_gen_wr;
    // From CTX RAM
    wire [GATE_CONTEXT_DATA_WIDTH-1:0]   ctx_rdata_from_ctx_ram_to_coo_gen_wr;

    //*** Inputs of QEA_Controller ***//
    // From COO
    wire [1:0]                           matrix_type_wr_from_coo_gen_to_qea_ctrl;
    wire [MAX_QBIT_WIDTH-1:0]            cx_ctrl_pos_from_gate_coo_wr_from_coo_gen_to_qea_ctrl;
    wire [MAX_QBIT_WIDTH-1:0]            cx_target_pos_from_gate_coo_wr_from_coo_gen_to_qea_ctrl;
    wire                                 done_temporality_from_gate_coo_wr_from_coo_gen_to_qea_ctrl;
	wire                                 done_from_gate_coo_wr_from_coo_gen_to_qea_ctrl;
    // From PE
    wire                                 done_pe_copmutation_from_pe_to_qea_ctrl_wr;
    // From CX Swapper
    wire                                 done_cx_computation_from_cx_swapper_to_qea_ctrl_wr;

    //*** Inputs of PEA ***//
    // From QEA_Controller
    wire                                 start_from_qea_to_pea;
	wire [MAX_QBIT_WIDTH-1:0]		     qbit_num_from_qea_to_pea; 
	wire [STATE_ADDR_WIDTH-1:0]          exe_num_from_qea_to_pea;
	wire [PE_NUM*STATE_ADDR_WIDTH-1:0]   start_state_pos_from_qea_to_pea;
	wire [1:0]                           op_mode_from_qea_to_pea; 
	wire                                 done_gate_coo_transfer_from_qea_to_pea;
	wire                                 done_state_transfer_from_qea_to_pea;
	wire                                 done_cx_computation_from_qea_to_pea;
    // From COO
    wire                                 gate_coo_valid_from_coo_to_pea;
    wire [GATE_ADDR_WIDTH-1 : 0]         gate_coo_addr_from_coo_to_pea;
	wire [GATE_DATA_WIDTH-1:0]           gate_coo_from_coo_to_pea; 
    // Shared signals
	wire [PE_NUM*(PE_NUM_WIDTH+STATE_ADDR_WIDTH)-1:0] ldm_addr_to_pea;
	wire [PE_NUM*STATE_DATA_WIDTH-1:0]                ldm_data_to_pea;
	wire [PE_NUM-1:0]				                  ldm_en_to_pea;
	wire [PE_NUM-1:0]				                  ldm_we_to_pea;

    //*** Inputs of CX Swapper ***//
    // From QEA_Controller
    wire                                 start_from_qea_ctrl_to_cx_swapper;
    wire [MAX_QBIT_WIDTH-1:0]		     qbit_num_from_qea_ctrl_to_cx_swapper;
    wire [MAX_QBIT_WIDTH-1:0]			 cx_ctrl_pos_from_qea_ctrl_to_cx_swapper;
    wire [MAX_QBIT_WIDTH-1:0]			 cx_target_pos_from_qea_ctrl_to_cx_swapper;
    // From PEA
	wire [PE_NUM*STATE_DATA_WIDTH-1 : 0] ldm_rdata_from_qea_ctrl_to_cx_swapper;

    //*** Inputs of CTX RAM ***//
    wire                                ctx_en_to_ctx_ram;
    wire                                ctx_wea_to_ctx_ram;
    wire [GATE_CONTEXT_ADDR_WIDTH-1:0]  ctx_addr_to_ctx_ram;
    wire [GATE_CONTEXT_DATA_WIDTH-1:0]  ctx_data_to_ctx_ram;

    //*** Outputs of COO_Matrix_Generator ***//
    // To CTX RAM
    wire                                ctx_en_from_coo_gen_to_ctx_ram;
    wire                                ctx_wea_from_coo_gen_to_ctx_ram;
    wire [GATE_CONTEXT_ADDR_WIDTH-1:0]  ctx_addr_from_coo_gen_to_ctx_ram;

    //*** Outputs of CX_Swapper ***//
    // To PEA
    wire [STATE_ADDR_WIDTH-1:0]        ldm_addr_from_cx_swapper_to_pea;
	wire [PE_NUM*STATE_DATA_WIDTH-1:0] ldm_din_from_cx_swapper_to_pea;
	wire [PE_NUM-1:0]				   ldm_en_from_cx_swapper_to_pea;
	wire [PE_NUM-1:0]				   ldm_we_from_cx_swapper_to_pea;

    //*** Others ***//
    wire [PE_NUM*STATE_DATA_WIDTH-1:0] ldm_rdata_from_pea;

    assign o_state_dout = ldm_rdata_from_pea;
    assign ldm_rdata_from_qea_ctrl_to_cx_swapper = ldm_rdata_from_pea;

    assign ctx_en_to_ctx_ram   = (i_ctx_en == 1'b1) ? i_ctx_en : ctx_en_from_coo_gen_to_ctx_ram;
    assign ctx_wea_to_ctx_ram  = (i_ctx_en == 1'b1) ? i_ctx_wea : ctx_wea_from_coo_gen_to_ctx_ram;
    assign ctx_addr_to_ctx_ram = (i_ctx_en == 1'b1) ? i_ctx_addr : ctx_addr_from_coo_gen_to_ctx_ram;
    assign ctx_data_to_ctx_ram = i_ctx_data;

    assign ldm_en_to_pea   = i_state_ena ? {PE_NUM{i_state_ena}} : ldm_en_from_cx_swapper_to_pea;
    assign ldm_we_to_pea   = i_state_ena ? {PE_NUM{i_state_wea}} : ldm_we_from_cx_swapper_to_pea;
    assign ldm_addr_to_pea = i_state_ena ? {PE_NUM{i_state_addra}} : {PE_NUM{ldm_addr_from_cx_swapper_to_pea}};
    assign ldm_data_to_pea = i_state_ena ? i_state_dina : ldm_din_from_cx_swapper_to_pea;

    QEA_Controller 
    #(
        .PE_NUM_WIDTH(PE_NUM_WIDTH),
        .PE_NUM(PE_NUM),
        .DATA_WIDTH(DATA_WIDTH),
        .MAX_QBIT_WIDTH(MAX_QBIT_WIDTH),
        .STATE_ADDR_WIDTH(STATE_ADDR_WIDTH)
    )
    QEA_Controller_inst
    (  
        .clk(clk),
        .rst_n(rst_n),

        .i_start(i_start), 
        .i_qbit_num(i_qbit_num), 

        .i_matrix_type(matrix_type_wr_from_coo_gen_to_qea_ctrl),
        .i_cx_ctrl_pos_from_gate_coo(cx_ctrl_pos_from_gate_coo_wr_from_coo_gen_to_qea_ctrl),
        .i_cx_target_pos_from_gate_coo(cx_target_pos_from_gate_coo_wr_from_coo_gen_to_qea_ctrl),
        .i_done_temporality_from_gate_coo(done_temporality_from_gate_coo_wr_from_coo_gen_to_qea_ctrl),
        .i_done_from_gate_coo(done_from_gate_coo_wr_from_coo_gen_to_qea_ctrl),

        .i_done_pe_copmutation(done_pe_copmutation_from_pe_to_qea_ctrl_wr),

        .i_done_cx_computation(done_cx_computation_from_cx_swapper_to_qea_ctrl_wr),

        .o_start_coo(start_from_qea_ctrl_to_coo_gen_wr),
        .o_continue_coo(continue_from_qea_ctrl_to_coo_gen_wr),
        .o_qbit_num_coo(qbit_num_from_qea_ctrl_to_coo_gen_wr),

        .o_start_pe(start_from_qea_to_pea),
        .o_qbit_num(qbit_num_from_qea_to_pea), 
        .o_exe_num(exe_num_from_qea_to_pea), 
        .o_start_state_pos(start_state_pos_from_qea_to_pea),
        .o_op_mode(op_mode_from_qea_to_pea),
        .o_gate_transfer_done(done_gate_coo_transfer_from_qea_to_pea),
        .o_state_transfer_done(done_state_transfer_from_qea_to_pea),
        .o_cx_computation_done(done_cx_computation_from_qea_to_pea),
        
        .o_start_cx_computation(start_from_qea_ctrl_to_cx_swapper),
        .o_qbit_num_cx(qbit_num_from_qea_ctrl_to_cx_swapper), 
        .o_cx_ctrl_pos(cx_ctrl_pos_from_qea_ctrl_to_cx_swapper),
        .o_cx_target_pos(cx_target_pos_from_qea_ctrl_to_cx_swapper),

        .o_done(o_complete)
    );

    PEA
    #(
        .PE_NUM_WIDTH(PE_NUM_WIDTH),
        .PE_NUM(PE_NUM),
        .DATA_WIDTH(DATA_WIDTH),
        .MAX_QBIT_WIDTH(MAX_QBIT_WIDTH),
        .STATE_ADDR_WIDTH(STATE_ADDR_WIDTH),
        .STATE_DATA_WIDTH(STATE_DATA_WIDTH),
        .GATE_ADDR_WIDTH(GATE_ADDR_WIDTH),
        .GATE_DATA_WIDTH(GATE_DATA_WIDTH),
        .ALU_DATA_WIDTH(ALU_DATA_WIDTH),
        .NUM_FRAC_BIT(NUM_FRAC_BIT)
    )
    PEA_inst
    (
        .clk(clk),
        .rst_n(rst_n),

        .i_start(start_from_qea_to_pea),
        .i_qbit_num(qbit_num_from_qea_to_pea), 
        .i_exe_num(exe_num_from_qea_to_pea),
        .i_start_state_pos(start_state_pos_from_qea_to_pea),
        .i_op_mode(op_mode_from_qea_to_pea), 

        .i_done_gate_coo_transfer(done_gate_coo_transfer_from_qea_to_pea),
        .i_done_state_transfer(done_state_transfer_from_qea_to_pea),
        .i_done_cx_computation(done_cx_computation_from_qea_to_pea),

        .i_gate_coo_valid(gate_coo_valid_from_coo_to_pea),
        .i_gate_coo_addr(gate_coo_addr_from_coo_to_pea),
        .i_gate_coo(gate_coo_from_coo_to_pea), 
        
        .i_ldm_addr(ldm_addr_to_pea),
        .i_ldm_data(ldm_data_to_pea),
        .i_ldm_en(ldm_en_to_pea),
        .i_ldm_we(ldm_we_to_pea),

        .o_ldm_data(ldm_rdata_from_pea),

        .o_done(done_pe_copmutation_from_pe_to_qea_ctrl_wr)
    );

    COO_Matrix_Generator
    #(
        .DATA_WIDTH(DATA_WIDTH),
        .PE_NUM_WIDTH(PE_NUM_WIDTH),
        .GATE_DATA_WIDTH(GATE_DATA_WIDTH),
        .GATE_ADDR_WIDTH(GATE_ADDR_WIDTH),
        .MAX_QBIT_WIDTH(MAX_QBIT_WIDTH),
        .GATE_CONTEXT_DATA_WIDTH(GATE_CONTEXT_DATA_WIDTH),
        .GATE_CONTEXT_ADDR_WIDTH(GATE_CONTEXT_ADDR_WIDTH)
    )
    COO_Matrix_Generator_inst
    ( 
        .clk(clk),
        .rst_n(rst_n),

        .i_start(start_from_qea_ctrl_to_coo_gen_wr),
        .i_continue(continue_from_qea_ctrl_to_coo_gen_wr),
        .i_qbit_num(qbit_num_from_qea_ctrl_to_coo_gen_wr),

        .i_ctx_rdata(ctx_rdata_from_ctx_ram_to_coo_gen_wr),
        
        .o_ctx_en(ctx_en_from_coo_gen_to_ctx_ram),
        .o_ctx_we(ctx_wea_from_coo_gen_to_ctx_ram),
        .o_ctx_addr(ctx_addr_from_coo_gen_to_ctx_ram),
        
        .o_matrix_type(matrix_type_wr_from_coo_gen_to_qea_ctrl),
        .o_cx_ctrl_pos(cx_ctrl_pos_from_gate_coo_wr_from_coo_gen_to_qea_ctrl),
        .o_cx_target_pos(cx_target_pos_from_gate_coo_wr_from_coo_gen_to_qea_ctrl),

        .o_done_temporality(done_temporality_from_gate_coo_wr_from_coo_gen_to_qea_ctrl),
        
        .o_gate_valid(gate_coo_valid_from_coo_to_pea),   
        .o_gate_addr(gate_coo_addr_from_coo_to_pea),
        .o_gate(gate_coo_from_coo_to_pea),

        .o_done(done_from_gate_coo_wr_from_coo_gen_to_qea_ctrl)
    ); 

    Dual_Port_BRAM
    #(
        .AWIDTH(GATE_CONTEXT_ADDR_WIDTH),
        .DWIDTH(GATE_CONTEXT_DATA_WIDTH)
    )
    Gate_Memory_inst
    (
        .clka(clk),
        .ena(ctx_en_to_ctx_ram),
        .wea(ctx_wea_to_ctx_ram),
        .addra(ctx_addr_to_ctx_ram),
        .dina(ctx_data_to_ctx_ram),
        .douta(ctx_rdata_from_ctx_ram_to_coo_gen_wr),

        .clkb(clk),
        .enb(1),
        .web(0),
        .addrb(),
        .dinb(0),
        .doutb()
    );

    CX_Swapper
    #(
        .PE_NUM_WIDTH(PE_NUM_WIDTH),
        .PE_NUM(PE_NUM),
        .DATA_WIDTH(DATA_WIDTH),
        .MAX_QBIT_WIDTH(MAX_QBIT_WIDTH),
        .STATE_DATA_WIDTH(STATE_DATA_WIDTH),
        .STATE_ADDR_WIDTH(STATE_ADDR_WIDTH),
        .GATE_DATA_WIDTH(GATE_DATA_WIDTH),
        .GATE_ADDR_WIDTH(GATE_ADDR_WIDTH)
    )
    CX_Swapper_inst
    (
        .clk(clk),
        .rst_n(rst_n),

        .i_start(start_from_qea_ctrl_to_cx_swapper),
        .i_qbit_num(qbit_num_from_qea_ctrl_to_cx_swapper),
        .i_cx_ctrl_pos(cx_ctrl_pos_from_qea_ctrl_to_cx_swapper), 
        .i_cx_target_pos(cx_target_pos_from_qea_ctrl_to_cx_swapper),

        .i_ldm_rdata(ldm_rdata_from_qea_ctrl_to_cx_swapper),

        .o_ldm_addr(ldm_addr_from_cx_swapper_to_pea),
        .o_ldm_din(ldm_din_from_cx_swapper_to_pea),
        .o_ldm_en(ldm_en_from_cx_swapper_to_pea),
        .o_ldm_we(ldm_we_from_cx_swapper_to_pea),

        .o_done(done_cx_computation_from_cx_swapper_to_qea_ctrl_wr)
    );
endmodule
