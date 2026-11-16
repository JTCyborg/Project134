# AMI486 semantic disassembly — phase 1

Date: 2026-11-16  
ROM: `ami486.bin`, 64 KiB  
Image SHA-256: `91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b`  
Branch: `main`

This report adds semantic labels to selected regions of the byte-complete linear listing. It deliberately distinguishes executable entry points from embedded data and overlapping streams. A label marked *probable* is not a proven runtime reachability claim.

## 1. Region 19A2–1A8E: mixed display data and CPU/cache reporting code

### Data identified

| Offset | Interpretation | Evidence |
|---|---|---|
| `19A2–19AF` | Small pointer/word area with several RET bytes at `19AE–19AF`; not a reliable linear code stream | Raw bytes and alternate-entry decodes in `ami486_region_19A0_1A80_20261116_01.txt` |
| `19B0–19C1` | Compact byte/word lookup data | Referenced through `CS:[SI]` with SI based at `19B0` |
| `19C2–19C8` | Seven values: `10 14 19 21 28 32 42` | Explicitly indexed by code at `1A30–1A35` |
| `19C9–19DB` | NUL-terminated text: ` KB CACHE MEMORY\r\n` | ASCII bytes |
| `19DC–19EB` | NUL-terminated text: `MHz CPU Clock\r\n` | ASCII bytes |
| `19EC–19FA` | NUL-terminated text: `MHz DX2 CPU\r\n` | ASCII bytes |

### Executable path

At `1A00–1A1A`, the routine reads ALi1429 register `18h` through helper `8DCF`, tests bit 1 of the returned value, derives an index from bits 4–6, looks up a word/byte near `19B0`, and passes it to `09FD` for output. It then passes the cache label at `19C9` to `F52E`.

At `1A1D`, it calls `29ED`, which tests CMOS `B6.0`. If the test is nonzero, it reads BIOS Data Area byte `0040:E2`, uses that value to index the seven-byte table at `19C2`, and then selects one of the CPU-clock labels according to a later test of the chipset/CMOS state. The text and lookup data are therefore embedded in the middle of the code region.

**Confirmed:** these strings are data, not instructions; the lookup at `19C2` is indexed by the CPU classification byte stored at `0040:E2`; `29ED` is the CMOS `B6.0` test.

**Not yet established:** the exact unit/scaling represented by each lookup value, and whether all paths that display these strings are reachable in every POST configuration.

## 2. Region 8E89–8EA6: indexed indirect dispatcher

The sequence is:

- `8E89`: saves DS and SI.
- Loads DS with `0040h`.
- Copies AX to SI, shifts right by 8, and masks the result with `0Fh`.
- Rejects indexes greater than or equal to 5.
- For indexes 0–4, performs an indirect near call through `CS:[SI-7159h]` (effective table base `8EA7h`).
- Restores SI and DS, then executes `IRET` at `8EA6`.

This is an interrupt-style dispatch path: the high byte of AX selects one of five handler slots, and the routine returns with IRET. The exact source of AX and the complete meaning of all five target entries still need caller/vector tracing. The table overlaps the linear decode beginning at `8EA7`; do not interpret the table bytes as ordinary instructions.

## 3. Region 82C0–840B: CMOS/setup record lookup helpers

The region around `8300` and `83AE` contains two closely related lookup routines.

### Helper at 8300

- Starts with a table base candidate at `B7D0`.
- For nonzero AL, adjusts the record pointer using values derived from `B55D` and `B508`.
- Uses the record's length/flags bytes at offsets `+1Eh` and `+1Fh` to walk variable-length data.
- Reads CMOS register `8Eh` through `70h/71h`.
- Uses the record fields at `+1Ch` and `+1Dh` to derive a value/mask.
- Tests CMOS status bits `C0h`; on one path it looks up a replacement value through a secondary table rooted at `873C` or the pointer in `CS:[82C0]`.
- Returns a transformed byte in AL and sets flags used by callers.

