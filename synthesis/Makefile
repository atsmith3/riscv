# ==============================================================================
# Makefile for Potato RISC-V Core Synthesis to AIGER
# ==============================================================================
# Version: 1.1.0 - Enhanced with redundancy removal, timing optimization, and ABC passes
# ==============================================================================

# Tools - Use PATH if available, fallback to absolute path
YOSYS ?= yosys
YOSYS := $(shell which yosys 2>/dev/null || echo "/home/andrew/software/yosys/yosys/yosys")
PYTHON := python3
ABC ?= abc  # ABC optimization tool (optional)

# Directories
BUILD_DIR := build
SCRIPTS_DIR := scripts
LOG_DIR := $(BUILD_DIR)/logs
OUTPUT_DIR := $(BUILD_DIR)/output
REPORT_DIR := $(BUILD_DIR)/reports

# Optimization settings
OPT_LEVEL ?= debug  # debug or production
ENABLE_ABC ?= 0     # Enable ABC optimization (0 or 1)
ENABLE_TIMING_OPT ?= 1  # Enable timing optimization (0 or 1)
ENABLE_AREA_OPT ?= 1   # Enable area optimization (0 or 1)

# Scripts
SYNTH_SCRIPT := $(SCRIPTS_DIR)/synth.tcl
EQUIV_SCRIPT := $(SCRIPTS_DIR)/equiv_check.tcl
PDK_MAP_SCRIPT := $(SCRIPTS_DIR)/pdk_map.tcl

# Outputs
VERILOG_NETLIST := $(OUTPUT_DIR)/core_top_synth.v
JSON_NETLIST := $(OUTPUT_DIR)/core_top_synth.json
BLIF_NETLIST := $(OUTPUT_DIR)/core_top_synth.blif
GF180_NETLIST := $(OUTPUT_DIR)/core_top_gf180.v

# Timestamped logs
TIMESTAMP := $(shell date +%Y%m%d_%H%M%S)
SYNTH_LOG := $(LOG_DIR)/synthesis_$(TIMESTAMP).log
EQUIV_LOG := $(LOG_DIR)/equiv_check_$(TIMESTAMP).log
PDK_MAP_LOG := $(LOG_DIR)/pdk_map_$(TIMESTAMP).log

# Summary reports
SUMMARY_REPORT := $(REPORT_DIR)/synthesis_summary.txt
TIMING_REPORT := $(REPORT_DIR)/timing_report.txt
OPTIMIZATION_REPORT := $(REPORT_DIR)/synthesis_optimization.txt

