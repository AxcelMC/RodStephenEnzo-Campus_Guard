# Campus Sentinel 2.0

## Overview

Campus Sentinel 2.0 is a Verilog-based multi-hazard emergency detection and evacuation control system.

The project demonstrates how dedicated digital hardware can monitor multiple emergency inputs, classify hazard severity, retain critical alarms, enforce acknowledgement safety rules, and generate evacuation-route outputs.

The design uses a four-state Finite State Machine (FSM) implemented entirely in Verilog.

The four operating states are:

- SAFE
- WARNING
- CRITICAL
- EVACUATE

## How It Works

Campus Sentinel monitors four emergency inputs:

- Smoke
- Motion
- Door
- Panic

The Smoke, Motion, and Door signals are considered normal hazard inputs.

If none of these inputs are active, the controller remains in the SAFE state.

If one normal hazard becomes active, the controller enters WARNING.

If two or more normal hazards are active simultaneously, the controller enters CRITICAL.

The Panic input has the highest priority and immediately causes the controller to enter EVACUATE.

The basic escalation sequence is:

```text
                 Single Hazard
SAFE --------------------------------> WARNING
                                         |
                                         | Multiple Hazards
                                         v
                                      CRITICAL
                                         |
                                         | Panic
                                         v
                                      EVACUATE
```

Panic may also transition directly from SAFE to EVACUATE.

## Hazard Fusion

The normal hazard condition is generated from:

```text
Smoke OR Motion OR Door
```

A critical condition is generated when at least two normal hazards are simultaneously active:

```text
Smoke AND Motion

OR

Smoke AND Door

OR

Motion AND Door
```

This allows the controller to distinguish an isolated sensor event from a combined emergency.

## Alarm Latching

CRITICAL and EVACUATE are latched emergency states.

For example:

```text
Smoke + Motion
      |
      v
   CRITICAL
      |
      | hazards disappear
      v
   CRITICAL
      |
      | ACK
      v
     SAFE
```

Removing the original hazards does not automatically clear a critical alarm.

This ensures that a serious emergency remains indicated until it has been acknowledged.

## Acknowledge Safety Interlock

The ACK input can only clear a latched critical condition after the hazard has disappeared.

Therefore:

```text
Active Hazard + ACK
        |
        v
Alarm remains active
```

while:

```text
Hazards Clear + ACK
        |
        v
       SAFE
```

This prevents an active emergency from simply being acknowledged away.

## Panic Priority

Panic has the highest operational priority.

It can cause:

```text
SAFE     -> EVACUATE
WARNING  -> EVACUATE
CRITICAL -> EVACUATE
```

The EVACUATE state remains latched until:

- Panic is released
- Normal hazards are clear
- ACK is asserted

## Evacuation Routing

Campus Sentinel includes three evacuation-route outputs:

- Route A
- Route B
- Route C

The demonstration routing policy is:

| Condition | Route |
|---|---|
| Panic | Route A |
| Smoke + Door | Route C |
| Smoke-related critical event | Route B |
| Door-related critical event | Route A |
| Other critical condition | Route A |

For example:

```text
Smoke + Motion
      |
      v
   CRITICAL
      |
      v
   ROUTE B
```

and:

```text
Smoke + Door
      |
      v
   CRITICAL
      |
      v
   ROUTE C
```

These routes demonstrate digital routing decisions. They are not intended to represent a certified real-world building evacuation plan.

## Pinout

### Inputs

| Pin | Signal | Description |
|---|---|---|
| ui_in[0] | Smoke | Smoke/fire hazard input |
| ui_in[1] | Motion | Motion/occupancy input |
| ui_in[2] | Door | Door/security input |
| ui_in[3] | Panic | Manual emergency input |
| ui_in[4] | Reset | User-controlled system reset |
| ui_in[5] | Ack | Emergency acknowledgement |
| ui_in[6] | Reserved | Currently unused |
| ui_in[7] | Reserved | Currently unused |

The dedicated `clk` signal clocks the FSM.

The dedicated active-low `rst_n` signal initializes the hardware to SAFE.

### Outputs

| Pin | Signal | Description |
|---|---|---|
| uo_out[0] | Safe | SAFE state indicator |
| uo_out[1] | Warning | WARNING state indicator |
| uo_out[2] | Critical | CRITICAL state indicator |
| uo_out[3] | Evacuate | EVACUATE state indicator |
| uo_out[4] | Buzzer | Alarm output |
| uo_out[5] | RouteA | Evacuation Route A |
| uo_out[6] | RouteB | Evacuation Route B |
| uo_out[7] | RouteC | Evacuation Route C |

The bidirectional `uio` pins are not currently used.

## How to Test

First reset the controller.

After reset and with all hazard inputs low:

```text
Safe = 1
```

### Test SAFE

Set:

```text
Smoke  = 0
Motion = 0
Door   = 0
Panic  = 0
```

Expected:

```text
SAFE
```

### Test WARNING

Set one normal hazard:

```text
Smoke = 1
```

Expected:

```text
WARNING
BUZZER ON
```

Motion alone and Door alone should produce the same WARNING state.

### Test CRITICAL

Set:

```text
Smoke  = 1
Motion = 1
```

Expected:

```text
CRITICAL
BUZZER ON
ROUTE B
```

Set:

```text
Smoke = 1
Door  = 1
```

Expected:

```text
CRITICAL
BUZZER ON
ROUTE C
```

Set:

```text
Motion = 1
Door   = 1
```

Expected:

```text
CRITICAL
BUZZER ON
ROUTE A
```

### Test Critical Latching

Create a CRITICAL condition using Smoke + Motion.

Then remove both hazards.

Expected:

```text
CRITICAL remains active
```

Now assert ACK.

Expected:

```text
SAFE
```

### Test ACK Safety Interlock

Create a CRITICAL condition.

Keep the hazards active and assert ACK.

Expected:

```text
CRITICAL remains active
```

ACK must not clear an active hazard.

### Test Panic

Set Panic high.

Expected:

```text
EVACUATE
BUZZER ON
ROUTE A
```

Release Panic without asserting ACK.

Expected:

```text
EVACUATE remains active
```

Then assert ACK while all hazards are clear.

Expected:

```text
SAFE
```

## External Hardware

No external hardware is required for the ASIC core.

For physical demonstration, the outputs could be connected through suitable interface circuitry to:

- LEDs
- Alarm indicators
- Buzzer drivers
- Route indicators
- Building-management interfaces

The inputs could conceptually interface with appropriately conditioned outputs from smoke detectors, motion detectors, security sensors, and emergency buttons.

## Safety Notice

Campus Sentinel 2.0 is an educational digital-design prototype.

It is not a certified fire alarm, life-safety controller, or evacuation system.

A real deployment would require certified sensors, fault supervision, redundancy, backup power, validated evacuation planning, appropriate electrical interfaces, and compliance with applicable safety standards.