### Related helper at 83AE

Uses the same record-walking logic but returns the two bytes at record offsets `+1Ch` and `+1Dh` in AL/AH. This is consistent with a helper for retrieving CMOS setup-record metadata, while `8300` applies the current CMOS/override state.

The pointer slots around `82C0–82C6` and the table records in `B500–B7D0` are data structures, not a single instruction stream. The exact record schema should be kept tied to the parsing behavior above; do not infer field names from offsets alone.

## 4. Region 26F9–284F: memory configuration / memory-test path (partial)

The entry at `26F9` reads an identifier from `CS:[B518]`, passes it to `8300`, and branches based on the result. The path beginning at `2706` saves the previous stack location, switches to a private stack, and enters a sequence of chipset register operations through the helpers at `8CB2`, `8DED`, and `8DFB`.

The code at `2761–27B8` selects segment `1000h`, writes pattern `55AA55AAh` to memory using 32-bit operand/address overrides, reads it back, and compares it. It probes several offsets around the segment base and branches to an error path on mismatch. This is strong evidence of a memory write/read verification step, not merely a register setup sequence.

The continuation at `27BC–27F2` changes segment values in `0400h` increments and iterates until the segment reaches `9000h`, with an error/abort branch and a halt path. The exact mapping and whether this is a full installed-memory sizing pass or a bounded diagnostic still need to be established.

## 5. Region 26A2–26F8: protected-mode transition and memory reads (purpose unresolved)

The code around `2692–26BA` loads a GDT, sets CR0.PE, executes a short sequence using a selector loaded into ES and a 32-bit address-size REP LODSD, then clears CR0.PE and continues in real mode. This is a genuine protected-mode transition sequence; the linear 16-bit decode alone obscures its mixed 16/32-bit instruction prefixes.

The later loop at `26D8–26F8` reads two 64-KiB windows beginning at segments `0700h` and `1700h` using REP LODSW. It does not store or compare the loaded words in the visible sequence. Its purpose is unresolved; do not label it as a destructive memory test.

## 6. Confirmed mixed code/data regions added to the map

| Range | Classification | Confidence |
|---|---|---|
| `19A2–19FA` | Mixed: pointer/lookup data, strings and executable display logic | High |
| `8E89–8EA6` | Executable indexed indirect dispatcher | High |
| `8EA7–8EB0` | Five-entry indirect target table area; target decoding still needs reconciliation | High for table role |
| `82C0–82E7` | Pointer/record metadata area, not linear code | High |
| `B500–B7D0` | Setup/CMOS record and string/table region | High |
| `26A2–26BA` | Protected-mode transition sequence with 32-bit-prefixed instruction(s) | High |
| `2761–27B8` | Memory write/read verification sequence | High |
| `27BC–284F` | Memory sizing/configuration continuation with unresolved branches | Partial |

## 7. Next semantic tasks

1. Reconcile the five indirect targets at `8EA7` against the actual interrupt/vector installation path and the caller that supplies AX.
2. Enumerate all writes to pointer slots `82C0–82E6`; distinguish static ROM defaults from runtime-installed handlers.
3. Decode the complete setup-record format used by `8300/83AE`, including the variable-length record walk and table at `873C`.
4. Trace the error and success exits of the `26F9–284F` memory path and identify which chipset registers are changed on each branch.
5. Identify the source of the CPU classification byte `0040:E2` and every consumer; keep the display path separate from benchmark execution.

## Source evidence in this repository

- `ami486_region_19A0_1A80_20261116_01.txt`
- `ami486_array_1980_20261116_01.txt`
- `ami486_vector_targets_20261116_01.txt`
- `ami486_vector_dispatch_callers_20261116_02.txt`
- `ami486_boot_cleanup_8300_20261116_01.txt`
- `ami486_26BE_20261116_01.txt`
- `ami486_ali1429_tables_and_dispatch_20261116_01.txt`
- `ami486_cmos_cpu_speed_context_20261116_125515.txt`
