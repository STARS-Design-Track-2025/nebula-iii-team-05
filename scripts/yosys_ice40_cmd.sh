#!/bin/bash
echo -n "read_verilog -sv -noblackbox $ICE $UART $TEAM_DIR/*.sv $SRC_DIR/*.sv "
echo -n "$USER_PROJECT_VERILOG/rtl/wishbone_manager/wishbone_manager.sv "
echo -n "$SRAM_WRAPPER "
echo -n "$USER_PROJECT_VERILOG/rtl/sram/sram_for_FPGA.v; "
echo -n "synth_ice40 -top ice40hx8k -json $BUILD/$FPGA_TOP.json"