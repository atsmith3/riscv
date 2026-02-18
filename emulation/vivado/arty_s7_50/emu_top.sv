/* emu_top.sv
 *
 * FPGA emulation wrapper for the RISC-V 32I core targeting the Arty S7-50.
 * Connects the board's 12 MHz clock to core_top with on-chip BRAM memory.
 * LEDs show pass/fail status and PC activity; BTN[0] is active-high reset.
 */

`include "datatypes.sv"

module emu_top #(
  parameter HEX_FILE = "program.hex"
) (
  input  logic        CLK12MHZ,
  input  logic [3:0]  btn,
  output logic [3:0]  led
);

  logic clk_ibuf, clk;

  IBUF u_ibuf (.I(CLK12MHZ), .O(clk_ibuf));
  BUFG u_bufg (.I(clk_ibuf), .O(clk));

  // Reset: BTN[0] is active-high on Arty S7, synchronize to clk domain
  logic rst_btn_sync0, rst_btn_sync1;
  always_ff @(posedge clk) begin
    rst_btn_sync0 <= btn[0];
    rst_btn_sync1 <= rst_btn_sync0;
  end
  wire rst_n = ~rst_btn_sync1;

  // Internal memory interface signals
  logic [31:0] mem_rdata, mem_wdata, mem_addr;
  logic        mem_read, mem_write, mem_resp;
  logic [3:0]  mem_be;
  logic [31:0] pc;

  core_top u_core_top (
    .clk       (clk),
    .rst_n     (rst_n),
    .mem_rdata (mem_rdata),
    .mem_resp  (mem_resp),
    .mem_wdata (mem_wdata),
    .mem_addr  (mem_addr),
    .mem_read  (mem_read),
    .mem_write (mem_write),
    .mem_be    (mem_be),
    .pc        (pc)
  );

  bram_memory #(
    .HEX_FILE (HEX_FILE)
  ) u_bram (
    .clk       (clk),
    .rst_n     (rst_n),
    .mem_read  (mem_read),
    .mem_write (mem_write),
    .mem_addr  (mem_addr),
    .mem_wdata (mem_wdata),
    .mem_be    (mem_be),
    .mem_rdata (mem_rdata),
    .mem_resp  (mem_resp)
  );

  // Magic address detection: last write to 0xDEAD_xxxx determines result
  logic magic_written;
  logic [31:0] magic_value;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      magic_written <= 1'b0;
      magic_value   <= 32'd0;
    end else if (mem_write && mem_addr[31:16] == 16'hDEAD) begin
      magic_written <= 1'b1;
      magic_value   <= mem_wdata;
    end
  end

  wire pass_flag = magic_written && (magic_value == 32'd1);
  wire fail_flag = magic_written && (magic_value != 32'd1);

  // LED outputs
  assign led[0] = pass_flag;          // pass
  assign led[1] = fail_flag;          // fail
  assign led[3:2] = pc[13:12];        // activity indicator

endmodule
