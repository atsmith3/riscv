#!/bin/bash
#
# Generate and display coverage report
#
# This script merges coverage data from all test runs and generates
# both HTML and text reports.
#
# Usage:
#   ./scripts/coverage_report.sh [threshold]
#
# Arguments:
#   threshold - Optional minimum coverage percentage (default: 80)

THRESHOLD=${1:-80}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERILATOR_DIR="$(dirname "$SCRIPT_DIR")"

cd "$VERILATOR_DIR/build"

echo "======================================"
echo "Coverage Report Generation"
echo "======================================"
echo ""

# Check if coverage data exists
if [ ! -f logs/coverage.dat ]; then
  echo "Error: No coverage data found at logs/coverage.dat"
  echo "Run tests first with: ./scripts/run_all_tests.sh"
  exit 1
fi

# Merge coverage from all test runs (if multiple files)
if ls logs/coverage_*.dat &> /dev/null; then
  echo "Merging multiple coverage files..."
  verilator_coverage logs/coverage_*.dat --write logs/merged_coverage.dat
  COVERAGE_FILE="logs/merged_coverage.dat"
else
  echo "Using single coverage file..."
  COVERAGE_FILE="logs/coverage.dat"
fi

# Generate HTML report
echo ""
echo "Generating HTML report..."
mkdir -p coverage_html
verilator_coverage "$COVERAGE_FILE" --annotate coverage_html/

# Generate text summary
echo ""
echo "Generating text summary..."
verilator_coverage "$COVERAGE_FILE" > coverage_summary.txt

# Display summary
echo ""
echo "======================================"
echo "Coverage Summary"
echo "======================================"
cat coverage_summary.txt

# Check thresholds if Python is available
echo ""
if command -v python3 &> /dev/null; then
  if [ -f ../scripts/check_coverage_threshold.py ]; then
    python3 ../scripts/check_coverage_threshold.py coverage_summary.txt "$THRESHOLD"
  else
    echo "Coverage threshold check script not found"
  fi
else
  echo "Python3 not found - skipping threshold check"
fi

echo ""
echo "======================================"
echo "HTML report: coverage_html/index.html"
echo "Text summary: coverage_summary.txt"
echo "======================================"
