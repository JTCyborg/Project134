# AMI486 ROM — Disassembly Index

Target ROM: ami486.bin
ROM size: 65536 bytes
Disassembler: NASM ndisasm 3.01
Mode: 16-bit

## Archived source listings

| File | Start address | Description |
|---|---:|---|
| ami486_reset.disasm.txt | F000:E05B | Reset entry and initial code |
| ami486_post_entry.disasm.txt | F000:D604 | POST entry investigation |
| ami486_branches.disasm.txt | Multiple | Branch targets and alternate entry points |
| analysis/disasm/ami486_full_linear_16bit.disasm.txt | 0000-FFFF | Complete byte-covering linear 16-bit decode; see manifest for SHA-256 and coverage |

## Address investigation

| Address | Current finding | Status |
|---|---|---|
| F000:FFF0 | Far jump to F000:E05B | Confirmed |
| F000:E05B | Near jump to F000:D604 | Confirmed |
| F000:D604 | POST entry candidate; CLI, CLD, KBC status check | Partial |
| F000:D60C | Unconditional jump to F000:88CE | Confirmed |
| F000:88CE | CPU/stack and mode checks; overlapping code/data possible | Partial |
| F000:8A04 | Checks CR0.PE; reset/halt path or alternate initialization | Partial |
| F000:8A20 | Checks initialization state and dispatches helper | Partial |
| F000:8A75 | Jump to F000:D74C | Confirmed |
| F000:8A78 | Indirect jump through CS:82DA | Confirmed |
| F000:D6DE | POST code 1; stack test sequence | Partial |
| F000:D74C | Keyboard controller and warm-boot checks | Partial |
| F000:D77B | ROM checksum loop | Partial |
| F000:D7AB | Keyboard controller self-test | Partial |
| F000:F4A5 | Error reporting and diagnostic/beep path | Partial |
| F000:F659 | Wait for keyboard controller input buffer | Partial |
| F000:F6D9 | Option ROM header/checksum validation and dispatch | Partial |
| F000:1AF8 | Jump to F000:D82F | Confirmed |
| F000:1B90 | Option ROM scanning candidate | Partial |

## Rules

- Never overwrite archived source listings.
- Do not repeat a disassembly already present in this archive.
- Add new address ranges as separate files.
- Distinguish confirmed control flow from linear-disassembly guesses.
- Do not mark a routine fully understood until its callers, inputs, outputs and side effects are checked.

## Update 2026-11-16 — POST flow

| Address | Finding | Status |
|---|---|---|
| F000:D604 | KBC status bit 2 dispatch | Confirmed |
| F000:88CE | SMSW / CR0.PE check | Confirmed |
| F000:891E | JMP F000:D60F | Confirmed |
| F000:D60F | JMP F000:D6DE | Confirmed |
| F000:8904 | Dispatch to EE94 | Confirmed |
| F000:8906 | Dispatch to EE94 | Confirmed |
| F000:8919 | Dispatch to EE9D | Confirmed |
| F000:8DCF | ALi1429 register read helper | Strongly supported |
| F000:8DDC | ALi1429 register write helper | Strongly supported |
| F000:8DED | ALi1429 register read sequence | Strongly supported |

Detailed report: AMI486_POST_FLOW_20261116_01.md

## Full-ROM coverage audit — 2026-11-16

Target image: `ami486.bin` (65,536 bytes; Git blob SHA `480c7520c93e6c7ed437cf3ad214da7503f82ec6`).

### Existing listing coverage

| Listing | First offset | Last offset | Lines | Meaning |
|---|---:|---:|---:|---|
| `ami486_reset.disasm.txt` | `E05B` | `FFFF` | 3,993 | Linear 16-bit listing from reset entry |
| `ami486_post_entry.disasm.txt` | `D604` | `FFFF` | 5,252 | Linear 16-bit listing from POST entry |
| `ami486_branches.disasm.txt` | multiple | multiple | 919 | Selected branch/alternate-entry excerpts |

