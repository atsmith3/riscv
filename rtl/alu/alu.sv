/*
 * Interger ALU
 */

`include datatypes.sv

module #(parameter WIDTH=32) alu (
  input logic [WIDTH-1:0] a,
  input logic [WIDTH-1:0] b,
  input logic [4:0] op,
  output logic [WIDTH-1:0] out,
  input logic valid,
  output logic ready);

logic [WIDTH-1:0] or_out;
logic [WIDTH-1:0] xor_out;
logic [WIDTH-1:0] and_out;
logic [WIDTH-1:0] sub_out;
logic [WIDTH-1:0] add_out;
logic [WIDTH-1:0] sll_out; // Shift Left Logical
logic [WIDTH-1:0] slt_out; // Store Lower Than
logic [WIDTH-1:0] sltu_out; // Store Lower Than Unsigned
logic [WIDTH-1:0] srl_out; // Shift Right Logical
logic [WIDTH-1:0] sra_out; // Shift Right Arithmatic
logic [WIDTH-1:0] out;

always_comb begin
case (op)
    ALU_ADD: begin
      out = add_out;
    end
    ALU_SLL: begin
      out = sll_out;
    end
    ALU_SLT: begin
      out = slt_out;
    end
    ALU_SLTU: begin
      out = sltu_out;
    end
    ALU_XOR: begin
      out = xor_out;
    end
    ALU_SRL: begin
      out = srl_out;
    end
    ALU_OR: begin
      out = or_out;
    end
    ALU_AND: begin
      out = and_out;
    end
    ALU_SUB: begin
      out = sub_out;
    end
    ALU_SRA: begin
      out = sra_out;
    end
    default: begin
      out = add_out;
    end
  endcase
end

endmodule : alu
