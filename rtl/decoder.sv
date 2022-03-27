/* decoder.sv
 *
 * RISCV32G
 */

module decoder 
  #(parameter CORE_WIDTH=32)
  (input logic [CORE_WIDTH-1:0] ir,
   output logic [4:0] rs1,
   output logic [4:0] rs2,
   output logic [4:0] rd);

endmodule : decoder
