/*
 * Register
 *
 * Register type that is used for IR and PC.
 *
 * 20210612
 */

module program_register (
  clk,
  rstn,
  in,
  out,
  load
);

  parameter WIDTH=32;
  parameter INIT=0;

  input wire clk;
  input wire rstn;
  input wire [WIDTH-1:0] in;
  input wire load;

  output wire [WIDTH-1:0] out;

  reg [WIDTH-1:0] data;

  assign out = data;

  initial begin
    data = 0;
  end

  always @ (posedge clk) begin
    if (!rstn) begin
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
