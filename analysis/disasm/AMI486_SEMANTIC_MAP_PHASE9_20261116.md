# AMI486 semantic disassembly — phase 9

Date: 2026-11-16

This phase cross-checks the BIOS chipset-access code against the user's Project124/PCem implementation and separates CMOS-table entries from ALi1429 indexed-register accesses.

## 1. Project124 PCem model of ALi1429

Source inspected: [Project124/PCem/ali1429.c](https://github.com/JTCyborg/Project124/blob/main/PCem/ali1429.c), header [ali1429.h](https://github.com/JTCyborg/Project124/blob/main/PCem/ali1429.h).

The implementation confirms:
- The ALi1429 uses an index/data pair at ports 22h and 23h.
- Even port 22h selects the register index; odd port 23h reads/writes the selected register.
- The emulator stores a generic 256-byte register array.
- Only indices 13h and 14h receive explicit device-side behavior in this implementation.
- Writes to 13h/14h recalculate shadow state for eight 32-KiB windows from C0000h through FFFFFh, using register 13h enable bits and register 14h read/write mode bits.
- Reset initializes the register array to FFh.
- Other register indices are stored/read generically; this source file does not document their bit meanings.

This source validates the BIOS port protocol, but it is not a complete ALi1429 register specification. Do not assign names or bit meanings to other indices from this model alone.

## 2. BIOS helpers match the PCem port protocol

The BIOS helper routines in the full disassembly:
- 8DCF: writes the index to port 22h, then reads the selected value from port 23h.
- 8DDC: writes the index to port 22h, then writes the selected value to port 23h.
- 8DED: another index/data read helper.

These are directly consistent with `ali1429_read()` and `ali1429_write()` in Project124/PCem.

## 3. Important separation: the 873Ch table is a CMOS table, not an ALi1429 register table

The 8400 routine consumes the 81 four-byte entries at 873Ch–887Fh through the CMOS helpers:
- It loads entry byte +0, sets bit 7, and calls the CMOS index/data path at EE94/EE9D (ports 70h/71h).
- It reads entry +1 as a mask and +2 as the replacement value.
- It therefore applies CMOS register values, not ALi1429 index/data registers.

Some table keys happen to equal ALi1429 register indices (for example 13h), but that numerical overlap does not make them ALi1429 settings. The access path and consumer prove the 8400 table is a CMOS configuration table.

Likewise, 85D6 operates on DS-relative memory buffers E080h+index and E000h+index. It is not a direct ALi1429 port driver.

## 4. Separate direct ALi1429 programming path: 1C5E–1DD0

The routine at 1C5E uses the 8DCF/8DDC helpers to read-modify-write indexed ALi1429 registers. The observed index sequence includes:

`20h, 17h, 12h, 14h, 17h, 1Eh, 1Ah, 20h, 21h, 22h, 25h, 27h`

It also reads CMOS registers 8Eh, 50h, 47h, 42h, 44h, 4Eh, 4Ah, 51h, 52h, 55h, and 57h to derive values/masks for those chipset writes. The path is gated by CMOS register B6h bit 0 via helper 29ED, with a separate speed-test branch through 8F12.

The routine performs bit-preserving read-modify-write operations; examples include:
- register 20h: retains bits F8h and inserts low three bits from CMOS register 50h;
- register 17h: retains bits 83h and merges selected bits from CMOS register 47h;
- register 12h: retains bits E0h and merges selected low five bits from CMOS register 42h;
- register 14h: retains bits A0h and merges selected bits from CMOS register 44h.

These are observed transformations only. Their named hardware meanings remain unresolved because Project124/PCem stores most register indices generically.

## 5. Consequences for the next stage

1. Keep three distinct mechanisms separate in the analysis:
   - CMOS register programming through ports 70h/71h;
   - ALi1429 indexed-register programming through ports 22h/23h;
   - internal Setup working-buffer updates in DS:E000h/DS:E080h.
2. Use the PCem model only to validate the indexed port protocol and the explicitly implemented 13h/14h shadow-window behavior.
3. For registers 20h, 17h, 12h, 14h, 1Eh, 1Ah, 21h, 22h, 25h and 27h, obtain a chipset datasheet or a more complete emulator implementation before assigning semantic names.

## Evidence

- Project124/PCem/ali1429.c
- Project124/PCem/ali1429.h
- ami486_cmos_callers_20261116_01.txt
- ami486_dynamic_hook_1C5E_1DD3_20261116_01.txt
- ami486_cpu_speed_analysis_20261116.md
- ami486_cmos_table_raw_873C_8888_20261116_01.txt
- AMI486_POST_FLOW_20261116_01.md
