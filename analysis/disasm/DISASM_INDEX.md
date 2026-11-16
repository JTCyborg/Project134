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


## Semantic map — phase 19 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE19_20261116.md](AMI486_SEMANTIC_MAP_PHASE19_20261116.md)
- Corrected the 8300h interpretation: it is a BX-preserving wrapper around the real record walker at 8306h; B51x values are lookup keys, not proven Boolean flags.
- Completed the common ROM-window helper family 2415h–244Ch, including the previously missed E000h and alternate C800h entries; documented register 13h/14h staging and the 32-KiB same-address read/write operation.
- Traced the 5E05h POST scan and the 1BB3h Option-ROM checksum/initialization far call.
- Corrected Phase 18: the 26F9h/2686h memory test path performs a 55AA55AAh write and compare at its base address; it is not read-only.


## Semantic map — phase 20 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE20_20261116.md](AMI486_SEMANTIC_MAP_PHASE20_20261116.md)
- Fully decoded the 8306h CMOS-to-option lookup and its 83AEh companion metadata lookup; caller ZF/JNZ checks test the decoded option, not a raw Boolean feature flag.
- Audited all static references to 82C6h/82C8h: no ROM write sites exist; stock optional extended Setup-record range remains inactive absent external/runtime initialization.
- Refined the POST memory-test sequence at 26F9h–29EAh: documented overlapping pattern writes, compared offsets, spaced reads, 32-KiB read pass, 16-KiB fill/scan/clear, and the unresolved physical mapping.


## Semantic map — phase 21 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE21_20261116.md](AMI486_SEMANTIC_MAP_PHASE21_20261116.md)
- Mapped POST handlers 1DE8h–1E35h, 1E78h, 1E9Dh, 1EC8h–1F46h, 1F47h–203Eh and 2042h–2064h.
- Added two further CMOS-option-gated ROM-shadow windows (E000h and alternate C800h) to the three already mapped in Phase 17/19.
- Documented additional ALi1429 register read/modify/write masks in the POST A4 path; kept hardware bit names unresolved.
- Explicitly separated 100% mechanical byte decoding from semantic recognition; a reliable semantic percentage requires a per-byte code/data/reachability ledger and is not yet available.


## Semantic map — phase 22 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE22_20261116.md](AMI486_SEMANTIC_MAP_PHASE22_20261116.md)
- Decoded shared CR0 cache-control continuations: 8CB2h clears CD/NW; 8CCDh sets CD/NW and executes WBINVD.
- Traced the 8042 command/response helper 8CEAh and fixed descriptor-driven I/O handlers 8B5Eh/8BA3h.
- Documented ALi1429 mode helpers 8D09h/8D39h and related protected-mode memory paths 8D56h/8D83h.
- Kept fixed descriptor blocks (8250h–826Eh) distinct from B51x Setup lookup keys; peripheral and chipset bit names remain unresolved.


## Semantic map — phase 23 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE23_20261116.md](AMI486_SEMANTIC_MAP_PHASE23_20261116.md)
- Completed mapping of the four fixed descriptor groups at 8250h, 8258h, 8260h and 8268h, including each port read-modify-write mask and [0016h] state-bit polarity.
- Traced the CS:[8281h].6 bypass and recorded its static cross-reference set; its initialization source is unresolved.
- Traced the 9400h–949Fh 8042 controller transaction and the 8B2Dh selector dispatch.
- Kept peripheral identities and board-specific command semantics explicitly unresolved.


## Semantic map — phase 24 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE24_20261116.md](AMI486_SEMANTIC_MAP_PHASE24_20261116.md)
- Corrected the stock descriptor interpretation: 8250h and 8260h groups are active; 8258h and 8268h groups are zero-filled. Recorded the actual stock selector bytes 4Eh and 4Ah and the zero stock value at 8281h.
- Traced the INT 15h AH=4Fh keyboard intercept and its keypad +/- scan-code dispatch to the active descriptor handlers.
- Distinguished the POST-time Setup-key decision at 1E1Ch from the separate keyboard scan-code intercept.


## Semantic map — phase 25 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE25_20261116.md](AMI486_SEMANTIC_MAP_PHASE25_20261116.md)
- Resolved CS:[B517h]=0Fh as the ordinal selector for the fifteenth Advanced CMOS Setup record, BA0Bh, `System Boot Up Sequence`.
- Decoded the record fields: CMOS ADh, mask 20h, two option codes 10h/0Fh; traced its decoded value to the 8BA3h/8B5Eh ALi1429 dispatch at 1E1Ch.
- Distinguished this POST Setup path from the independent INT 15h AH=4Fh keyboard intercept that also reaches the same handlers.


## Semantic map — phase 26 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE26_20261116.md](AMI486_SEMANTIC_MAP_PHASE26_20261116.md)
- Resolved B51Bh=13h as the ordinal selector for record 19, `Fast Gate A20 Option` (BA91h; CMOS 2Dh, mask 02h).
- Traced POST 1DD8h–1E18h to the 8042 read-input-port command C0h via F5D9h.
- Resolved B519h=11h as record 17, `External Cache Memory` (BA4Fh), and callback selector 2 to 2EB4h.


## Semantic map — phase 27 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE27_20261116.md](AMI486_SEMANTIC_MAP_PHASE27_20261116.md)
- Mapped the 8042 command/data helpers F635h, F644h, F622h, F62Dh, F651h and response/read helpers.
- Identified F66Ah as D1h/DFh (A20 gate enable) and F66Eh as D1h/DDh (A20 gate disable), using output-port bit 1.
- Separated the POST C0h input-port probe at F5D9h from the actual D1h output-port writes.


## Semantic map — phase 28 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE28_20261116.md](AMI486_SEMANTIC_MAP_PHASE28_20261116.md)
- Traced the INT 15h AH=87h extended-memory move path: A20 enabled before CR0.PE, disabled after PE is cleared on the normal return path.
- Identified a second A20/PE sequencing pair at 20C9h–23CBh and an additional protected-mode entry at 933Ah.
- Established that the D1h writes use fixed DFh/DDh values rather than saving and restoring the previous 8042 output-port byte.


## Semantic map — phase 29 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE29_20261116.md](AMI486_SEMANTIC_MAP_PHASE29_20261116.md)
- Resolved 933Ah from the INT 15h dispatch table as AH=89h, the protected-mode entry service.
- Established that AH=89h enables A20, loads caller GDT/IDT, sets PE, loads protected-mode selectors, and intentionally returns with A20/PE enabled.
- Reframed 20C9h–23CBh as an A20-bracketed protected-mode memory-address probe/configuration sequence; ALi register 10h remains unnamed.
- Refined AH=87h exit analysis: the normal path is paired, but alternate/error branches have distinct cleanup and require separate tracing.


## Semantic map — phase 30 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE30_20261116.md](AMI486_SEMANTIC_MAP_PHASE30_20261116.md)
- Enumerated the AH=87h ordinary transfer and CS:[8281h].6 alternate reset/recovery branches; the alternate branch is not a normal return path.
- Confirmed AH=87h ordinary path clears CR0.PE and disables A20 before RETF 2; documented early enable failure and exceptional cleanup paths.
- Added A20 helper callers at 528Eh/5291h (two consecutive disables) and F47Eh (POST keyboard initialization).
- Consolidated direct references to 8ACFh/8AD2h/F66Ah/F66Eh, with explicit limits of linear-disassembly xref coverage.


