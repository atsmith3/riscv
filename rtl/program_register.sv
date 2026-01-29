/*
 * Program Register
 *
 * Configurable-width register with load enable and reset value
 *
 * This module implements a general-purpose register used for processor
 * state elements such as the Instruction Register (IR), Program Counter (PC),
 * Memory Address Register (MAR), and Memory Data Register (MDR).
 *
 * Features:
 *   - Parameterizable width (default 32 bits)
 *   - Parameterizable initial/reset value
 *   - Load enable control for selective updates
 *   - Synchronous operation with active-low reset
 *
 * 20210612
 */

module program_register (
  clk,
  rst_n,
  in,
  out,
  load
);

  parameter WIDTH=32;
  parameter INIT=0;

  input wire clk;
  input wire rst_n;
  input wire [WIDTH-1:0] in;
  input wire load;

  output wire [WIDTH-1:0] out;

  // Generate single-bit DFFs for each bit position
  // This allows Yosys to properly technology-map each bit with its
  // individual reset value from the INIT parameter
  genvar i;
  generate
    for (i = 0; i < WIDTH; i = i + 1) begin : gen_bits
      dff_init #(.INIT(INIT[i])) u_bit (
        .clk(clk),
        .rst_n(rst_n),
        .d(in[i]),
        .load(load),
        .q(out[i])
      );
    end
  endgenerate

endmodule : program_register
