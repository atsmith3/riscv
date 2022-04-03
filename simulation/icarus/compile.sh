#!/bin/bash

iverilog -g2005-sv \
  ../../rtl/register.sv \
  ../../rtl/mux4.sv \
  ../../rtl/control.sv \
  ../../rtl/core_top.sv \
  ./core_top_tb.sv \
  -I ../../rtl \
  -D IVERILOG \
  -s tb \
  -o core_top_test
