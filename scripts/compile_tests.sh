#!/bin/bash
#
# Compile all test programs using Docker
#
# This script builds a Docker image with the RISC-V toolchain and uses it
# to compile all test programs.
#
# Usage:
#   ./scripts/compile_tests.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

echo "======================================"
echo "RISC-V Test Program Compilation"
echo "======================================"
echo ""

# Build Docker image
echo "Building RISC-V toolchain Docker image..."
docker build -t riscv-toolchain:latest -f "$REPO_ROOT/Dockerfile.riscv-toolchain" "$REPO_ROOT"
echo ""

# Function to compile a test program
compile_test() {
  local test_dir=$1
  local test_name=$(basename "$test_dir")

  echo "Compiling $test_name..."

  docker run --rm \
    -v "$test_dir:/workspace" \
    -w /workspace \
    riscv-toolchain:latest \
    bash -c "./compile.sh"

  if [ $? -eq 0 ]; then
    echo "[OK] $test_name compiled successfully"
  else
    echo "[ERROR] $test_name compilation failed"
    return 1
  fi
}

# Compile all test programs
echo "Compiling test programs..."
echo ""

cd "$REPO_ROOT/test"

for test_dir in */; do
  if [ -f "$test_dir/compile.sh" ]; then
    compile_test "$REPO_ROOT/test/$test_dir"
  fi
done

echo ""
echo "======================================"
echo "Compilation Complete"
echo "======================================"
