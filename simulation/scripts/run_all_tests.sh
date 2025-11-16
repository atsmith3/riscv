#!/bin/bash
#
# Run complete test regression suite
#
# This script builds the test infrastructure and runs all tests with
# coverage analysis.
#
# Usage:
#   ./scripts/run_all_tests.sh

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERILATOR_DIR="$(dirname "$SCRIPT_DIR")"

echo "======================================"
echo "RISC-V Core Test Regression Suite"
echo "======================================"
echo ""

# Ensure WORKSPACE is set
if [ -z "$WORKSPACE" ]; then
  export WORKSPACE="$(dirname "$(dirname "$VERILATOR_DIR")")"
  echo "Setting WORKSPACE=$WORKSPACE"
fi

# Create build directory
echo "Creating build directory..."
mkdir -p "$VERILATOR_DIR/build"
cd "$VERILATOR_DIR/build"

# Create trace directory
mkdir -p trace
mkdir -p logs

# Build tests
echo ""
echo "======================================"
echo "Building tests..."
echo "======================================"
cmake ..
make -j$(nproc)

# Run tests
echo ""
echo "======================================"
echo "Running tests..."
echo "======================================"
ctest --output-on-failure

# Generate coverage
echo ""
echo "======================================"
echo "Generating coverage report..."
echo "======================================"
if [ -f logs/coverage.dat ]; then
  make coverage
else
  echo "Warning: No coverage data found"
fi

# Display summary
echo ""
echo "======================================"
echo "Test Results Summary:"
echo "======================================"
ctest --output-on-failure --verbose | grep -E "(Test|Passed|Failed|Total)"

echo ""
if [ -d coverage_html ]; then
  echo "Coverage report available in: build/coverage_html/index.html"
fi
echo ""
echo "======================================"
echo "Regression Complete"
echo "======================================"
