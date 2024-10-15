/*
 * Interger ALU
 */

`include "datatypes.sv"

module alu #(parameter WIDTH=32) (
  input logic [WIDTH-1:0] a,
  input logic [WIDTH-1:0] b,
  input alu_op_t op,
  output logic [WIDTH-1:0] y,
  output logic [2:0] bsr);

logic [4:0] shift;
assign shift = b[4:0];

always_comb begin
  case (op)
    ALU_ADD: begin
      y = a + b;
    end
    ALU_SLL: begin
      y = a << shift;
    end
    ALU_SLT: begin
      // STORE LESS THAN - RS1 < RS2/IMM
      y = ( $signed(a) < $signed(b) ) ? 1 : 0;
    end
    ALU_SLTU: begin
      // STORE LESS THAN UNSIGNED - RS1 < RS2/IMM
      y = (a < b) ? 1 : 0;
    end
    ALU_XOR: begin
      y = a ^ b;
    end
    ALU_SRL: begin
      y = a >> shift;
    end
    ALU_OR: begin
      y = a | b;
    end
    ALU_AND: begin
      y = a & b;
    end
    ALU_SUB: begin
      y = a - b;
    end
    ALU_PASS_RS1: begin
      y = a;
    end
    ALU_PASS_RS2: begin
      y = b;
    end
    ALU_SRA: begin
      y = a >>> shift;
    end
    default: begin
      y = 0;
    end
  endcase


  bsr[1] = ($signed(a) < $signed(b)) ? 1 : 0;
  bsr[0] = (a < b) ? 1 : 0;
  bsr[2] = (a == b) ? 1 : 0;

end

endmodule : alu
