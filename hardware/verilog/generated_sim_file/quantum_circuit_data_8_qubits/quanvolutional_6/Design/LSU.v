`timescale 1ns / 1ps

module LSU
#(
	parameter PE_IDX = 2,
    parameter DATA_WIDTH      = 32,
	parameter STATE_DATA_WIDTH = DATA_WIDTH*2,
	parameter STATE_ADDR_WIDTH = 16,
	parameter GATE_DATA_WIDTH = DATA_WIDTH*2,
	parameter GATE_ADDR_WIDTH = 10,
	parameter PE_NUM_WIDTH = 2
)
(
	input                                     clk,         
	input                                     rst_n, 

	input                                     i_state_ram_off_chip_en,  
	input                                     i_state_ram_off_chip_we,  
	input [PE_NUM_WIDTH+STATE_ADDR_WIDTH-1:0] i_state_ram_off_chip_addr,
	input [STATE_DATA_WIDTH-1:0]              i_state_ram_off_chip_data,
	
	input                                     i_gate_coo_en,  
	input                                     i_gate_coo_we,  
	input [GATE_ADDR_WIDTH-1:0]               i_gate_coo_addr,
	input [STATE_DATA_WIDTH-1:0]              i_gate_coo_data,

	input [1:0]                               i_state_en,  
	input [1:0]                               i_state_we,  
	input [STATE_ADDR_WIDTH*2-1:0]            i_state_addr,
	input [STATE_DATA_WIDTH*2-1:0]            i_state_data,

	input [1:0]                               i_gate_en,  
	input [1:0]                               i_gate_we,  
	input [GATE_ADDR_WIDTH*2-1:0]             i_gate_addr, 
	input [GATE_DATA_WIDTH*2-1:0]             i_gate_data,

	output [STATE_DATA_WIDTH*2-1:0]           o_state_data, 
	output [GATE_DATA_WIDTH*2-1:0]            o_gate_data 
);
	wire                        is_selected_state_pe_wr;
	wire [1:0]                  state_mem_en_wr, state_mem_we_wr, gate_mem_en_wr, gate_mem_we_wr;
	wire [STATE_ADDR_WIDTH*2-1:0] state_mem_addr_wr;
	wire [STATE_DATA_WIDTH*2-1:0] state_mem_data_wr;

	wire [GATE_ADDR_WIDTH*2-1:0] gate_mem_addr_wr;
	wire [GATE_DATA_WIDTH*2-1:0] gate_mem_data_wr;

	// For STATE MEM
	assign is_selected_state_pe_wr                                     = (i_state_ram_off_chip_addr[PE_NUM_WIDTH+STATE_ADDR_WIDTH-1:STATE_ADDR_WIDTH] == PE_IDX) ? 1 : 0;
	assign state_mem_en_wr[0]                                          = (i_state_ram_off_chip_en == 1) ? {(is_selected_state_pe_wr == 1) ? i_state_ram_off_chip_en : 0} : i_state_en[0];
	assign state_mem_we_wr[0]                                          = (i_state_ram_off_chip_en == 1) ? {(is_selected_state_pe_wr == 1) ? i_state_ram_off_chip_we : 0} : i_state_we[0];
	assign state_mem_addr_wr[STATE_ADDR_WIDTH*2-1 -: STATE_ADDR_WIDTH] = (i_state_ram_off_chip_en == 1) ? i_state_ram_off_chip_addr : i_state_addr[STATE_ADDR_WIDTH*2-1 -: STATE_ADDR_WIDTH];
	assign state_mem_data_wr[STATE_DATA_WIDTH*2-1 -: STATE_DATA_WIDTH] = (i_state_ram_off_chip_en == 1) ? i_state_ram_off_chip_data : i_state_data[STATE_DATA_WIDTH*2-1 -: STATE_DATA_WIDTH];

	assign state_mem_en_wr[1]                        = i_state_en[1];
	assign state_mem_we_wr[1]                        = i_state_we[1];
	assign state_mem_addr_wr[STATE_ADDR_WIDTH-1 : 0] = i_state_addr[STATE_ADDR_WIDTH-1 : 0];
	assign state_mem_data_wr[STATE_DATA_WIDTH-1 : 0] = i_state_data[STATE_DATA_WIDTH-1 : 0];
	
	// FOR GATE MEM
	assign gate_mem_en_wr[0]                                        = (i_gate_coo_en == 1) ? i_gate_coo_en : i_gate_en[0];
	assign gate_mem_we_wr[0]                                        = (i_gate_coo_en == 1) ? i_gate_coo_we : i_gate_we[0];
	assign gate_mem_addr_wr[GATE_ADDR_WIDTH*2-1 -: GATE_ADDR_WIDTH] = (i_gate_coo_en == 1) ? i_gate_coo_addr : i_gate_addr[GATE_ADDR_WIDTH*2-1 -: GATE_ADDR_WIDTH];
	assign gate_mem_data_wr[GATE_DATA_WIDTH*2-1 -: GATE_DATA_WIDTH] = (i_gate_coo_en == 1) ? i_gate_coo_data : i_gate_data[GATE_DATA_WIDTH*2-1 -: GATE_DATA_WIDTH];

	assign gate_mem_en_wr[1]                       = i_gate_en[1];
	assign gate_mem_we_wr[1]                       = i_gate_we[1];
	assign gate_mem_addr_wr[GATE_ADDR_WIDTH-1 : 0] = i_gate_addr[GATE_ADDR_WIDTH-1 : 0];
	assign gate_mem_data_wr[GATE_DATA_WIDTH-1 : 0] = i_gate_data[GATE_DATA_WIDTH-1 : 0];

	Dual_Port_BRAM 
	#(
		.DWIDTH(STATE_DATA_WIDTH), 
		.AWIDTH(STATE_ADDR_WIDTH)
	)
	STATE_MEM_inst 
	(
		.clka(clk),
		.ena(state_mem_en_wr[0]),
		.wea(state_mem_we_wr[0]),
		.addra(state_mem_addr_wr[STATE_ADDR_WIDTH*2-1 : STATE_ADDR_WIDTH]),
		.dina(state_mem_data_wr[STATE_DATA_WIDTH*2-1 : STATE_DATA_WIDTH]),
		.douta(o_state_data[STATE_DATA_WIDTH*2-1 : STATE_DATA_WIDTH]),
		
		.clkb(clk),
		.enb(state_mem_en_wr[1]),
		.web(state_mem_we_wr[1]),
		.addrb(state_mem_addr_wr[STATE_ADDR_WIDTH-1 : 0]),
		.dinb(state_mem_data_wr[STATE_DATA_WIDTH-1 : 0]),
		.doutb(o_state_data[STATE_DATA_WIDTH-1 : 0])
	);

	Dual_Port_BRAM 
	#(
		.DWIDTH(GATE_DATA_WIDTH), 
		.AWIDTH(GATE_ADDR_WIDTH)
	)
	GATE_MEM_inst 
	(
		.clka(clk),
		.ena(gate_mem_en_wr[0]),
		.wea(gate_mem_we_wr[0]),
		.addra(gate_mem_addr_wr[GATE_ADDR_WIDTH*2-1 -: GATE_ADDR_WIDTH]),
		.dina(gate_mem_data_wr[GATE_DATA_WIDTH*2-1 -: GATE_DATA_WIDTH]),
		.douta(o_gate_data[GATE_DATA_WIDTH*2-1 -: GATE_DATA_WIDTH]),
		
		.clkb(clk),
		.enb(gate_mem_en_wr[1]),
		.web(gate_mem_we_wr[1]),
		.addrb(gate_mem_addr_wr[GATE_ADDR_WIDTH-1 : 0]),
		.dinb(gate_mem_data_wr[GATE_DATA_WIDTH-1 : 0]),
		.doutb(o_gate_data[GATE_DATA_WIDTH-1 : 0])
	);
endmodule


// // For STATE MEM
// assign is_selected_state_pe_0_wr                                   = (i_state_ram_off_chip_addr[PE_NUM_WIDTH+STATE_ADDR_WIDTH -: PE_NUM_WIDTH] == PE_IDX) ? 1 : 0;
// assign is_selected_state_pe_1_wr                                   = (i_state_addr[STATE_ADDR_WIDTH*2-1 -: STATE_ADDR_WIDTH] == PE_IDX) ? 1 : 0;
// assign state_mem_en_wr[0]                                          = (i_state_ram_off_chip_en == 1) ? 
// 																			{(is_selected_state_pe_0_wr == 1) ? i_state_ram_off_chip_en : 0} :	
// 																			{(is_selected_state_pe_1_wr == 1) ? i_state_en[0] : 0};
// assign state_mem_we_wr[0]                                          = (i_state_ram_off_chip_en == 1) ? 
// 																			{(is_selected_state_pe_0_wr == 1) ? i_state_ram_off_chip_we : 0} :	
// 																			{(is_selected_state_pe_1_wr == 1) ? i_state_we[0] : 0};
// assign state_mem_addr_wr[STATE_ADDR_WIDTH*2-1 -: STATE_ADDR_WIDTH] = (i_state_ram_off_chip_en == 1) ? i_state_ram_off_chip_addr : i_state_addr[STATE_ADDR_WIDTH*2-1 -: STATE_ADDR_WIDTH];
// assign state_mem_data_wr[STATE_DATA_WIDTH*2-1 -: STATE_DATA_WIDTH] = (i_state_ram_off_chip_en == 1) ? i_state_ram_off_chip_data : i_state_data[STATE_DATA_WIDTH*2-1 -: STATE_DATA_WIDTH];

// assign state_mem_en_wr[1]                        = i_state_en[1];
// assign state_mem_we_wr[1]                        = i_state_we[1];
// assign state_mem_addr_wr[STATE_ADDR_WIDTH-1 : 0] = i_state_addr[STATE_ADDR_WIDTH-1 : 0];
// assign state_mem_data_wr[STATE_DATA_WIDTH-1 : 0] = i_state_data[STATE_DATA_WIDTH-1 : 0];

// // FOR GATE MEM
// assign gate_mem_en_wr[0]                                        = (i_gate_coo_en == 1) ? i_gate_coo_en : i_gate_en[0];
// assign gate_mem_we_wr[0]                                        = (i_gate_coo_en == 1) ? i_gate_coo_we : i_gate_we[0];
// assign gate_mem_addr_wr[GATE_ADDR_WIDTH*2-1 -: GATE_ADDR_WIDTH] = (i_gate_coo_en == 1) ? i_gate_coo_addr : i_gate_addr[GATE_ADDR_WIDTH*2-1 -: GATE_ADDR_WIDTH];
// assign gate_mem_data_wr[GATE_DATA_WIDTH*2-1 -: GATE_DATA_WIDTH] = (i_gate_coo_en == 1) ? i_gate_coo_data : i_gate_data[GATE_DATA_WIDTH*2-1 -: GATE_DATA_WIDTH];

// assign gate_mem_en_wr[1]                       = i_gate_en[1];
// assign gate_mem_we_wr[1]                       = i_gate_we[1];
// assign gate_mem_addr_wr[GATE_ADDR_WIDTH-1 : 0] = i_gate_addr[GATE_ADDR_WIDTH-1 : 0];
// assign gate_mem_data_wr[GATE_DATA_WIDTH-1 : 0] = i_gate_data[GATE_DATA_WIDTH-1 : 0];

// `timescale 1ns / 1ps

