//
// CSR Register File for RV32I User Mode
//
// Implements the minimum required user-mode CSRs:
//   0xC00 - cycle[31:0]    - Cycle counter (lower 32 bits) - RO
//   0xC01 - time[31:0]     - Real-time clock (lower 32 bits) - RO
//   0xC02 - instret[31:0]  - Instructions retired (lower 32 bits) - RO
//   0xC80 - cycleh[31:0]   - Cycle counter (upper 32 bits) - RO
//   0xC81 - timeh[31:0]    - Real-time clock (upper 32 bits) - RO
//   0xC82 - instreth[31:0] - Instructions retired (upper 32 bits) - RO
//
// All user-mode CSRs are read-only. Writes are ignored.
// Invalid CSR addresses signal an error.
//

module csr_file (
  input  logic        clk,
  input  logic        rst_n,

  // CSR access interface
  input  logic [11:0] csr_addr,      // CSR address from instruction[31:20]
  input  logic [31:0] csr_wdata,     // Write data (ignored for RO CSRs)
  input  logic        csr_we,        // Write enable (ignored for RO CSRs)
  output logic [31:0] csr_rdata,     // Read data
  output logic        csr_valid,     // 1 if address is valid, 0 for invalid

  // Counter control
  input  logic        instret_inc    // Increment instruction retired counter
);

  // 64-bit counters
  logic [63:0] cycle_counter;
  logic [63:0] time_counter;    // Mirrors cycle counter per user requirements
  logic [63:0] instret_counter;

  // Counter increment logic
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      cycle_counter   <= 64'h0;
      time_counter    <= 64'h0;
      instret_counter <= 64'h0;
    end else begin
      // Cycle counter increments every clock cycle
      cycle_counter <= cycle_counter + 64'h1;

      // Time counter mirrors cycle counter
      time_counter <= time_counter + 64'h1;

      // Instruction retired counter increments when signaled
      if (instret_inc) begin
        instret_counter <= instret_counter + 64'h1;
      end
    end
  end

  // CSR address decoding and read logic
  always_comb begin
    csr_rdata = 32'h0;
    csr_valid = 1'b1;

    case (csr_addr)
      12'hC00: csr_rdata = cycle_counter[31:0];     // cycle (lower 32)
      12'hC01: csr_rdata = time_counter[31:0];      // time (lower 32)
      12'hC02: csr_rdata = instret_counter[31:0];   // instret (lower 32)
      12'hC80: csr_rdata = cycle_counter[63:32];    // cycleh (upper 32)
      12'hC81: csr_rdata = time_counter[63:32];     // timeh (upper 32)
      12'hC82: csr_rdata = instret_counter[63:32];  // instreth (upper 32)

      default: begin
        csr_rdata = 32'h0;
        csr_valid = 1'b0;  // Invalid CSR address
      end
    endcase
  end

endmodule
