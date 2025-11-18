/*
 * Instruction Decoder
 *
 * Decodes RV32I instructions and extracts instruction fields
 *
 * This module decodes RISC-V instructions and determines the instruction
 * format type (R, I, S, B, U, J) based on the opcode. It also extracts
 * all instruction fields (rs1, rs2, rd, funct3, funct7, etc.) and
 * generates the appropriate immediate value for the instruction type.
 *
 * Outputs:
 *   - instr_type: Instruction format (R/I/S/B/U/J/ERR)
 *   - opcode: 7-bit opcode field
 *   - rs1, rs2, rd: Register indices
 *   - funct3, funct7: Function fields for instruction variants
 *   - arithmetic: Bit 30 of instruction (distinguishes SUB/SRA from ADD/SRL)
 *   - immediate: Sign-extended immediate value based on instruction type
 *
 * 2022 04 10
 */

`include "datatypes.sv"

module ir_decoder (
  input logic [31:0] ir,
  output logic [2:0] instr_type,
  output logic [6:0] opcode,
  output logic [4:0] rs1,
  output logic [4:0] rs2,
  output logic [4:0] rd,
  output logic [6:0] funct7,
  output logic [2:0] funct3,
  output logic [3:0] fm,
  output logic [3:0] pred,
  output logic [3:0] succ,
  output logic arithmetic,
  output logic ebreak,
  output logic [31:0] immediate
);

assign funct7 = ir[31:25];
assign funct3 = ir[14:12];
assign rs1 = ir[19:15];
assign rs2 = ir[24:20];
assign rd = ir[11:7];
assign fm = ir[31:28];
assign pred = ir[27:24];
assign succ = ir[23:20];
assign opcode = ir[6:0];
assign arithmetic = ir[30];
assign ebreak = ir[20];

imm_gen_32 u_imm_gen (
  .ir(ir),
  .instr_type(instr_type),
  .imm(immediate)
);

always_comb begin
  instr_type=INSTR_ERR;
  if ((opcode==LUI)||(opcode==AUIPC)) begin
    instr_type = INSTR_U;
  end
  else if (opcode==JAL) begin
    instr_type = INSTR_J;
  end
  else if ((opcode==JALR) ||
    (opcode==LD) ||
    (opcode==ALUI && (funct3 != 3'b001 && funct3 != 3'b101)) ||
    (opcode==ECSR) ||
    (opcode==FENCE)) begin
    instr_type = INSTR_I;
  end
  else if ((opcode==ALU)||
    (opcode==ALUI && (funct3 == 3'b001 || funct3 == 3'b101))) begin
    instr_type = INSTR_R;
  end
  else if (opcode==ST) begin
    instr_type = INSTR_S;
  end
  else if (opcode==BRANCH) begin
    instr_type = INSTR_B;
  end
end


endmodule : ir_decoder
