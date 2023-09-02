/* memory.sv
 *
 * Single port memory model for testing.
 */

module mem #(parameter SIZE=65536, parameter DEPTH=8, parameter W_DELAY=10, parameter R_DELAY=10) ();

  reg [SIZE-1:0][DEPTH-1:0] data;

endmodule
