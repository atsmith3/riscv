/* emu_top.sv
 *
 * FPGA emulation wrapper for the RISC-V 32I core targeting the EK-SCU35-G
 * (Spartan UltraScale+ XCSU35P).
 *
 * Clock:  200 MHz differential SYSTEM_R_CLK_P/N (Bank 46, 1.8 V LVDS).
 *         IBUFDS → MMCME4_BASE → 12 MHz core clock.
 *         VCO = 200 MHz × 6 / 1 = 1200 MHz; CLKOUT0 = 1200 / 100 = 12 MHz.
 *
 * Reset:  Active when any of:
 *           CPU_RESET_B = 0  (dedicated reset button, active-low, Bank 66)
 *           GPIO_SW_C   = 1  (center pushbutton, active-high, Bank 45)
 *           mmcm_locked = 0  (clock not yet stable)
 *         Two-stage async-assert / sync-deassert synchronizer.
 *
 * LEDs (Bank 45):
 *   LED0_GREEN — pass (magic write 0xDEADxxxx with value 1)
 *   LED1_RED   — fail (magic write 0xDEADxxxx with value ≠ 1)
 *   LED2_BLUE  — PC[12] activity
 *   LED3_BLUE  — PC[13] activity
 */

`include "datatypes.sv"

module emu_top #(
  parameter HEX_FILE = "program.hex"
) (
  input  logic SYSTEM_R_CLK_P,  // 200 MHz diff clock, Bank 46 (1.8 V)
  input  logic SYSTEM_R_CLK_N,
  input  logic CPU_RESET_B,     // Active-low reset button, Bank 66 (3.3 V)
  input  logic GPIO_SW_C,       // Center pushbutton, active-high, Bank 45
  output logic LED0_GREEN,      // Pass indicator
  output logic LED1_RED,        // Fail indicator
  output logic LED2_BLUE,       // PC[12] activity
  output logic LED3_BLUE        // PC[13] activity
);

  // ── Clock ─────────────────────────────────────────────────────────────────
  logic clk_ibufds;
  logic clk_fb_out, clk_fb;
  logic clk_mmcm, clk;
  logic mmcm_locked;

  IBUFDS u_ibufds (
    .I  (SYSTEM_R_CLK_P),
    .IB (SYSTEM_R_CLK_N),
    .O  (clk_ibufds)
  );

  // VCO = 200 MHz × CLKFBOUT_MULT_F(6) / DIVCLK_DIVIDE(1) = 1200 MHz
  // CLKOUT0 = 1200 MHz / CLKOUT0_DIVIDE_F(100) = 12 MHz
  MMCME4_BASE #(
    .CLKIN1_PERIOD      (5.000),    // 200 MHz input → 5 ns period
    .CLKFBOUT_MULT_F    (6.000),    // VCO = 1200 MHz
    .DIVCLK_DIVIDE      (1),
    .CLKOUT0_DIVIDE_F   (100.000),  // 12 MHz output
    .CLKOUT0_DUTY_CYCLE (0.500),
    .CLKOUT0_PHASE      (0.000),
    .BANDWIDTH          ("OPTIMIZED"),
    .STARTUP_WAIT       ("FALSE")
  ) u_mmcm (
    .CLKIN1   (clk_ibufds),
    .CLKFBIN  (clk_fb),
    .CLKOUT0  (clk_mmcm),
    .CLKFBOUT (clk_fb_out),
    .LOCKED   (mmcm_locked),
    .RST      (1'b0),
    .PWRDWN   (1'b0)
  );

  BUFG u_bufg_fb  (.I(clk_fb_out), .O(clk_fb));
  BUFG u_bufg_clk (.I(clk_mmcm),   .O(clk));

  // ── Reset: async-assert, sync-deassert ────────────────────────────────────
  // rst_async goes high immediately on any reset condition; deasserts
  // synchronously after two clean clock edges once all conditions clear.
  logic rst_async;
  logic rst_sync0, rst_sync1;

  assign rst_async = !CPU_RESET_B || GPIO_SW_C || !mmcm_locked;

  always_ff @(posedge clk or posedge rst_async) begin
    if (rst_async) begin
      rst_sync0 <= 1'b1;
      rst_sync1 <= 1'b1;
    end else begin
      rst_sync0 <= 1'b0;
      rst_sync1 <= rst_sync0;
    end
  end

  wire rst_n = ~rst_sync1;

  // ── Memory interface ──────────────────────────────────────────────────────
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

  // ── Test result detection ─────────────────────────────────────────────────
  // Any SW write to 0xDEAD_xxxx latches the result value.
  // Value 1 = pass, anything else = fail.
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

  // ── LED outputs ───────────────────────────────────────────────────────────
  assign LED0_GREEN = pass_flag;
  assign LED1_RED   = fail_flag;
  assign LED2_BLUE  = pc[12];
  assign LED3_BLUE  = pc[13];

endmodule
