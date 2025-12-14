//
// CSR ALU - CSR Read-Modify-Write Logic
//
// Implements the atomic read-modify-write operations for CSR instructions:
//   CSRRW/CSRRWI (001/101): Write rs1/zimm to CSR
//   CSRRS/CSRRSI (010/110): Set bits in CSR using rs1/zimm as mask
//   CSRRC/CSRRCI (011/111): Clear bits in CSR using rs1/zimm as mask
//
// Write suppression: If rs1=x0 (or zimm=0), don't write to CSR
// (Allows read-only access without side effects)
//

`include "datatypes.sv"

module csr_alu (
  input  logic [31:0] csr_rdata,      // Current CSR value (from csr_file)
  input  logic [31:0] rs1_or_zimm,    // RS1 value or zero-extended immediate
  input  logic [2:0]  funct3,         // CSR operation (from instruction[14:12])
  input  logic        rs1_is_zero,    // True if rs1=x0 or zimm=0

  output logic [31:0] csr_wdata,      // New CSR value to write
  output logic        csr_we          // Write enable (0 if write suppressed)
);

  // CSR operation encoding from datatypes.sv (csr_op_t enum)
  // Using enum values: CSR_RW, CSR_RS, CSR_RC, CSR_RWI, CSR_RSI, CSR_RCI

  always_comb begin
    // Default values
    csr_wdata = csr_rdata;
    csr_we = 1'b0;

    case (funct3)
      // CSRRW / CSRRWI: Atomic read/write
      // New CSR value = rs1_or_zimm (pass through)
      // Write suppression: Never suppress for CSRRW (always writes)
      CSR_RW, CSR_RWI: begin
        csr_wdata = rs1_or_zimm;
        csr_we = 1'b1;  // Always write for RW variants
      end

      // CSRRS / CSRRSI: Atomic read and set bits
      // New CSR value = csr_rdata | rs1_or_zimm (bitwise OR)
      // Write suppression: If rs1=x0 or zimm=0, don't write
      CSR_RS, CSR_RSI: begin
        csr_wdata = csr_rdata | rs1_or_zimm;
        csr_we = ~rs1_is_zero;  // Write only if rs1 ≠ x0 (or zimm ≠ 0)
      end

      // CSRRC / CSRRC I: Atomic read and clear bits
      // New CSR value = csr_rdata & ~rs1_or_zimm (bitwise AND with complement)
      // Write suppression: If rs1=x0 or zimm=0, don't write
      CSR_RC, CSR_RCI: begin
        csr_wdata = csr_rdata & ~rs1_or_zimm;
        csr_we = ~rs1_is_zero;  // Write only if rs1 ≠ x0 (or zimm ≠ 0)
      end

      default: begin
        csr_wdata = csr_rdata;
        csr_we = 1'b0;
      end
    endcase
  end

endmodule
