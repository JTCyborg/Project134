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
