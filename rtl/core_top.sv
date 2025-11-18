/* core_top.sv
 *
 * Top-level module for the RISC-V 32I processor core
 *
 * This module contains the complete datapath and control logic for a
 * multi-cycle, non-pipelined RISC-V 32I processor. The design uses an
 * FSM-based control scheme with separate fetch, decode, and execute states.
 *
 * Architecture:
 *   - Multi-cycle execution (7-12 cycles per instruction)
 *   - Shared databus connecting all major components
 *   - Single memory interface with separate read/write signals
 *   - Harvard-style memory access pattern
 *
 * Major Components:
 *   - Program registers (IR, PC, MAR, MDR)
 *   - 32-entry register file with dual-read, single-write ports
 *   - ALU supporting all RV32I operations
 *   - Control FSM with instruction decoder
 *   - Datapath multiplexers for flexible routing
 */

`include "datatypes.sv"

module core_top (
  input logic clk,
  input logic rst_n,
  input logic [31:0] mem_rdata,
  input logic mem_resp,
  output logic [31:0] mem_wdata,
  output logic [31:0] mem_addr,
  output logic mem_read,
  output logic mem_write,
  output logic [3:0] mem_be,  // Byte enables for sub-word memory access
  output logic [31:0] pc  // Program counter output for testbench visibility
);

// Constants for PC increment values
localparam WORD_SIZE = 32'd4;
localparam HALF_WORD_SIZE = 32'd2;

databus_mux_sel_t databus_mux_sel;
rs1_mux_sel_t rs1_mux_sel;
rs2_mux_sel_t rs2_mux_sel;
wire [31:0] alu_out;
wire [31:0] databus;
wire [31:0] ir_out;
wire [31:0] mar_out;
wire [31:0] mdr_out;
wire [31:0] mdr_in;
wire [31:0] pc_in;
wire [31:0] pc_incr;
wire [31:0] pc_out;
wire [31:0] rd_in;
wire [31:0] rs1_mux_out;
wire [31:0] rs1_out;
wire [31:0] rs2_mux_out;
wire [31:0] rs2_out;
wire [4:0] rd;
wire [4:0] rs1;
wire [4:0] rs2;
alu_op_t op;
wire beq, blt, bltu;
wire beq_in, blt_in, bltu_in;
wire load_ir;
wire load_pc;
wire load_reg;
wire load_mar;
wire load_mdr;
wire mdr_mux_sel;
wire [31:0] imm;

// Byte lane signals for sub-word memory access
mem_size_t mem_size;
wire load_unsigned;
wire [31:0] load_data_aligned;   // Data from byte_lane (load path)
wire [31:0] store_data_aligned;  // Data to byte_lane (store path)

program_register #(.WIDTH(32), .INIT(0)) u_ir (.clk(clk), .rst_n(rst_n), .in(databus), .out(ir_out), .load(load_ir));
program_register #(.WIDTH(32), .INIT('h1000)) u_pc (.clk(clk), .rst_n(rst_n), .in(databus), .out(pc_out), .load(load_pc));
program_register #(.WIDTH(32), .INIT(0)) u_mar (.clk(clk), .rst_n(rst_n), .in(databus), .out(mar_out), .load(load_mar));
program_register #(.WIDTH(32), .INIT(0)) u_mdr (.clk(clk), .rst_n(rst_n), .in(mdr_in), .out(mdr_out), .load(load_mdr));

// Byte lane module for sub-word memory operations
byte_lane u_byte_lane (
  // Load path: memory -> register file (with byte extraction and sign extension)
  .mem_data_in(mem_rdata),
  .load_size(mem_size),
  .load_unsigned(load_unsigned),
  .addr_low(mar_out[1:0]),
  .load_data_out(load_data_aligned),

  // Store path: register file -> memory (with byte replication)
  .store_data_in(mdr_out),
  .store_size(mem_size),
  .mem_data_out(store_data_aligned),

  // Byte enable output
  .byte_enable(mem_be)
);

// Word-align memory address for sub-word accesses
// For byte/halfword loads, the memory returns the word containing the byte/halfword
// The byte_lane module then extracts the correct byte/halfword based on mar_out[1:0]
assign mem_addr = {mar_out[31:2], 2'b00};
assign mem_wdata = store_data_aligned;  // Use aligned data from byte_lane
assign pc = pc_out;  // Export PC for testbench visibility

regfile u_regfile (
  .clk(clk),
  .rst_n(rst_n),
  .a(rs1_out),
  .a_idx(rs1),
  .b(rs2_out),
  .b_idx(rs2),
  .c(databus),
  .c_idx(rd),
  .wr(load_reg));

control u_control (
  .clk(clk),
  .rst_n(rst_n),
  .load_mar(load_mar),
  .load_pc(load_pc),
  .load_ir(load_ir),
  .load_mdr(load_mdr),
  .load_reg(load_reg),
  .mem_write(mem_write),
  .mem_read(mem_read),
  .mem_resp(mem_resp),
  .rs1_mux_sel(rs1_mux_sel),
  .rs2_mux_sel(rs2_mux_sel),
  .databus_mux_sel(databus_mux_sel),
  .mdr_mux_sel(mdr_mux_sel),
  .alu_op(op),
  .bsr({beq, blt, bltu}),
  .ir(ir_out),
  .immediate(imm),
  .rs1_val(rs1_out),
  .rs2_val(rs2_out),
  .rs1(rs1),
  .rs2(rs2),
  .rd(rd),
  .mem_size(mem_size),
  .load_unsigned(load_unsigned));

alu #(.WIDTH(32)) u_alu (
  .a(rs1_mux_out),
  .b(rs2_mux_out),
  .op(op),
  .bsr({beq, blt, bltu}),
  .y(alu_out));

mux4 #(.WIDTH(32)) u_databus_mux (
  .sel(databus_mux_sel),
  .a(pc_out),
  .b(alu_out),
  .c(mdr_out),
  .d('b0 /* mar_out */),
  .y(databus));

mux2 #(.WIDTH(32)) u_mdr_mux (
  .sel(mdr_mux_sel),
  .a(load_data_aligned),  // Load data comes through byte_lane for extraction/extension
  .b(databus),
  .y(mdr_in));

mux4 #(.WIDTH(32)) u_rs1_mux (
  .sel(rs1_mux_sel),
  .a(rs1_out),
  .b(pc_out),
  .c(HALF_WORD_SIZE),
  .d(WORD_SIZE),
  .y(rs1_mux_out));

mux4 #(.WIDTH(32)) u_rs2_mux (
  .sel(rs2_mux_sel),
  .a(rs2_out),
  .b('b0),
  .c(imm),
  .d(pc_out),
  .y(rs2_mux_out));

endmodule : core_top
