# RISC-V CPU (RV32E) – RTL Implementation & Verification

This project presents a custom RTL implementation of a RISC-V CPU developed during the “一生一芯 (YSYX)” framework. The work focuses on microarchitecture design, verification, and system-level bring-up.

---

## Overview

- ISA: RV32E (with partial M extension support in reference model)
- Microarchitecture: Multi-cycle (transitioning towards pipeline)
- Design Style: Modular datapath (IFU / IDU / EXU / LSU / WBU)
- Interface: Valid–Ready handshake (latency-insensitive design)
- Memory: SimpleBus (YSYX framework)

---

## Key Features

### RTL CPU Design
- Designed full datapath and control logic
- Modular stage separation (IF / ID / EX / MEM / WB style)
- Support for load/store, branch, CSR operations

### Exception & Privilege Support
- Machine-mode privilege architecture
- CSR implementation (e.g., `mstatus`, `mtvec`, `mepc`, `mcause`)
- Precise trap and return mechanism

### Verification Infrastructure
- Built a C reference model (RV32E + M)
- Differential testing (RTL vs reference)
- ISA-level correctness validation

### Simulation & Debugging
- Verilator-based simulation
- Waveform tracing (FST / GTKWave)
- Instruction trace, memory trace
- Watchpoints / breakpoints / single-step execution

### System-Level Validation
- Successfully ran RT-Thread RTOS on RTL CPU
- Verified exception handling and context switching

---

## Project Structure
