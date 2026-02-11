#!/usr/bin/env python3
"""Convert .ini memory files (space-separated hex bytes) to $readmemh format.

Usage: python3 ini2hex.py <input.ini> <output.hex>

Input format:  space-separated hex bytes loaded at address 0
Output format: $readmemh-compatible (one hex word per line, @addr directives)
"""

import sys


def main():
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <input.ini> <output.hex>", file=sys.stderr)
        sys.exit(1)

    in_path, out_path = sys.argv[1], sys.argv[2]

    with open(in_path, "r") as f:
        tokens = f.read().split()

    # Parse all hex byte tokens
    bytes_list = [int(tok, 16) for tok in tokens]

    # Pad to word boundary
    while len(bytes_list) % 4 != 0:
        bytes_list.append(0)

    # Group into little-endian 32-bit words
    words = []
    for i in range(0, len(bytes_list), 4):
        word = (
            bytes_list[i]
            | (bytes_list[i + 1] << 8)
            | (bytes_list[i + 2] << 16)
            | (bytes_list[i + 3] << 24)
        )
        words.append(word)

    with open(out_path, "w") as f:
        f.write("@00000000\n")
        for word in words:
            f.write(f"{word:08X}\n")

    print(f"Converted {len(bytes_list)} bytes -> {len(words)} words -> {out_path}")


if __name__ == "__main__":
    main()
