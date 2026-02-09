# Makefile — Vivado non-project mode build flow for RISC-V 32I on Arty S7-50
#
# Targets: lint, synth, opt, place, route, bitstream, all, clean, help
# Each stage writes checkpoints and reports into a timestamped build directory.

SHELL := /bin/bash

# ── Configuration ────────────────────────────────────────────────────────────
PART    := xc7s50csga324-1
TOP     := emu_top
RTL_DIR := ../../../rtl
XDC_DIR := xdc

# Timestamp evaluated once per make invocation so all targets share it.
TIMESTAMP := $(shell date +%Y%m%d_%H%M%S)
BUILD_DIR  = build/$(TIMESTAMP)

# ── Phony targets ────────────────────────────────────────────────────────────
.PHONY: all lint synth opt place route bitstream clean help

# ── Default target ───────────────────────────────────────────────────────────
all: lint synth opt place route bitstream

# ── Lint (RTL elaboration) ───────────────────────────────────────────────────
lint:
	@mkdir -p $(BUILD_DIR)/lint
	@ln -sfn $(TIMESTAMP) build/latest
	@echo "=== Lint  [$(BUILD_DIR)/lint] ==="
	vivado -mode batch -source scripts/lint.tcl \
	  -tclargs $(BUILD_DIR)/lint $(RTL_DIR) $(PART) $(XDC_DIR) \
	  2>&1 | tee $(BUILD_DIR)/lint/lint.log

# ── Helper: verify build/latest exists ───────────────────────────────────────
define check_latest
	@if [ ! -L build/latest ]; then \
	  echo "ERROR: build/latest symlink not found. Run 'make lint' first."; \
	  exit 1; \
	fi
endef

# ── Synthesis (out-of-context) ───────────────────────────────────────────────
synth:
	$(check_latest)
	@mkdir -p build/latest/synth
	@echo "=== Synth [build/latest/synth] ==="
	vivado -mode batch -source scripts/synth.tcl \
	  -tclargs build/latest/synth $(RTL_DIR) $(PART) $(XDC_DIR) \
	  2>&1 | tee build/latest/synth/synth.log

# ── Optimization (post-synthesis) ─────────────────────────────────────────────
opt:
	$(check_latest)
	@mkdir -p build/latest/opt
	@echo "=== Opt   [build/latest/opt] ==="
	vivado -mode batch -source scripts/opt.tcl \
	  -tclargs build/latest/opt build/latest/synth/post_synth.dcp \
	  2>&1 | tee build/latest/opt/opt.log

# ── Placement ────────────────────────────────────────────────────────────────
place:
	$(check_latest)
	@mkdir -p build/latest/place
	@echo "=== Place [build/latest/place] ==="
	vivado -mode batch -source scripts/place.tcl \
	  -tclargs build/latest/place build/latest/opt/post_opt.dcp \
	  2>&1 | tee build/latest/place/place.log

# ── Routing ──────────────────────────────────────────────────────────────────
route:
	$(check_latest)
	@mkdir -p build/latest/route
	@echo "=== Route [build/latest/route] ==="
	vivado -mode batch -source scripts/route.tcl \
	  -tclargs build/latest/route build/latest/place/post_place.dcp \
	  2>&1 | tee build/latest/route/route.log

# ── Bitstream ────────────────────────────────────────────────────────────────
bitstream:
	$(check_latest)
	@mkdir -p build/latest/bitstream
	@echo "=== Bitstream [build/latest/bitstream] ==="
	vivado -mode batch -source scripts/bitstream.tcl \
	  -tclargs build/latest/bitstream build/latest/route/post_route.dcp $(TOP) \
	  2>&1 | tee build/latest/bitstream/bitstream.log

# ── Clean ────────────────────────────────────────────────────────────────────
clean:
	rm -rf build

# ── Help ─────────────────────────────────────────────────────────────────────
help:
	@echo "Vivado build flow for $(TOP) on $(PART)"
	@echo ""
	@echo "Targets:"
	@echo "  make lint       — RTL elaboration (syntax/hierarchy check)"
	@echo "  make synth      — Out-of-context synthesis"
	@echo "  make opt        — Logic optimization (opt_design)"
	@echo "  make place      — Placement (place_design)"
	@echo "  make route      — Routing"
	@echo "  make bitstream  — Bitstream generation"
	@echo "  make all        — Full flow: lint -> synth -> opt -> place -> route -> bitstream"
	@echo "  make clean      — Remove all build artifacts"
	@echo ""
	@echo "Build output goes to build/<timestamp>/ with a build/latest symlink."
	@echo "Open any checkpoint in the GUI:  vivado build/latest/synth/post_synth.dcp"
