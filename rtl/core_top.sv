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

// CSR signals
wire [2:0] funct3_csr;    // Instruction funct3 for CSR operations
wire csr_access;          // High when accessing CSR
wire csr_write;           // High when writing to CSR
wire csr_valid;           // CSR address valid signal
wire [31:0] csr_rdata;    // CSR read data
wire [31:0] csr_wdata;    // CSR write data
wire csr_we;              // CSR write enable (from csr_alu)
wire [31:0] csr_operand;  // RS1 or zero-extended immediate
wire rs1_is_zero;         // True if rs1=x0 or zimm=0
wire instret_inc;         // Increment instruction retired counter

// Trap handling signals
wire trap_entry;          // High during trap entry
wire load_pc_from_csr;    // High when loading PC from CSR
wire load_mepc;           // High when writing current PC to mepc
wire load_mcause;         // High when writing mcause
wire load_mtval;          // High when writing mtval
wire [31:0] mcause_val;   // Value to write to mcause
logic [11:0] trap_csr_addr;// CSR address during trap handling
logic [31:0] trap_csr_wdata;// CSR write data during trap handling
logic trap_csr_we;         // CSR write enable during trap handling

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

// Trap CSR address mux - select CSR address
always_comb begin
  if (load_mepc) begin
    trap_csr_addr = 12'h341;  // mepc
  end else if (load_mcause) begin
    trap_csr_addr = 12'h342;  // mcause
  end else if (load_mtval) begin
    trap_csr_addr = 12'h343;  // mtval
  end else if (trap_entry && csr_access && !load_pc_from_csr) begin
    // Read mtvec during TRAP_ENTRY_3 (before load_pc_from_csr is asserted)
    trap_csr_addr = 12'h305;  // mtvec
  end else if (load_pc_from_csr) begin
    // Read mtvec (TRAP_ENTRY_4) or mepc (MRET_0)
    trap_csr_addr = trap_entry ? 12'h305 : 12'h341;  // mtvec or mepc
  end else begin
    trap_csr_addr = imm[11:0];
  end
end

// Trap CSR write data mux - select write data
// During trap, use trap-specific values. During normal CSR ops, use CSR ALU output.
// These are mutually exclusive (trap signals and csr_write never active together)
// Refactored to avoid combinational loop warning by separating dependencies

// Trap-specific write data (doesn't depend on csr_wdata)
wire [31:0] trap_wdata;
assign trap_wdata = load_mepc ? pc_out :
                    load_mcause ? mcause_val :
                    32'h0;  // mtval

// Detect if we're in a trap operation
wire is_trap_operation;
assign is_trap_operation = load_mepc | load_mcause | load_mtval;

// Final mux: use trap data during trap operations, CSR ALU output otherwise
assign trap_csr_wdata = is_trap_operation ? trap_wdata : csr_wdata;

// Trap CSR write enable
assign trap_csr_we = load_mepc | load_mcause | load_mtval | (csr_we & csr_write);

// CSR register file for user-mode counters and machine-mode trap handling
csr_file u_csr_file (
  .clk(clk),
  .rst_n(rst_n),
  .csr_addr(trap_csr_addr),   // Muxed CSR address
  .csr_wdata(trap_csr_wdata), // Muxed write data
  .csr_we(trap_csr_we),       // Muxed write enable
  .csr_rdata(csr_rdata),      // Read data
  .csr_valid(csr_valid),      // Address valid signal
  .instret_inc(instret_inc)   // Increment instruction retired counter
);

// CSR ALU for read-modify-write operations
csr_alu u_csr_alu (
  .csr_rdata(csr_rdata),     // Current CSR value
  .rs1_or_zimm(csr_operand), // RS1 value or zero-extended immediate
  .funct3(funct3_csr),       // CSR operation from instruction funct3
  .rs1_is_zero(rs1_is_zero), // Write suppression flag
  .csr_wdata(csr_wdata),     // New CSR value
  .csr_we(csr_we)            // Write enable
);

// CSR operand selection: For immediate variants (funct3[2] set), use zimm from rs1 field
// Otherwise use rs1 register value
assign csr_operand = funct3_csr[2] ? {27'b0, rs1} : rs1_out;
assign rs1_is_zero = funct3_csr[2] ? (rs1 == 5'b0) : (rs1 == 5'b0);

// Increment instret counter when completing an instruction (transitioning to PC_INC or direct to FETCH)
assign instret_inc = load_pc;  // PC is loaded when instruction completes

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
  .rs1(rs1),
  .rs2(rs2),
  .rd(rd),
  .mem_size(mem_size),
  .load_unsigned(load_unsigned),
  .funct3_out(funct3_csr),
  .csr_access(csr_access),
  .csr_write(csr_write),
  .csr_valid(csr_valid),
  .trap_entry(trap_entry),
  .load_pc_from_csr(load_pc_from_csr),
  .load_mepc(load_mepc),
  .load_mcause(load_mcause),
  .load_mtval(load_mtval),
  .mcause_val(mcause_val));

alu #(.WIDTH(32)) u_alu (
  .a(rs1_mux_out),
  .b(rs2_mux_out),
  .op(op),
  .bsr({beq, blt, bltu}),
  .y(alu_out));

mux8 #(.WIDTH(32)) u_databus_mux (
  .sel(databus_mux_sel),
  .a(pc_out),          // DATABUS_PC = 0
  .b(alu_out),         // DATABUS_ALU = 1
  .c(mdr_out),         // DATABUS_MDR = 2
  .d('b0 /* mar_out */), // DATABUS_MAR = 3
  .e(csr_rdata),       // DATABUS_CSR = 4
  .f(32'b0),           // Unused
  .g(32'b0),           // Unused
  .h(32'b0),           // Unused
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
