# AMI486 semantic disassembly — phase 4

Date: 2026-11-16  
ROM identity per full-disassembly manifest: 64 KiB, SHA-256 `91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b`

This phase follows the configuration-table consumers more closely and separates proven static facts from assumptions about runtime pointer initialization.

## 1. Corrected interpretation of pointer slots

The code references establish the following *roles*, but do not yet establish who writes the runtime values:

| Slot | Read sites | Proven use |
|---|---|---|
| `CS:[82C0]` | 8382, 8485, 85EE | Alternate four-byte table base used by 8300 and 85D6; start of the bounded table walk in the 8400 path |
| `CS:[82C2]` | 848A, 84C2 | End pointer for the bounded four-byte table walk in 8400 |
| `CS:[82C6]` | 8326, 83CE; direct data read at 0C53 | Base of the extended variable-length setup-record collection |
| `CS:[82C8]` | direct data read at 0C59 | Upper boundary copied by the setup-editor helper; used together with 82C6 to calculate a span |
| `CS:[82CA]` | 85E6 | Base of a word array; selector at 82B0 chooses a word from it |
| `CS:[82B0]` | 85DB | One-based selector for the word array at 82CA |

### Writer search result

The repository's existing static reference inventory contains reads of these slots but no direct immediate stores or direct `MOV [82C0/82C2/82C6/82C8/82CA],reg` writer. That is a bounded negative result: it does **not** exclude writes through string operations, computed pointers, table copies, or runtime shadow/extension code.

Consequently, the previous phase's wording that these are definitely initialized by a particular BIOS routine would be unjustified. Their *consumer-side roles* are established; their runtime provenance remains unresolved.

## 2. The alternate four-byte table is optional, with built-in fallback paths

Three consumers show how the alternate table relates to the built-in table at 873Ch:

### 8300 — setup-value translation

- Default lookup base: `873Ch`.
- If the input value is above the threshold at `CS:[8888]`, the lookup base changes to `CS:[82C0]`.
- Entries are four bytes apart.
- Byte +0 is compared against the requested key.
- Byte +3 is returned when a match is found.

Important safety/format observation: the visible search loop at `8387–838F` advances by four bytes until a match; it does not check `[82C2]`. Do not assume this particular lookup is bounded by the end pointer.

### 8400 — bounded CMOS application

The routine uses the built-in table at `873Ch` for the count in `CS:[8886]`, then separately checks the runtime range:

- SI = `[CS:82C0]`
- continue only while SI < `[CS:82C2]`
- step by four bytes
- use entry byte +0 as CMOS register selector, byte +1 as mask, and byte +2 as the replacement value
- read old CMOS value, merge the selected bits, and write the resulting value through the CMOS helper.

Byte +3 is not used by this CMOS write loop.

### 85D6 — selected configuration values

- If `CS:[82B0]` is nonzero, it is decremented and doubled; the corresponding word is loaded from `[CS:82CA + 2*(selector-1)]` as the entry count.
- If the selector is zero, the routine uses the built-in count at `CS:[8880]` and base `873Ch`.
- Otherwise it uses base `[CS:82C0]`.
- Each entry has a four-byte stride.
- Byte +0 selects an index; byte +1 is a mask; bytes +2 and +3 are alternative values selected by input AL=1 or AL=2.
- Input AL=0 leaves the source value from `[BX-1F80h]` in place, then the common mask/merge path copies those masked bits to `[BX-2000h]`.
- Input AL=1 selects byte +2; AL=2 selects byte +3. The selected value is masked and merged into the destination at `[BX-2000h]`.

This is a table-driven masked update between two indexed memory windows in the current data segment. The available evidence does not justify naming those windows as specific ALi1429 register banks yet.

## 3. Refined four-byte entry schema

The cross-consumer schema is now:

`{ key/index, bitmask, value_A, value_B }`

The field meanings are consumer-dependent:

