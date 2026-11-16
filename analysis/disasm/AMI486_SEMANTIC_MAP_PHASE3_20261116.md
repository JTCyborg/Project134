# AMI486 semantic disassembly — phase 3

Date: 2026-11-16  
ROM: `ami486.bin`, 64 KiB  
SHA-256: `91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b`

This phase resolves the roles of the pointer pairs around 82C0 and connects the same four-byte configuration records to the CMOS setup and chipset-configuration paths.

## 1. Pointer groups around 82B0–82CA

| Address | Role supported by references | Confidence |
|---|---|---|
| `82B0` | Count/index selector used by 85D6 to choose a word from the list at `[82CA]` | High |
| `82C0` | Start pointer for a runtime four-byte configuration-entry array | High |
| `82C2` | End pointer for the same array; 8485/848A and 84C2 bound the walk | High |
| `82C6` | Start pointer for the variable-length setup-record collection used by 8300/83AE | High |
| `82C8` | End pointer associated with the 82C6 collection; copied alongside it by setup-editor code at 0C53 | Medium-high |
| `82CA` | Pointer to a word list indexed by `2*(82B0-1)` in 85D6 | High |

The initialization/source writer for the runtime pointer values is not yet proven. The direct-reference inventory does not show a simple immediate MOV into 82C0/82C2/82C6/82C8; indirect copies or runtime table construction remain possible.

## 2. Four-byte configuration entries: cross-routine reconstruction

The same four-byte stride appears in three independent consumers. Taken together, they support this provisional schema:

| Byte | Provisional field | Evidence |
|---:|---|---|
| +0 | Register/index key | 8300 compares it to the requested key; 8400 uses it as the CMOS register index; 85D6 uses it to form the target address |
| +1 | Bit mask | 8400 and 85D6 use it to preserve unselected bits |
| +2 | Value A | 8400 uses it as the replacement value; 85D6 selects it for one selector state |
| +3 | Value B / translated value | 8300 returns it from a matching record; 85D6 selects it for another selector state |

This layout is a reconstruction from code use, not a claim that all records populate every field identically. The precise meaning of the index depends on the consumer.

### Consumer A: 8300 translation lookup

When CMOS status bits C0h require translation, 8300 chooses the table at 873Ch or the dynamic table at [82C0], scans four-byte records by byte +0, and returns byte +3 from the matching record.

Unlike the bounded walk at 8400, this lookup loop does not visibly compare its cursor with [82C2]. The table contents or caller must therefore guarantee a matching entry / valid termination; do not assume the 8300 loop itself is bounds-safe.

### Consumer B: 8400–84C8 CMOS update loop

At 8485 the code loads SI from [82C0] and compares it with [82C2]. If SI is below the end pointer, it processes the current entry:

1. Read the current CMOS register selected by entry byte +0.
2. Load entry byte +2 as the replacement value and byte +1 as the mask.
3. Compute `new = (old & ~mask) | (valueA & mask)`.
4. Write the result back to the selected CMOS register.
5. Advance SI by four bytes and repeat until the end pointer is reached.

This establishes [82C0,82C2) as a bounded array of four-byte entries. The loop at 84C2 rechecks the end pointer after each entry.

### Consumer C: 85D6 configuration application

The routine first selects a count from the word list at [82CA], using [82B0] as the selector. It then walks four-byte entries from [82C0]. If no selected count is present, it falls back to a default table at 873Ch with a count from 8880h.

For each entry it:
- reads byte +0 as an index;
- reads the current target value from a memory-mapped location derived from that index;
- for one selector state chooses byte +2, and for another chooses byte +3;
- merges the selected value with the current target using the mask at byte +1;
- advances by four bytes.

The exact target address space behind the effective `[BX-2000h]` / `[BX-1F80h]` references is not assigned here because the relevant segment and calling context must be followed before naming the chipset register bank.

## 3. Variable-length setup records at 82C6–82C8

The 8300/83AE walkers use [82C6] as the record base for selector values in the extended range. The setup-editor helper at 0C53 snapshots:
- [82C6] into [E191];
- [82C8] into [E193];
- computes the difference and tests it against FFE0h.

This strongly supports [82C6,82C8) as a separate range describing the variable-length setup-record collection. It is not the same array as the four-byte table [82C0,82C2).

The editor helper subsequently chooses additional values at 82BC, 82D2 and 82CE when the span test requires it. Their exact schema is not assigned in this phase.

## 4. Configuration setup flow around 8400

The routine beginning at 8400 is gated by bit 6 of `CS:[8280]`. If the gate is clear, it exits through D90D.

When enabled, it:
- reads CMOS register 8Eh and checks the C0h status bits;
- in the non-C0h path, writes a sequence of values beginning at 90h to CMOS registers;
- in the alternate path, copies a 30h-byte block from CS:8210 into the current data segment at E010;
- calls 85B3, 85CB and 85D6 to apply configuration data;
- calls A35 and 1A8F for subsequent setup/reporting;
- copies an 80h-byte block from E000 to E080 and invokes E7E8 before returning.

The exact interpretation of the CMOS status bits and the 90h-register initialization remains open. The routine clearly performs conditional configuration initialization and applies the table-driven configuration entries; it is not merely a table reader.

## 5. Important distinction between table types

There are at least two separate table formats in this area:

1. **Four-byte fixed entries** in the runtime range [82C0,82C2), also mirrored by a default table at 873Ch. These are consumed by 8300, 8400 and 85D6.
2. **Variable-length setup records** in [82C6,82C8), indexed by 8300/83AE after the 55h selector split. Each has a 20h-byte base/header region plus an optional zero-terminated variable tail.

Do not merge these formats merely because both are used by the BIOS setup code.

## 6. Remaining work

1. Identify the code that initializes [82C0,82C2), [82C6,82C8), [82CA] and [82B0].
2. Decode the actual contents of the runtime four-byte array and map each entry to its CMOS register / chipset field.
3. Trace the target memory segment for the [BX-2000h] accesses in 85D6.
4. Decode the variable record headers and tails in the [82C6,82C8) range.
5. Resolve the 8E3C overlapping handler and the callback contracts at 8BA3, 8B5E, 8BE8 and 8C4D.

## Evidence files

- `ami486_pointer_refs_82C0_82C2_82C6_20261116_01.txt`
- `ami486_dynamic_table_pointer_refs_20261116_01.txt`
- `ami486_config_tables_8400_20261116_01.txt`
- `ami486_pointer_init_85D0_8640_20261116_01.txt`
- `ami486_pointer_init_0C30_0C90_20261116_01.txt`
- `ami486_cmos_table_routine_83AE_20261116_01.txt`
- `ami486_config_table_B7D0_20261116_01.txt`
