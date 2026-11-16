# Project134 / ami486.bin — checkpoint and pause (2026-11-16)

## Status

**Work paused at the user's request.** No further ROM analysis, source edits, or report generation should be performed unless the user explicitly asks to resume.

Target: `ami486.bin` in `JTCyborg/Project134`, branch `main`. The work is semantic reverse engineering of the 64 KiB AMI486 BIOS image, including instruction-boundary verification, alternate entries, indirect control flow, helper routines, and cross-references.

## Last completed work

The latest completed reports are phases 84–88:

- `AMI486_SEMANTIC_MAP_PHASE84_20261116.md` — low-ROM region and Setup UI/editor entry points.
- `AMI486_SEMANTIC_MAP_PHASE85_20261116.md` — indirect callback dispatcher at 01EDh..020Dh and callback record chain beginning at 0AF5h.
- `AMI486_SEMANTIC_MAP_PHASE86_20261116.md` — shared UI/input/display helper family for callbacks 6373h..6541h.
- `AMI486_SEMANTIC_MAP_PHASE87_20261116.md` — decoded prompt strings and identified the six date/time callbacks:
  - 6373h Month
  - 63C9h Day
  - 641Fh Year
  - 6485h Hour
  - 64E3h Minute
  - 6541h Second
  Their paths use BIOS INT 1Ah RTC services, INT 16h keyboard services, and INT 10h display services.
- `AMI486_SEMANTIC_MAP_PHASE88_20261116.md` — callbacks 0319h and 0351h edit the high and low nibbles of BP+12h via common hexadecimal editor 0383h. Fh sentinel paths use BP+19h/BP+1Ah.

The phase 84–88 reports and the updated `DISASM_INDEX.md` were fetched from GitHub after writing and verified present on `main`.

## Exact stopping point / next unfinished items

If work is resumed, start from these items rather than repeating the completed CMOS 8Eh scans or redoing phases 84–88:

1. Resolve callback 026Fh and its dispatch/table around 0280h..02A5h.
2. Decode callback 02DBh and the BP+10h/BP+14h state it manipulates.
3. Decode 02F1h as the aligned low-nibble callback entry. The short jump is at 02EFh (EB 0E), its displacement is at 02F0h, and 02F1h begins MOV AL,[BP+10h]. The 02DBh high-nibble path jumps to shared code at 02FFh.
4. Trace shared helpers 05E0h/05EEh, 08C8h/08CDh and the date/time helper paths only where needed to close the Setup callback contracts.
5. Resume the ROM-wide range coverage ledger. The full 64 KiB BIOS is **not** completely semantically disassembled; no whole-ROM completion percentage was established.

## Known unresolved questions carried forward

- Meaning of the configuration byte at BP+12h and the BP+10h/BP+14h pair.
- Exact runtime traversal outcomes of the indirect callback table; the static record chain alone does not prove every callback executes on each Setup visit.
- Exact helper contracts for 05E0h/05EEh, 08C8h/08CDh, 6774h, 67AEh and the RTC update helper around 6616h.
- Earlier open POST/control-flow questions remain open: producer of BP.13 and dynamic/indirect entry into DA5Eh/DA61h.
- The earlier reports explicitly superseded/corrected in later phases must remain treated as superseded; in particular phase 77 by phase 78, phase 79 by phase 80, and the corrections recorded in phases 73–83.

## Working rules for resumption

- Verify raw bytes and exact instruction alignment before assigning semantics.
- Treat pattern hits and static pointer candidates as candidates until reachability/entry is demonstrated.
- Preserve alternate-entry and overlapping-instruction annotations.
- Do not infer hardware meanings from port numbers or CMOS indices without caller/context evidence.
- Keep the user's project architecture constraints in mind where relevant; this task concerns BIOS ROM analysis, not implementation on real hardware.


## Post-resumption raw-offset correction (phases 89–91)

The pause checkpoint's note that 02F1h was inside an instruction beginning at 02F0h was off by one byte. The short jump is at 02EFh (`EB 0E`), its displacement is at 02F0h, and 02F1h is an aligned low-nibble callback entry (`8A 46 10`). The 02DBh high-nibble path jumps to shared code at 02FFh. Both paths call 05A3h and share a balanced `PUSH AX` / `POP AX; POPF; RET` sequence. See corrected phase-88 and phase-89 reports and phase-90/91 reports for the resumed analysis.


## Cross-phase audit update — phases 1–96 (2026-11-16)

The user explicitly requested a cross-phase audit before any further disassembly. All 96 phase report files were found in the recursive repository tree and reviewed at document level. The audit report is:
- `analysis/disasm/AMI486_PHASES_1_96_AUDIT_20261116.md`

