# Campus Sentinel 2.0
# Tiny Tapeout Cocotb test Makefile

SIM ?= icarus

TOPLEVEL_LANG = verilog

SRC_DIR = $(PWD)/../src

PROJECT_SOURCES = project.v

ifneq ($(GATES),yes)

SIM_BUILD = sim_build/rtl

COMPILE_ARGS += -g2012

VERILOG_SOURCES += $(addprefix $(SRC_DIR)/,$(PROJECT_SOURCES))

else

SIM_BUILD = sim_build/gl

COMPILE_ARGS += -DGL_TEST

VERILOG_SOURCES += $(PWD)/gate_level_netlist.v

endif

# Tiny Tapeout simulation wrapper
VERILOG_SOURCES += $(PWD)/tb.v

TOPLEVEL = tb

MODULE = test

include $(shell cocotb-config --makefiles)/Makefile.sim
