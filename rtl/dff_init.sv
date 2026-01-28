/*
 * Single-Bit D Flip-Flop with Parameterizable Reset Value
 *
 * This module implements a single-bit register with configurable reset value.
 * Designed for Yosys technology mapping compatibility - single-bit DFFs with
 * constant INIT values map cleanly to standard cell libraries.
 *
 * Features:
 *   - Parameterizable initial/reset value (1'b0 or 1'b1)
 *   - Load enable control for selective updates
 *   - Synchronous operation with active-low reset
 *
 * 20210612
 */

module dff_init (
  clk,
  rst_n,
  d,
  load,
  q
);

  parameter INIT = 1'b0;

  input wire clk;
  input wire rst_n;
  input wire d;
  input wire load;

  output wire q;

  reg data;

  assign q = data;

  initial begin
    data = 1'b0;
  end

  always @ (posedge clk) begin
    if (!rst_n) begin
      data <= INIT;
    end
    else if (load) begin
      data <= d;
    end
    else begin
      data <= data;
    end
  end

endmodule : dff_init