## Semantic map — phase 31 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE31_20261116.md](AMI486_SEMANTIC_MAP_PHASE31_20261116.md)
- Checked all references to CS:[8281h].6: stock byte is zero; no direct static in-ROM write/initializer was found in the full linear decode.
- Connected POST flow 1B58h -> 208Dh -> 20C9h A20 enable -> protected-mode memory-address tests -> 23CBh A20 disable -> 23CEh POST continuation.
- Documented ALi table programming, PIT/port-61 setup, and limits on identifying the upstream entry and chipset register semantics.


## Semantic map — phase 32 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE32_20261116.md](AMI486_SEMANTIC_MAP_PHASE32_20261116.md)
- Separated the CMOS-B3-bit2-selected ALi table at 8E4Eh/8E76h from the independent 8750h–87A4h table at 208Dh.
- Traced port 61h, port 8Fh, PIT control/data writes and the 400h-byte fill preceding the A20-bracketed protected-mode probe.
- Decoded the probe's ordinal alias-test outcomes and packing into ALi indexed registers 10h/11h; left chipset meanings and capacity interpretation unresolved pending independent register documentation.


## Semantic map — phase 33 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE33_20261116.md](AMI486_SEMANTIC_MAP_PHASE33_20261116.md)
- Corrected the CMOS-B3-selected small table ranges to 8E4Eh–8E61h and 8E76h–8E79h.
- Disassembled helper 8DDCh and proved that each small-table word is a direct ALi index/value byte pair written through ports 22h/23h.
- Established that 8750h–87A3h is a separate 21-record, four-byte encoding with a transformed selector and a value byte; entries resolving to selector 26h are skipped.
- Explicitly supersedes the incorrect small-table range/encoding description in phase32.


## Semantic map — phase 34 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE34_20261116.md](AMI486_SEMANTIC_MAP_PHASE34_20261116.md)
- Fully decoded the 21 four-byte records at 8750h–87A3h: 20 ALi indexed writes and one skipped selector (26h).
- Recorded exact effective register indices and values after the BIOS subtracts 30h from byte 0 and uses byte 3 as data.
- Separated confirmed write behavior from unknown ALi register semantics; Project124 mapping remains unverified.


## Semantic map — phase 35 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE35_20261116.md](AMI486_SEMANTIC_MAP_PHASE35_20261116.md)
- Audited ALi indexed read/write helpers (8DCF/8DDC) and their call sites.
- Recovered the CMOS-to-ALi masked read/modify/write mapping in the manual POST configuration path at 1C85h–1DD0h.
- Separated AUTO Config derived-table paths from manual CMOS programming and the later POST A4 stage.
- Documented ALi register 13h/14h shadow-control operations and the CMOS 8Eh C0h configuration gate.


## Semantic map — phase 36 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE36_20261116.md](AMI486_SEMANTIC_MAP_PHASE36_20261116.md)
- Recovered the shared 20-byte row selector at 25C4h, including CMOS B3h bit 2 bank selection, the SMSW CR0-high-byte condition (not a direct PE-bit test), and the special category-5 substitution.
- Traced BDA 0040:E2h to the 8F12h measurement-category routine and documented its eight threshold buckets without assigning unsupported MHz values.
- Mapped four table fields to masked ALi register updates: 2588h→16h, 256Ah→17h, 25A6h→19h, and 2537h→20h.
- Confirmed ALi register 20h bit 3 selects an alternate byte within its table field; hardware meanings of these registers remain unresolved.


## Semantic map — phase 37 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE37_20261116.md](AMI486_SEMANTIC_MAP_PHASE37_20261116.md)
- Recovered the PIT channel-2 measurement: 9096h programs mode 2 with reload 0000h (65536), and 9033h times two generated DIV-instruction stubs.
- Identified the stubs as repeated DIV BX (F7 F3) and DIV BL (F6 F3), each 1000 instructions, and traced the modular elapsed-count difference returned by 8F50h.
- Connected that score to 8F12h's eight BDA performance categories and subsequent ALi table-row selection; left MHz calibration and emulator timing fidelity explicitly unresolved.


## Semantic map — phase 38 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE38_20261116.md](AMI486_SEMANTIC_MAP_PHASE38_20261116.md)
- Recovered the CPU-speed display lookup at 19C2h: categories 0–6 display nominal values 16/20/25/33/40/50/66 with explicit CPU Clock or DX2 CPU MHz labels.
- Confirmed AUTO Config gates the category display; CMOS B3h bit 1 selects the DX2 label and separately controls the base-bank category-5 row substitution in 25C4h.
- Clarified 25C4h +6-bank conditions (CMOS B3h bit 2 OR nonzero CR0 high byte); phase 40 corrects 1A60h: conditional ALi 12h/24h writes occur only when B3h bits 2–3 are both clear and SMSW AH is nonzero.
- Corrected by phase 39: category 7 reads byte 20h at 19C9h and displays 32; whether the overlap with the cache suffix string was intentional remains unresolved.


## Semantic map — phase 39 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE39_20261116.md](AMI486_SEMANTIC_MAP_PHASE39_20261116.md)
- Corrected phase 38: CPU-speed category 7 reads 20h at 19C9h and is displayed as 32 MHz; 19C9h aliases the leading space of the cache suffix string.
- Decoded the L2 cache-size display: ALi register 18h bit 1 gates the line, bits 6:4 select eight little-endian values (32/128/256/512/64/256/512/1024 KB).
- Traced POST A1h's CMOS B3h bits 2–3 selection between two small ALi index/value lists, gated by SMSW AH.
- Kept the intentionality of the data overlap and hardware meanings of ALi register 18h / the B3h-selected lists unresolved.


## Semantic map — phase 40 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE40_20261116.md](AMI486_SEMANTIC_MAP_PHASE40_20261116.md)
- Consolidated direct CMOS B3h bit consumers and both in-ROM writers: bit 7 is recalculated from a strict >0200h comparison; bit 0 is set at the end of the DS scan.
- Catalogued the independent effects of bits 1, 2 and 3 across CPU-speed labels, ALi row selection, small ALi tables, and diagnostic text.
- Corrected phase 38's 1A60h branch polarity: the conditional ALi 12h/24h writes happen only when B3h bits 2–3 are both clear and SMSW AH is nonzero.
- Preserved uncertainty about the intended names of B3h bits 0/7 and the hardware meanings of ALi register operations.


## Semantic map — phase 41 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE41_20261116.md](AMI486_SEMANTIC_MAP_PHASE41_20261116.md)
- Audited direct CMOS B3h write sites: automatic bit-7 recomputation at 11C8h, bit-0 set after the DS scan at 27E8h, and an OR-only update at 8914h capable of setting bit 1.
- Identified Setup/editor selector 575Eh, which returns CMOS index B3h or BAh according to UI state word E19Dh bit 1; the corresponding user-visible label remains unresolved.
- Documented additional B3h bit-2 table selection at 8A2Eh and separated it from the other read-only consumers.
- Explicitly left the stack/caller contract of the 88D3h continuation family unresolved rather than guessing its Setup trigger.


