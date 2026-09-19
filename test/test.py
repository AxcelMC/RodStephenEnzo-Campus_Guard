"""
Campus Sentinel 2.0
Tiny Tapeout / IHP Cocotb Testbench

Tests:
1. Hardware reset
2. SAFE state
3. Smoke warning
4. Motion warning
5. Door warning
6. Smoke + Motion critical condition
7. Smoke + Door critical condition
8. Motion + Door critical condition
9. Critical alarm latching
10. ACK safety interlock
11. Panic evacuation
12. Evacuation latching
13. Manual reset
"""

import cocotb

from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


# ================================================================
# INPUT BIT DEFINITIONS
# ================================================================

SMOKE  = 1 << 0
MOTION = 1 << 1
DOOR   = 1 << 2
PANIC  = 1 << 3
RESET  = 1 << 4
ACK    = 1 << 5


# ================================================================
# OUTPUT BIT DEFINITIONS
# ================================================================

SAFE       = 1 << 0
WARNING    = 1 << 1
CRITICAL   = 1 << 2
EVACUATE   = 1 << 3
BUZZER     = 1 << 4
ROUTE_A    = 1 << 5
ROUTE_B    = 1 << 6
ROUTE_C    = 1 << 7


async def wait_clock(dut, cycles=1):
    """Wait for a specified number of FSM clock cycles."""

    await ClockCycles(dut.clk, cycles)


async def clear_inputs(dut):
    """Clear all Campus Sentinel inputs."""

    dut.ui_in.value = 0
    dut.uio_in.value = 0

    await wait_clock(dut, 1)


async def hardware_reset(dut):
    """Apply the dedicated active-low Tiny Tapeout reset."""

    dut.rst_n.value = 0
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.ena.value = 1

    await wait_clock(dut, 2)

    dut.rst_n.value = 1

    await wait_clock(dut, 1)


def output_value(dut):
    """Return uo_out as an integer."""

    return int(dut.uo_out.value)


def check_bit(dut, bit_mask, expected, message):
    """Check one output bit."""

    value = output_value(dut)

    actual = 1 if (value & bit_mask) else 0

    assert actual == expected, (
        f"{message}: expected {expected}, "
        f"got {actual}. uo_out={value:08b}"
    )


def check_safe(dut):

    check_bit(dut, SAFE, 1, "SAFE output")
    check_bit(dut, WARNING, 0, "WARNING output")
    check_bit(dut, CRITICAL, 0, "CRITICAL output")
    check_bit(dut, EVACUATE, 0, "EVACUATE output")
    check_bit(dut, BUZZER, 0, "BUZZER output")


def check_warning(dut):

    check_bit(dut, SAFE, 0, "SAFE output")
    check_bit(dut, WARNING, 1, "WARNING output")
    check_bit(dut, CRITICAL, 0, "CRITICAL output")
    check_bit(dut, EVACUATE, 0, "EVACUATE output")
    check_bit(dut, BUZZER, 1, "BUZZER output")


def check_critical(dut):

    check_bit(dut, SAFE, 0, "SAFE output")
    check_bit(dut, WARNING, 0, "WARNING output")
    check_bit(dut, CRITICAL, 1, "CRITICAL output")
    check_bit(dut, EVACUATE, 0, "EVACUATE output")
    check_bit(dut, BUZZER, 1, "BUZZER output")


def check_evacuate(dut):

    check_bit(dut, SAFE, 0, "SAFE output")
    check_bit(dut, WARNING, 0, "WARNING output")
    check_bit(dut, CRITICAL, 0, "CRITICAL output")
    check_bit(dut, EVACUATE, 1, "EVACUATE output")
    check_bit(dut, BUZZER, 1, "BUZZER output")


