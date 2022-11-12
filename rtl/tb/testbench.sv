/*
 * Testbench for POTATO RISC-V CORE
 */

module tb ();
  localparam WIDTH=32;

  core_top u_POTATO (

  );

  memory_model #(.ADDR_WIDTH(WIDTH)) mem (

  );

endmodule
