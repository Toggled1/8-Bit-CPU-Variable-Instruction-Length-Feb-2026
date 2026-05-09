#!/bin/bash
echo "Assembling Program..."
python -u "Assembler/assembler_complete.py"

echo "Compiling VHDL..."
ghdl -a --std=08 vhdl/ram_pkg.vhd

echo "Running Simulation..."
ghdl -a --std=08 vhdl/Dreg.vhd
ghdl -a --std=08 vhdl/8x_Dreg.vhd

ghdl -a --std=08 vhdl/ALU_module.vhd
ghdl -a --std=08 vhdl/ram_module.vhd

ghdl -a --std=08 vhdl/datapath.vhd
ghdl -a --std=08 vhdl/cpu_frame.vhd

ghdl -a --std=08 tb/cpu_tb.vhd


ghdl -r --std=08 cpu_tb --fst=waves.fst --stop-time=150us 
gtkwave waves.fst default.gtkw &

echo "Launching Python Analysis Script..."
python -u "verification_scripts/ram_dump_verify.py"
