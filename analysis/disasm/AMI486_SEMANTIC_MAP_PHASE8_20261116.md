# AMI486 semantic disassembly — phase 8

Date: 2026-11-16  
ROM: 64 KiB; SHA-256 `91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b`

This phase checks the actual ROM-initialized values of the optional table pointers and corrects a fallback-path mistake in phase 6.

## 1. Initial contents of the pointer slots

The bytes at 82A0h–82FFh were reconstructed from the full linear disassembly. Relevant little-endian fields are:

| Field | ROM initial value | Meaning from consumers |
|---|---:|---|
| `CS:[82B0]` (byte) | `00h` | Runtime table selector; zero disables the dynamic-table count lookup |
| `CS:[82C0]` | `0000h` | Runtime four-byte table base |
| `CS:[82C2]` | `0000h` | Runtime table end pointer |
| `CS:[82C6]` | `0000h` | Extended setup-record base |
| `CS:[82C8]` | `0000h` | Extended setup-record end |
| `CS:[82CA]` | `19A3h` | Base pointer for the selector-indexed word table, only read when 82B0 is nonzero |

These are ROM image initial bytes. They do not prove the values cannot be patched after shadowing, but the static linear disassembly contains no direct instruction writes to these slots.

## 2. Correct 85D6 behavior when 82B0 is zero

The exact instructions are:

```
85D6  push si
85D7  xor bx,bx
85D9  xor cx,cx
85DB  mov bl,[cs:82B0]
85E0  dec bl
85E2  js 85EE
85E4  shl bx,1
85E6  mov si,[cs:82CA]
85EB  mov cx,[cs:bx+si]
85EE  mov si,[cs:82C0]
85F3  jmp 85FE
85FE  jcxz 862E
```

With the stock ROM value `[82B0]=0`:
- `DEC BL` produces FFh and sets the sign flag.
- The branch to 85EE skips the word-count lookup through 82CA.
- CX remains zero from 85D9.
- SI is loaded from 82C0, also zero.
- The common worker immediately returns at 85FE because CX=0.

**Correction:** phase 6 incorrectly described the zero-selector path as falling back to the five-entry table at 873Ch. It does not. The five-entry table is selected by the separate routine 85F5. Routine 85D6 with selector zero is an empty/no-op path.

If 82B0 is nonzero, 85D6 reads a count word from `CS:[82CA + 2*(selector-1)]`, loads the table base from 82C0, and processes that many four-byte records. Both values must therefore be populated coherently by an extension/patch for this path to do useful work.

## 3. Stock-ROM behavior of the optional ranges

The zero-initialized values make the optional areas inactive in the unmodified ROM image:

- 8400 reads SI=82C0=0 and compares it with 82C2=0; the runtime-table loop is skipped.
- 0C53 copies 82C6=0 and 82C8=0 to its editor state, calculates a zero span, and returns at 0C7C without opening the extended-record editor.
- 85D6 sees selector 82B0=0, leaves CX=0, and returns without applying a dynamic table.
- 82CA=19A3 is not dereferenced on this stock path because the selector check bypasses the lookup.

This explains why the base BIOS contains consumers for optional runtime configuration records even though the ROM image itself supplies no active record range.

## 4. Corrected relationship among the workers

Keep these paths distinct:

- `85F5`: always selects the built-in five-entry prefix at 873Ch.
- `85C0`: selects the built-in 76-entry suffix at 8750h.
- `85CB`: selects the built-in zero-entry table at 8880h.
- `85D6`: selects an optional runtime table only when 82B0 is nonzero; otherwise it is a no-op.

The wrapper 85B3 calls 85F5, 85CB, and 85D6 in sequence. With stock pointer values this means the five-entry prefix is applied, while the latter two calls process zero entries. The 5A5E dispatch for E187=4 jumps directly to 85D6, so the stock Peripheral Management path has no dynamic table entries unless an extension supplies them.

The separate 84F3 path calls 85B3 and then explicitly calls 85CB and 85D6 again. In the stock image the repeated calls are harmless no-ops for the empty table paths.

## 5. What remains to find

1. Identify any runtime patch, shadow-BIOS writer, or OEM extension that populates 82B0, 82C0, 82C2, 82C6, 82C8, or 82CA.
2. Decode the selector-count array at 19A3 only in the context of a nonzero 82B0 value; do not interpret it as active default data.
3. Determine whether the optional table mechanism was intended for a board-specific Peripheral Management extension or for a different OEM configuration layer.
4. Continue decoding the active built-in CMOS and chipset records independently of the empty optional ranges.

## Evidence

- `ami486_full_linear_16bit.disasm.txt` (bytes at 82A0h–82FFh; instructions 8400h, 85D6h–862Fh)
- `ami486_config_tables_8400_20261116_01.txt`
- `ami486_pointer_init_85D0_8640_20261116_01.txt`
- `ami486_pointer_init_0C30_0C90_20261116_01.txt`
- `ami486_pointer_area_82A0_82FF_20261116_01.txt`
