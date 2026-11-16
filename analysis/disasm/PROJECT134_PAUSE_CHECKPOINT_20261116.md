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

**No phase 97.** Continue by validating the runtime INT 40h target (C610h is the strong in-ROM floppy handler candidate), decoding FDC command bytes D40Ah–D462h, finding the INT 14h vector source for F900h, identifying chipset registers 10h/11h/16h, and tracing the RTC display callers. The address ledger is still a first-pass classification; whole-ROM semantic coverage is not complete.


## Seeded decode results — 2026-11-16

Generated `analysis/disasm/ami486_candidate_windows_20261116.txt` using Capstone x86-16 from bounded, independent seeds. The script is `tools/disasm_ami486_candidate_windows.py`; near-relative branch/call targets are normalized to 16-bit IP wraparound.

The decoded A000h region is identified as the hard-disk INT 13h handler and ATA service. A95Eh installs F000:A08Dh at INT 13h, saves the old INT 13h vector at INT 40h, installs F000:E845h at INT 76h/IRQ14, and sets INT 41h/INT 46h parameter-table pointers to E401h-based 16-byte records. The embedded A125h prompt is rendered at A847h. This is not the floppy controller: D100h–D5FFh is called by the legacy floppy INT 13h handler at C610h; C8BBh/C936h call D156h DMA setup and C913h reaches the FDC result path. AD00h–AE5Fh is keyboard translation data candidate; AE60h onward enters keyboard/INT 15h handler code.

The A08Dh INT 13h entry forwards DL<80h to INT 40h; A0A0h dispatches selectors 00h–19h through the table at A0F1h–A124h. The prior byte-swapped-table hypothesis is withdrawn. The A000h initial seed itself is not yet proven as a true entry.

No phase 97. Continue with call/branch cross-reference and entry validation for the ATA region, then trace the separate FDC and keyboard paths.


## Storage/dispatch continuation — 2026-11-16

See `analysis/disasm/AMI486_STORAGE_AND_DISPATCH_REGIONS_20261116.md`.

The A000h subsystem is now classified as IDE/ATA hard-disk and boot-sector protection code (01F0h–01F7h, 03F6h), including IDENTIFY DEVICE at AC00h, a 512-byte data-out routine at A406h, and a Y/N “Possible VIRUS” prompt at A847h/A8F4h. The A95Eh stream writes the INT 13h vector slot through ES; ES=0 is not yet proven from the caller.

D100h–D5FFh is a separate FDC/DMA subsystem (03F2h/03F4h/03F5h/03F7h and DMA 0Ch/0Bh/05h/04h). F92Ah–F935h is a six-entry dispatch table; F977h is an overlapping entry in the F936h stream. The generated candidate decode now covers 146 unique bounded code windows plus 6 separately emitted data ranges (152 headers total), with 16-bit near-branch wraparound.

Next: validate the actual incoming vector/caller for F900h, confirm ES provenance at A95Eh, and map full helper boundaries/callers for ATA and FDC. No phase 97.


## INT 13h table correction — 2026-11-16

A100h–A123h is not a separate byte-swapped pointer table. The actual 26-entry native little-endian function table begins at A0F1h and ends at A124h; A100h is inside it. A08Dh is the INT 13h hard-disk handler and forwards DL<80h to INT 40h. See AMI486_STORAGE_AND_DISPATCH_REGIONS_20261116.md.


## INT 13h function-map progress — 2026-11-16

The A0F1h–A124h table is now resolved for the principal standard INT 13h services. Confirmed: AH=02 read sectors (ATA command 20h), AH=03 write sectors (30h), AH=04 verify (40h), AH=05 format track (50h with user prompt), AH=08 drive parameters, AH=09 initialize parameters (91h), AH=0Ah/0Bh read/write long (22h/32h), AH=0Ch seek (70h), AH=0Dh reset, AH=10 ready/status, AH=11 recalibrate (10h), AH=14 diagnostic (90h), AH=15 disk type/capacity (AH=03h and total sectors CX:DX). Unsupported selectors route to A18Eh; AH=19h remains unresolved. See AMI486_STORAGE_AND_DISPATCH_REGIONS_20261116.md.


## INT 13h handler progress — 2026-11-16

A08Dh/A0A0h is now mapped as the hard-disk INT 13h handler and AH dispatcher. The table at A0F1h has 26 entries. Main functions: read sectors AH=02h (ATA 20h / REP INSW), write sectors AH=03h (30h / REP OUTSW), verify AH=04h (40h), format AH=05h (50h plus Y/N warning), get parameters AH=08h, initialize AH=09h (91h), read/write long AH=0Ah/0Bh (22h/32h), seek AH=0Ch (70h), reset AH=0Dh, ready AH=10h, recalibrate AH=11h (10h), diagnostics AH=14h (90h), disk type/capacity AH=15h. Detailed entry-to-return map is in AMI486_STORAGE_AND_DISPATCH_REGIONS_20261116.md.


## FDC/DMA follow-up — 2026-11-16

See AMI486_FDC_DMA_SUBSYSTEM_20261116.md. D156h programs DMA channel 2; D243h and D294h implement FDC FIFO command/result byte exchange; D270h collects result blocks; D2FDh issues Sense Interrupt Status 08h; D348h resets the controller; D3B5h reads CMOS floppy type register 10h; D499h performs a three-attempt FDC command/result transaction. D40Ah–D462h command sequences and the runtime INT 40h segment:offset remain open; C610h is the strong matching floppy handler candidate.


## Keyboard subsystem follow-up — 2026-11-16

