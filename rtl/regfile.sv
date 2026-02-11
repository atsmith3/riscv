/* REGFILE
 *
 * 32-entry register file for RISC-V processor
 *
 * This module implements the general-purpose register file with 32 registers
 * (x0-x31) as specified by the RISC-V ISA. Register x0 is hardwired to zero.
 *
 * Features:
 *   - 32 registers of configurable width (default 32 bits)
 *   - Dual-read ports (a and b) for simultaneous operand access
 *   - Single-write port (c) for result writeback
 *   - Synchronous write, combinational read
 *   - Register x0 always reads as 0 and ignores writes
 *
 * Port Mapping:
 *   - Port a: Read port 1 (typically rs1)
 *   - Port b: Read port 2 (typically rs2)
 *   - Port c: Write port (typically rd)
 *
 * 20210611
 */

module regfile (
  clk,
  rst_n,
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
  input logic rst_n;
  input logic [4:0] a_idx;
  input logic [4:0] b_idx;
  input logic [4:0] c_idx;
  input logic [WIDTH-1:0] c;
  input logic wr;

  output logic [WIDTH-1:0] a;
  output logic [WIDTH-1:0] b;

  reg [WIDTH-1:0] data [DEPTH-1:0];

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
    if (!rst_n) begin
      for (int i = 1; i < DEPTH; i = i+1) begin
        data[i] <= 0;
      end
    end
    else if ((wr) && (c_idx > 0)) begin
      data[c_idx] <= c;
    end
  end
endmodule : regfile
