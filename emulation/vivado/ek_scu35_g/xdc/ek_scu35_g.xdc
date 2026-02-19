## EK-SCU35-G design constraints for the RISC-V emulation wrapper.
## Only the pins actually used by emu_top are constrained here.
## The vendor master file (EK_SCU35_Rev3B.xdc) lives in xdc/reference/ for reference only.
##
## Bank voltage notes:
##   Bank 46 (clock):             VR_VCCO_47_1V8  → 1.8 V  (fixed)
##   Bank 45 (LEDs, GPIO_SW_C):   VR_VCCO_45_46_ADJ → 3.3 V (eval-kit default)
##   Bank 66 (CPU_RESET_B):       VR_VCCO_65_66_67_68_3V3 → 3.3 V (fixed)

## ── System reference clock: 200 MHz differential, Bank 46 (1.8 V) ──────────
set_property PACKAGE_PIN F23     [get_ports SYSTEM_R_CLK_P]
set_property PACKAGE_PIN E23     [get_ports SYSTEM_R_CLK_N]
set_property IOSTANDARD  LVDS    [get_ports SYSTEM_R_CLK_P]
set_property IOSTANDARD  LVDS    [get_ports SYSTEM_R_CLK_N]
create_clock -name sys_clk -period 5.000 -waveform {0.000 2.500} [get_ports SYSTEM_R_CLK_P]

## ── CPU Reset button: active-low, Bank 66 (3.3 V) ───────────────────────────
set_property PACKAGE_PIN F3       [get_ports CPU_RESET_B]
set_property IOSTANDARD  LVCMOS33 [get_ports CPU_RESET_B]

## ── Center pushbutton (GPIO_SW_C): active-high, Bank 45 (3.3 V) ─────────────
set_property PACKAGE_PIN Y22      [get_ports GPIO_SW_C]
set_property IOSTANDARD  LVCMOS33 [get_ports GPIO_SW_C]

## ── LEDs: Bank 45 (3.3 V) ───────────────────────────────────────────────────
## LED0_GREEN — pass indicator
set_property PACKAGE_PIN AB18     [get_ports LED0_GREEN]
set_property IOSTANDARD  LVCMOS33 [get_ports LED0_GREEN]

## LED1_RED — fail indicator
set_property PACKAGE_PIN V18      [get_ports LED1_RED]
set_property IOSTANDARD  LVCMOS33 [get_ports LED1_RED]

## LED2_BLUE — PC[12] activity
set_property PACKAGE_PIN AA21     [get_ports LED2_BLUE]
set_property IOSTANDARD  LVCMOS33 [get_ports LED2_BLUE]

## LED3_BLUE — PC[13] activity
set_property PACKAGE_PIN U21      [get_ports LED3_BLUE]
set_property IOSTANDARD  LVCMOS33 [get_ports LED3_BLUE]

## ── Bitstream / configuration ────────────────────────────────────────────────
set_property CONFIG_VOLTAGE  3.3  [current_design]
set_property CFGBVS          VCCO [current_design]
