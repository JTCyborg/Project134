# AMI486 — decode of Setup handler table entries (first pass)

Date: 2026-11-17  
Repository: `JTCyborg/Project134`, branch `main`  
Input: `ami486.bin` (65,536 bytes; fetched blob SHA `480c7520c93e6c7ed437cf3ad214da7503f82ec6`).

## 1. Correct handler-table interpretation

The generic UI code at `60A0–60B0` performs:

- `SHL BX,1` — scale the current item index by two.
- `MOV SI,[E195]` — load the selected handler-table base.
- `MOV BX,[SI+BX]` — fetch a 16-bit handler address.
- Save registers/segments, then `CALL BX`.

Thus `E195` points to a table of 16-bit near-call handler addresses, not an untyped byte list. The table is indexed by the selected item number.

At `B7B0`, the first word `0C00h` is likely a header/metadata field; the handler addresses begin at `B7B2`:

```
B7B2: 2E74
B7B4: 86DB
B7B6: 29F6
B7B8: 2AC1
B7BA: 2B13
B7BC: 2B4C
B7BE: 2B91
B7C0: 2BD3
B7C2: 2C1D
B7C4: 2C69
B7C6: 2CCF
B7C8: 0584
B7CA: 08A5
```

These are little-endian near offsets in the ROM code segment. The previous note's caution that the entries might be relative offsets is superseded for this table: the generic UI engine loads each word and calls it directly with `CALL BX`.

## 2. Handler families visible in the first entries

### 2E74 and 86DB

Both start with a similar register/segment and machine-state prologue. They inspect CPU/segment state and global flags, then branch into helper paths. These appear to be special Setup handlers, not simple bitfield setters. They require deeper call-target tracing before naming.

### 29F6

This handler saves registers, reads and updates global words/flags at `E036` and `E066`, and chooses between option strings at `B571` and `B568` (the nearby strings are `Enabled` and `Disabled`). It is a boolean/toggle-style setting handler.

### 2AC1, 2B13, 2B4C, 2B91, 2BD3, 2C1D, 2C69, 2CCF

These handlers share a common shape:
- preserve SI/DI and use BX as a temporary setting value;
- load a setting-specific state word/byte (for example `E050`, `E046`, `E049`, `E047`, `E042`, or `E052`);
- test a global enable/valid flag at `E036`;
- extract or update a selected bitfield;
- use a CS-relative word table at `2E...` or `2B...` to map the selected option to a display/value encoding;
- return with `RETF` (`CB`), matching the far-call wrapper used by the generic UI engine.

The repeated `2E 8B 04` sequence loads an option value through a table indexed by the setting's current selection. These are setting-specific option handlers, not direct proof of chipset register numbers.

### 0584 and 08A5

These are also present in the handler table. `0584` calls display/format helpers and contains BIOS video calls; `08A5` is part of keyboard/input handling. Their presence suggests the table includes navigation/display-related entries as well as hardware-setting entries. Do not assume every handler in the table writes a chipset register.

## 3. UI calling convention evidence

The dispatcher at `60A7–60B0` fetches the near handler offset and performs a far-segment-preserving call sequence. The handlers inspected above commonly terminate with `CB` (RETF), so the actual stack/call convention must be modeled as a far-call-compatible wrapper around the near table entry. This is an important distinction: the pointer is a near offset, but the caller establishes a far return frame / segment context.

The exact segment stack sequence should be reconstructed from the complete bytes around `60A7–60B4` and compared against all handler epilogues before implementing a compatibility layer.

## 4. What is now established

1. `B7B2` is a near-offset handler table consumed by the generic Setup UI dispatcher.
2. The first several entries implement a mixture of boolean/toggle and multi-option setting handlers.
3. Setting handlers manipulate shadow/configuration variables in the `E0xx` RAM region.
4. Some handlers use option lookup tables; others invoke display or keyboard helpers.
5. A direct ALi1429 register mapping is still not established by this pass. The `E0xx` variables must be traced to the final I/O routines.

## 5. Next analysis steps

- Decode the complete dispatcher stack frame and RETF convention.
- Trace each `E0xx` setting shadow variable to all writes and final hardware I/O.
- Decode the option tables referenced by handlers `29F6–2CCF`.
- Separate actual hardware settings from display, keyboard, and navigation handlers.
- Prioritize the final port-I/O sinks; only those can support chipset register labels.

## Evidence limits

This is a first-pass handler-family classification. It does not claim all 13 table entries are fully understood, nor that any E0xx field is an ALi1429 register. The ROM bytes and direct call-table use are confirmed; semantic labels remain provisional.
