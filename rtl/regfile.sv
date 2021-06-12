/* REGFILE
 * Dual Port Register Array with 32 registers
 *
 * 20210611
 */

module regfile (
  clk,
  rstn,
  a,
  a_idx,
  b,
  b_idx,
  c,
  c_idx,
  wr
);

  parameter WIDTH=32;
  parameter DEPTH=32;

  input logic clk;
  input logic rstn;
  input logic [4:0] a_idx;
  input logic [4:0] b_idx;
  input logic [4:0] c_idx;
  input logic [WIDTH-1:0] c;
  input logic wr;

  output logic [WIDTH-1:0] a;
  output logic [WIDTH-1:0] b;

  reg [WIDTH-1:0] data [DEPTH-1:0];

  // Initialize the array to 0 in simulation
  initial begin
    for (int i = 0; i < DEPTH; i = i+1) begin
      data[i] = 0;
    end
  end

  // Output logic
  always_comb begin
    if (a_idx > 0) begin
      a = data[a_idx];
    end
    else begin
      a = 0;
    end
    if (b_idx > 0) begin
      b = data[b_idx];
    end
    else begin
      b = 0;
    end
  end

  always_ff @ (posedge clk) begin
    if (!rstn) begin
      for (int i = 0; i < DEPTH; i = i+1) begin
        data[i] <= 0;
      end
    end
    else begin
      if ((wr) && (c_idx > 0)) begin
        data[c_idx] <= c;
      end
      else begin
        data[c_idx] <= data[c_idx];
      end
    end
  end
endmodule : regfile