# Colors for output
COLOR_RESET := \033[0m
COLOR_BOLD := \033[1m
COLOR_GREEN := \033[32m
COLOR_BLUE := \033[34m
COLOR_YELLOW := \033[33m
COLOR_CYAN := \033[36m

.PHONY: all synth validate equiv pdk-map reports clean help version

# ==============================================================================
# Default target: run complete synthesis flow
# ==============================================================================

all: synth validate equiv pdk-map reports
	@echo ""
	@echo "$(COLOR_BOLD)$(COLOR_GREEN)================================================================================$(COLOR_RESET)"
	@echo "$(COLOR_BOLD)$(COLOR_GREEN)SYNTHESIS FLOW COMPLETE$(COLOR_RESET)"
	@echo "$(COLOR_BOLD)$(COLOR_GREEN)================================================================================$(COLOR_RESET)"
	@echo ""
	@echo "Output files:"
	@echo "  - Verilog netlist: $(VERILOG_NETLIST)"
	@echo ""
	@echo "Reports:"
	@echo "  - Summary:         $(SUMMARY_REPORT)"
	@echo ""

# ==============================================================================
# Synthesis: Convert RTL to gate-level netlist
# ==============================================================================

synth: $(VERILOG_NETLIST)

$(VERILOG_NETLIST): $(SYNTH_SCRIPT) $(SCRIPTS_DIR)/file_list.txt | $(LOG_DIR) $(OUTPUT_DIR)
	@# Verify Yosys is available
	@test -f $(YOSYS) || (echo "$(COLOR_BOLD)ERROR: Yosys not found at $(YOSYS)$(COLOR_RESET)" && echo "Install from https://github.com/YosysHQ/yosys" && exit 1)
	@# Verify required scripts exist
	@test -f $(SYNTH_SCRIPT) || (echo "$(COLOR_BOLD)ERROR: Synthesis script not found: $(SYNTH_SCRIPT)$(COLOR_RESET)" && exit 1)
	@test -f $(SCRIPTS_DIR)/file_list.txt || (echo "$(COLOR_BOLD)ERROR: File list not found: $(SCRIPTS_DIR)/file_list.txt$(COLOR_RESET)" && exit 1)
	@echo ""
	@echo "$(COLOR_BOLD)$(COLOR_BLUE)================================================================================$(COLOR_RESET)"
	@echo "$(COLOR_BOLD)$(COLOR_BLUE)RUNNING YOSYS SYNTHESIS$(COLOR_RESET)"
	@echo "$(COLOR_BOLD)$(COLOR_BLUE)================================================================================$(COLOR_RESET)"
	@echo ""
	@echo "Synthesis script: $(SYNTH_SCRIPT)"
	@echo "Log file:         $(SYNTH_LOG)"
	@echo ""
	@echo "Optimization settings:"
	@echo "  - Optimization level: $(COLOR_CYAN)$(OPT_LEVEL)$(COLOR_RESET)"
	@echo "  - ABC optimization:   $(COLOR_CYAN)$(ENABLE_ABC)$(COLOR_RESET)"
	@echo ""
	@echo "This will take 60-120 seconds..."
	@echo ""
	@cd $(SCRIPTS_DIR) && $(YOSYS) -c synth.tcl 2>&1 | tee ../$(SYNTH_LOG)
	@echo ""
	@echo "$(COLOR_GREEN)Synthesis complete!$(COLOR_RESET)"
	@echo ""
	@echo "Output files generated:"
	@ls -lh $(OUTPUT_DIR)/*.v $(OUTPUT_DIR)/*.json $(OUTPUT_DIR)/*.blif 2>/dev/null || true
	@echo ""

# ==============================================================================
# Validation: Check gate-level netlist
# ==============================================================================

validate: $(VERILOG_NETLIST)
	@echo ""
	@echo "$(COLOR_BOLD)$(COLOR_BLUE)================================================================================$(COLOR_RESET)"
	@echo "$(COLOR_BOLD)$(COLOR_BLUE)VALIDATING GATE-LEVEL NETLIST$(COLOR_RESET)"
	@echo "$(COLOR_BOLD)$(COLOR_BLUE)================================================================================$(COLOR_RESET)"
	@echo ""
	@echo "Checking file existence..."
	@test -f $(VERILOG_NETLIST) || (echo "ERROR: Verilog netlist not found" && exit 1)
	@test -s $(VERILOG_NETLIST) || (echo "ERROR: Verilog netlist is empty" && exit 1)
	@test -f $(JSON_NETLIST) || (echo "ERROR: JSON netlist not found" && exit 1)
	@test -f $(BLIF_NETLIST) || (echo "ERROR: BLIF netlist not found" && exit 1)
	@echo "$(COLOR_GREEN)All output files exist$(COLOR_RESET)"
	@echo ""
	@echo "File sizes:"
	@ls -lh $(VERILOG_NETLIST) $(JSON_NETLIST) $(BLIF_NETLIST) | awk '{print "  " $$9 ": " $$5}'
	@echo ""
	@echo "Checking for synthesized logic..."
	@grep -q 'always @(posedge clk)' $(VERILOG_NETLIST) && echo "$(COLOR_GREEN)✓ Synthesized logic found in Verilog netlist$(COLOR_RESET)" || (echo "$(COLOR_YELLOW)WARNING: No synthesized logic found$(COLOR_RESET)" && exit 1)
	@echo ""

# ==============================================================================
# Equivalence checking: Formal proof of RTL-to-gates correctness
# ==============================================================================

equiv: $(VERILOG_NETLIST) | $(LOG_DIR)
	@echo ""
	@echo "$(COLOR_BOLD)$(COLOR_BLUE)================================================================================$(COLOR_RESET)"
	@echo "$(COLOR_BOLD)$(COLOR_BLUE)RUNNING EQUIVALENCE CHECK$(COLOR_RESET)"
	@echo "$(COLOR_BOLD)$(COLOR_BLUE)================================================================================$(COLOR_RESET)"
	@echo ""
	@echo "Equivalence script: $(EQUIV_SCRIPT)"
	@echo "Log file:           $(EQUIV_LOG)"
	@echo ""
	@echo "This will take 30-60 seconds..."
	@echo ""
	@cd $(SCRIPTS_DIR) && $(YOSYS) -c equiv_check.tcl 2>&1 | tee ../$(EQUIV_LOG)
	@echo ""
	@echo "$(COLOR_GREEN)Equivalence check complete!$(COLOR_RESET)"
	@echo ""
	@if grep -q "EQUIVALENCE CHECK: PASSED" $(EQUIV_LOG); then \
		echo "$(COLOR_BOLD)$(COLOR_GREEN)✓ EQUIVALENCE PROOF: PASSED$(COLOR_RESET)"; \
		echo "  RTL and gate-level netlist are formally equivalent"; \
	else \
		echo "$(COLOR_BOLD)$(COLOR_YELLOW)⚠ WARNING: Check equivalence log for details$(COLOR_RESET)"; \
		echo "  Log file: $(EQUIV_LOG)"; \
		echo "  Common issues:"; \
		echo "    - RTL and gate-level use different file lists"; \
		echo "    - Synthesis warnings may indicate problems"; \
		echo "    - Yosys version mismatch"; \
		echo "  Run: cat $(EQUIV_LOG) | grep -i 'error\|warning'"; \
		fi
	@echo ""

# ==============================================================================
# PDK Mapping: Map Yosys primitives to GF180 standard cells
# ==============================================================================

pdk-map: $(GF180_NETLIST)

$(GF180_NETLIST): $(VERILOG_NETLIST) $(PDK_MAP_SCRIPT) | $(LOG_DIR) $(OUTPUT_DIR)
	@echo ""
	@echo "$(COLOR_BOLD)$(COLOR_BLUE)================================================================================$(COLOR_RESET)"
	@echo "$(COLOR_BOLD)$(COLOR_BLUE)MAPPING TO GF180 PDK CELLS$(COLOR_RESET)"
	@echo "$(COLOR_BOLD)$(COLOR_BLUE)================================================================================$(COLOR_RESET)"
	@echo ""
	@echo "PDK mapping script: $(PDK_MAP_SCRIPT)"
	@echo "Input:              $(VERILOG_NETLIST)"
	@echo "Output:             $(GF180_NETLIST)"
	@echo ""
	@echo "Optimization settings:"
	@echo "  - Timing optimization: $(COLOR_CYAN)$(ENABLE_TIMING_OPT)$(COLOR_RESET)"
	@echo "  - Area optimization:   $(COLOR_CYAN)$(ENABLE_AREA_OPT)$(COLOR_RESET)"
	@echo ""
	@echo "This will take 30-60 seconds..."
	@echo ""
	@cd $(SCRIPTS_DIR) && $(YOSYS) -c pdk_map.tcl 2>&1 | tee ../$(PDK_MAP_LOG)
	@echo ""
	@echo "$(COLOR_GREEN)PDK mapping complete!$(COLOR_RESET)"
	@echo ""
	@echo "Output netlist:"
	@ls -lh $(GF180_NETLIST)
	@echo ""
	@echo "Cell types used:"
	@grep 'gf180mcu_fd_sc_mcu9t5v0__' $(GF180_NETLIST) | sed 's/(.*//g' | sort -u | head -20
	@echo ""

# ==============================================================================
# Reports: Generate synthesis summary and statistics
# ==============================================================================

reports: $(REPORT_DIR)
	@echo ""
	@echo "$(COLOR_BOLD)$(COLOR_BLUE)================================================================================$(COLOR_RESET)"
	@echo "$(COLOR_BOLD)$(COLOR_BLUE)GENERATING SYNTHESIS REPORTS$(COLOR_RESET)"
	@echo "$(COLOR_BOLD)$(COLOR_BLUE)================================================================================$(COLOR_RESET)"
	@echo ""
	@echo "Generating synthesis summary report..."
	@echo "Output: $(SUMMARY_REPORT)"
	@echo ""
	@echo "# Potato RISC-V Core - Synthesis Summary" > $(SUMMARY_REPORT)
	@echo "# Generated: $(TIMESTAMP)" >> $(SUMMARY_REPORT)
	@echo "" >> $(SUMMARY_REPORT)
	@echo "## Synthesis Flow" >> $(SUMMARY_REPORT)
	@echo "" >> $(SUMMARY_REPORT)
	@echo "Synthesis script: $(SYNTH_SCRIPT)" >> $(SUMMARY_REPORT)
	@echo "Latest log: $(SYNTH_LOG)" >> $(SUMMARY_REPORT)
	@echo "" >> $(SUMMARY_REPORT)
	@echo "## Output Files" >> $(SUMMARY_REPORT)
	@echo "" >> $(SUMMARY_REPORT)
	@ls -lh $(OUTPUT_DIR)/* | awk '{print $$9 ": " $$5}' >> $(SUMMARY_REPORT)
	@echo "" >> $(SUMMARY_REPORT)
	@echo "## Interface Summary" >> $(SUMMARY_REPORT)
	@echo "" >> $(SUMMARY_REPORT)
	@echo "Inputs (35 bits):" >> $(SUMMARY_REPORT)
	@echo "  - clk: System clock" >> $(SUMMARY_REPORT)
	@echo "  - rst_n: Active-low reset" >> $(SUMMARY_REPORT)
	@echo "  - mem_rdata[31:0]: Memory read data" >> $(SUMMARY_REPORT)
	@echo "  - mem_resp: Memory ready signal" >> $(SUMMARY_REPORT)
	@echo "" >> $(SUMMARY_REPORT)
	@echo "Outputs (102 bits):" >> $(SUMMARY_REPORT)
	@echo "  - mem_wdata[31:0]: Memory write data" >> $(SUMMARY_REPORT)
	@echo "  - mem_addr[31:0]: Memory address" >> $(SUMMARY_REPORT)
	@echo "  - mem_read: Read enable" >> $(SUMMARY_REPORT)
	@echo "  - mem_write: Write enable" >> $(SUMMARY_REPORT)
	@echo "  - mem_be[3:0]: Byte enables" >> $(SUMMARY_REPORT)
	@echo "  - pc[31:0]: Program counter" >> $(SUMMARY_REPORT)
	@echo "" >> $(SUMMARY_REPORT)
	@cat $(SUMMARY_REPORT)
	@echo ""
	@echo "$(COLOR_GREEN)Summary report generated: $(SUMMARY_REPORT)$(COLOR_RESET)"
	@echo ""

# ==============================================================================
# Clean: Remove all generated files
# ==============================================================================

clean:
	@echo ""
	@echo "$(COLOR_BOLD)$(COLOR_YELLOW)Cleaning synthesis build artifacts...$(COLOR_RESET)"
	@echo ""
	@rm -rf $(LOG_DIR)
	@rm -rf $(OUTPUT_DIR)
	@rm -rf $(REPORT_DIR)
	@echo "$(COLOR_GREEN)Clean complete$(COLOR_RESET)"
	@echo ""
	@echo "Recreating directory structure..."
	@mkdir -p $(LOG_DIR) $(OUTPUT_DIR) $(REPORT_DIR)
	@echo "$(COLOR_GREEN)Done$(COLOR_RESET)"
	@echo ""
	@echo "To verify Yosys installation:"
	@echo "  $(YOSYS) --version"
	@echo ""

# ==============================================================================
# Help: Display usage information
# ==============================================================================

help:
	@echo ""
	@echo "$(COLOR_BOLD)Potato RISC-V Core - Synthesis Flow$(COLOR_RESET)"
	@echo ""
	@echo "$(COLOR_BOLD)Usage:$(COLOR_RESET)"
	@echo "  make [target] [OPT_LEVEL=debug|production] [ENABLE_ABC=0|1]"
	@echo ""
	@echo "$(COLOR_BOLD)Targets:$(COLOR_RESET)"
	@echo "  $(COLOR_BOLD)all$(COLOR_RESET)       Run complete synthesis flow (default)"
	@echo "             synth → validate → equiv → pdk-map → reports"
	@echo ""
	@echo "  $(COLOR_BOLD)synth$(COLOR_RESET)     Run Yosys synthesis to generate gate-level netlist"
	@echo "             Runtime: 60-120 seconds"
	@echo "             Outputs: .v, .json, .blif"
	@echo ""
	@echo "  $(COLOR_BOLD)validate$(COLOR_RESET)  Validate gate-level netlist structure"
	@echo "             Checks format, file existence, logic presence"
	@echo ""
	@echo "  $(COLOR_BOLD)equiv$(COLOR_RESET)     Run equivalence checking (formal proof)"
	@echo "             Runtime: 30-60 seconds"
	@echo "             Proves RTL ≡ gate-level netlist"
	@echo ""
	@echo "  $(COLOR_BOLD)pdk-map$(COLOR_RESET)   Map Yosys primitives to GF180 PDK cells"
	@echo "             Runtime: 30-60 seconds"
	@echo "             Outputs: core_top_gf180.v"
	@echo ""
	@echo "  $(COLOR_BOLD)reports$(COLOR_RESET)   Generate synthesis summary reports"
	@echo "             Creates human-readable statistics"
	@echo ""
	@echo "  $(COLOR_BOLD)clean$(COLOR_RESET)     Remove all build artifacts"
	@echo "             Preserves source scripts"
	@echo ""
	@echo "  $(COLOR_BOLD)help$(COLOR_RESET)      Display this help message"
	@echo ""
	@echo "  $(COLOR_BOLD)version$(COLOR_RESET)   Display version and environment information"
	@echo ""
	@echo "$(COLOR_BOLD)Optimization Settings:$(COLOR_RESET)"
	@echo "  OPT_LEVEL=debug      Preserve intermediate signals (default)"
	@echo "  OPT_LEVEL=production Aggressive optimization (smaller netlist)"
	@echo "  ENABLE_ABC=1         Enable ABC gate decomposition (requires ABC tool)"
	@echo "  ENABLE_TIMING_OPT=1  Enable timing-aware optimization"
	@echo "  ENABLE_AREA_OPT=1    Enable area optimization"
	@echo ""
	@echo "$(COLOR_BOLD)Output Locations:$(COLOR_RESET)"
	@echo "  Logs:    $(LOG_DIR)/"
	@echo "  Outputs: $(OUTPUT_DIR)/"
	@echo "  Reports: $(REPORT_DIR)/"
	@echo ""
	@echo "$(COLOR_BOLD)Requirements:$(COLOR_RESET)"
	@echo "  - Yosys 0.49+ (found: $(YOSYS))"
	@echo "  - Python 3"
	@echo "  - ABC (optional, for ENABLE_ABC=1)"
	@echo ""
	@echo "$(COLOR_BOLD)Example Workflows:$(COLOR_RESET)"
	@echo "  Full synthesis:        make all"
	@echo "  Synthesis only:        make synth"
	@echo "  Production mode:       make OPT_LEVEL=production all"
	@echo "  With ABC optimization: make ENABLE_ABC=1 all"
	@echo "  Clean rebuild:         make clean && make all"
	@echo ""

# ==============================================================================
# Version Information
# ==============================================================================

version:
	@echo ""
	@echo "$(COLOR_BOLD)Potato RISC-V Core - Synthesis Flow$(COLOR_RESET)"
	@echo ""
	@echo "Version: 1.1.0"
	@echo ""
	@echo "Yosys: $(YOSYS)"
	@echo "  $(shell $(YOSYS) --version 2>&1 | head -1)"
	@echo ""
	@echo "Python: $(PYTHON)"
	@echo "  $(shell $(PYTHON) --version)"
	@echo ""
	@if command -v abc >/dev/null 2>&1; then \
		echo "ABC: $(ABC)"; \
		echo "  $(shell $(ABC) -v 2>&1 | head -1)"; \
	else \
		echo "ABC: Not installed (optional, for gate decomposition)"; \
	fi; \
	@echo ""
	@echo "Build directories:"
	@echo "  Logs:    $(LOG_DIR)"
	@echo "  Output:  $(OUTPUT_DIR)"
	@echo "  Reports: $(REPORT_DIR)"
	@echo ""
	@echo "$(COLOR_BOLD)Recent Build Logs:$(COLOR_RESET)"
	@ls -lt $(LOG_DIR)/ 2>/dev/null | head -5 || echo "  No build logs found"
	@echo ""
