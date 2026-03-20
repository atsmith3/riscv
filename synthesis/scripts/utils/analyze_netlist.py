#!/usr/bin/env python3
# ==============================================================================
# Netlist Analysis Tool
# ==============================================================================
# Usage: ./analyze_netlist.py <netlist_file>
#
# This script analyzes Yosys-generated netlists and provides statistics
# about cell types, flip-flops, and design metrics.
# ==============================================================================

import sys
import os
import re
import json
from collections import Counter
from pathlib import Path


# Colors for output
class Colors:
    RESET = '\033[0m'
    BOLD = '\033[1m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    RED = '\033[0;31m'
    BLUE = '\033[0;34m'


def print_header(text):
    """Print a formatted header"""
    print(f"\n{Colors.BOLD}{Colors.BLUE}{'='*70}{Colors.RESET}")
    print(f"{Colors.BOLD}{Colors.BLUE}{text}{Colors.RESET}")
    print(f"{Colors.BOLD}{Colors.BLUE}{'='*70}{Colors.RESET}\n")


def print_success(text):
    """Print success message"""
    print(f"{Colors.GREEN}✓ {text}{Colors.RESET}")


def print_warning(text):
    """Print warning message"""
    print(f"{Colors.YELLOW}⚠ {text}{Colors.RESET}")


def print_error(text):
    """Print error message"""
    print(f"{Colors.RED}✗ {text}{Colors.RESET}")


def analyze_verilog_netlist(filepath):
    """Analyze Verilog netlist and extract statistics"""
    print_header(f"Analyzing Verilog Netlist: {filepath}")

    if not os.path.exists(filepath):
        print_error(f"File not found: {filepath}")
        return None

    with open(filepath, 'r') as f:
        content = f.read()

    # Count lines
    line_count = len(content.split('\n'))

    # Count cell types
    cell_patterns = {
        '$_AND_': r'$_AND_\s+\w+',
        '$_OR_': r'$_OR_\s+\w+',
        '$_NOT_': r'$_NOT_\s+\w+',
        '$_NAND_': r'$_NAND_\s+\w+',
        '$_NOR_': r'$_NOR_\s+\w+',
        '$_XOR_': r'$_XOR_\s+\w+',
        '$_MUX_': r'$_MUX_\s+\w+',
        '$_DFF_': r'$_DFF_\w+',
    }

    cell_counts = Counter()
    for cell_type, pattern in cell_patterns.items():
        matches = re.findall(pattern, content)
        cell_counts[cell_type] = len(matches)

    # Count flip-flops by type
    dff_types = Counter()
    dff_pattern = r'$_DFF_([A-Z0-9_]*)\s+\w+'
    for match in re.finditer(dff_pattern, content):
        dff_types[match.group(1)] += 1

    # Extract module name
    module_match = re.search(r'module\s+(\w+)', content)
    module_name = module_match.group(1) if module_match else "unknown"

    # Count ports
    inputs = re.findall(r'input\s+(\w+)', content)
    outputs = re.findall(r'output\s+(\w+)', content)

    # Calculate total cells
    total_cells = sum(cell_counts.values())
    total_ffs = sum(dff_types.values())

    print(f"Module: {module_name}")
    print(f"Lines: {line_count}")
    print(f"\n{Colors.BOLD}Cell Type Distribution:{Colors.RESET}")
    print("-" * 40)

    # Sort by count
    for cell_type, count in sorted(cell_counts.items(),
                                   key=lambda x: x[1],
                                   reverse=True):
        percentage = (count / total_cells * 100) if total_cells > 0 else 0
        print(f"  {cell_type:15} : {count:6} ({percentage:5.1f}%)")

    print(f"\n{Colors.BOLD}Flip-Flop Types:{Colors.RESET}")
    print("-" * 40)
    for ff_type, count in sorted(dff_types.items(),
                                 key=lambda x: x[1],
                                 reverse=True):
        print(f"  $_DFF_{ff_type}: {count}")

    print(f"\n{Colors.BOLD}Summary:{Colors.RESET}")
    print(f"  Total cells: {total_cells}")
    print(f"  Total flip-flops: {total_ffs}")
    print(f"  Inputs: {len(inputs)}")
    print(f"  Outputs: {len(outputs)}")

    return {
        'module': module_name,
        'lines': line_count,
        'cells': dict(cell_counts),
        'dff_types': dict(dff_types),
        'inputs': len(inputs),
        'outputs': len(outputs),
        'total_cells': total_cells,
        'total_ffs': total_ffs
    }


def analyze_json_netlist(filepath):
    """Analyze JSON netlist and extract statistics"""
    print_header(f"Analyzing JSON Netlist: {filepath}")

    if not os.path.exists(filepath):
        print_error(f"File not found: {filepath}")
        return None

    try:
        with open(filepath, 'r') as f:
            data = json.load(f)
    except json.JSONDecodeError as e:
        print_error(f"Invalid JSON: {e}")
        return None

    # Get module info
    modules = data.get('modules', {})
    if not modules:
        print_warning("No modules found in JSON")
        return None

    module_name = list(modules.keys())[0]
    module = modules[module_name]

    # Count cells
    cells = module.get('cells', {})
    cell_types = Counter()
    for cell in cells.values():
        cell_type = cell.get('type', 'unknown')
        cell_types[cell_type] += 1

    # Count nets
    nets = module.get('netnames', {})

    # Count ports
    ports = module.get('ports', {})

    # Calculate totals
    total_cells = len(cells)

    print(f"Module: {module_name}")
    print(f"Cells: {total_cells}")
    print(f"Nets: {len(nets)}")
    print(f"Ports: {len(ports)}")

    print(f"\n{Colors.BOLD}Cell Type Distribution:{Colors.RESET}")
    print("-" * 40)

    for cell_type, count in sorted(cell_types.items(),
                                   key=lambda x: x[1],
                                   reverse=True):
        percentage = (count / total_cells * 100) if total_cells > 0 else 0
        print(f"  {cell_type:20} : {count:6} ({percentage:5.1f}%)")

    return {
        'module': module_name,
        'cells': total_cells,
        'nets': len(nets),
        'ports': len(ports),
        'cell_types': dict(cell_types)
    }


def main():
    if len(sys.argv) < 2:
        print_header("Netlist Analysis Tool")
        print("Usage: ./analyze_netlist.py <netlist_file>")
        print("")
        print("Supported formats:")
        print("  - Verilog netlist (.v)")
        print("  - JSON netlist (.json)")
        print("")
        print("Examples:")
        print("  ./analyze_netlist.py build/output/core_top_synth.v")
        print("  ./analyze_netlist.py build/output/core_top_synth.json")
        sys.exit(1)

    filepath = sys.argv[1]
    path = Path(filepath)

    if not path.exists():
        print_error(f"File not found: {filepath}")
        sys.exit(1)

    # Determine file type and analyze
    if path.suffix == '.v':
        result = analyze_verilog_netlist(filepath)
    elif path.suffix == '.json':
        result = analyze_json_netlist(filepath)
    else:
        print_error(f"Unsupported file type: {path.suffix}")
        sys.exit(1)

    if result:
        print(f"\n{Colors.GREEN}Analysis complete!{Colors.RESET}")
        sys.exit(0)
    else:
        sys.exit(1)


if __name__ == '__main__':
    main()
