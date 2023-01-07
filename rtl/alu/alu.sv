/*
 * Interger ALU
 */

`include "datatypes.sv"

module alu #(parameter WIDTH=32) (
  input logic [WIDTH-1:0] rs1,
  input logic [WIDTH-1:0] rs2,
  input logic [3:0] op,
  output logic [WIDTH-1:0] rd,
  output logic [2:0] bsr);

logic [4:0] shift;
assign shift = rs2[4:0];

always_comb begin
  case (op)
    ALU_ADD: begin
      rd = rs1 + rs2;
    end
    ALU_SLL: begin
      rd = rs1 << shift;
    end
    ALU_SLT: begin
      // STORE LESS THAN - RS1 < RS2/IMM
      rd = ( $signed(rs1) < $signed(rs2) ) ? 1 : 0;
    end
    ALU_SLTU: begin
      // STORE LESS THAN UNSIGNED - RS1 < RS2/IMM
      rd = (rs1 < rs2) ? 1 : 0;
    end
    ALU_XOR: begin
      rd = rs1 ^ rs2;
    end
    ALU_SRL: begin
      rd = rs1 >> shift;
    end
    ALU_OR: begin
      rd = rs1 | rs2;
    end
    ALU_AND: begin
      rd = rs1 & rs2;
    end
    ALU_SUB: begin
      rd = rs1 - rs2;
    end
    ALU_SRA: begin
      rd = rs1 >>> shift;
    end
    default: begin
      rd = 0;
    end
  endcase
end

endmodule : alu
