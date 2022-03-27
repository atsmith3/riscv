/* mux.sv
 * Mux definitions.
 */

module mux2 #(parameter WIDTH=32) (
  input logic [WIDTH-1:0] a,
  input logic [WIDTH-1:0] b,
  input logic sel,
  output logic [WIDTH-1:0] y
);

always_comb begin
  y = a;
  if (sel) begin
    y = b;
  end
end

endmodule : mux2
