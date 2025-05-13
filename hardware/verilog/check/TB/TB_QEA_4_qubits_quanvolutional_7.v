`timescale 1ns / 1ps

module TB_QEA_4_qubits_quanvolutional_7;
    parameter PE_NUM_WIDTH            = 2;
    parameter PE_NUM                  = 4;
    parameter PE_IDX                  = 0;
    parameter DATA_WIDTH              = 32;
    parameter MAX_QBIT_WIDTH          = 6;
    parameter ALU_DATA_WIDTH          = DATA_WIDTH;
    parameter STATE_DATA_WIDTH        = DATA_WIDTH*2;
    parameter STATE_ADDR_WIDTH        = 16;
    parameter GATE_DATA_WIDTH         = DATA_WIDTH*2;
    parameter GATE_ADDR_WIDTH         = 6;
    parameter GATE_CONTEXT_DATA_WIDTH = DATA_WIDTH*2;
    parameter GATE_CONTEXT_ADDR_WIDTH = 16;
    // parameter GATE_NUM_WIDTH          = 4;
    parameter NUM_FRAC_BIT            = 30;
    parameter HALF_CYCLE_TIME         = 2;
    parameter CTX_LINK = "..\\hardware\\gate_ctx_for_sim\\quantum_circuit_data_4_qubits\\output_hex_4_qubits_quanvolutional_7.txt";

    reg                                 clk;
    reg                                 rst_n;

    reg 					            i_start;
    reg [MAX_QBIT_WIDTH-1:0]		    i_qbit_num;

    reg                                 i_ctx_en;
    reg                                 i_ctx_wea;
    reg [GATE_CONTEXT_ADDR_WIDTH-1:0]   i_ctx_addr;
    reg [GATE_CONTEXT_DATA_WIDTH-1:0]   i_ctx_data;
                            
    reg              			        i_state_ena;
    reg              		            i_state_wea;
    reg [STATE_ADDR_WIDTH-1 : 0]        i_state_addra;
    reg [PE_NUM*STATE_DATA_WIDTH-1 : 0] i_state_dina;

    wire 						        o_complete;
    wire [STATE_DATA_WIDTH*PE_NUM-1:0]  o_state_dout;

    reg [STATE_ADDR_WIDTH-1 : 0]        state_addra;

	reg [GATE_CONTEXT_DATA_WIDTH-1:0] ctx_ram [2**GATE_CONTEXT_ADDR_WIDTH-1:0];
    integer ins_num = 127;

    integer i;

    time start_time, end_time;
    integer file_time_check;
     
    initial begin
        file_time_check = $fopen("..\\hardware\\verilog\\generated_sim_file\\quantum_circuit_data_4_qubits\\quanvolutional_7\\timestamps_4_qubits_quanvolutional_7.txt", "w");
        $readmemh(CTX_LINK, ctx_ram, 0, ins_num-1);

        #(HALF_CYCLE_TIME*5);
            clk <= 0;
            rst_n <= 0;

            i_start       <= 0;
            i_qbit_num    <= 4;

            i_ctx_en      <= 0;
            i_ctx_wea     <= 0;
            i_ctx_addr    <= 0;
            i_ctx_data    <= 0;
                                    
            i_state_ena   <= 0;
            i_state_wea   <= 0;
            i_state_addra <= 0;
            i_state_dina  <= 0;

            state_addra   <= 0;
        
        #(HALF_CYCLE_TIME*3); 
            rst_n <= 1;

        // =========================== Load ctx data into CTX RAM ===========================
        #(HALF_CYCLE_TIME*2); 
            for(i=0; i<ins_num; i=i+1) begin
                if(i == 0) begin
                    i_ctx_addr <= 0;
                end
                else begin
                    i_ctx_addr <= i_ctx_addr+1;
                end

                i_ctx_en   <= 1;
                i_ctx_wea  <= 1;
                i_ctx_data <= ctx_ram[i];
                #(HALF_CYCLE_TIME*2);
            end

            i_ctx_en  <= 0;
            i_ctx_wea <= 0;

        // =========================== Load state data into STATE RAM ===========================  
        #(HALF_CYCLE_TIME*2);
            for(i=0; i<2**(i_qbit_num-2); i=i+1) begin
                if(i == 0) begin
                    i_state_addra <= 0;
                    i_state_dina  <= {
                        64'h40000000_00000000,
                        64'h00000000_00000000,
                        64'h00000000_00000000,
                        64'h00000000_00000000
                    };
                end
                else begin
                    i_state_addra <= state_addra;
                    i_state_dina  <= {
                        64'h00000000_00000000,
                        64'h00000000_00000000,
                        64'h00000000_00000000,
                        64'h00000000_00000000
                    };
                end
                i_state_ena   <= 0-1;
                i_state_wea   <= 0-1;
                state_addra <= state_addra + 1;
                #(HALF_CYCLE_TIME*2);
            end

            i_state_ena <= 0;
            i_state_wea <= 0;

        #(HALF_CYCLE_TIME*2);
            start_time = $time;
            $fwrite(file_time_check, "Program started at time %0t ns\n", start_time);
            i_start <= 1;

        #(HALF_CYCLE_TIME*2);
            i_start <= 0;

        #(HALF_CYCLE_TIME*2);
            while(o_complete == 0) begin
                #(HALF_CYCLE_TIME*2);
            end

            end_time = $time;
            $fwrite(file_time_check, "Program ended at time %0t ns\n", end_time);
            $fwrite(file_time_check, "Execution time = %0t ns\n", end_time - start_time);
            $fclose(file_time_check);

        #(HALF_CYCLE_TIME*2);
            state_addra <= 0;
            
            for(i=0; i<2**(i_qbit_num-2); i=i+1) begin
                if(i == 0) begin
                    i_state_addra <= 0;
                end
                else begin
                    i_state_addra <= state_addra;
                end
                i_state_ena   <= 0-1;
                i_state_wea   <= 0-1;
                state_addra <= state_addra + 1;
                #(HALF_CYCLE_TIME*2);
            end

            i_state_ena <= 0;
            i_state_wea <= 0;

        #200 $finish;
    end


    always @(clk) begin
		#HALF_CYCLE_TIME; 
		    clk <= ~clk;
	end

    QEA
    #(
        .PE_NUM_WIDTH(PE_NUM_WIDTH),
        .PE_NUM(PE_NUM),
        .DATA_WIDTH(DATA_WIDTH),
        .MAX_QBIT_WIDTH(MAX_QBIT_WIDTH),
        .ALU_DATA_WIDTH(ALU_DATA_WIDTH),
        .STATE_DATA_WIDTH(STATE_DATA_WIDTH),
        .STATE_ADDR_WIDTH(STATE_ADDR_WIDTH),
        .GATE_DATA_WIDTH(GATE_DATA_WIDTH),
        .GATE_ADDR_WIDTH(GATE_ADDR_WIDTH),
        .GATE_CONTEXT_DATA_WIDTH(GATE_CONTEXT_DATA_WIDTH),
        .GATE_CONTEXT_ADDR_WIDTH(GATE_CONTEXT_ADDR_WIDTH),
        .NUM_FRAC_BIT(NUM_FRAC_BIT)
    )
    QEA_inst
    (
        .clk(clk),
        .rst_n(rst_n),

        .i_start(i_start),
        .i_qbit_num(i_qbit_num),

        .i_ctx_en(i_ctx_en),
        .i_ctx_wea(i_ctx_wea),
        .i_ctx_addr(i_ctx_addr),
        .i_ctx_data(i_ctx_data),
                                
        .i_state_ena(i_state_ena),
        .i_state_wea(i_state_wea),
        .i_state_addra(i_state_addra),
        .i_state_dina(i_state_dina),

        .o_complete(o_complete),
        .o_state_dout(o_state_dout)
    );
endmodule
