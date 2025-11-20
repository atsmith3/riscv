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

module mux4 #(parameter WIDTH=32) (
  input logic [WIDTH-1:0] a,
  input logic [WIDTH-1:0] b,
  input logic [WIDTH-1:0] c,
  input logic [WIDTH-1:0] d,
  input logic [1:0] sel,
  output logic [WIDTH-1:0] y
);

logic [WIDTH-1:0] n1, n2;

mux2 u_mux_0 (
  .a(a),
  .b(b),
  .sel(sel[0]),
  .y(n1));

mux2 u_mux_1 (
  .a(c),
  .b(d),
  .sel(sel[0]),
  .y(n2));

mux2 u_mux_2 (
  .a(n1),
  .b(n2),
  .sel(sel[1]),
  .y(y));

endmodule : mux4

module mux8 #(parameter WIDTH=32) (
  input logic [WIDTH-1:0] a,
  input logic [WIDTH-1:0] b,
  input logic [WIDTH-1:0] c,
  input logic [WIDTH-1:0] d,
  input logic [WIDTH-1:0] e,
  input logic [WIDTH-1:0] f,
  input logic [WIDTH-1:0] g,
  input logic [WIDTH-1:0] h,
  input logic [2:0] sel,
  output logic [WIDTH-1:0] y
);

logic [WIDTH-1:0] n1, n2;

mux4 u_mux_0 (
  .a(a),
  .b(b),
  .c(c),
  .d(d),
  .sel(sel[1:0]),
  .y(n1));

mux4 u_mux_1 (
  .a(e),
  .b(f),
  .c(g),
  .d(h),
  .sel(sel[1:0]),
  .y(n2));

mux2 u_mux_2 (
  .a(n1),
  .b(n2),
  .sel(sel[2]),
  .y(y));

endmodule : mux8
