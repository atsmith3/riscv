/* bram_memory.sv
 *
 * Synthesizable BRAM memory for FPGA emulation of the RISC-V 32I core.
 * 128KB (32768 x 32-bit words), initialized via $readmemh.
 * 1-cycle read latency with byte-enable support for sub-word stores.
 */

module bram_memory #(
  parameter HEX_FILE = "program.hex"
) (
  input  logic        clk,
  input  logic        rst_n,

  input  logic        mem_read,
  input  logic        mem_write,
  input  logic [31:0] mem_addr,
  input  logic [31:0] mem_wdata,
  input  logic [3:0]  mem_be,

  output logic [31:0] mem_rdata,
  output logic        mem_resp
);

  // 128KB = 32768 x 32-bit words, covers byte addresses 0x0000–0x1FFFF
  localparam ADDR_BITS = 15;  // 2^15 = 32768 words
  localparam ADDR_MAX  = 32'h1FFFF;

  logic [31:0] mem [0:2**ADDR_BITS-1];

  // Initialize from hex file
  initial begin
    $readmemh(HEX_FILE, mem);
  end

  // Word-aligned address index
  wire [ADDR_BITS-1:0] word_addr = mem_addr[ADDR_BITS+1:2];
  wire addr_valid = (mem_addr <= ADDR_MAX);

  // 1-cycle latency: register request, respond next cycle
  logic read_pending;
  logic write_pending;
  logic [ADDR_BITS-1:0] addr_reg;
  logic [31:0] wdata_reg;
  logic [3:0]  be_reg;
  logic addr_valid_reg;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      read_pending   <= 1'b0;
      write_pending  <= 1'b0;
      addr_reg       <= '0;
      wdata_reg      <= '0;
      be_reg         <= '0;
      addr_valid_reg <= 1'b0;
    end else begin
      read_pending   <= mem_read;
      write_pending  <= mem_write;
      addr_reg       <= word_addr;
      wdata_reg      <= mem_wdata;
      be_reg         <= mem_be;
      addr_valid_reg <= addr_valid;
    end
  end

  // Write with byte enables (on registered cycle)
  always_ff @(posedge clk) begin
    if (write_pending && addr_valid_reg) begin
      if (be_reg[0]) mem[addr_reg][7:0]   <= wdata_reg[7:0];
      if (be_reg[1]) mem[addr_reg][15:8]  <= wdata_reg[15:8];
      if (be_reg[2]) mem[addr_reg][23:16] <= wdata_reg[23:16];
      if (be_reg[3]) mem[addr_reg][31:24] <= wdata_reg[31:24];
    end
  end

  // Read data (on registered cycle)
  // Hold last read value until next valid read — the CPU captures mem_rdata
  // one cycle after mem_resp, so clearing early would zero out all loads.
  always_ff @(posedge clk) begin
    if (read_pending && addr_valid_reg)
      mem_rdata <= mem[addr_reg];
  end

  // Response signal: asserted one cycle after any read or write request.
  // Out-of-range accesses still get a response (so the CPU FSM advances),
  // but the actual read/write blocks are gated by addr_valid_reg.
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      mem_resp <= 1'b0;
    else
      mem_resp <= read_pending || write_pending;
  end

endmodule