// module LSU
// #(
// 	parameter PE_IDX = 0,
//     parameter DATA_WIDTH      = 32,
// 	parameter STATE_DATA_WIDTH = DATA_WIDTH*2,
// 	parameter STATE_ADDR_WIDTH = 16,
// 	parameter GATE_DATA_WIDTH = DATA_WIDTH*2,
// 	parameter GATE_ADDR_WIDTH = 10,
// 	parameter PE_NUM_WIDTH = 2
// )
// (
// 	input                                     clk,         
// 	input                                     rst_n, 

// 	input                                     i_state_ram_off_chip_en,  
// 	input                                     i_state_ram_off_chip_we,  
// 	input [PE_NUM_WIDTH+STATE_ADDR_WIDTH-1:0] i_state_ram_off_chip_addr,
// 	input [STATE_DATA_WIDTH-1:0]              i_state_ram_off_chip_data,
	
// 	input                                     i_gate_coo_en,  
// 	input                                     i_gate_coo_we,  
// 	input [GATE_ADDR_WIDTH-1:0]               i_gate_coo_addr,
// 	input [STATE_DATA_WIDTH-1:0]              i_gate_coo_data,

// 	input                                     i_state_en,  
// 	input                                     i_state_we,  
// 	input [STATE_ADDR_WIDTH-1:0]              i_state_addr,
// 	input [STATE_DATA_WIDTH-1:0]              i_state_data,

