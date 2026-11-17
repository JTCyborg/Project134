# AMI486 semantic disassembly — phase 6

Date: 2026-11-16  
ROM: 64 KiB; SHA-256 `91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b`

This phase traces the selector dispatch at 5A5E–5A77 into the four table workers and records the exact relationship between E187 and the built-in table slices.

## 1. E187 selects the configuration-table slice

The code at 5A5E reads `[E187]` and dispatches:

| E187 | Branch | Target | Worker setup | Entries |
|---:|---|---|---|---:|
| 0 or 1 | `cmp 2; JC` | 85F5 | SI=873Ch; CX=[8880] | 5 |
| 2 | equality after compare | 85C0 | SI=8750h; CX=[8882] | 76 |
| 3 | greater than 2, not 4 | 85CB | SI=8880h; CX=[8884] | 0 |
| 4 | equality at second compare | 85D6 | SI=[82C0]; CX from [82CA + 2*(82B0-1)] or fallback | Dynamic |
| 5–255 | greater than 2, not 4 | 85CB | SI=8880h; CX=[8884] | 0 |

The branch logic is exact:
- `E187 <= 2` selects 85F5 for values below 2 and 85C0 for value 2.
- Values above 2 select 85D6 only when E187 is exactly 4.
- All other values above 2 select 85CB.

Do not infer the semantic name of E187 from this dispatch alone. Its producer and the meaning of values 0–4 remain to be traced.

## 2. What each worker actually applies

### 85F5 — five-entry prefix

Loads count 5 and base 873Ch, then enters the common worker at 85FE.

### 85C0 — 76-entry suffix

Loads count 76 and base 8750h, then enters the same worker.

### 85CB — no-op / empty set

Loads count 0 and base 8880h. The common worker at 85FE checks CX and immediately returns when it is zero. This is a deliberate empty configuration set.

### 85D6 — optional runtime table

- Reads selector `CS:[82B0]`.
- If nonzero, decrements it, doubles it, reads a word count from `CS:[82CA + 2*(selector-1)]`, and takes base `CS:[82C0]`.
- If zero, falls back to count 5 at `CS:[8880]` and base 873Ch.
- Uses the common four-byte record worker at 85FE.

## 3. Common worker semantics at 85FE–862F

For each four-byte entry:
- Byte +0 is the index/key.
- The routine reads the current source byte from `[BX-1F80h]`, where BX is the key.
- Byte +1 is the mask.
- For input AL=1, byte +2 is selected.
- For input AL=2, byte +3 is selected.
- For input AL=0, the current source byte remains selected.
- The selected byte is ANDed with the mask.
- The destination byte at `[BX-2000h]` is ANDed with the inverted mask, then ORed with the selected masked bits.
- SI advances by four and CX decrements through LOOP.

The common operation is therefore:
`destination = (destination & ~mask) | (selected_source & mask)`.

For AL=0, `selected_source` is the value read from `[BX-1F80h]`; for AL=1/2 it is the record's value +2/+3. The two windows are distinct offsets in the current DS segment. Their exact hardware mapping remains unresolved.

## 4. Higher-level wrapper 85B3

The wrapper at 85B3:
1. Saves AX.
2. Calls 85F5 (five-entry prefix).
3. Restores AX.
4. Calls 85CB (zero-entry table, so no entries are changed).
5. Saves AX.
6. Calls 85D6 (dynamic table or its five-entry fallback).
7. Restores AX.
8. Falls through into 85C0h, which loads CX=[8882h]=76 and SI=8750h, then jumps to the common worker at 85FEh. The suffix is processed before the routine returns at 862Fh.

Thus 85B3 applies the five-entry prefix, the zero-count 85CB slot, the optional runtime table selected by 85D6, and then the 76-entry suffix. In the stock ROM, 85CB is a no-op and 85D6 also processes no entries because 82B0h=0; the wrapper therefore applies all 81 built-in records. The middle 85CB call may be a retained hook for a patched/alternate BIOS data set, but that is not proven.

A call site at 84FE invokes 85B3 with AL=1 after copying a 30h-byte configuration block from CS:8210 to E010. This is a concrete initialization path that applies value-A entries to the configuration window.

A second call site at 5A92 invokes 85B3 after the E187-related checks and an additional configuration test. It then calls 58BE and 5902. The exact semantic meaning of that higher-level path remains open.

## 5. What is now established vs unresolved

**Established**
- E187 chooses one of four table slices by exact numeric value.
- The built-in slices have counts 5, 76 and 0.
- E187=4 chooses the optional runtime table path.
- 85B3 applies the five-entry prefix, the optional 85CB/85D6 slots, then falls through to the 76-entry suffix; the stock path processes all 81 built-in records.
- AL=1/2 selects record byte +2/+3; AL=0 copies masked bits from the source window.
- 84FE calls 85B3 with AL=1 after copying the 8210h block.

**Unresolved**
- Where E187 is assigned and whether it represents a chipset profile, CPU class, setup selection or a temporary mode.
- The physical meaning of DS:[index-1F80h] and DS:[index-2000h].
- Whether the zero-count 85CB path is intentionally reserved for a runtime patch.
- Which configuration state causes the 5A92 call to 85B3.

## 6. Next analysis

1. Find all writes and reads of E187, including byte stores and structure copies.
2. Trace the caller of the 5A5E dispatch and determine what AL contains at each entry.
3. Decode the 30h-byte block at 8210h and correlate it with the copy to E010 at 84F6–84F9.
4. Map the two DS-relative windows used by 85D6.
5. Trace 5A92 through 58BE and 5902 to identify the higher-level configuration mode.

## Evidence

- `ami486_cmos_table_callers_context_20261116_02.txt`
- `ami486_pointer_init_85D0_8640_20261116_01.txt`
- `ami486_config_tables_8400_20261116_01.txt`
- `ami486_cmos_table_raw_873C_8888_20261116_01.txt`


## Correction from phase 8 — zero selector in 85D6

The phase-6 statement that 85D6 falls back to the five-entry built-in table when `CS:[82B0]` is zero was incorrect. The routine zeroes CX before reading the selector; when selector is zero, DEC BL branches around the count lookup, CX remains zero, and the common worker exits immediately. The five-entry table is selected only by the separate 85F5 routine.

The stock ROM initializes `82B0=00h`, `82C0=0000h`, and `82C2=0000h`, so 85D6 is a no-op in the unpatched image. See [phase 8](AMI486_SEMANTIC_MAP_PHASE8_20261116.md) for the byte-level verification and corrected call-path summary.


## Audit correction — 85B3h falls through into the 76-record suffix (2026-11-17)

The earlier description in section 4 that 85B3h returns after the 85D6h call is incorrect. At 85BFh, POP AX is followed by 85C0h PUSH SI; there is no RET at 85BFh. Execution falls through into the 85C0h worker, loads the 76-entry count from 8882h and base 8750h, and returns only at 862Fh. This is a second caller of the 76-record suffix in addition to the direct E187h=2 Setup dispatch. In the stock ROM, the 85D6h optional table is empty (phase 8 correction), so the 85B3h wrapper processes 5 + 0 + 0 + 76 = 81 records. See `AMI486_ADDRESS_LEDGER_REGION_873C_8DCE_20261117.md`.