The reset and POST listings overlap heavily: both continue linearly to `FFFF`. They are not independent contiguous ROM partitions and must not be concatenated as if they cover the complete image.

### Missing full-ROM range

The existing two linear listings do not cover offsets `0000-D603` (54,788 bytes). The branch listing and focused analysis files contain selected excerpts from that region, not a byte-complete disassembly.

### Status and required method

- **Byte-complete 64-KiB linear disassembly: COMPLETE** (`analysis/disasm/ami486_full_linear_16bit.disasm.txt`; 65,536/65,536 bytes). Semantic code/data classification remains incomplete.
- Existing listings are preserved as historical entry-point listings.
- Do not label a listing as complete based only on reaching `FFFF`; its starting offset matters.
- To finish, run NASM `ndisasm -b 16` against the exact `ami486.bin` for the missing range `0000-D603`, then reconcile code/data and alternate-entry regions against the existing listings.
- Source image SHA-256: `91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b`. Generated listing contains 29,731 records and explicitly emits undecodable bytes as `db`.
- Verify the input image SHA-256 and byte length before generating the final master listing. Preserve the existing reset/POST listings unchanged.

### Next deliverables

1. **Done:** byte-complete linear listing covering `0000-FFFF`.
2. Build a separate control-flow/alternate-entry map so overlapping instruction streams remain explicit.
3. Build a code/data classification map for tables, strings, padding, option-ROM payloads and embedded structures.
4. **Done:** index updated with verified coverage and source-image hash.



## Full-ROM linear disassembly generator — 2026-11-16

A reproducible generator is now tracked at `tools/disasm_ami486_full.ps1`.

Run from the repository root in PowerShell:

```powershell
.\tools\disasm_ami486_full.ps1 -RomPath .\ami486.bin -Ndisasm ndisasm
```

The script requires the exact 65,536-byte ROM and NASM `ndisasm`, decodes in 16-bit mode from offset `0000`, verifies that the listing accounts for exactly 65,536 input bytes, and writes:
- `analysis/disasm/ami486_full_linear.disasm.txt`
- `analysis/disasm/ami486_full_linear.disasm.manifest.txt`

The manifest records the local ROM SHA-256, disassembler path, mode, origin, line count and decoded byte count. The generated linear listing is a mechanical decode only; it does not establish code reachability or distinguish embedded data from instructions. Preserve the existing reset/POST entry-point listings as separate views.


## Automated full-ROM disassembly

A GitHub Actions workflow (`.github/workflows/ami486-full-disasm.yml`) generates `ami486_full_linear_16bit.disasm.txt` directly from the checked-in 64-KiB ROM using NASM `ndisasm -b 16`. The listing is a complete **linear byte decode**, not a claim that every decoded byte is executable code; embedded tables, strings, vectors and overlapping entry points must be classified separately. The workflow uses Capstone in 16-bit x86 mode, emits undecodable bytes as `db`, verifies exact byte coverage and commits the generated listing.


## Semantic map — phase 1 (2026-11-16)

| Region | Classification / finding | Status |
|---|---|---|
| 19A2–1A8E | Mixed CPU/cache reporting code, lookup values and embedded strings | Partial; data ranges identified |
| 8E89–8EA6 | Indexed indirect dispatcher; five handler slots selected by AH | Confirmed dispatch mechanics; targets pending |
| 8EA7–8EB0 | Indirect target table used by dispatcher | Confirmed table role; entries pending reconciliation |
| 82C0–82E7 | Pointer/record metadata, not a continuous instruction stream | Confirmed data region |
| B500–B7D0 | Setup/CMOS record and string/table region | Strongly supported |
| 26A2–26BA | GDT/CR0 protected-mode transition with 32-bit-prefixed operation | Confirmed |
| 2761–27B8 | 32-bit memory pattern write/read verification | Confirmed |
| 27BC–284F | Memory sizing/configuration continuation | Partial |