// 	input [1:0]                               i_gate_en,  
// 	input [1:0]                               i_gate_we,  
// 	input [GATE_ADDR_WIDTH*2-1:0]             i_gate_addr, 
// 	input [GATE_DATA_WIDTH*2-1:0]             i_gate_data,

// 	output [STATE_DATA_WIDTH*2-1:0]           o_state_data, 
// 	output [GATE_DATA_WIDTH*2-1:0]            o_gate_data 
// );
// 	wire                        is_selected_state_pe_wr;
// 	wire [1:0]                    state_mem_en_wr, state_mem_we_wr, gate_mem_en_wr, gate_mem_we_wr;
// 	wire [STATE_ADDR_WIDTH-1:0] state_mem_addr_wr;
// 	wire [STATE_DATA_WIDTH-1:0] state_mem_data_wr;

// 	wire [GATE_ADDR_WIDTH-1:0] gate_mem_addr_wr;
// 	wire [GATE_DATA_WIDTH-1:0] gate_mem_data_wr;

// 	// For STATE MEM
// 	assign is_selected_state_pe_wr                                     = (i_state_ram_off_chip_addr[PE_NUM_WIDTH+STATE_ADDR_WIDTH -: PE_NUM_WIDTH] == PE_IDX) ? 1 : 0;
// 	assign state_mem_en_wr[0]                                          = (is_selected_state_pe_wr == 1) ? i_state_ram_off_chip_en : 0;
// 	assign state_mem_we_wr[0]                                          = (is_selected_state_pe_wr == 1) ? i_state_ram_off_chip_we : 0;
// 	assign state_mem_addr_wr[STATE_ADDR_WIDTH*2-1 -: STATE_ADDR_WIDTH] = i_state_ram_off_chip_addr;
// 	assign state_mem_data_wr[STATE_DATA_WIDTH*2-1 -: STATE_DATA_WIDTH] = i_state_ram_off_chip_data;