## Semantic map — phase 42 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE42_20261116.md](AMI486_SEMANTIC_MAP_PHASE42_20261116.md)
- Traced the Setup/editor renderer: E19Dh bit 1 selects CMOS index B3h/BAh at 575Eh, consumed by 587Ah; 571Ch decodes packed UI state and 5862h has Setup/menu callers.
- Corrected the Phase 41 open question: 88D3h is not directly called by the Setup renderer; it follows the delay loop at 88CEh, reached via D60Ch. The 8914h CMOS B3h write is a separate continuation.
- Confirmed the local 88FAh–8919h path ORs mask 02h into CMOS B3h only when DL bits 4 and 5 are both set; it never clears existing bits. Exact Setup label and D60Ch caller/register contract remain unresolved.


## Semantic map — phase 43 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE43_20261116.md](AMI486_SEMANTIC_MAP_PHASE43_20261116.md)
- Recovered the sole direct entry to D604h from 5D04h: conditional on BP bit 13, the caller sends 8042 command 60h with data 30h (command-byte programming) before the status branch.
- Corrected the interpretation of D606h: port 64h bit 2 is the 8042 SYS flag, not IBF/busy. SYS=0 reaches the 88CEh delay and 88D3h continuation; SYS=1 branches to 8A04h.
- Narrowed the CMOS B3h bit-1 update to the SYS=0, real-mode, non-special-DH path; (DL AND 30h)=30h ORs bit 1 into B3h. DH=4 selects a separate stack continuation whose full register contract remains unresolved.


## Semantic map — phase 44 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE44_20261116.md](AMI486_SEMANTIC_MAP_PHASE44_20261116.md)
- Audited BP bit 13 at 5CF9h: it is tested but no direct immediate setter is present in the full linear listing. BP bit 12 is a separate test at 5C8Ch; 5D07h clears bit 12, not bit 13.
- The 5CF9h→F651h→F622h 8042 command-byte path does not assign DX/DH/DL; the values used at 88D3h are inherited from an unresolved upstream context.
- Confirmed 1B5Eh and 1B5Fh are RET stubs and do not initialize BP/DX. The relationship of POST's POP BP / AND BP,C000h path to the 5C70h entry remains unproven.


## Semantic map — phase 45 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE45_20261116.md](AMI486_SEMANTIC_MAP_PHASE45_20261116.md)
- Reconstructed stack-crafted control flow around 5BF8h–5C8Ch; 5C70h is not a proven standalone entry point.
- The only direct linear-list transfer into 5BF8h is DA9Fh. The apparent D9E0h–DA9Fh caller block is not reached sequentially from D9D9h, whose 16-bit near JMP wraps to 1AFBh. No static direct entry or stack setup into D9DCh–DA9Fh was found.
- DX=0061h is only a conditional result if the unverified D9E0h alternate block executes; it is not established as the register value at 88D3h. BP bit 13 source remains unresolved.


## Semantic map — phase 46 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE46_20261116.md](AMI486_SEMANTIC_MAP_PHASE46_20261116.md)
- Confirmed direct entries 8408h→D90Dh and 84C8h→D90Dh, plus 86D8h→D8EAh.
- D8EAh path can OR BP bits 3, 4, or 5, but not bit 13. D90Dh is a live CMOS/POST path; it restores DX with POP DX from its crafted stack at D958h and exits through D9D9h→1AFBh, not into DAxx.
- Corrects phase45's overly broad statement about no external entry into D8xx–DAxx; no entry into DA9Fh/D9E0h has been established.


## Semantic map — phase 47 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE47_20261116.md](AMI486_SEMANTIC_MAP_PHASE47_20261116.md)
- Reconstructed DH=4 stack continuation: SP=88EEh; RET at 8930h pops 88F0h and resumes at JNE 88FAh. The branch depends on LAHF after DIV BL, whose flags are undefined, so outcome is CPU/emulator-specific and must not be assumed.
- 8400h has no direct CALL/JMP entry in the linear listing; 84C8h is internal to the 8400h routine. BP bit13 remains unresolved.


## Semantic map — phase 48 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE48_20261116.md](AMI486_SEMANTIC_MAP_PHASE48_20261116.md)
- Reconstructed the stack-crafted path at `5C50–5C58`: the second POP loads SP=`ED0Bh`; the following `OR BP,BP` tests bit 15, not bit 13.
- Resolved the return from the `552A` 32-KiB word-pattern test: the stack word at `5C66` makes RET land at `5C68`, where ZF selects failure at `5C2E` or successful continuation at `5C6A`.
- Confirmed successful continuation initializes ES via LES, DS=`0040h`, SS=`0030h`, SP=`0100h`, then enters the keyboard-controller checks.
- BP bit-13 provenance and an indirect live caller for `8400h` remain unresolved.


## Semantic map — phase 49 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE49_20261116.md](AMI486_SEMANTIC_MAP_PHASE49_20261116.md)
- Corrected the alternate instruction boundary after the `552A` return: successful execution resumes at `5C6A`, not at the linear decode boundary `5C69`. The real path sets ES=`0023h`, DS=`0040h`, SS=`0030h`; no LES executes there.
- Confirmed `5C8C` tests BP bit12 and `5CF9` tests bit13. The keyboard-controller path and `5D07 AND BP,EFFFh` do not set bit13.
- The only direct listed entry into `5BF8` is `DA9F`. Its visible predecessor may set BP bit0; a separate `BP=1` path exits to `F4A5` and does not reach `DA9F`.
- BP bit13 producer/context remains unresolved.


## Semantic map — phase 50 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE50_20261116.md](AMI486_SEMANTIC_MAP_PHASE50_20261116.md)
- Split the 8042 SYS=1 route at D604 from the SYS=0 path through 88CE; traced the real-mode branch through D724 and D74C.
- Confirmed BP is zeroed at D743 before the only listed D74C entry; D74C can set bits 12 and 15, but not bit 13.
- Resolved the stock indirect dispatch at 8A78: CS:[82DA]=19ABh, an alternate entry to JMP DI; the trampoline continues through 8A81 to 8CCD, not 8400h.
- BP bit-13 provenance and any other dynamic entry to 8400h remain unresolved.


## Semantic map — phase 51 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE51_20261116.md](AMI486_SEMANTIC_MAP_PHASE51_20261116.md)
- Traced CMOS 8Fh read/clear at D615–D629 and separated the selector branches at D637/D655.
- Resolved the indexed near-jump operand at D6A2: CS:[SI-2958h] addresses a table based at D6A8h.
- Recorded the first 11 near targets (selectors 0–10); none targets 8400h. Values above 0Ah are range-routed before this table on the examined dispatch path.
- No new BP.13 producer identified; D74C still only sets BP bits 12 and 15 after clearing BP.


