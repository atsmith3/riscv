/*
 * Integer ALU
 *
 * Arithmetic Logic Unit supporting all RV32I operations
 *
 * This module implements the ALU for the RISC-V processor, supporting
 * all standard integer operations including arithmetic, logical, shift,
 * and comparison operations.
 *
 * Supported Operations:
 *   - Arithmetic: ADD, SUB
 *   - Logical: AND, OR, XOR
 *   - Shift: SLL (logical left), SRL (logical right), SRA (arithmetic right)
 *   - Comparison: SLT (signed), SLTU (unsigned)
 *   - Pass-through: PASS_RS1, PASS_RS2 (for LUI, AUIPC, etc.)
 *
 * Branch Status Register (bsr):
 *   - bsr[2]: beq (a == b)
 *   - bsr[1]: blt (a < b, signed)
 *   - bsr[0]: bltu (a < b, unsigned)
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
      y = $signed(a) >>> shift;
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
