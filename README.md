# APB / AHB Bus Protocol Checker

**Author:** Saravana Kumar T J A
**Role:** Design & Verification Engineer — Semiconductor
**Tools:** QuestaSim 10.4e | Verilog | SystemVerilog | SVA
**GitHub:** [APB-AHB-Bus-Protocol-Checker](https://github.com/sachin07sk/APB-AHB-Bus-Protocol-Checker)

---

## Overview

A protocol compliance verification environment for both **APB (Advanced Peripheral Bus)** and **AHB (Advanced High-performance Bus)** — two key buses in the ARM AMBA family.

The environment:
- Generates valid and invalid bus transactions
- Monitors all bus signals every clock cycle
- Detects protocol violations using **SVA assertions** automatically
- Reports PASS/FAIL for every protocol rule checked
- Runs both APB and AHB verification simultaneously in one simulation

---

## Protocol Specifications

### APB — Advanced Peripheral Bus

| Parameter       | Value                          |
|----------------|--------------------------------|
| Type           | Simple 2-phase bus             |
| Memory         | 1KB (256 × 32-bit words)       |
| Address range  | 0x000 to 0x3FF                 |
| Data width     | 32-bit                         |
| Wait states    | 1 cycle (PREADY insertion)     |
| Error response | PSLVERR on out-of-range access |
| Reset          | Active LOW (PRESETn)           |

**APB Transfer Phases:**

```
Cycle →       1        2        3
CLK        ─┐ ┌─┐ ┌─┐ ┌─┐ ┌─
             └─┘ └─┘ └─┘ └─┘

PSEL       ──────────────────
PENABLE    ─────────┐
                    └────────
PWRITE     ═════════════════   (1=write 0=read)
PADDR      ══0x1000══════════
PWDATA     ══0xABCD══════════
PREADY     ──────────────────  (no wait state)

           SETUP    ENABLE    IDLE
                    ↑
              transfer here
           (PENABLE=1 AND PREADY=1)
```

### AHB — Advanced High-performance Bus

| Parameter       | Value                           |
|----------------|---------------------------------|
| Type           | Pipelined burst bus             |
| Memory         | 1KB (256 × 32-bit words)        |
| Address range  | 0x000 to 0x3FF                  |
| Data width     | 32-bit                          |
| Burst support  | SINGLE, INCR4, INCR8            |
| Wait states    | HREADY=0 insertion              |
| Error response | HRESP=ERROR on out-of-range     |
| Reset          | Active LOW (HRESETn)            |

**AHB Pipelined Transfer:**

```
Cycle →     1        2        3        4
HADDR    ══0x100══0x104══0x108══0x10C══   ← address phase
HWDATA   ══xxxxxxx══DATA_A══DATA_B══DATA_C ← data phase (1 cycle later)
HTRANS   ══NONSEQ══SEQ════SEQ════SEQ════
HREADY   ─────────────────────────────────

DATA_A belongs to address 0x100 — arrives 1 cycle after address
```

---

## Protocol Rules Verified

### APB — 13 SVA Assertions + 4 Cover Properties

| Rule | Description |
|------|-------------|
| R01 | PENABLE cannot be high without PSEL |
| R02 | SETUP phase must be followed by ENABLE phase |
| R03 | PADDR must not change during ENABLE phase |
| R04 | PWRITE must not change during ENABLE phase |
| R05 | PWDATA must not change during ENABLE phase (writes) |
| R06 | PSEL must remain high during entire ENABLE phase |
| R07 | After transfer completes PENABLE must go low |
| R08 | PSLVERR valid only when PREADY=1 |
| R09 | No transfer allowed during reset (PRESETn=0) |
| R10 | PADDR must be word-aligned (PADDR[1:0]==00) |
| R11 | PENABLE rising edge requires prior PSEL high |
| R12 | PRDATA must be valid (not X) on read completion |
| R13 | PENABLE must be asserted cycle after PSEL rises |

**Cover Properties:** Write complete, Read complete, PSLVERR occurred, Wait state occurred

### AHB — 12 SVA Assertions + 4 Cover Properties

| Rule | Description |
|------|-------------|
| R01 | SEQ must always follow NONSEQ or SEQ (not IDLE) |
| R02 | HTRANS must remain stable during wait state (HREADY=0) |
| R03 | HADDR must remain stable during wait state |
| R04 | HWDATA must remain stable during write wait state |
| R05 | HWRITE must not change during a burst |
| R06 | HSIZE must not change during a burst |
| R07 | HRESETn=0 must drive HTRANS to IDLE |
| R08 | HSEL must be high during active transfer |
| R09 | HADDR must increment by 4 each SEQ beat (INCR4) |
| R10 | SEQ transfer must not follow IDLE state |
| R11 | HRESP ERROR must be held for minimum 2 cycles |
| R12 | HBURST must not change during a burst |

**Cover Properties:** NONSEQ occurred, SEQ burst occurred, Wait state occurred, ERROR response occurred

---

## SVA Examples

```systemverilog
// APB Rule 1: PENABLE needs PSEL
APB_R01_PENABLE_NEEDS_PSEL: assert property (
    @(posedge PCLK) disable iff (!PRESETn)
    PENABLE |-> PSEL
) else $error("VIOLATION R01: PENABLE=1 but PSEL=0");

// APB Rule 2: SETUP → ENABLE phase
APB_R02_SETUP_TO_ENABLE: assert property (
    @(posedge PCLK) disable iff (!PRESETn)
    (PSEL && !PENABLE) |=> PENABLE
) else $error("VIOLATION R02: SETUP not followed by ENABLE");

// AHB Rule 1: No SEQ without prior NONSEQ
AHB_R01_SEQ_AFTER_NONSEQ: assert property (
    @(posedge HCLK) disable iff (!HRESETn)
    (HTRANS == 2'b11) |->
    ($past(HTRANS) == 2'b10 || $past(HTRANS) == 2'b11)
) else $error("VIOLATION R01: SEQ without prior NONSEQ/SEQ");

// AHB Rule 3: HADDR stable during wait state
AHB_R03_HADDR_STABLE_WAIT: assert property (
    @(posedge HCLK) disable iff (!HRESETn)
    !HREADY |=> $stable(HADDR)
) else $error("VIOLATION R03: HADDR changed during wait");
```

---

## Test Scenarios

### APB Test Scenarios (10 tests)

| Test | Scenario | Expected |
|------|----------|----------|
| 1 | Single write | SETUP → ENABLE → IDLE |
| 2 | Single read | PRDATA valid on PREADY |
| 3 | Write with wait state | PREADY=0 for 1 cycle |
| 4 | Read with wait state | Data held stable |
| 5 | Out-of-range address | PSLVERR=1 asserted |
| 6 | Back-to-back writes | No gap between transfers |
| 7 | Reset during transfer | All outputs clear |
| 8 | Bug: PENABLE without PSEL | R01 assertion fires |
| 9 | Bug: PADDR changes in ENABLE | R03 assertion fires |
| 10 | Bug: PENABLE stays after transfer | R07 assertion fires |

### AHB Test Scenarios (10 tests)

| Test | Scenario | Expected |
|------|----------|----------|
| 1 | Single write | NONSEQ then IDLE |
| 2 | Single read | HRDATA valid next cycle |
| 3 | INCR4 write burst | 4 beats incrementing |
| 4 | INCR4 read burst | 4 beats of read data |
| 5 | INCR8 write burst | 8 beats incrementing |
| 6 | Transfer with wait | HREADY=0 handled |
| 7 | Out-of-range address | HRESP=ERROR 2 cycles |
| 8 | Bug: SEQ without NONSEQ | R01 assertion fires |
| 9 | Bug: HADDR no increment | R09 assertion fires |
| 10 | Bug: HTRANS in wait state | R02 assertion fires |

---

## File Structure

```
apb_ahb_checker/
├── rtl/
│   ├── apb_slave.v           APB slave memory DUT (1KB, wait states, PSLVERR)
│   ├── apb_master.v          APB stimulus generator (10 transactions)
│   ├── ahb_slave.v           AHB slave memory DUT (SINGLE+INCR4+INCR8)
│   └── ahb_master.v          AHB stimulus generator (5 test scenarios)
│
├── tb/
│   ├── apb_if.sv             APB interface (all signals + clocking block)
│   ├── apb_assertions.sv     13 SVA rules + 4 cover properties
│   ├── apb_monitor.sv        APB signal watcher (prints all transfers)
│   ├── apb_checker.sv        APB procedural protocol violation detector
│   ├── ahb_if.sv             AHB interface (all signals + clocking block)
│   ├── ahb_assertions.sv     12 SVA rules + 4 cover properties
│   ├── ahb_monitor.sv        AHB pipelined signal watcher
│   └── ahb_checker.sv        AHB procedural checker
│
└── sim/
    └── protocol_tb.sv        Top — APB + AHB running simultaneously

```

---

## Simulation Results

```
=========================================
 APB MONITOR SUMMARY
 Writes  : 5
 Reads   : 3
 Errors  : 1
=========================================

=========================================
 APB CHECKER RESULTS
 PASSED : 47
 FAILED : 0
 STATUS : ALL APB CHECKS PASSED ✓
=========================================

[AHB MON] t=350ns | WRITE  | ADDR=0x00000100 DATA=0xa0000000
[AHB MON] t=380ns | WRITE  | ADDR=0x00000104 DATA=0xa0000001
[AHB MON] t=410ns | WRITE  | ADDR=0x00000108 DATA=0xa0000002
[AHB MON] t=440ns | WRITE  | ADDR=0x0000010c DATA=0xa0000003

=========================================
 AHB CHECKER RESULTS
 PASSED : 38
 FAILED : 0
 STATUS : ALL AHB CHECKS PASSED ✓
=========================================
```

---

## How to Simulate

```tcl
# 1. Open QuestaSim
# 2. In transcript window:

cd C:/VLSI_Projects/apb_ahb_checker/sim
do run.do
```

**Expected output:**
- All APB and AHB modules compile with 0 errors
- APB Monitor prints each SETUP and ENABLE phase
- AHB Monitor prints each pipelined transfer
- APB Checker: ALL CHECKS PASSED ✓
- AHB Checker: ALL CHECKS PASSED ✓

---

## Key Concepts Demonstrated

```
SVA |-> operator:   Same-cycle implication
SVA |=> operator:   Next-cycle implication
$stable(signal):    Checks signal unchanged from previous cycle
$past(signal):      Returns signal value from previous cycle
$rose(signal):      Detects 0→1 transition
disable iff:        Disable assertion during reset

APB difference from AHB:
  APB:  no pipelining, PSEL+PENABLE handshake
  AHB:  pipelined address/data, HTRANS state machine,
        burst support (NONSEQ/SEQ), HREADY wait states
```

---

## Interview Points

- Wrote **33 total SVA statements** (13 APB + 12 AHB + 8 cover)
- Injected **6 deliberate protocol violations** to verify checker fires
- Implemented **pipelined AHB monitor** that correctly tracks address pipeline
- Both protocols verified **simultaneously** in single simulation
- All SVA assertions use `disable iff` to suppress false violations during reset

---

*Saravana Kumar T J A — Design & Verification Engineer*
*LinkedIn: linkedin.com/in/sk-212010-tja*
*GitHub: github.com/sachin07sk*
