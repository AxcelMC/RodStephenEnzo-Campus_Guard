# Campus Guard / Campus Sentinel
# Tiny Tapeout IHP test Makefile
#
# Temporary GLS workaround:
# ihp_physical_stubs.v provides empty simulation models for
# physical-only filler/decap cells.

SIM ?= icarus

FST ?= -fst

TOPLEVEL_LANG ?= verilog

SRC_DIR = $(PWD)/../src

PROJECT_SOURCES = project.v


# ============================================================
# RTL SIMULATION
# ============================================================

ifneq ($(GATES),yes)

SIM_BUILD = sim_build/rtl

VERILOG_SOURCES += $(addprefix $(SRC_DIR)/,$(PROJECT_SOURCES))


# ============================================================
# GATE LEVEL SIMULATION
# ============================================================

else

SIM_BUILD = sim_build/gl

COMPILE_ARGS += -DGL_TEST
COMPILE_ARGS += -DFUNCTIONAL
COMPILE_ARGS += -DSIM

# IHP simulation libraries
VERILOG_SOURCES += $(PDK_ROOT)/ihp-sg13g2/libs.ref/sg13g2_io/verilog/sg13g2_io.v
VERILOG_SOURCES += $(PDK_ROOT)/ihp-sg13g2/libs.ref/sg13g2_stdcell/verilog/sg13g2_stdcell.v

# ------------------------------------------------------------
# TEMPORARY WORKAROUND
# ------------------------------------------------------------
# Empty models for physical-only cells such as:
#   sg13g2_decap_8
#   sg13g2_fill_2
#   sg13g2_fill_1
#
VERILOG_SOURCES += $(PWD)/ihp_physical_stubs.v

# Generated gate-level netlist
VERILOG_SOURCES += $(PWD)/gate_level_netlist.v

endif


# ============================================================
# COMMON
# ============================================================

COMPILE_ARGS += -I$(SRC_DIR)

VERILOG_SOURCES += $(PWD)/tb.v

TOPLEVEL = tb

COCOTB_TEST_MODULES = test


# ============================================================
# COCOTB
# ============================================================

include $(shell cocotb-config --makefiles)/Makefile.sim
