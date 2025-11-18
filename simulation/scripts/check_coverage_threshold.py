#!/usr/bin/env python3
"""
Check if coverage meets minimum threshold

Parses Verilator coverage summary output and checks if coverage
percentages meet specified thresholds.

Usage:
    python3 check_coverage_threshold.py <summary_file> <threshold>

Arguments:
    summary_file - Path to coverage summary text file
    threshold    - Minimum coverage percentage (e.g., 80 for 80%)

Exit codes:
    0 - Coverage meets threshold
    1 - Coverage below threshold or error
"""

import sys
import re


def check_coverage(summary_file, threshold):
    """Check if coverage meets threshold"""
    try:
        with open(summary_file, 'r') as f:
            content = f.read()
    except FileNotFoundError:
        print(f"Error: File not found: {summary_file}")
        return 1

    # Extract line coverage percentage
    # Verilator format: "XX.XX% of NNNN lines"
    line_match = re.search(r'(\d+\.?\d*)%\s+of\s+\d+\s+lines', content)

    if line_match:
        coverage = float(line_match.group(1))
        print(f"Line coverage: {coverage:.2f}%")

        if coverage >= threshold:
            print(f"✓ Coverage meets threshold ({threshold}%)")
            return 0
        else:
            print(f"✗ Coverage below threshold ({threshold}%)")
            print(f"  Gap: {threshold - coverage:.2f}%")
            return 1
    else:
        print("Error: Could not parse coverage percentage")
        print("\nCoverage output:")
        print(content)
        return 1


def main():
    """Main entry point"""
    if len(sys.argv) != 3:
        print("Usage: check_coverage_threshold.py <summary_file> <threshold>")
        print("Example: check_coverage_threshold.py coverage_summary.txt 80")
        return 1

    summary_file = sys.argv[1]
    try:
        threshold = float(sys.argv[2])
    except ValueError:
        print(f"Error: Invalid threshold: {sys.argv[2]}")
        print("Threshold must be a number (e.g., 80 for 80%)")
        return 1

    return check_coverage(summary_file, threshold)


if __name__ == "__main__":
    sys.exit(main())
