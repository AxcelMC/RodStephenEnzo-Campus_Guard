# Campus Sentinel 2.0
# Tiny Tapeout IHP Cocotb Test Makefile
#
# Based on the official TinyTapeout IHP Verilog template.

# Simulator
SIM ?= icarus

# Use FST waveform output
FST ?= -fst

TOPLEVEL_LANG ?= verilog

# Source directory
SRC_DIR = $(PWD)/../src

# Project source files
PROJECT_SOURCES = project.v


# ============================================================
# RTL SIMULATION
# ============================================================

ifneq ($(GATES),yes)

SIM_BUILD = sim_build/rtl

VERILOG_SOURCES += $(addprefix $(SRC_DIR)/,$(PROJECT_SOURCES))


# ============================================================
# GATE-LEVEL SIMULATION
# ============================================================

else

SIM_BUILD = sim_build/gl

# Gate-level simulation defines required by IHP models
COMPILE_ARGS += -DGL_TEST
COMPILE_ARGS += -DFUNCTIONAL
COMPILE_ARGS += -DSIM

# IHP SG13G2 IO-cell simulation models
VERILOG_SOURCES += $(PDK_ROOT)/ihp-sg13g2/libs.ref/sg13g2_io/verilog/sg13g2_io.v

# IHP SG13G2 standard-cell simulation models
VERILOG_SOURCES += $(PDK_ROOT)/ihp-sg13g2/libs.ref/sg13g2_stdcell/verilog/sg13g2_stdcell.v

# Generated gate-level netlist.
# The TinyTapeout GDS action copies this file into test/
VERILOG_SOURCES += $(PWD)/gate_level_netlist.v

endif


# ============================================================
# COMMON CONFIGURATION
# ============================================================

# Allow Verilog files to include files from src/
COMPILE_ARGS += -I$(SRC_DIR)

# Tiny Tapeout simulation wrapper
VERILOG_SOURCES += $(PWD)/tb.v

# Top-level simulation module
TOPLEVEL = tb

# Cocotb test file: test.py
COCOTB_TEST_MODULES = test


# ============================================================
# COCOTB
# ============================================================

include $(shell cocotb-config --makefiles)/Makefile.sim