See AMI486_KEYBOARD_SUBSYSTEM_20261116.md. The AD00h–AE5Fh keymap data is followed by scan-code processing at AE6Fh (INT 15h AH=4Fh), E0h/E1h prefix tracking, modifier/lock state updates, 8042 commands ADh/AEh/EDh/F3h/F4h, BIOS ring-buffer insertion/dequeue, and an INT 16h dispatcher at B3E2h. AH=00/01/02/03/05/10/11/12 paths are mapped; exact flag contracts remain to be verified.


## INT vector and parameter-table wiring — 2026-11-16

A95Eh replaces INT 13h with F000:A08Dh and saves the old INT 13h vector at the INT 40h slot; A08Dh forwards DL<80h requests to INT 40h. It installs IRQ14/INT 76h at F000:E845h and configures INT 41h/INT 46h fixed-disk parameter table pointers into 16-byte records at E401h, selected via CMOS 92h/99h/9Ah. E845h sends EOIs to both PICs and calls INT 15h AX=9100h. See AMI486_STORAGE_AND_DISPATCH_REGIONS_20261116.md.


## Legacy floppy INT13 path — 2026-11-16

C610h is the matching in-ROM floppy INT 13h handler candidate. It accepts AH=00h–05h, 08h and 15h–18h through the 11-entry table at C5FAh. Its code directly reaches D156h DMA setup and the D100h–D5FFh FDC routines. A95Eh saves the old INT13 vector in INT40; A08Dh forwards DL<80h there. Runtime INT40 offset:segment still needs capture, but the code path strongly supports the floppy chain. See AMI486_FDC_DMA_SUBSYSTEM_20261116.md.


## Memory/chipset initialization follow-up — 2026-11-16

See AMI486_MEMORY_CHIPSET_INITIALIZATION_20261116.md. The memory probe compares patterns at 8 MiB, 64 MiB and 2/4/8 KiB offsets, then uses stack-threaded RET continuations into 8DCFh/8DDCh indexed I/O helpers for ports 22h/23h. Confirmed updates: register 16h OR 30h, register 11h = 44h; another path updates 10h/11h and clears CR0.PE before F66Eh. Do not infer RAM capacity or chipset vendor yet.


## RTC and text-rendering follow-up — 2026-11-16

See AMI486_CLOCK_AND_TEXT_RENDERING_20261116.md. The 6774h and 67AEh routines call INT 1Ah AH=04h/AH=02h for RTC date/time. 6700h calls the 6805h numeric grid renderer; 6841h prints decimal, 68B0h prints hexadecimal bytes, and 6860h/68C8h use INT 10h character/attribute services. Exact UI entry and field contracts remain open.


## Address-ledger reconciliation — 2026-11-16

The address ledger is present as a first-pass reference map; it is not yet the complete per-byte semantic classification. Corrected its gap count to 103 pages (153 referenced + 103 without explicit phase-address tokens = 256). The candidate listing now contains 146 code windows and 6 data windows; their distinct union is 8,618 bytes across 46 pages, not a semantic-coverage percentage. The master linear listing already covers the entire 64-KiB ROM, so do not regenerate a duplicate linear decode. Continue with CFG, data/code boundaries and unresolved caller/vector contracts.


## Serial BIOS follow-up — 2026-11-16

See AMI486_INT14_SERIAL_BIOS_20261116.md. F900h is a six-function IRET dispatch wrapper strongly matching BIOS INT 14h. F936h initializes UART baud divisor and LCR; F986h transmits; F9C4h receives; F977h reads LSR/MSR; F999h/F9D3h configure modem-control outputs. DX-relative register offsets match a 16550-compatible UART. The actual vector installation remains unresolved.


## INT 14h service mapping confirmed — 2026-11-16

F900h implements the BIOS INT 14h serial service family. AH=00h initializes the UART with baud divisors 0417/0300/0180/00C0/0060/0030/0018/000C for 110–9600 baud; AH=01h transmits; AH=02h receives; AH=03h reads LSR/MSR; AH=04h/05h control modem outputs. The IVT entry/caller remains open. Full report: AMI486_INT14_SERIAL_BIOS_20261116.md.


## FDC DMA direction — 2026-11-16

The caller mode bytes resolve DMA direction: C8BBh passes 46h (memory-to-FDC write), while C936h/C913h pass 4Ah (FDC-to-memory read). Both use 8237 DMA channel 2 in single-transfer mode. Remaining FDC work is the command sequence at D40Ah–D462h and runtime INT40 vector capture.


## INT 14h wrapper correction — 2026-11-16

The F9xx serial dispatcher entry was byte-aligned again against the generated Capstone window. Correct candidate entry: F8E7h (83 FA 04), not F900h or F8E8h. DX is the COM-port index 0..3; the wrapper reads the COM base word from BDA 0040:0000+2*DX and the timeout byte from 0040:007Ch+DX. The valid path begins at F8F2h; AH selects one of six UART handlers via F92Ah. The common cleanup CALL is F926h, IRET F929h, and table F92Ah–F935h. F900h is the last displacement byte of MOV DX,[DI+0000h], not a function entry. The generator output now verifies F8E7h–F929h. The INT 14h vector installation/caller remains unresolved.


## Candidate-window refresh — 2026-11-16

The generated candidate listing now contains 189 code windows plus 6 data windows (195 headers total). Their distinct union is 10,493 bytes across 54 pages; this is not a semantic coverage percentage. The F9xx serial window is aligned at F8E7h–F929h, with F92Ah–F935h emitted as the handler table. The INT 14h vector source remains open.