Detailed report: [AMI486_SEMANTIC_MAP_PHASE1_20261116.md](AMI486_SEMANTIC_MAP_PHASE1_20261116.md)

This phase is semantic classification of selected regions, not a complete CFG. See the report for confidence levels and unresolved target/record details.


## Semantic map — phase 2 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE2_20261116.md](AMI486_SEMANTIC_MAP_PHASE2_20261116.md)
- Dispatcher `8E89`: resolved five indirect targets: `8EB1`, `8EC2`, `8EC1`, `8ECE`, `8E3C`.
- Setup walkers `8300/83AE`: selector split at `55h`; built-in base `B7D0h`, runtime record-table base via `CS:[82C6h]`; optional variable-length tails; CMOS conversion and four-byte translation entries.
- Memory pattern `2761–27B8`: narrowed to explicit verification of two dwords; additional reads are not visibly compared.
- Runtime writers of `82C0h/82C6h`, exact setup-record schema, and the overlapping entry at `8E3C` remain open.


## Semantic map — phase 3 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE3_20261116.md](AMI486_SEMANTIC_MAP_PHASE3_20261116.md)
- Resolved pointer groups: `82C0/82C2` bound a runtime four-byte entry array; `82C6/82C8` bound a separate variable-length setup-record range; `82CA` points to a word selector list; `82B0` selects within that list.
- Reconstructed provisional four-byte record schema: `{index/register, mask, value A, value B/translated value}`, corroborated by consumers `8300`, `8400–84C8`, and `85D6`.
- Distinguished fixed four-byte configuration entries from variable-length setup records; their formats must not be conflated.
- Runtime pointer initialization and exact chipset address-space mapping remain unresolved.


## Semantic map — phase 4 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE4_20261116.md](AMI486_SEMANTIC_MAP_PHASE4_20261116.md)
- Tightened the four-byte record schema to `{key/index, mask, value_A, value_B}`, with consumer-specific meanings.
- Distinguished the unbounded key search in `8300` from the end-pointer-bounded walk in `8400`.
- Traced `85D6` selectors: AL=0 copies masked source-window bits, AL=1 selects +2, AL=2 selects +3, merging into the destination window.
- Confirmed the separate setup-record base/end pair `82C6/82C8` is consumed by 8300/83AE and the setup editor; direct static writers remain unidentified.
- Corrected the earlier overstatement: pointer consumer roles are established, but runtime pointer provenance and chipset-window names are still unresolved.


## Semantic map — phase 5 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE5_20261116.md](AMI486_SEMANTIC_MAP_PHASE5_20261116.md)
- Decoded built-in configuration table: exactly 81 four-byte records at `873C–887F`.
- Count fields: `8880=5`, `8882=76`, `8884=0`, `8886=81`; threshold `8888=E0h`.
- Identified table slices: first five records at `873C`, remaining 76 at `8750`; 8400 consumes all 81 for CMOS application.
- Preserved the distinction between the CMOS register/mask/value consumer and the generic two-profile configuration worker.


## Semantic map — phase 6 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE6_20261116.md](AMI486_SEMANTIC_MAP_PHASE6_20261116.md)
- Resolved `E187` dispatch values: 0–1 → 5-entry prefix; 2 → 76-entry suffix; 3 → empty set; 4 → optional dynamic table; other values above 4 → empty set.
- Confirmed common worker semantics at `85FE–862F`: masked merge into DS-relative destination window, with AL=0 copying masked source-window bits and AL=1/2 selecting record +2/+3.
- Traced wrapper `85B3`: applies the five-entry prefix and then the optional table; called from `84FE` with AL=1 after copying the 8210h block.
- Meaning/producer of E187 and hardware mapping of the two DS-relative windows remain unresolved.