## Semantic map — phase 52 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE52_20261116.md](AMI486_SEMANTIC_MAP_PHASE52_20261116.md)
- Corrected phase 51 reachability: selectors 04h/05h are diverted before D6A2; selectors 09h/0Ah have conditional alternate routing.
- Selector 3 -> 5280 restores the saved PUSHAW register frame with POPAW; BP is restored from the frame saved at 5260 in BDA 0040:0067.
- Selector 6 -> 5486 likewise restores BP from that saved frame at 5493, then saves/restores working registers around INT 15h/AH=89h.
- Selector 2 -> F71E explicitly sets BP=7 and enters fatal POST handling; it cannot produce BP.13.
- BP.13 producer remains unresolved; trace the caller/context that populated the PUSHAW frame at 5260.


## Semantic map — phase 53 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE53_20261116.md](AMI486_SEMANTIC_MAP_PHASE53_20261116.md)
- Traced the stack-crafted transfer at 5189h through FA4Eh back to 5190h.
- 5194h tests BP sign (bit 15). The nonnegative branch temporarily sets BP=1 but restores the original BP at 5239h; the negative branch does not modify BP.
- PUSHAW at 525Fh therefore saves the inherited BP value at 5260h, not the temporary BP=1.
- Earlier 5DF7h also tests bit 15 and writes 1234h to BDA 0040:0072 when BP is negative.
- 5F7Dh and 5ECCh set only BP bits 6 and 7. BP.13 producer remains unresolved.


## Semantic map — phase 54 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE54_20261116.md](AMI486_SEMANTIC_MAP_PHASE54_20261116.md)
- Traced the BP value tested at 5CF9h through the crafted memory-test continuations at 5C24h/5C26h and 5C66h/5C68h.
- Both paths converge into the 5C70h keyboard-controller setup without modifying BP; 5C58h tests bit 15, 5C8Ch tests bit 12, and 5CF9h tests bit 13.
- 5CC6h and 5CF0h OR BP,0 are no-ops; 5D07h clears bit 12 only. 5C37h MOV BP,3 is confined to the fatal memory-test error path.
- The BP.13 producer must precede the 5C04h memory test or arrive via an earlier stack restore; DA9Fh -> 5BF8h remains an unproven runtime chain.
- Separated the 546Ch PUSHAW frame from 525Fh: 546Ch is called at 51FEh, 5403h and 541Ah and captures caller-dependent BP.


## Semantic map — phase 55 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE55_20261116.md](AMI486_SEMANTIC_MAP_PHASE55_20261116.md)
- Confirmed the stack-crafted continuation DA9Fh -> 5BF8h -> F5A9h -> RET to 5C04h; SP is explicitly set to 5C02h and the word there is the return IP 5C04h.
- The DAxx PIT/port-61 timing path does not set BP.13. DA29h can set only BP.0; DA95h sets BP=1 only on the fatal-alarm branch.
- External runtime entry into the DAxx timing block remains unknown; no direct CALL/JMP to DA61h or DA9Fh appears in the linear listing.
- 5DBDh saves BP around CALL 1B5Fh and 5DC1h restores it; the RET stub cannot create BP.13.
- Audited early POST BP flag producers at 113Bh, 1141h, 117Fh, 11A1h/11BCh and 145Eh; none sets bit 13. 12D3h–12D4h restores BP then clears bits 0–13 on a separate path.


## Semantic map — phase 56 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE56_20261116.md](AMI486_SEMANTIC_MAP_PHASE56_20261116.md)
- Audited early POST BP status collection: 113Bh/1141h/117Fh/11A1h/11BCh set bits 8–11; the saved value is restored at 12D3h and masked with C000h at 12D4h, discarding bits 0–13 on that path.
- 27D0h sets BP.14 (4000h), not BP.13, and only on the memory-probe failure branch.
- The verified 5C04h–5F7Dh path still has no local producer of BP.13; 5CF9h only tests it.
- The apparent 87xx indirect jumps overlap structured configuration/default data and are not accepted as control-flow edges without runtime/table-base proof.
- Runtime ordering between 12D3h and the DAxx/5Cxx sequence, and the upstream BP stack frame, remain unresolved.


## Semantic map — phase 57 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE57_20261116.md](AMI486_SEMANTIC_MAP_PHASE57_20261116.md)
- 1662h–1676h performs a 16-bit BP bitmap walk using ROR BP,1 and CF, but PUSH BP / POP BP restores the original bitmap before TEST BX,BP. BP.13 is consumed here, not produced.
- 145Eh sets BP.6 on the RTC/time validation failure branch; 1576h–158Fh isolates helper BP changes.
- D743h initializes BP=0; D760h can set bit12; D76Ch can set bit15. D794h/D7F2h/D8B8h set fatal numeric codes 9/6/10. D8DCh/D8EEh/D8F3h set bits3/5/4.
- 2913h–2939h uses BP as a memory-size counter, copies the count to BX, then repurposes BP as a stack-frame pointer.
- No newly audited path writes BP.13. Its producer and the runtime entry into DAxx/5Cxx remain unresolved.


## Semantic map — phase 58 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE58_20261116.md](AMI486_SEMANTIC_MAP_PHASE58_20261116.md)
- The 120Dh CALL 1656h enters the BP bitmap consumer by fall-through: 1656h calls F571h, sets CX=2000h, calls E93Ch, calls F571h, then reaches 1662h.
- 1662h–1675h rotates and consumes all 16 bits of BP, restores BP, then 1676h tests BX against the original bitmap.
- E3ACh jumps to POST entry 10E0h (16-bit IP wrap explains linear target 110E0h). EEE7h PIC setup and F419h checksum helper do not assign BP.
- Early POST writes bits 8–11 only; 11FDh AND BP,7FFFh clears bit15 but preserves bit13. Thus BP.13 is already present at entry 10E0h or was set by an unlocated predecessor.
- 12D3h POP BP / 12D4h AND BP,C000h is cleanup after the bitmap consumer on the 120Dh path, not a pre-consumer clear.
- Upstream BP source before E3ACh and the relation to the later DAxx/5Cxx path remain unresolved.


## Semantic map — phase 59 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE59_20261116.md](AMI486_SEMANTIC_MAP_PHASE59_20261116.md)
- Corrected reset-vector location: the hardware reset vector is at file offset FFF0h and executes LJMP F000:E05B; E05Bh jumps to D604h.
- E000h→E005h→F73Bh is a separate ROM entry, not the hardware reset path. F73Ch copies SP to BP, but no connection to the later BP bitmap path is proven.
- D604h checks 8042 port64 bit2 and branches to 88CEh or 8A04h.
- D724h path clears BP at D743h; D74Ch can set BP.12 and BP.15, not BP.13.
- Relationship between the D604h dispatcher and the E2C6h/E3xx POST route remains unresolved.



## Semantic map — phase 60 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE60_20261116.md](AMI486_SEMANTIC_MAP_PHASE60_20261116.md)
- Corrected the reset-vector analysis: FFF0h contains LJMP F000:E05B; E05Bh jumps to D604h. E000h is a separate code entry, not the reset vector.
- Identified the successful upstream edge into the E3xx POST route: 52C1h → E2C6h → (normal path) E2F7h…E380h → E394h → E3ACh → 10E0h. E2F4h→E382h is a conditional error path.
- PUSHAW at 525Fh saves the incoming BP after temporary BP=1 at 51F4h is undone by POP BP at 5239h; POPAW at 5289h restores it before E2C6h.
- The bitmap BP.13 is therefore already present at 5194h. Its caller/producer and the connection to D604h remain unresolved.