@cocotb.test()
async def test_campus_sentinel(dut):

    # ============================================================
    # START CLOCK
    # ============================================================

    clock = Clock(dut.clk, 10, units="us")
    cocotb.start_soon(clock.start())


    # ============================================================
    # INITIALIZE
    # ============================================================

    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 1


    # ============================================================
    # TEST 1: HARDWARE RESET
    # ============================================================

    dut._log.info("TEST 1: Hardware reset")

    await hardware_reset(dut)

    check_safe(dut)


    # ============================================================
    # TEST 2: SMOKE -> WARNING
    # ============================================================

    dut._log.info("TEST 2: Smoke -> WARNING")

    dut.ui_in.value = SMOKE

    await wait_clock(dut, 1)

    check_warning(dut)


    # ============================================================
    # TEST 3: REMOVE SINGLE HAZARD -> SAFE
    # ============================================================

    dut._log.info("TEST 3: Warning clears when hazard disappears")

    dut.ui_in.value = 0

    await wait_clock(dut, 1)

    check_safe(dut)


    # ============================================================
    # TEST 4: MOTION -> WARNING
    # ============================================================

    dut._log.info("TEST 4: Motion -> WARNING")

    dut.ui_in.value = MOTION

    await wait_clock(dut, 1)

    check_warning(dut)

    dut.ui_in.value = 0

    await wait_clock(dut, 1)

    check_safe(dut)


    # ============================================================
    # TEST 5: DOOR -> WARNING
    # ============================================================

    dut._log.info("TEST 5: Door -> WARNING")

    dut.ui_in.value = DOOR

    await wait_clock(dut, 1)

    check_warning(dut)

    dut.ui_in.value = 0

    await wait_clock(dut, 1)

    check_safe(dut)


    # ============================================================
    # TEST 6: SMOKE + MOTION -> CRITICAL + ROUTE B
    # ============================================================

    dut._log.info(
        "TEST 6: Smoke + Motion -> CRITICAL + Route B"
    )

    dut.ui_in.value = SMOKE | MOTION

    await wait_clock(dut, 1)

    check_critical(dut)

    check_bit(
        dut,
        ROUTE_B,
        1,
        "Route B for Smoke + Motion"
    )

    check_bit(dut, ROUTE_A, 0, "Route A")
    check_bit(dut, ROUTE_C, 0, "Route C")


    # ============================================================
    # TEST 7: CRITICAL LATCH
    # ============================================================

    dut._log.info(
        "TEST 7: Critical remains latched after hazards disappear"
    )

    dut.ui_in.value = 0

    await wait_clock(dut, 2)

    check_critical(dut)


    # ============================================================
    # TEST 8: ACK CLEARS LATCHED CRITICAL
    # ============================================================

    dut._log.info(
        "TEST 8: ACK clears CRITICAL after hazards are gone"
    )

    dut.ui_in.value = ACK

    await wait_clock(dut, 1)

    check_safe(dut)

    dut.ui_in.value = 0

    await wait_clock(dut, 1)


    # ============================================================
    # TEST 9: SMOKE + DOOR -> CRITICAL + ROUTE C
    # ============================================================

    dut._log.info(
        "TEST 9: Smoke + Door -> CRITICAL + Route C"
    )

    dut.ui_in.value = SMOKE | DOOR

    await wait_clock(dut, 1)

    check_critical(dut)

    check_bit(
        dut,
        ROUTE_C,
        1,
        "Route C for Smoke + Door"
    )

    check_bit(dut, ROUTE_A, 0, "Route A")
    check_bit(dut, ROUTE_B, 0, "Route B")


    # ============================================================
    # TEST 10: ACK CANNOT CLEAR AN ACTIVE HAZARD
    # ============================================================

    dut._log.info(
        "TEST 10: ACK cannot clear an active critical hazard"
    )

    dut.ui_in.value = SMOKE | DOOR | ACK

    await wait_clock(dut, 2)

    check_critical(dut)


    # Clear hazards, then acknowledge.
    dut.ui_in.value = 0

    await wait_clock(dut, 1)

    check_critical(dut)

    dut.ui_in.value = ACK

    await wait_clock(dut, 1)

    check_safe(dut)

    dut.ui_in.value = 0

    await wait_clock(dut, 1)


    # ============================================================
    # TEST 11: MOTION + DOOR -> CRITICAL + ROUTE A
    # ============================================================

    dut._log.info(
        "TEST 11: Motion + Door -> CRITICAL + Route A"
    )

    dut.ui_in.value = MOTION | DOOR

    await wait_clock(dut, 1)

    check_critical(dut)

    check_bit(
        dut,
        ROUTE_A,
        1,
        "Route A for Motion + Door"
    )

    check_bit(dut, ROUTE_B, 0, "Route B")
    check_bit(dut, ROUTE_C, 0, "Route C")


    # Clear and acknowledge.
    dut.ui_in.value = 0

    await wait_clock(dut, 1)

    check_critical(dut)

    dut.ui_in.value = ACK

    await wait_clock(dut, 1)

    check_safe(dut)

    dut.ui_in.value = 0

    await wait_clock(dut, 1)


    # ============================================================
    # TEST 12: PANIC -> IMMEDIATE EVACUATE + ROUTE A
    # ============================================================

    dut._log.info(
        "TEST 12: Panic -> EVACUATE + Route A"
    )

    dut.ui_in.value = PANIC

    await wait_clock(dut, 1)

    check_evacuate(dut)

    check_bit(
        dut,
        ROUTE_A,
        1,
        "Route A during panic evacuation"
    )


    # ============================================================
    # TEST 13: ACK CANNOT CLEAR WHILE PANIC ACTIVE
    # ============================================================

    dut._log.info(
        "TEST 13: ACK cannot clear active panic"
    )

    dut.ui_in.value = PANIC | ACK

    await wait_clock(dut, 2)

    check_evacuate(dut)


    # ============================================================
    # TEST 14: EVACUATION LATCH
    # ============================================================

    dut._log.info(
        "TEST 14: EVACUATE remains latched after Panic release"
    )

    dut.ui_in.value = 0

    await wait_clock(dut, 2)

    check_evacuate(dut)


    # ============================================================
    # TEST 15: ACK CLEARS EVACUATION
    # ============================================================

    dut._log.info(
        "TEST 15: ACK clears evacuation after hazards are gone"
    )

    dut.ui_in.value = ACK

    await wait_clock(dut, 1)

    check_safe(dut)

    dut.ui_in.value = 0

    await wait_clock(dut, 1)


    # ============================================================
    # TEST 16: MANUAL RESET
    # ============================================================

    dut._log.info(
        "TEST 16: Manual Reset returns controller to SAFE"
    )

    # First create another critical condition.
    dut.ui_in.value = SMOKE | MOTION

    await wait_clock(dut, 1)

    check_critical(dut)

    # ui_in[4] is Reset.
    dut.ui_in.value = RESET

    await wait_clock(dut, 1)

    check_safe(dut)

    dut.ui_in.value = 0

    await wait_clock(dut, 1)

    check_safe(dut)


    dut._log.info(
        "ALL CAMPUS SENTINEL TESTS PASSED"
    )