// 	assign state_mem_en_wr[1]                        = i_state_en;
// 	assign state_mem_we_wr[1]                        = i_state_we;
// 	assign state_mem_addr_wr[STATE_ADDR_WIDTH-1 : 0] = i_state_addr;
// 	assign state_mem_data_wr[STATE_DATA_WIDTH-1 : 0] = i_state_data;
	
// 	// FOR GATE MEM
// 	assign gate_mem_en_wr[0]                                        = (i_gate_coo_en == 1) ? i_gate_coo_en : i_gate_en[0];
// 	assign gate_mem_we_wr[0]                                        = (i_gate_coo_en == 1) ? i_gate_coo_we : i_gate_we[0];
// 	assign gate_mem_addr_wr[GATE_ADDR_WIDTH*2-1 -: GATE_ADDR_WIDTH] = (i_gate_coo_en == 1) ? i_gate_coo_addr : i_gate_addr[GATE_ADDR_WIDTH*2-1 -: GATE_ADDR_WIDTH];
// 	assign gate_mem_data_wr[GATE_DATA_WIDTH*2-1 -: GATE_DATA_WIDTH] = (i_gate_coo_en == 1) ? i_gate_coo_data : i_gate_data[GATE_DATA_WIDTH*2-1 -: GATE_DATA_WIDTH];

// 	assign gate_mem_en_wr[1]                       = i_gate_en[1];
// 	assign gate_mem_we_wr[1]                       = i_gate_we[1];
// 	assign gate_mem_addr_wr[GATE_ADDR_WIDTH-1 : 0] = i_gate_addr[GATE_ADDR_WIDTH-1 : 0];
// 	assign gate_mem_data_wr[GATE_DATA_WIDTH-1 : 0] = i_gate_data[GATE_DATA_WIDTH-1 : 0];

// 	Dual_Port_LDM 
// 	#(
// 		.DWIDTH(STATE_DATA_WIDTH), 
// 		.AWIDTH(STATE_ADDR_WIDTH)
// 	)
// 	STATE_MEM_inst 
// 	(
// 		.clka(clk),
// 		.ena(state_mem_en_wr[0]),
// 		.wea(state_mem_we_wr[0]),
// 		.addra(state_mem_addr_wr[STATE_ADDR_WIDTH*2-1 -: STATE_ADDR_WIDTH]),
// 		.dina(state_mem_data_wr[STATE_DATA_WIDTH*2-1 -: STATE_DATA_WIDTH]),
// 		.douta(o_state_data[STATE_DATA_WIDTH-1 -: STATE_DATA_WIDTH]),
		
// 		.clkb(clk),
// 		.enb(state_mem_en_wr[1]),
// 		.web(state_mem_we_wr[1]),
// 		.addrb(state_mem_addr_wr[STATE_ADDR_WIDTH-1 : 0]),
// 		.dinb(state_mem_data_wr[STATE_DATA_WIDTH-1 : 0]),
// 		.doutb(o_state_data[STATE_DATA_WIDTH-1 : 0])
// 	);

// 	Dual_Port_LDM 
// 	#(
// 		.DWIDTH(GATE_DATA_WIDTH), 
// 		.AWIDTH(GATE_ADDR_WIDTH)
// 	)
// 	GATE_MEM_inst 
// 	(
// 		.clka(clk),
// 		.ena(gate_mem_en_wr[0]),
// 		.wea(gate_mem_we_wr[0]),
// 		.addra(gate_mem_addr_wr[GATE_ADDR_WIDTH*2-1 -: GATE_ADDR_WIDTH]),
// 		.dina(gate_mem_data_wr[GATE_DATA_WIDTH*2-1 -: GATE_DATA_WIDTH]),
// 		.douta(o_gate_data[GATE_DATA_WIDTH*2-1 -: GATE_DATA_WIDTH]),
		
// 		.clkb(clk),
// 		.enb(gate_mem_en_wr[1]),
// 		.web(gate_mem_we_wr[1]),
// 		.addrb(gate_mem_addr_wr[GATE_ADDR_WIDTH-1 : 0]),
// 		.dinb(gate_mem_data_wr[GATE_DATA_WIDTH-1 : 0]),
// 		.doutb(o_gate_data[GATE_DATA_WIDTH-1 : 0])
// 	);
// endmodule