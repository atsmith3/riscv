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

  reg [WIDTH-1:0] data;

  assign out = data;

  initial begin
    data = 0;
  end

  always @ (posedge clk) begin
    if (!rst_n) begin
      data <= INIT;
    end
    else if (load) begin
      data <= in;
    end
    else begin
      data <= data;
    end
  end
endmodule : program_register
