`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/24/2023 03:32:15 PM
// Design Name: 
// Module Name: blaze_core_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

//include files
`include "rtl_constants.sv"
`include "structs.sv"

module blaze_core_top(
    input wire logic clk, rst,
    input wire logic [15:0] instr_id_input,
    
    output [ROB_SIZE_CLOG-1:0] robid_out
    );
    
    
    //////////////////////////////////////////////////////////////////
    ///
    /// Fetch RAT Instance
    ///
    /// includes decode as well
    
    logic  [ISSUE_WIDTH_MAX-1:0] instr_val_id; //valid instr id
    logic  [ISSUE_WIDTH_MAX-1:0][DATA_LEN-1:0] instr_id;

    //inputs from rob
    logic  [ISSUE_WIDTH_MAX-1:0][ROB_SIZE_CLOG-1:0] rob_is_ptr;
    logic   rob_full;
    //rob retire bus
    logic  [ROB_MAX_RETIRE-1:0][SRC_LEN-1:0]          rd_ret;
    logic  [ROB_MAX_RETIRE-1:0]                      val_ret;
    logic  [ROB_MAX_RETIRE-1:0]                  rfWrite_ret;
    logic  [ROB_MAX_RETIRE-1:0][DATA_LEN-1:0]    wb_data_ret;
    logic  [ROB_MAX_RETIRE-1:0][ROB_SIZE_CLOG-1:0] robid_ret;
    
    //outputs of f-rat
    logic [ISSUE_WIDTH_MAX-1:0][OPCODE_LEN-1:0] opcode_ar;
    logic [ISSUE_WIDTH_MAX-1:0][SRC_LEN-1:0]        rd_ar;
    logic [ISSUE_WIDTH_MAX-1:0][NUM_SRCS-1:0][RAT_RENAME_DATA_WIDTH-1:0] src_rdy_2_issue_ar;
    logic [ISSUE_WIDTH_MAX-1:0][NUM_SRCS-1:0]                  src_data_type_rdy_2_issue_ar; // 1: PRF, 0: ROB 
    logic [ISSUE_WIDTH_MAX-1:0]      		instr_val_ar;

    instr_info_t [ISSUE_WIDTH_MAX-1:0]     instr_info_ar; //important instr. info passed down pipeline
    
    //*****strictly testing signals*****
    logic [ISSUE_WIDTH_MAX-1:0][OPCODE_LEN-1:0] opcode_id;
    logic [ISSUE_WIDTH_MAX-1:0][FUNC3_WIDTH-1:0] func3_id;
    logic [ISSUE_WIDTH_MAX-1:0][SRC_LEN-1   :0] rd_id;
    logic [ISSUE_WIDTH_MAX-1:0][SRC_LEN-1   :0] rs1_id;
    logic [ISSUE_WIDTH_MAX-1:0][SRC_LEN-1   :0] rs2_id;
    //logic [ISSUE_WIDTH_MAX-1:0][DATA_LEN-1:0] instr_id;
    
    always_comb begin
      instr_id = '{default:0};
          instr_id[0][6:0]   = instr_id_input[6:0];
          instr_id[0][11:7]  = instr_id_input[11:7];
          instr_id[0][19:15] = instr_id_input[19-5:15-5];
          instr_id[0][24:20] = instr_id_input[24-10:20-10];
          instr_id[0][14:12] = instr_id_input[14:12];
      for (int i = 1; i < ISSUE_WIDTH_MAX; i++) begin
          instr_id[i][6:0] = opcode_id[i];
          instr_id[i][11:7] = rd_id[i];
          instr_id[i][19:15] = rs1_id[i];
          instr_id[i][24:20] = rs2_id[i];
          instr_id[i][14:12] = func3_id[i];
      end
    end
    
    f_rat f_rat_t(.*);
    
    ///////////////////////////////////////////////////
    //
    // Multiported Regfile Instance 
    //
    
    //only output for now -> may want to add a valid signal
    logic [NUM_RF_R_PORTS-1:0][DATA_LEN-1:0] rf_r_port_data;
    
    regfile regfile_t(.*);
    
    ///////////////////////////////////////////////////
    //
    // Reservation Station Instance 
    //
    
    //inputs from CDB
	logic [CPU_NUM_LANES-1:0][ROB_SIZE_CLOG-1:0] robid_cdb;
	logic [CPU_NUM_LANES-1:0][5:0]  op_cdb;
	logic [CPU_NUM_LANES-1:0][4:0]  rd_tag_cdb;
	logic [CPU_NUM_LANES-1:0] 	   commit_instr_cdb;
	logic [CPU_NUM_LANES-1:0][31:0] result_data_cdb;

	//inputs from functional units
	logic [CPU_NUM_LANES-1:0] fu_free, fu_free_1c; //fu_free_1c means fu free in 1 cycle
    
	//rs OUTPUTS TO EXECUTION UNITS
	alu_lane_t [NUM_ALU_LANES-1:0] alu_lane_info_ex1;
	logic 	   rs_full;
	
	assign robid_out = alu_lane_info_ex1[0].robid;
    
    rs rs_t(.*);
      
    // END FRAT INSTANCE
    /////////////////////////////////////////////////////////////////////
    
endmodule