## Semantic map — phase 7 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE7_20261116.md](AMI486_SEMANTIC_MAP_PHASE7_20261116.md)
- Resolved `E187`: it is the 0–10 top-level Setup menu item index, not a CPU/chipset profile identifier.
- Decoded the 11 menu labels and corresponding handler offsets from tables at `342E` and `3446`; item 4 is Peripheral Management Setup and dispatches to `0C53h`.
- Reinterpreted the `5A5E` table dispatch as Setup-page-specific behavior: Standard/Advanced CMOS → 5 entries; Advanced CHIPSET → 76 entries; Power Management → empty; Peripheral Management → optional runtime table.
- Corrected `85D6`: `DS:E080+index` is the source and `DS:E000+index` the destination working buffer. These are not ALi1429 hardware windows.
- Confirmed the separate ALi1429 access helpers use ports `22h/23h`.


## Semantic map — phase 8 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE8_20261116.md](AMI486_SEMANTIC_MAP_PHASE8_20261116.md)
- Read the stock ROM initial values: `82B0=00h`, `82C0=0000h`, `82C2=0000h`, `82C6=0000h`, `82C8=0000h`, `82CA=19A3h`.
- Corrected `85D6`: when `82B0=0`, CX remains zero and the worker returns; it does **not** fall back to the five-entry table. The optional dynamic table is inactive in the stock ROM.
- Confirmed the stock runtime table and extended Setup-record ranges are empty; 8400 and 0C53 skip them.
- Updated phase 6 with an explicit correction to its earlier zero-selector fallback statement.


## Semantic map — phase 9 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE9_20261116.md](AMI486_SEMANTIC_MAP_PHASE9_20261116.md)
- Cross-checked BIOS ALi1429 access helpers against `Project124/PCem/ali1429.c`: indexed protocol is ports `22h/23h`.
- PCem explicitly models only registers `13h/14h` for C0000h–FFFFFh shadow windows; remaining indices are generic storage in that model.
- Confirmed the 81-entry table at `873C–887F` is applied through CMOS ports `70h/71h`, not ALi1429 ports `22h/23h`.
- Traced the separate direct ALi1429 read-modify-write sequence at `1C5E–1DD0`; register bit meanings remain unassigned absent a fuller register map.


## Semantic map — phase 10 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE10_20261116.md](AMI486_SEMANTIC_MAP_PHASE10_20261116.md)
- Traced the main Setup page handlers: Advanced CMOS `0BDEh` edits `B7D0–BD53`; Advanced CHIPSET `0C05h` edits `BD54–C5F8`.
- Decoded page gates: `[B7CA]=0584h` and `[B7CC]=08A5h` enable Advanced CMOS/CHIPSET; `[B7CE]=0000h` disables Power Management.
- Confirmed Peripheral Management handler `0C53h` uses optional `[82C6,82C8)`, empty in the stock ROM.
- Identified the common editor entry at `0C7Dh` and the page-specific range/title/help setup performed by each handler.


## Semantic map — phase 11 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE11_20261116.md](AMI486_SEMANTIC_MAP_PHASE11_20261116.md)
- Catalogued the stock Advanced CMOS Setup descriptors in `B7D0–BD53` and Advanced CHIPSET descriptors in `BD54–C5F8`.
- Extracted Setup item labels, raw descriptor bytes, selector counts/values, and associated explanatory strings.
- Kept Setup descriptor records separate from the 81-entry CMOS initialization table and the ALi1429 indexed-register path; exact field semantics and hardware bit meanings remain under investigation.


## Semantic map — phase 12 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE12_20261116.md](AMI486_SEMANTIC_MAP_PHASE12_20261116.md)
- Resolved the common Setup record layout: key/index at `+1C`, mask/routing byte at `+1D`, flags/callback selector at `+1E`, option count at `+1F`, option codes from `+20`.
- Traced variable-length record advancement, hidden-item filtering, working-image bit extraction/writeback, optional callback dispatch, and option-label translation.
- Confirmed the editor manipulates the `DS:E000` RAM working image; hardware/CMOS application is a separate later path.