## Semantic map — phase 61 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE61_20261116.md](AMI486_SEMANTIC_MAP_PHASE61_20261116.md)
- Traced the 509Eh–5194h path: it includes CMOS write, F3DB helper, INT 15h/AH=89h, memory-test helpers, and stack-crafted RET into FA4E.
- 5194h tests BP.15 (sign), not BP.13. The nonnegative path temporarily writes BP=1 and restores the prior value at 5239h.
- PUSHAW at 525Fh captures BP after both branches converge; POPAW at 5289h restores it before E2C6h.
- No direct static near CALL/JMP targets into 509Eh, 50E1h, 5189h, 5190h, 5194h, 51F3h, 525Fh, 5280h, or 52C1h were found; simple literal near-offset table words were also absent.
- BP preservation across F3DB, helper calls, and INT 15h/AH=89h remains unproven. The caller and first BP.13 producer remain unresolved.



## Semantic map — phase 62 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE62_20261116.md](AMI486_SEMANTIC_MAP_PHASE62_20261116.md)
- INT 15h/AH=89h dispatches to 933Ah; dispatcher temporarily saves/restores BP as its table index.
- Handler 933Ah, helper F66Ah, and PIC initializer EEEFh do not write BP.
- F3DBh and F419h preserve all general registers through PUSHAW/POPAW.
- Audited memory helpers 5305h, 534Ch, 5371h and 53A6h do not write BP.
- On the successful path, the temporary BP=1 at 51F4h is restored at 5239h. PUSHAW at 525Fh therefore captures the incoming BP value to this block.
- BP.13 was already present at the runtime entry into 509Eh/50A0h; the actual entry/caller and first producer remain unresolved.



## Semantic map — phase 63 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE63_20261116.md](AMI486_SEMANTIC_MAP_PHASE63_20261116.md)
- Found the unique direct near JMP into 509Eh at 5F62h, following calls to 5FD6h and 54E5h.
- Reconstructed the stack-crafted path DA9Fh → 5BF8h → 5C04h → 5F62h → 509Eh.
- No BP.13 producer appears on the successful DAxx/5Cxx path; BP.13 is inherited from an earlier context.
- Corrected a linear-disassembly false positive: the apparent 1B05h SBB BP instruction is skipped stack data because EE94h RET consumes the word at 1B04h and resumes at 1B06h.


## Semantic map — phase 64 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE64_20261116.md](AMI486_SEMANTIC_MAP_PHASE64_20261116.md)
- Early POST 1100h–11C2h sets BP bits9,10,8,11 only; no BP.13 producer found.
- 12D3h–12D4h restores BP then masks with C000h, clearing bits0–13 on that path.
- 145Eh sets bit6; 157Ch/1580h clear bits0,8,15 inside a saved-BP diagnostic frame; 27D0h sets bit14 only.
- 2913h resets BP and uses it as a memory-segment counter.
- D6CEh copies AX through general registers into BP in a stack/register self-test; no edge to DAxx established.
- BP.13 source remains unresolved; likely inherited or dynamically loaded rather than set by an immediate mask in these paths.


## Semantic map — phase 65 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE65_20261116.md](AMI486_SEMANTIC_MAP_PHASE65_20261116.md)
- D9D9 is an unconditional jump to 1AFBh; D9DCh is not its fall-through.
- 1AFBh uses a crafted stack return at 1B04h to resume at 1B06h; 1B58h then transfers to 208Dh.
- The 208Dh/20C6h/20D2h paths use further crafted stack returns; execution resumes at 2098h, 20CCh, and 20DAh.
- 20DAh enters a temporary CR0.PE memory probe; CR0.PE is cleared at 23BDh. MOV BP,3 at 23DEh is error-only.
- No direct decoded branch or static pointer word to plausible DAxx entry addresses was found; DA5Eh/DA61h runtime entry remains unresolved.


## Repository code review — continued (2026-11-16)

- [Project134 continued code/reference review](../PROJECT134_CODE_REVIEW_CONTINUED_20261116.md)
- [Project134 initial code review](../PROJECT134_CODE_REVIEW_20261116.md)
- Updated [project plan](../../docs/PROJECT134_PLAN.md) to separate byte-complete linear disassembly from unfinished semantic CFG/code-data classification and to clarify build evidence.
- Additional 6.27.10 reference files reviewed: MBIOSEQU, DIM, DEVNODE, PCI, PNP, ESCD, DMI and SMB definitions. These describe BIOS data structures/interfaces; they do not establish the target AMI486 hardware inventory or ALi 1429 programming.
- Flagged conflicting BIOS-stack layout notes in MBIOSEQU.EQU and DIM.EQU; treat them as subsystem-specific reference data, not a unified Project134 memory map.


## Semantic map — phase 66 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE66_20261116.md](AMI486_SEMANTIC_MAP_PHASE66_20261116.md)
- Audited the CS-resident pointer slots at 82D8h–82E6h: 82DAh defaults to 19ABh, a JMP DI trampoline used by 8A78h; 82DEh and 82E2h default to RET stubs at 19ADh/19AEh.
- The indirect CALLs at 1C06h and 1C5Eh are therefore no-op callbacks in the stock ROM and cannot produce BP.13 or enter DAxx.
- Runtime patching by unsearched store/copy forms and external hooks remains unproven; next step is a complete write-form audit of these slots.


## Semantic map — phase 67 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE67_20261116.md](AMI486_SEMANTIC_MAP_PHASE67_20261116.md)
- Traced the real caller of callback slot `82E2h`: `12E7h CALL 1C5Eh`; the default callback at `19AEh` is RET.
- Traced the real caller of callback slot `82DEh`: `52A1h CALL 1C06h`, reached when `CS:8281h` bit 6 is clear; the default callback at `19ADh` is RET.
- Confirmed these are separate POST paths and neither default callback supplies BP.13 or a DAxx transfer.
- Runtime patching of the slots and the producer of BP.13 remain unresolved.


## Semantic map — phase 68 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE68_20261116.md](AMI486_SEMANTIC_MAP_PHASE68_20261116.md)
- Reconstructed `8AD5h–8AE6h` as the keyboard-controller reset terminal path: wait on port 64h status, write FEh to port 64h, then halt.
- Confirmed the `527Dh -> 8AD9h` branch is not a normal BIOS callback and does not lead to DA5Eh/DA61h.
- Catalogued direct consumers of `CS:8281h`: D657h, D724h, 8B11h, F06Ah (bit 6) and F43Dh (bit 7).
- No direct store to 8281h was confirmed in the inspected ROM paths; producer/source remains unresolved.
- BP.13 provenance and dynamic entry to DA5Eh/DA61h remain open.


