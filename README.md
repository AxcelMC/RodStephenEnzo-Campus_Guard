# Campus Sentinel 2.0

### Verilog-Based Multi-Hazard Emergency Detection and Evacuation Controller

Campus Sentinel 2.0 is a digital emergency-management controller implemented in Verilog HDL for the Tiny Tapeout IHP SG13G2 flow.

The project monitors multiple simulated emergency inputs and uses hazard-fusion logic and a Finite State Machine to classify conditions as:

- SAFE
- WARNING
- CRITICAL
- EVACUATE

The controller also provides alarm latching, acknowledgement safety interlocking, panic priority, an audible alarm output, and hazard-dependent evacuation routing.

---

## System Architecture

```text
 Smoke ────┐
 Motion ───┤
 Door ─────┼──► Hazard Fusion
 Panic ────┘         |
                     v
              Severity Logic
                     |
                     v
              +-------------+
 CLK ────────►|             |
 RESET ──────►|     FSM     |
 ACK ────────►|             |
              +------+------+
                     |
             +-------+-------+
             |               |
             v               v
       Status Outputs    Route Logic
             |               |
     +-------+------+    +----+----+
     |       |      |    |    |    |
   SAFE   WARNING CRIT   A    B    C
             |
           BUZZER
```

---

## Inputs

| Input | Description |
|---|---|
| Smoke | Smoke/fire hazard |
| Motion | Motion/occupancy hazard |
| Door | Door/security hazard |
| Panic | Immediate emergency override |
| Reset | System reset |
| Ack | Emergency acknowledgement |
| clk | FSM system clock |
| rst_n | Active-low hardware reset |

---

## Outputs

| Output | Description |
|---|---|
| Safe | Normal operating state |
| Warning | Single hazard detected |
| Critical | Multiple hazards detected |
| Evacuate | Immediate evacuation state |
| Buzzer | Alarm output |
| RouteA | Evacuation Route A |
| RouteB | Evacuation Route B |
| RouteC | Evacuation Route C |

---

## Finite State Machine

Campus Sentinel uses four states:

```text
00 = SAFE
01 = WARNING
10 = CRITICAL
11 = EVACUATE
```

A single normal hazard causes:

```text
SAFE -> WARNING
```

Two or more simultaneous normal hazards cause:

```text
SAFE/WARNING -> CRITICAL
```

Panic has the highest priority:

```text
ANY STATE -> EVACUATE
```

---

## Hazard Fusion

A normal hazard is present when:

```verilog
Smoke | Motion | Door
```

A critical multi-hazard condition occurs when:

```verilog
(Smoke & Motion) |
(Smoke & Door)   |
(Motion & Door)
```

---

## Alarm Latching

CRITICAL and EVACUATE conditions are latched.

Example:

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

This prevents a serious alarm from automatically disappearing when sensor signals return to normal.

---

## ACK Safety Interlock

ACK only clears a latched emergency when the hazard has cleared.

```text
Active Hazard + ACK
        |
        v
Emergency remains active
```

```text
No Hazard + ACK
        |
        v
       SAFE
```

---

## Evacuation Routing

| Emergency Condition | Route |
|---|---|
| Panic | Route A |
| Smoke + Door | Route C |
| Smoke-related critical event | Route B |
| Door-related critical event | Route A |
| Other critical event | Route A |

---

## Tiny Tapeout Pin Mapping

### Inputs

```text
ui_in[0] = Smoke
ui_in[1] = Motion
ui_in[2] = Door
ui_in[3] = Panic
ui_in[4] = Reset
ui_in[5] = Ack
ui_in[6] = Reserved
ui_in[7] = Reserved
```

### Outputs

```text
uo_out[0] = Safe
uo_out[1] = Warning
uo_out[2] = Critical
uo_out[3] = Evacuate
uo_out[4] = Buzzer
uo_out[5] = RouteA
uo_out[6] = RouteB
uo_out[7] = RouteC
```

The FSM uses the dedicated Tiny Tapeout `clk` input.

The design also uses the dedicated active-low `rst_n` reset.

---

## Main Test Cases

| Smoke | Motion | Door | Panic | Result |
|---:|---:|---:|---:|---|
| 0 | 0 | 0 | 0 | SAFE |
| 1 | 0 | 0 | 0 | WARNING |
| 0 | 1 | 0 | 0 | WARNING |
| 0 | 0 | 1 | 0 | WARNING |
| 1 | 1 | 0 | 0 | CRITICAL + Route B |
| 1 | 0 | 1 | 0 | CRITICAL + Route C |
| 0 | 1 | 1 | 0 | CRITICAL + Route A |
| X | X | X | 1 | EVACUATE + Route A |

---

## Repository Structure

```text
RodStephenEnzo-Campus_Guard/
|
├── src/
│   └── project.v
|
├── test/
│   ├── Makefile
│   ├── tb.v
│   └── test.py
|
├── docs/
│   └── info.md
|
├── .github/
│   └── workflows/
│       └── gds.yaml
|
├── info.yaml
└── README.md
```

---

## Technology

- Verilog HDL
- Tiny Tapeout
- IHP SG13G2
- Cocotb
- GitHub Actions
- RTL simulation
- ASIC synthesis and physical-design flow

---

## Project Goal

Campus Sentinel demonstrates how digital hardware can perform more than simple sensor-to-alarm mapping.

The complete processing sequence is:

```text
Multiple Sensors
       |
       v
Hazard Detection
       |
       v
Hazard Fusion
       |
       v
Severity Classification
       |
       v
Priority Logic
       |
       v
Finite State Machine
       |
       v
Emergency Latching
       |
       v
Safety Interlock
       |
       v
Evacuation Routing
       |
       v
Visual / Audible Outputs
```

---

## Safety Notice

Campus Sentinel 2.0 is an educational RTL prototype.

It is not a certified life-safety, fire-alarm, security, or evacuation system. Real deployment would require certified sensors, redundancy, fault monitoring, backup power, validated evacuation planning, appropriate interfaces, and compliance with applicable safety standards.

---

## Author

**Rod Geryk Navarro**

Campus Sentinel 2.0  
Verilog-Based Multi-Hazard Emergency Detection and Evacuation Controller
