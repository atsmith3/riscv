#!/bin/bash

iverilog -g2005-sv ../../rtl/reg.sv ../../rtl/reg_tb.sv -o testbench