## Semantic map — phase 69 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE69_20261116.md](AMI486_SEMANTIC_MAP_PHASE69_20261116.md)
- Corrected the phase 68 configuration-byte hypothesis: raw ROM offset 8281h is byte 00h in the checked-in image, not an ordinary RAM configuration variable.
- CS-qualified bit-6 tests at D657h, D724h, 8B11h and related sites therefore take their clear-bit paths in the stock ROM.
- The unprefixed read at F06Ah still requires DS-state tracing before equating it with the CS-qualified ROM read.
- The bit-6-set route to the keyboard-controller reset routine is not a stock path through the CS-qualified tests.
- BP.13 provenance and dynamic entry to DA5Eh/DA61h remain unresolved.


## Semantic map — phase 70 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE70_20261116.md](AMI486_SEMANTIC_MAP_PHASE70_20261116.md)
- Re-decoded the alternate entry at F000:F068: CLI; CS-qualified TEST of CS:8281h bit 6; stock value 00h takes JZ to F074.
- F074–F096 is a protected-mode exit trampoline: load CS-relative GDTR/IDTR, set DS/ES/SS=0040h, clear CR0.PE, far-transfer to F000:F090, then jump to reset/POST entry E05Bh.
- This resolves the phase 69 DS question: the read at F068/F06Ah is CS-overridden, not DS-relative.
- Candidate raw relative-branch byte patterns targeting near F068h are not yet confirmed incoming edges because source instruction boundaries have not been established.
- BP.13 provenance and dynamic entry to DA5Eh/DA61h remain unresolved.


## Semantic map — phase 71 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE71_20261116.md](AMI486_SEMANTIC_MAP_PHASE71_20261116.md)
- Confirmed live POST path 156Ah -> 1EC8h -> 2850h; wrapper 1EC8h saves/restores BP around the call.
- 2850h scans memory segments, counts them temporarily in BP, copies the count to BX, then reuses BP as SP; exports memory count via port 81h and BDA 0040:00E0h.
- 296Bh–2996h samples PIT channel 0 through ports 43h/40h around a REP LODSW delay loop.
- This confirmed live routine is distinct from DA5Eh/DA61h; it does not explain persistent BP.13 or establish a DAxx entry.
- Next: classify 299Bh–29EAh RAM helpers and continue independent BP.13 / DAxx entry analysis.


## Semantic map — phase 72 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE72_20261116.md](AMI486_SEMANTIC_MAP_PHASE72_20261116.md)
- Corrected instruction alignment at 2998h: bytes FF E7 are `JMP DI`, dispatching the PIT sampler back to the continuation selected in DI (2911h or 291Bh).
- 299Ah begins a separate DS:SI segment-read routine; no direct near CALL/JMP or literal pointer to 299Ah was found in the raw-image scan.
- 27C7h directly jumps to 29BBh after setting DS=ES=1000h and SP=27CAh. 29BBh is a 55AAh fill/scan/clear test; the all-matching scan loops, mismatch clears and returns.
- The crafted stack makes RET at 29EAh pop 01F1h, an overlapping-code continuation inside the short-JMP displacement at 01F0h.
- 29EDh is directly called from 1A1Dh, 1C72h, 1F4Dh and 23F2h; it calls EE94h with DH=B6h and returns AL bit 0.
- BP.13 provenance and DA5Eh/DA61h dynamic entry remain unresolved.


## Semantic map — phase 73 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE73_20261116.md](AMI486_SEMANTIC_MAP_PHASE73_20261116.md)
- Corrected phase 72: the crafted stack at SP=27CAh makes RET from 29EAh return to 27CCh, not 01F1h; the overlapping-code claim at 01F1h is withdrawn.
- Decoded 29BBh as a two-pass 55AAh/AA55h memory-pattern test. Successful verification returns with ZF=1; mismatch returns with ZF=0. The continuation at 27CCh branches on ZF and sets BP bit 14 (OR BP,4000h) only on failure.
- Corrected 29EDh: MOV AX,B6B6h; CALL EE94h; TEST AL,1; RET. EE94h writes AL to CMOS index port 70h and reads data port 71h. The tested value is CMOS byte B6h bit 0.
- Four direct callers of 29EDh: 1A1Dh, 1C72h, 1F4Dh, 23F2h.
- BP.13 provenance and DA5Eh/DA61h dynamic entry remain unresolved.


## Semantic map — phase 74 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE74_20261116.md](AMI486_SEMANTIC_MAP_PHASE74_20261116.md)
- Decoded CMOS read primitive EE94h (index AL via port 70h, data returned in AL via port 71h) and write primitive EE9Dh (index AL, value AH).
- 29EDh reads CMOS/NVRAM byte B6h and tests bit 0. Four direct consumers: 1A1Dh (JZ 1A60h), 1C72h (JZ 1C86h), 1F4Dh (JZ 1F61h), 23F2h (JZ 23FDh). Bit set enables the respective initialization paths.
- No immediate B6h selector was found at EE9Dh write call sites; dynamic-index writers remain possible and unclassified.
- BP.13 provenance and DA5Eh/DA61h dynamic entry remain unresolved.


## Semantic map — phase 75 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE75_20261116.md](AMI486_SEMANTIC_MAP_PHASE75_20261116.md)
- Identified aligned CMOS scan loops at 17F0h (indices 90h..ADh) and 1810h (starting B4h, skips two indices at BEh, upper bound CS:[82B3h]); both accumulate read bytes in BX and dispatch through JMP DI.
- Classified the EE9Dh raw CALL-site scan as candidates only; overlapping code/data means each must be validated against reachable instruction boundaries.
- Confirmed no CMOS B6h write yet. B6h is still only proven as a read selector in 29EDh.
- Identified additional direct CMOS/I/O paths at 13F8h, 14D0h..1508h, 5E10h..5E30h and 834Fh..8372h for subsequent tracing.
- BP.13 provenance and DA5Eh/DA61h dynamic entry remain unresolved.


## Semantic map — phase 76 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE76_20261116.md](AMI486_SEMANTIC_MAP_PHASE76_20261116.md)
- Resolved CS:[82B3h] = 00E0h. The 1810h CMOS sum loop reads B4h..BDh, skips BEh/BFh, then reads C0h..E0h inclusive; it accumulates bytes in BX and dispatches via JMP DI.
- Confirmed 17F0h separately sums CMOS indices 90h..ADh.
- Corrected phase 75: 14D0h..1518h mixes POST writes to port 80h with CMOS reads. The shown helper calls target EE94h (read), not EE9Dh (write); no CMOS write is proven in this snippet.
- BP.13 at 5CF8h is tested, not produced. 5D08h AND BP,EFFFh clears bit 12. No BP.13 producer found here.
- BP.13 provenance and DA5Eh/DA61h dynamic entry remain unresolved.


## Semantic map — phase 77 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE77_20261116.md](AMI486_SEMANTIC_MAP_PHASE77_20261116.md)
- Identified overlapping alternate entry: 183Ah jumps to 17F3h, the middle byte of aligned `XOR BX,BX` at 17F2h. Keep this decode separate; do not assume it is the CMOS sum loop.
- Identified explicit DI setup and indirect-dispatch candidates around 1837h–1859h. The 184Eh short jump targets the aligned second sum loop at 1810h.
- Correction: calls at 1840h/1847h resolve to EE9Eh, an alternate entry into the CMOS write helper (one byte after EE9Dh). They skip index-select OUT 70h and write the data byte through OUT 71h to the already-selected CMOS index.
- CMOS index-selection state and actual runtime reachability of the overlapping dispatcher remain under investigation.


