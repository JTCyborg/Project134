# AMI486 semantic map — phase 15 (2026-11-16)

## Scope

Trace the POST caller of `1C5E`, resolve its indirect callback pointer, and document the live ALi1429 chipset-apply path. This directly addresses the unresolved question from phase 14: where Setup CMOS values become writes to ports `22h/23h`.

## Confirmed POST caller

The routine is called directly from the POST sequence:

- `12D8`: emits POST checkpoint `8Bh`.
- `12DC–12E3`: saves DS/ES, disables interrupts, calls `1C50`, restores ES/DS.
- `12E4–12E7`: emits checkpoint `8Ch`.
- `12E8–12EC`: disables interrupts, calls `1C5E`, then enables interrupts.
- `12ED`: emits checkpoint `8Dh`.

So `1C5E` is not merely a Setup-menu callback: it is part of the normal POST chipset initialization path, at POST checkpoint `8Ch`.

## Indirect extension hook at 82E2

At entry, `1C5E` loads a near offset from `CS:[82E2]` and calls it indirectly.

- ROM word `CS:[82E2] = 19AEh`.
- `19AE` contains a single `RET`.
- No static writes to `CS:[82E2]` were found in the complete linear disassembly.

Therefore the stock ROM's optional pre-initialization hook is a no-op. The hook could be replaced by an OEM/runtime patch, but no such patch is demonstrated by this ROM image.

## CMOS gate and configuration selection

After the hook, `1C5E` reads CMOS register `8Eh` and tests mask `C0h`.

- If either bit in `8Eh & C0h` is set, it jumps to `1DD3`, bypassing the ALi1429 register programming block.
- If both bits are clear, it proceeds with chipset programming.

It then calls `29ED`, which reads CMOS register `B6h` and tests bit 0. This is the previously identified **AUTO Config Function** selector:

- `B6.0 = 1`: automatic branch. Calls CPU/memory timing measurement `8F12`, then `2537` and `256A` to derive and program selected ALi1429 timing fields.
- `B6.0 = 0`: manual branch. Reads CMOS values `50h` and `47h` and merges their selected bits into ALi1429 registers `20h` and `17h`.
- Both branches converge at `1CB5` and continue with the common register programming sequence.

The distinction is important: AUTO Config does not bypass the rest of the chipset initialization. It selects how the initial register 20h/17h timing fields are obtained; common writes follow either branch.

## Exact ALi1429 writes in 1C5E–1DD0

The low-level helpers are confirmed by their instruction bodies:

- `8DCF`: `OUT 22h,AL`; `IN AL,23h` — select/read indexed register.
- `8DDC`: `OUT 22h,AL`; `OUT 23h,AL` (after swapping AH/AL) — select/write indexed register.

The common sequence performs read/modify/write operations on these indices:

| ALi1429 index | CMOS source | Merge behavior |
|---|---:|---|
| `20h` | `50h` | preserve register bits F8; replace low 3 bits from CMOS |
| `17h` | `47h` | preserve register bits 7C; replace bits selected by CMOS mask 83 |
| `12h` | `42h` | preserve register bits E0; replace low 5 bits from CMOS |
| `14h` | `44h` | preserve register bits 5F; replace bits selected by CMOS mask A0 |
| `17h` | `47h` | second field merge; preserve bits 83, replace selected bits 7C |
| `1Eh` | `4Eh` | preserve bits 0C; replace selected bits F3 |
| `1Ah` | `4Ah` | preserve bits 30; replace selected bits CF |
| `20h` | `50h` | second field merge; preserve bits 0F, replace upper nibble |
| `21h` | `51h` | preserve bits 48; replace selected bits B7 |
| `22h` | `52h` | preserve bits F7; replace bit 3 |
| `25h` | `55h` | preserve bits CF; replace selected bits 30 |
| `27h` | `57h` | preserve bit 0; replace bit 0 |
| `27h` | `57h` | second field merge; preserve bits 30; replace selected bits CF |
| `14h` | — | clear bit 6, then conditionally set bit 6 based on BL bits 4–5 |

The duplicated indices are intentional: distinct CMOS fields control separate bit groups within the same chipset register. The final write to register `14h` uses the current BL value from the caller's preserved context; do not reinterpret it as a direct CMOS read.

The table describes exact bit-level operations, not undocumented functional names for the chipset fields. Register meanings remain unassigned unless confirmed by ALi1429 documentation or an emulator implementation.

## What this proves

1. The live chipset-apply path is `POST 8Ch -> 1C5E`.
2. Setup's CMOS image is not merely stored and forgotten: when CMOS status bits `8E.C0` are clear, POST reads CMOS configuration bytes and applies their selected bits to ALi1429 indexed registers through `22h/23h`.
3. CMOS `B6.0` selects automatic versus manual sourcing for the initial `20h/17h) timing fields; the rest of the chipset RMW sequence is common.
4. The stock extension hook `[82E2]` points to a RET stub, so it contributes no extra chipset writes in the unmodified ROM.
5. The CMOS `8E.C0` gate can suppress this entire block. Its broader firmware meaning should not be guessed from this single caller.

## Next trace

Inspect the POST callers around `1E4B`, `1E5F`, `1E78`, `1E9D`, and the large register-write blocks in `1F47–203B`, plus any indirect callback tables they use. These appear to be later, conditional chipset/video/cache initialization paths; trace their callers before assigning them to a specific Setup option.
