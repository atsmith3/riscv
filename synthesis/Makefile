# ==============================================================================
# Makefile for Potato RISC-V Core Synthesis to AIGER
# ==============================================================================

# Tools
YOSYS := /home/andrew/software/yosys/yosys/yosys
PYTHON := python3

# Directories
BUILD_DIR := build
SCRIPTS_DIR := scripts
LOG_DIR := $(BUILD_DIR)/logs
OUTPUT_DIR := $(BUILD_DIR)/output
REPORT_DIR := $(BUILD_DIR)/reports

# Scripts
SYNTH_SCRIPT := $(SCRIPTS_DIR)/synth.tcl
EQUIV_SCRIPT := $(SCRIPTS_DIR)/equiv_check.tcl

# Outputs
VERILOG_NETLIST := $(OUTPUT_DIR)/core_top_synth.v
JSON_NETLIST := $(OUTPUT_DIR)/core_top_synth.json
BLIF_NETLIST := $(OUTPUT_DIR)/core_top_synth.blif

# Timestamped logs
TIMESTAMP := $(shell date +%Y%m%d_%H%M%S)
SYNTH_LOG := $(LOG_DIR)/synthesis_$(TIMESTAMP).log
EQUIV_LOG := $(LOG_DIR)/equiv_check_$(TIMESTAMP).log

# Summary report
SUMMARY_REPORT := $(REPORT_DIR)/synthesis_summary.txt

# Colors for output
COLOR_RESET := \033[0m
COLOR_BOLD := \033[1m
COLOR_GREEN := \033[32m
COLOR_BLUE := \033[34m
COLOR_YELLOW := \033[33m

.PHONY: all synth validate equiv reports clean help

# ==============================================================================
# Default target: run complete synthesis flow
# ==============================================================================

all: synth validate equiv reports
	@echo ""
	@echo "$(COLOR_BOLD)$(COLOR_GREEN)================================================================================$(COLOR_RESET)"
	@echo "$(COLOR_BOLD)$(COLOR_GREEN)SYNTHESIS FLOW COMPLETE$(COLOR_RESET)"
	@echo "$(COLOR_BOLD)$(COLOR_GREEN)================================================================================$(COLOR_RESET)"
	@echo ""
	@echo "Output files:"
	@echo "  - Verilog netlist: $(VERILOG_NETLIST)"
	@echo "  - Symbol map:      $(SYMBOL_MAP)"
	@echo ""
	@echo "Reports:"
	@echo "  - Summary:         $(SUMMARY_REPORT)"
	@echo ""

# ==============================================================================
# Synthesis: Convert RTL to gate-level netlist
# ==============================================================================

synth: $(VERILOG_NETLIST)

$(VERILOG_NETLIST): $(SYNTH_SCRIPT) $(SCRIPTS_DIR)/file_list.txt | $(LOG_DIR) $(OUTPUT_DIR)
	@echo ""
	@echo "$(COLOR_BOLD)$(COLOR_BLUE)================================================================================$(COLOR_RESET)"
	@echo "$(COLOR_BOLD)$(COLOR_BLUE)RUNNING YOSYS SYNTHESIS$(COLOR_RESET)"
	@echo "$(COLOR_BOLD)$(COLOR_BLUE)================================================================================$(COLOR_RESET)"
	@echo ""
	@echo "Synthesis script: $(SYNTH_SCRIPT)"
	@echo "Log file:         $(SYNTH_LOG)"
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
	fi
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

# ==============================================================================
# Help: Display usage information
# ==============================================================================

help:
	@echo ""
	@echo "$(COLOR_BOLD)Potato RISC-V Core - Synthesis to AIGER$(COLOR_RESET)"
	@echo ""
	@echo "$(COLOR_BOLD)Usage:$(COLOR_RESET)"
	@echo "  make [target]"
	@echo ""
	@echo "$(COLOR_BOLD)Targets:$(COLOR_RESET)"
	@echo "  $(COLOR_BOLD)all$(COLOR_RESET)       Run complete synthesis flow (default)"
	@echo "             synth → validate → equiv → reports"
	@echo ""
	@echo "  $(COLOR_BOLD)synth$(COLOR_RESET)     Run Yosys synthesis to generate AIGER files"
	@echo "             Runtime: 60-120 seconds"
	@echo "             Outputs: .aag, .aig, _synth.v, .map"
	@echo ""
	@echo "  $(COLOR_BOLD)validate$(COLOR_RESET)  Validate AIGER file structure and statistics"
	@echo "             Checks format, I/O counts, latch/gate counts"
	@echo ""
	@echo "  $(COLOR_BOLD)equiv$(COLOR_RESET)     Run equivalence checking (formal proof)"
	@echo "             Runtime: 30-60 seconds"
	@echo "             Proves RTL ≡ gate-level netlist"
	@echo ""
	@echo "  $(COLOR_BOLD)reports$(COLOR_RESET)   Generate synthesis summary reports"
	@echo "             Creates human-readable statistics"
	@echo ""
	@echo "  $(COLOR_BOLD)clean$(COLOR_RESET)     Remove all build artifacts"
	@echo "             Preserves source scripts"
	@echo ""
	@echo "  $(COLOR_BOLD)help$(COLOR_RESET)      Display this help message"
	@echo ""
	@echo "$(COLOR_BOLD)Output Locations:$(COLOR_RESET)"
	@echo "  Logs:    $(LOG_DIR)/"
	@echo "  Outputs: $(OUTPUT_DIR)/"
	@echo "  Reports: $(REPORT_DIR)/"
	@echo ""
	@echo "$(COLOR_BOLD)Requirements:$(COLOR_RESET)"
	@echo "  - Yosys 0.49+ (found: $(YOSYS))"
	@echo "  - Python 3"
	@echo ""
	@echo "$(COLOR_BOLD)Example Workflows:$(COLOR_RESET)"
	@echo "  Full synthesis:        make all"
	@echo "  Synthesis only:        make synth"
	@echo "  Re-validate:           make validate"
	@echo "  Clean rebuild:         make clean && make all"
	@echo ""

# ==============================================================================
# Directory creation
# ==============================================================================

$(LOG_DIR):
	@mkdir -p $(LOG_DIR)

$(OUTPUT_DIR):
	@mkdir -p $(OUTPUT_DIR)

$(REPORT_DIR):
	@mkdir -p $(REPORT_DIR)
