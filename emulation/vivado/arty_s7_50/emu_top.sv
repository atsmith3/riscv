/* emu_top.sv
 *
 * FPGA emulation wrapper for the RISC-V 32I core targeting the Arty S7-50.
 * Connects the board's 12 MHz clock to core_top and ties reset inactive.
 * All memory interface and PC ports are exposed at the top level for
 * out-of-context synthesis.
 */

`include "datatypes.sv"

module emu_top (
  input  logic        CLK12MHZ,

  // Memory interface (directly from core_top)
  input  logic [31:0] mem_rdata,
  input  logic        mem_resp,
  output logic [31:0] mem_wdata,
  output logic [31:0] mem_addr,
  output logic        mem_read,
  output logic        mem_write,
  output logic [3:0]  mem_be,

  // Program counter
  output logic [31:0] pc
);

  core_top u_core_top (
    .clk       (CLK12MHZ),
    .rst_n     (1'b1),
    .mem_rdata (mem_rdata),
    .mem_resp  (mem_resp),
    .mem_wdata (mem_wdata),
    .mem_addr  (mem_addr),
    .mem_read  (mem_read),
    .mem_write (mem_write),
    .mem_be    (mem_be),
    .pc        (pc)
  );

endmodule
