/*
 * Register
 *
 * Register type that is used for IR and PC.
 *
 * 20210612
 */

module register (
  clk,
  rstn,
  in,
  out,
  wr
);

  parameter WIDTH=32;

  input wire clk;
  input wire rstn;
  input wire [WIDTH-1:0] in;
  input wire wr;

  output wire [WIDTH-1:0] out;

  reg [WIDTH-1:0] data;

  assign out = data;

  initial begin
    data = 0;
  end

  always @ (posedge clk) begin
    if (!rstn) begin
      data <= 0;
    end
    else if (wr) begin
      data <= in;
    end
    else begin
      data <= data;
    end
  end
endmodule : register
