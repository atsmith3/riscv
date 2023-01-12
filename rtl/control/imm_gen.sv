/* 
 * Immediate value generator
 *
 * Outputs all the immediate values based on the instruction register.
 * Definitions for both the 32 bit G instructions and TODO eventually the 16
 * bit compressed C instructions.
 *
 * 2022 04 10
 */

`include "datatypes.sv"

module imm_gen_32 (
  input logic [31:0] ir,
  input logic [2:0] instr_type,
  output logic [31:0] imm
);

logic [31:0] imm_i, imm_s, imm_b, imm_u, imm_j;
assign imm_i = {{20{ir[31]}},ir[31:20]};
assign imm_s = {{20{ir[31]}},{ir[31:25],ir[11:7]}};
assign imm_b = {{19{ir[31]}},{ir[12],ir[7],ir[30:25],ir[11:8],1'b0}};
assign imm_u = {ir[31:12],12'b0};
assign imm_j = {{11{ir[31]}},{ir[19:12],ir[20],ir[30:21],1'b0}};

always_comb begin
  imm = 0;
  case (instr_type)
    INSTR_I: begin
      // Sign Extended Immediate[11:0]
      imm = imm_i;
    end
    INSTR_S: begin
      // Sign Extended Immediate[11:0]
      imm = imm_s;
    end
    INSTR_B: begin 
      // Sign Extended Immediate
      imm = imm_b;
    end
    INSTR_U: begin
      // Unsigned 32b Immedate
      imm = imm_u;
    end
    INSTR_J: begin
      // Sign Extended Immediate[20:1]
      imm = imm_j;
    end
    default: begin

    end
  endcase
end

endmodule