Important byte-verified corrections committed:
- Phase 60: ROM size corrected from 65,534 to 65,536 bytes; reset-vector offset label corrected to FFF0h.
- Phases 92/94/95: false claim that 05E0h is a RET stub withdrawn. Raw bytes at 05E0h are `50 52 BA 03 12 E8 5D 02 5A 58 C3`, i.e. PUSH AX / PUSH DX / MOV DX,1203h / CALL 0845h / POP DX / POP AX / RET. The separate 05EBh entry remains the dispatcher exit call target.
- DISASM_INDEX: stale 5D54h -> F5DBh statement corrected; aligned caller is 5D52h -> F5D9h. Master-listing decoder metadata clarified: Capstone x86 16-bit; historical listing metadata kept separate.
- Phases 72, 77 and 79 now explicitly mark the findings superseded by phases 73, 78 and 80/81 respectively.

The checked-in ROM is 65,536 bytes, SHA-256 `91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b`. The generated linear listing covers 0000–FFFF byte-for-byte, but there is still no complete semantic code/data/overlap/unresolved byte ledger and no defensible semantic completion percentage.

**Phase 97 has not been started.** The next task is the ROM-wide address ledger and cross-reference reconciliation, selecting work by uncovered or ambiguous byte ranges rather than by phase number. BP.13 provenance, DA5Eh/DA61h runtime entry, optional OEM table provenance, and raw overlapping targets 9CE8h/01F2h/46E8h remain unresolved.


## Address-ledger continuation — 2026-11-16

First-pass page ledger created at `analysis/disasm/AMI486_ADDRESS_LEDGER_20261116.md`. The narrow explicit-address scan finds references in 153/256 pages and no matching `hhhh` token in 103 pages; neither number is a semantic coverage percentage.

Raw-byte sampling shows that several pages with no phase-address tokens contain code candidates, especially 2100h, 6800h, A000h–ACFFh, AE60h–AFFFh, D100h–D5FFh and F900h. A000h–AFFFh is mixed: the Format/BootSector Write/Possible VIRUS message is embedded at A125h–A18Dh; the INT 13h handler at A08Dh dispatches AH through a 26-entry little-endian table at A0F1h–A124h; AD00h–AE5Fh contains keyboard translation data candidates. D100h–D5FFh contains I/O code candidates referencing ports 03F4h/03F7h.

**No phase 97.** Continue by resolving the A000h mixed subsystem and its D100h controller callers, then trace 2100h and F900h. The address ledger remains a first-pass index; exact semantic coverage is still unknown.


## Seeded decode results — 2026-11-16

Generated `analysis/disasm/ami486_candidate_windows_20261116.txt` using Capstone x86-16 from bounded, independent seeds. The script is `tools/disasm_ami486_candidate_windows.py`; near-relative branch/call targets are normalized to 16-bit IP wraparound.

The decoded A000h region is now identified as IDE/ATA hard-disk service and boot-sector protection code (ports 01F0h–01F7h), including 512-byte PIO transfer at A406h and an INT 13h vector-hook candidate at A95Eh. The embedded A125h prompt is rendered at A847h. This is not the floppy controller: D100h–D5FFh independently accesses ports 03F4h/03F7h. AD00h–AE5Fh is keyboard translation data candidate; AE60h onward enters keyboard/INT 15h handler code.

The A08Dh INT 13h entry forwards DL<80h to INT 40h; A0A0h dispatches selectors 00h–19h through the table at A0F1h–A124h. The prior byte-swapped-table hypothesis is withdrawn. The A000h initial seed itself is not yet proven as a true entry.

No phase 97. Continue with call/branch cross-reference and entry validation for the ATA region, then trace the separate FDC and keyboard paths.


## Storage/dispatch continuation — 2026-11-16

See `analysis/disasm/AMI486_STORAGE_AND_DISPATCH_REGIONS_20261116.md`.

The A000h subsystem is now classified as IDE/ATA hard-disk and boot-sector protection code (01F0h–01F7h, 03F6h), including IDENTIFY DEVICE at AC00h, a 512-byte data-out routine at A406h, and a Y/N “Possible VIRUS” prompt at A847h/A8F4h. The A95Eh stream writes the INT 13h vector slot through ES; ES=0 is not yet proven from the caller.

D100h–D5FFh is a separate FDC/DMA subsystem (03F2h/03F4h/03F5h/03F7h and DMA 0Ch/0Bh/05h/04h). F92Ah–F935h is a six-entry dispatch table; F977h is an overlapping entry in the F936h stream. The generated candidate decode now covers 69 bounded seeds with 16-bit near-branch wraparound.

Next: validate the actual incoming vector/caller for F900h, confirm ES provenance at A95Eh, and map full helper boundaries/callers for ATA and FDC. No phase 97.


## INT 13h table correction — 2026-11-16

A100h–A123h is not a separate byte-swapped pointer table. The actual 26-entry native little-endian function table begins at A0F1h and ends at A124h; A100h is inside it. A08Dh is the INT 13h hard-disk handler and forwards DL<80h to INT 40h. See AMI486_STORAGE_AND_DISPATCH_REGIONS_20261116.md.