## Semantic map — phase 13 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE13_20261116.md](AMI486_SEMANTIC_MAP_PHASE13_20261116.md)
- Mapped the `E195=B7B2` callback table and associated selectors in Advanced CMOS / Advanced CHIPSET records.
- Traced Setup save-and-restart through `2F67 -> 852F -> 854F`, including checksum bytes and CMOS index range.
- Traced the complementary load/default path at `84CB` and corrected phase-11 record boundaries using the exact variable-length walker behavior.


## Semantic map — phase 14 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE14_20261116.md](AMI486_SEMANTIC_MAP_PHASE14_20261116.md)
- Decoded `0A35` as CMOS/RTC, memory-size and equipment-data refresh; confirmed its `70h/71h` CMOS helper path.
- Confirmed `1A8F` is a RET stub and traced `1A90` as pre-save normalization of `E017` plus a video-ROM signature consistency check.
- Corrected phase 13: `E7E8` is a keyboard-controller command/response test, not a Setup-image validator; `E1AA.0` records that test result.
- No new ALi1429 writeback path was found in these routines; the direct `22h/23h` RMW block remains `1C5E–1DD0`.


## Semantic map — phase 15 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE15_20261116.md](AMI486_SEMANTIC_MAP_PHASE15_20261116.md)
- Traced POST checkpoint `8Ch` to `1C5E`, proving this is the live chipset-apply routine.
- Resolved `[CS:82E2]` to `19AE`, a stock `RET` hook.
- Documented CMOS `8Eh & C0h` bypass gate and CMOS `B6.0` AUTO Config/manual selection.
- Catalogued bit-level CMOS-to-ALi1429 RMW operations on indices `20h,17h,12h,14h,1Eh,1Ah,21h,22h,25h,27h` through ports `22h/23h`.


## Semantic map — phase 16 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE16_20261116.md](AMI486_SEMANTIC_MAP_PHASE16_20261116.md)
- Traced POST callers for `1E9D`, `1E78`, and `1F47`.
- Documented second AUTO Config/manual selection at POST checkpoint `A4h` and CMOS-to-ALi1429 RMW writes for indices `16h,19h,25h,12h,18h,1Ah,27h`.
- Identified independent feature-gated register 14h bit operations and ROM-window setup calls.


## Semantic map — phase 17 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE17_20261116.md](AMI486_SEMANTIC_MAP_PHASE17_20261116.md)
- Traced POST 98h through 1E9D to three independently gated 32-KiB ROM-window helpers (2420h, 242Bh, 2436h), and confirmed their reuse from 1B60h.
- Decoded the shared helper sequence: ALi1429 register 13h mask update, register 14h staging/finalization, and same-address 8000h-byte copy; behavior is strongly consistent with shadow-ROM initialization and PCem's register-13h/14h model.
- Corrected the interpretation of hook 8300h: the stock stub preserves flags and does not test AL; B51F/B521/B523/B518 therefore remain patch/context-dependent gates.
- Traced POST A1h through 1EC8h, 2850h and 26F9h, documenting observed writes to ALi registers 18h/19h/43h and the gated memory test/sizing continuation.
- Exact chipset bit meanings, OEM hook provenance, helper 2686h and the mode tables at 8E62h/8E7Ah remain unresolved.


## Semantic map — phase 18 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE18_20261116.md](AMI486_SEMANTIC_MAP_PHASE18_20261116.md)
- Resolved 1BB3h as an option-ROM validator/executor: checks AA55h, size and checksum, then far-calls the image entry at segment:0003; 1B60h scans E0000h–E7FFFh in 2-KiB candidate steps.
- Traced the separate C0000h shadow-window path: POST 5E20h -> 1BF6h -> B51D/8300h hook -> 2415h.
- Decoded 2686h as a protected-mode flat-segment read sweep of 1 MiB at physical 00100000h–001FFFFFh, followed by a return to real mode through DI.
- Kept the purpose of the read sweep and the OEM/runtime hook conditions unresolved; no unsupported cache semantics assigned.
