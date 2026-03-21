/*
 * Immediate Value Generator
 *
 * This module generates immediate values for RISC-V instructions based on
 * the instruction format type. It constructs sign-extended or zero-extended
 * immediates from the instruction fields.
 *
 * Supported Instruction Formats:
 *   - I-type: Sign-extended 12-bit immediate (bits [31:20] and [11:7])
 *   - S-type: Sign-extended 12-bit immediate (bits [31:25] and [11:7])
 *   - B-type: Sign-extended 13-bit immediate (bits [31], [7], [30:25], [11:8])
 *   - U-type: Zero-extended 20-bit immediate (bits [31:12])
 *   - J-type: Sign-extended 20-bit immediate (bits [31], [19:12], [20], [30:21])
 *   - R-type: 5-bit shift amount (bits [24:20]) for shift instructions
 *
 * Input:
 *   - ir[31:7]: Instruction bits 31-7 (opcode, funct3, rs1, funct7, rd, shamt, imm)
 *   - instr_type: Instruction format type (R, I, S, B, U, J)
 *
 * Output:
 *   - imm: 32-bit immediate value (sign or zero extended as appropriate)
 *
 * Note:
 *   - ir[6:0] (opcode) is not included in input to save wiring
 *   - Sign extension replicates bit [31] to upper bits
 *   - Zero extension fills upper bits with 0
 */

`include "datatypes.sv"

module imm_gen_32 (
  input logic [31:7] ir,
  input logic [2:0] instr_type,
  output logic [31:0] imm
);

// ============================================================================
// I-type Immediate (Sign-Extended 12-bit)
// ============================================================================
// Format: [31:20] [11:7]
// Example: ADDI x1, x0, 100 -> imm = 0x64
logic [31:0] imm_i;
assign imm_i = {{20{ir[31]}}, ir[31:20]};

// ============================================================================
// S-type Immediate (Sign-Extended 12-bit)
// ============================================================================
// Format: [31:25] [11:7]
// Example: SW x2, 100(x1) -> imm = 0x64
logic [31:0] imm_s;
assign imm_s = {{20{ir[31]}}, {ir[31:25], ir[11:7]}};

// ============================================================================
// B-type Immediate (Sign-Extended 13-bit)
// ============================================================================
// Format: [31] [7] [30:25] [11:8] [6:5]
// Bits [6:5] are always 0
// Example: BEQ x1, x2, offset -> imm = sign-extended offset
logic [31:0] imm_b;
assign imm_b = {{19{ir[31]}}, {ir[31], ir[7], ir[30:25], ir[11:8], 1'b0}};

// ============================================================================
// U-type Immediate (Zero-Extended 20-bit)
// ============================================================================
// Format: [31:12] [11:0] = 0
// Example: LUI x1, 0x1234 -> imm = 0x12340000
logic [31:0] imm_u;
assign imm_u = {ir[31:12], 12'b0};

// ============================================================================
// J-type Immediate (Sign-Extended 20-bit)
// ============================================================================
// Format: [31] [19:12] [20] [30:21] [19:20]
// Example: JAL x1, offset -> imm = sign-extended offset
logic [31:0] imm_j;
assign imm_j = {{12{ir[31]}}, {ir[19:12], ir[20], ir[30:21], 1'b0}};

// ============================================================================
// R-type Shift Amount (5-bit)
// ============================================================================
// Format: [31:25] [24:20]
// Example: SLLI x1, x0, 4 -> imm = 0x4
logic [31:0] imm_r;
assign imm_r = {27'b0, ir[24:20]};

always_comb begin
  imm = 0;
  case (instr_type)
    INSTR_I: begin
      // Sign-extended 12-bit immediate for I-type instructions
      // Used by: ADDI, SLTI, XORI, SLLI, SRLI, SRAI, LB, LH, LW, etc.
      imm = imm_i;
    end
    INSTR_S: begin
      // Sign-extended 12-bit immediate for S-type instructions
      // Used by: SB, SH, SW
      imm = imm_s;
    end
    INSTR_B: begin
      // Sign-extended 13-bit immediate for B-type instructions
      // Used by: BEQ, BNE, BLT, BGE, BLTU, BGEU
      imm = imm_b;
    end
    INSTR_U: begin
      // Zero-extended 20-bit immediate for U-type instructions
      // Used by: LUI, AUIPC
      imm = imm_u;
    end
    INSTR_J: begin
      // Sign-extended 20-bit immediate for J-type instructions
      // Used by: JAL
      imm = imm_j;
    end
    INSTR_R: begin
      // 5-bit shift amount for R-type shift instructions
      // Used by: SLLI, SRLI, SRAI (when funct3 = 001/101/101 and arithmetic=1)
      imm = imm_r;
    end
    default: begin
      // Default: zero immediate
      imm = 32'b0;
    end
  endcase
end

endmodule
