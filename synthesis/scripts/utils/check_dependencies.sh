#!/bin/bash
# ==============================================================================
# Check Dependencies for Synthesis Flow
# ==============================================================================
# Usage: ./check_dependencies.sh
#
# This script checks that all required tools and files are available for
# the synthesis flow.
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "================================================================================"
echo "Potato RISC-V Core - Synthesis Flow Dependency Check"
echo "================================================================================"
echo ""

ERRORS=0

# ==============================================================================
# Check Yosys
# ==============================================================================
echo -e "${YELLOW}Checking Yosys...${NC}"
if command -v yosys &> /dev/null; then
    YOSYS_VERSION=$(yosys --version 2>&1 | head -1)
    echo -e "  ${GREEN}✓ Found${NC}: $YOSYS_VERSION"
else
    echo -e "  ${RED}✗ Not found${NC}"
    echo "  Install from: https://github.com/YosysHQ/yosys"
    ERRORS=$((ERRORS + 1))
fi

# ==============================================================================
# Check Python
# ==============================================================================
echo -e "${YELLOW}Checking Python...${NC}"
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    echo -e "  ${GREEN}✓ Found${NC}: $PYTHON_VERSION"
else
    echo -e "  ${RED}✗ Not found${NC}"
    echo "  Install Python 3 from your package manager"
    ERRORS=$((ERRORS + 1))
fi

# ==============================================================================
# Check Required Scripts
# ==============================================================================
echo -e "${YELLOW}Checking required scripts...${NC}"

REQUIRED_SCRIPTS=(
    "$SCRIPT_DIR/synth.tcl"
    "$SCRIPT_DIR/equiv_check.tcl"
    "$SCRIPT_DIR/pdk_map.tcl"
    "$SCRIPT_DIR/file_list.txt"
)

for script in "${REQUIRED_SCRIPTS[@]}"; do
    if [ -f "$script" ]; then
        echo -e "  ${GREEN}✓ Found${NC}: $(basename "$script")"
    else
        echo -e "  ${RED}✗ Missing${NC}: $(basename "$script")"
        ERRORS=$((ERRORS + 1))
    fi
done

# ==============================================================================
# Check PDK Files
# ==============================================================================
echo -e "${YELLOW}Checking PDK files...${NC}"

PDK_DIR="$ROOT_DIR/pdk/globalfoundries-pdk-libs-gf180mcu_fd_sc_mcu9t5v0"

if [ -d "$PDK_DIR" ]; then
    echo -e "  ${GREEN}✓ PDK directory found${NC}: $PDK_DIR"

    # Check for liberty files
    LIB_FILES=(
        "gf180mcu_fd_sc_mcu9t5v0__tt_025C_3v30.lib"
        "gf180mcu_fd_sc_mcu9t5v0__tt_025C_1v80.lib"
        "gf180mcu_fd_sc_mcu9t5v0__ss_125C_1v62.lib"
    )

    for lib in "${LIB_FILES[@]}"; do
        if [ -f "$PDK_DIR/$lib" ]; then
            echo -e "  ${GREEN}✓ Found${NC}: $lib"
        else
            echo -e "  ${YELLOW}⚠ Missing${NC}: $lib"
        fi
    done
else
    echo -e "  ${RED}✗ PDK directory not found${NC}"
    echo "  Expected: $PDK_DIR"
    echo "  Download from: https://github.com/google/gf180mcu-pdk"
    ERRORS=$((ERRORS + 1))
fi

# ==============================================================================
# Check RTL Files
# ==============================================================================
echo -e "${YELLOW}Checking RTL files...${NC}"

RTL_DIR="$ROOT_DIR/rtl"

if [ -d "$RTL_DIR" ]; then
    echo -e "  ${GREEN}✓ RTL directory found${NC}: $RTL_DIR"

    # Check for core files
    CORE_FILES=(
        "core_top.sv"
        "control.sv"
        "regfile.sv"
        "alu/alu.sv"
    )

    for file in "${CORE_FILES[@]}"; do
        if [ -f "$RTL_DIR/$file" ]; then
            echo -e "  ${GREEN}✓ Found${NC}: $file"
        else
            echo -e "  ${RED}✗ Missing${NC}: $file"
            ERRORS=$((ERRORS + 1))
        fi
    done
else
    echo -e "  ${RED}✗ RTL directory not found${NC}"
    echo "  Expected: $RTL_DIR"
    ERRORS=$((ERRORS + 1))
fi

# ==============================================================================
# Summary
# ==============================================================================
echo ""
echo "================================================================================"

if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}All dependencies satisfied!${NC}"
    echo ""
    echo "You can now run synthesis:"
    echo "  cd $ROOT_DIR/synthesis"
    echo "  make all"
    exit 0
else
    echo -e "${RED}Found $ERRORS error(s). Please fix the issues above.${NC}"
    echo ""
    echo "To continue anyway (not recommended):"
    echo "  cd $ROOT_DIR/synthesis"
    echo "  make all"
    exit 1
fi
