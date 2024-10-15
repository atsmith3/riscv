#!/usr/bin/python3
# Pad an ini file with 00 to fill a whole memory for RTL Sim

import sys
import os

infile = sys.argv[1]
address_width = int(sys.argv[2])

file = []
with open(infile,'r') as f:
  file = f.readlines()

mem = file[0].strip().split(" ")

addresses = 2**address_width

i = len(mem)
while i < addresses:
  mem.append("00")
  i = i+1

with open(infile,'w') as f:
  f.write(" ".join(mem))