## Semantic map — phase 78 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE78_20261116.md](AMI486_SEMANTIC_MAP_PHASE78_20261116.md)
- Resolved both DI-selected CMOS sum-loop continuations: the 90h..ADh sum is written as BH:BL to CMOS AEh:AFh; the B4h..BDh plus C0h..E0h sum is written to CMOS BEh:BFh.
- Verified the three CALLs at 183Fh, 1846h and 1853h all target EE9Dh, the complete CMOS write helper (including OUT 70h,AL). These are checksum write-back fields, not just read-only accumulators.
- Corrected phase 77 byte alignment: 1834h is JMP DI; 1836h sets DI=183Bh; 1839h jumps to aligned 17F2h. The second setup at 184Ah jumps to aligned 1810h. Withdrawn phase 77's 17F3h alternate-entry claim and EE9Eh CALL-target claim.
- Stored checksum fields are established; when/how they are validated and which callers refresh them remain open. BP.13 provenance and DA5Eh/DA61h dynamic entry remain unresolved.


## Semantic map — phase 79 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE79_20261116.md](AMI486_SEMANTIC_MAP_PHASE79_20261116.md)
- Corrected the 5D81h..5DA0h interpretation: calls at 5D83h/5D88h target EE93h (RET-only stub), not CMOS read helper EE94h. The block forms a value from immediate BFBEh, swaps bytes to BEBFh, subtracts DI=CS, and writes the result to CMOS BEh:BFh through EE9Dh.
- The update is gated by status bits from AL: bit 5 at 5D5Ah skips the larger initialization block; bits 6/7 at 5D7Eh skip the CMOS write.
- CMOS BEh:BFh therefore has at least two distinct writers: the checksum sum routine (phase 78) and this CS-relative POST value writer. Withdraw the global claim that BEh:BFh is a dedicated checksum field; the checksum routine's local behavior remains confirmed.
- E5DBh status provenance, BEh:BFh readers and writer ordering, BP.13 provenance, and DA5Eh/DA61h dynamic entry remain open.


## Semantic map — phase 80 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE80_20261116.md](AMI486_SEMANTIC_MAP_PHASE80_20261116.md)
- Corrected the phase 79 CALL-target alignment at 5D6Dh..5D99h: calls enter EE94h (CMOS read) and EE9Dh (CMOS write), not EE93h RET stubs.
- Decoded the second BEh:BFh writer: read CMOS[B8h] into DI, clear CMOS[B8h], read CMOS[8Eh] and test bits 6/7; if clear, read CMOS[BEh:BFh], subtract the saved old CMOS[B8h] byte, and write the adjusted word back.
- Withdrawn phase 79's incorrect CS-relative BFBEh interpretation. BEh:BFh has at least two writers (range-sum writer and this conditional adjustment), so its global semantic role and update ordering remain unresolved.
- CMOS[B8h]/[8Eh] provenance, E5DBh status source, BP.13 producer and DA5Eh/DA61h dynamic entry remain open.


- Phase 80 correction: the prelude is `MOV DI,0020h; INC SP; PUSH DS; STOSW; MOV AX,CS; STOSW`; there is no PUSHA at 5D5Fh. The two STOSW stores remain at ES:0020h and ES:0022h.


## Semantic map — phase 81 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE81_20261116.md](AMI486_SEMANTIC_MAP_PHASE81_20261116.md)
- Immediate CMOS[B8h] selector is found only in the 5D6Ah/5D72h pair: read old B8h byte, clear B8h, then conditionally subtract the saved byte from CMOS[BEh:BFh].
- CMOS[8Eh] is a shared status/configuration byte with immediate reads at 121Ah, 1271h, 1338h, 140Eh, 15ACh, 1C64h, 5D78h, 5EDFh, 84D3h, 8630h, 8649h, 8662h and F481h (all to EE94h). Other callsites resolve to EEAAh and need separate decode.
- Corrected 5D54h CALL target: F5DBh (not E5DBh). It starts with TEST AL,01h and accesses keyboard controller ports 64h/60h along its conditional path; caller saves returned AL at DS:0012h and tests bit 5.
- BEh:BFh has multiple writers; update order and semantic meaning remain open. BP.13 producer and DA5Eh/DA61h dynamic entry remain unresolved.


## Corrections after raw-offset revalidation (2026-11-16)

- Phase 80's exact aligned sequence is corrected in its report: it begins at 5D5Ch with `MOV DI,0020h; MOV AX,1E44h; STOSW; MOV AX,CS; STOSW`. The earlier INC SP/PUSH DS and PUSHA interpretations at this location are withdrawn.
- Correct phase80 CALL sites remain 5D6Dh, 5D75h, 5D7Ah, 5D84h, 5D89h, 5D91h and 5D99h; their targets are EE94h/EE9Dh as tabulated in the corrected report. The conditional branch at 5D7Fh targets 5D9Ch.
- Phase 81 keyboard-controller call correction: the CALL is at 5D52h and targets F5D9h (not 5D54h/F5DBh). F5D9h begins with IN AL,64h; caller stores AL at DS:0012h and tests bit 5. The corrected phase81 report replaces the earlier offset/target statement.


## Semantic map — phase 82 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE82_20261116.md](AMI486_SEMANTIC_MAP_PHASE82_20261116.md)
- Classified thirteen immediate CMOS[8Eh] reads through EE94h by their immediate consumer masks: bit 0 at 121Ah/F481h, bit 5 at 1271h, C0h at 1338h/140Eh/1C64h/5D78h/84D3h/8630h/8649h/8662h, D0h at 15ACh, and a compound 8Eh→8Fh path at 5EDFh.
- Several callers use C0h as a gate, but their subsequent branches and helpers differ; this is not evidence that bits 6/7 have one global semantic meaning.
- EEAAh pattern matches at CC87h, CD8Bh and F10Dh are excluded from the EE94h CMOS-read group.
- CMOS[8Eh] writers, indirect B8h/8Eh accesses, BEh:BFh update order, BP.13 producer and DA5Eh/DA61h dynamic entry remain open.


## Semantic map — phase 83 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE83_20261116.md](AMI486_SEMANTIC_MAP_PHASE83_20261116.md)
- Added a direct CMOS[8Eh] read at 834Fh: OUT 70h selects 8Eh, IN 71h returns the byte, and mask C0h gates a table-selected secondary CMOS read.
- CMOS[8Eh] now has at least fourteen confirmed read sites: thirteen through EE94h plus the direct 834Fh access.
- No immediate EE9Dh write-helper call or direct immediate OUT70h/OUT71h write sequence for index 8Eh was found. Register-indexed and data-driven writes remain possible; this is not proof that 8Eh is immutable.
- The CS-relative table walker around 8324h..83F0h and the CMOS[8Eh] writer search remain open.