| Consumer | +0 | +1 | +2 | +3 |
|---|---|---|---|---|
| 8300 | Match key | Preserved as metadata/rotation parameter outside the table entry | Not used in lookup | Returned translation byte |
| 8400 | CMOS register index | Bit mask | CMOS replacement value | Not used by this loop |
| 85D6 | Source/destination index | Bit mask | Variant selected by AL=1 | Variant selected by AL=2 |

Therefore byte +3 should not be globally named simply “translated value”; it is a second value slot in the general record shape, with 8300 assigning it a translation role.

## 4. Separate extended setup-record range

The 8300/83AE walkers choose the built-in base `B7D0h` for selector values below `55h`. At or above `55h`, they subtract `55h` and load the base from `CS:[82C6]`.

The setup-editor helper at `0C53` copies:
- `[82C6]` to `[E191]`
- `[82C8]` to `[E193]`

It subtracts the base from the end and tests the result with `0FFE0h`. If the span has bits outside the low five bits, it also loads related fields from `82BC`, `82D2`, and `82CE` before invoking the editor helper at `0C7D`.

This is consistent with a separate extended setup-record area, but does not prove that 82C6/82C8 are initialized by the editor itself. The exact table-copy or shadowing code that supplies them remains to be found.

## 5. Setup-record format: corrected boundary of what is known

For each record, 8300/83AE:
- reads byte +1Eh as flags;
- adds byte +1Fh to the low byte of the record pointer and propagates carry;
- adds 20h to the pointer;
- if bit 7 of the flags byte is set, advances in two-byte increments until a zero word is found at [BX-2];
- decrements the requested record index and repeats;
- returns bytes +1Ch and +1Dh from the selected record.

The walker proves a 20h-byte base component plus a conditional zero-terminated extension. It does **not** prove that +1Fh is a complete record length by itself, nor that the optional tail is part of every record.

## 6. Related code: 2E84 and the setup-derived chipset bit

Callers at `2E80` and `2EC0` pass setup selectors from `CS:[B513]` and `CS:[B519]` to `83AE`. They:
- use the returned AX as a configuration value;
- take SI = AX & 7Fh as an index;
- take AH as a mask;
- conditionally set, clear, or test bits in the window `[SI-2000h]`;
- branch according to whether the BIOS is executing from segment F000h and whether the call is in the protected-mode/initialization path.

A further caller at `86EE` uses selector `CS:[B52C]` and follows a similar masked-update path. This ties setup records to actual chipset/window configuration code, but the selector names and individual record meanings still need to be recovered from the strings/record tables.

## 7. Next concrete analysis steps

1. Search all instruction forms that can write the pointer slots, not just direct MOV: `STOSW/STOSD`, `MOVSW/MOVSD`, `XCHG`, arithmetic through a computed pointer, and bulk copies.
2. Identify the initialization of the segment/window containing `82C0–82CA` and establish whether it is ROM, shadow RAM, or a copied BIOS data block at each relevant call.
3. Decode the built-in four-byte table at `873C` entry-by-entry, including the count words at `8880/8882/8884/8886` and threshold at `8888`.
4. Decode the word selector array at `82CA` and the setup records at `B7D0`.
5. Map the `[BX-1F80h]` and `[BX-2000h]` windows in 85D6 to their actual segment base and chipset register definitions.

## Evidence files

- `ami486_boot_cleanup_8300_20261116_01.txt`
- `ami486_cmos_table_routine_83AE_20261116_01.txt`
- `ami486_config_tables_8400_20261116_01.txt`
- `ami486_pointer_init_85D0_8640_20261116_01.txt`
- `ami486_pointer_init_0C30_0C90_20261116_01.txt`
- `ami486_pointer_write_refs_20261116_01.txt`
- `ami486_pointer_all_refs_20261116_01.txt`
- `ami486_cmos_table_callers_context_20261116_02.txt`