## Semantic map — phase 84 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE84_20261116.md](AMI486_SEMANTIC_MAP_PHASE84_20261116.md)
- Classified 0000h..00EEh as OEM/signature metadata and copyright/date text; code begins at 00EFh.
- Decoded 00EFh..0235h as a coherent Setup/video presentation routine: INT 10h cursor save/restore, 80h-byte stack buffer, save/restore of DS:E000h, BP-relative record formatting, and a CS-resident callback structure at 0AF5h with indirect CALL AX dispatch.
- Decoded adjacent 0236h..026Eh as a field-edit helper that merges a two-bit field into BP+14h while separately handling bit 3.
- This is a new low-ROM semantic region; 026Fh onward and callback targets remain to be traced. A raw scan found no direct near CALL to 00EFh, but far/pointer/indirect entries are not excluded.


## Semantic map — phase 85 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE85_20261116.md](AMI486_SEMANTIC_MAP_PHASE85_20261116.md)
- Reconstructed the indirect dispatcher at 01EDh..020Dh: record word +0 is copied to BP+00h and feeds the next cursor; word +2 is invoked by CALL AX.
- Callback return CF/ZF controls traversal (JAE adds 4; otherwise JZ re-enters without adding; otherwise exits through 099Dh). This is a flag-controlled threaded structure, not a simple fixed array.
- Following the JAE continuation from 0AF5h yields callback targets 6373h, 63C9h, 641Fh, 6485h, 64E3h, 6541h, 0319h, 0351h, 02DBh, 02F1h, 0236h, 026Fh, then 6373h again.
- The six 63xx handlers share a port/parameter + helper + saved-flags prologue; 0319h/0351h/02DBh/02F1h manipulate BP-relative editor state. Individual field labels and actual callback execution outcomes remain open.


## Semantic map — phase 86 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE86_20261116.md](AMI486_SEMANTIC_MAP_PHASE86_20261116.md)
- Classified the six 63xx callbacks as a shared Setup UI/input family, not independent raw-port handlers.
- Resolved the common alternate entries 656Eh/6573h: select one of two prompt-string bases (75D2h/7625h), call shared display/input helpers, and retry on AH=3Ch/3Dh.
- Resolved 659Bh as a deliberate alternate entry into a display-cell helper at 65A7h; the helper uses INT 10h/AH=02h, AH=08h and AH=09h.
- Identified 65BFh/65C3h as alternate entry modes of a decimal/character validation helper that ultimately calls INT 1Ah/AH=05h. Calendar field labels remain provisional pending string and caller analysis.
- Callback target meanings are not yet individually named; year-like comparisons in 641Fh/6485h and character checks in 64E3h/6541h are recorded as evidence, not final labels.


## Semantic map — phase 87 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE87_20261116.md](AMI486_SEMANTIC_MAP_PHASE87_20261116.md)
- Decoded prompt strings at 75D2h and 7625h: date fields Month/Date/Year and 24-hour Time fields Hour/Minute/Second.
- Definitively identified callbacks 6373h, 63C9h, 641Fh, 6485h, 64E3h and 6541h as Month, Day, Year, Hour, Minute and Second.
- Verified date and time paths use BIOS INT 1Ah RTC services (AH=04h/05h for date and AH=02h/03h for time), plus INT 16h keyboard and INT 10h display services.
- Documented wrap/range evidence: month 1..12, day 1..31, year 1901..2099, hour 00..23, minute/second 00..59.
- Remaining Setup callbacks and helper contracts are still open; no claims are made that the entire Setup editor is complete.


## Semantic map — phase 88 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE88_20261116.md](AMI486_SEMANTIC_MAP_PHASE88_20261116.md)
- Resolved callback 0319h as the high-nibble editor for BP+12h and 0351h as the low-nibble editor; both call the common hexadecimal editor at 0383h.
- Confirmed Fh sentinel handling with fallback storage at BP+19h/BP+1Ah.
- Classified 0383h as a Setup hexadecimal digit editor with scan-code-driven increment/decrement and 0..F digit bounds.
- Flagged callback 02F1h as an overlapping alternate entry (it begins at the second byte of the 02F0h linear instruction); it must be decoded independently.
- 02DBh and 026Fh remain only partially classified; BP+10h/BP+14h semantics are unresolved.


## Project status — paused (2026-11-16)

- User-requested pause recorded in [PROJECT134_PAUSE_CHECKPOINT_20261116.md](PROJECT134_PAUSE_CHECKPOINT_20261116.md).
- Last completed semantic reports: phases 84–88. Latest work resolved the Setup date/time callback family and the two BP+12h hexadecimal-nibble editor callbacks.
- Immediate resume targets: 026Fh, 02DBh, and the overlapping alternate entry 02F1h; then continue the ROM-wide coverage ledger.
- The full 64 KiB BIOS is not yet completely semantically disassembled. BP.13 provenance and dynamic/indirect entry into DA5Eh/DA61h remain open.
- No further work is to be performed until the user explicitly requests resumption.


## Semantic map — phase 89 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE89_20261116.md](AMI486_SEMANTIC_MAP_PHASE89_20261116.md)
- Resolved callback 026Fh as an "Options:" path that tests and updates BP+14h bit 2 through the secondary dispatcher at 05B4h.
- Resolved 02DBh as the high-nibble editor for BP+10h and the overlapping alternate entry 02F1h as the low-nibble editor. Both recompute BP+14h bit 6 based on whether both nibbles are nonzero.
- Preserved unresolved stack/return behavior: 02DBh has no visible local PUSH AX for its POP AX, while 02F1h begins with PUSH CS. The nested 05A4h/05A3h -> 05B4h path and indirect target 0BA5h require further tracing.
- Phase 89's initial 0BA5h table alignment was corrected in its report: 0BA5h is a record offset, and the first 026Fh-selected callbacks are 064Ah or 06AEh. See phases 90–91.


## Semantic map — phase 90 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE90_20261116.md](AMI486_SEMANTIC_MAP_PHASE90_20261116.md)
- Corrected and decoded the secondary linked callback table selected by 026Fh: the bit-2 branches lead first to 064Ah ("Not Installed") or 06AEh, not to a code target at 0BA5h.
- Identified 0644h/064Ah as "Installed"/"Not Installed" prompt entries into 02BAh.
- Mapped the shared list-selection helper at 0749h and five field callbacks (0650h, 066Bh, 068Ah, 069Ch, 06AEh) writing BP+1Bh, BP+1Dh, BP+1Eh, BP+21h and BP+23h.
- Secondary dispatcher 05B4h follows a linked record chain controlled by returned CF/ZF and AH; exact runtime traversal and alternate entries 0745h/0747h remain open.


## Semantic map — phase 91 (2026-11-16)

- [AMI486_SEMANTIC_MAP_PHASE91_20261116.md](AMI486_SEMANTIC_MAP_PHASE91_20261116.md)
- Decoded the shared numeric list-selection editor at 0749h: BIOS text rendering, keyboard navigation, digit entry, and decimal conversion.
- Decoded 080Fh as the decimal parser returning the value in DX and entered-digit count in CX; the callbacks commit their fields only when CX is nonzero.
- Preserved alternate-entry boundaries at 0745h and 0747h; neither is the aligned 0749h entry.
- Remaining: caller-specific AH/CF interpretation, alternate-entry contracts, and exact runtime traversal through the 05B4h linked callback dispatcher.
