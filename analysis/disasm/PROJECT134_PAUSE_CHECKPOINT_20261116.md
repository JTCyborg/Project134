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

**No phase 97.** Continue by verifying ES=0000h at A95Eh's caller and capturing the displaced INT 13h vector copied into INT 40h (C610h is only a strong in-ROM candidate), tracing the remaining low-nibble [BX+90h] FDC state fields, capturing the runtime INT 14h IVT slot for F8E7h, identifying chipset registers 10h/11h/16h, and tracing the RTC display callers. The address ledger is still a first-pass classification; whole-ROM semantic coverage is not complete.


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

See AMI486_FDC_DMA_SUBSYSTEM_20261116.md. D156h programs DMA channel 2; D243h and D294h implement FDC FIFO command/result byte exchange; D270h collects result blocks; D2FDh issues Sense Interrupt Status 08h; D348h resets the controller; D3B5h reads CMOS floppy type register 10h; D499h performs a three-attempt FDC command/result transaction. D40Ah–D462h is now understood as data-rate/state-token selection feeding a D499h MFM READ ID transaction; D520h–D5D9h performs VERSION/DUMPREG/UNLOCK/CONFIGURE/PERPENDICULAR/LOCK setup. Remaining gaps are low-nibble state-token semantics and the runtime INT 40h segment:offset (it is copied dynamically from the previous INT 13h vector by A95Eh); C610h remains a strong in-ROM candidate but is not proven as that runtime target.


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

The address ledger is present as a first-pass reference map; it is not yet the complete per-byte semantic classification. Corrected its gap count to 103 pages (153 referenced + 103 without explicit phase-address tokens = 256). The candidate listing now contains 168 code windows and 18 data windows; their distinct union is 10,700 bytes across 56 pages, not a semantic-coverage percentage. The master linear listing already covers the entire 64-KiB ROM, so do not regenerate a duplicate linear decode. Continue with CFG, data/code boundaries and unresolved caller/vector contracts.


## Serial BIOS follow-up — 2026-11-16

See AMI486_INT14_SERIAL_BIOS_20261116.md. F900h is a six-function IRET dispatch wrapper strongly matching BIOS INT 14h. F936h initializes UART baud divisor and LCR; F986h transmits; F9C4h receives; F977h reads LSR/MSR; F999h/F9D3h configure modem-control outputs. DX-relative register offsets match a 16550-compatible UART. The actual vector installation remains unresolved.


## INT 14h service mapping confirmed — 2026-11-16

F8E7h is the guarded BIOS INT 14h serial-dispatch candidate. AH=00h initializes the UART with baud divisors 0417/0300/0180/00C0/0060/0030/0018/000C for 110–9600 baud; AH=01h transmits; AH=02h receives; AH=03h reads LSR/MSR; AH=04h/05h control modem outputs. The IVT entry/caller remains open. Full report: AMI486_INT14_SERIAL_BIOS_20261116.md.


## FDC DMA direction — 2026-11-16

The caller mode bytes resolve DMA direction: C8BBh passes 46h (memory-to-FDC write), while C936h/C913h pass 4Ah (FDC-to-memory read). Both use 8237 DMA channel 2 in single-transfer mode. Remaining FDC work is the command sequence at D40Ah–D462h and runtime INT40 vector capture.


## INT 14h wrapper correction — 2026-11-16

The F9xx serial dispatcher entry was byte-aligned again against the generated Capstone window. Correct candidate entry: F8E7h (83 FA 04), not F900h or F8E8h. DX is the COM-port index 0..3; the wrapper reads the COM base word from BDA 0040:0000+2*DX and the timeout byte from 0040:007Ch+DX. The valid path begins at F8F2h; AH selects one of six UART handlers via F92Ah. The common cleanup CALL is F926h, IRET F929h, and table F92Ah–F935h. F900h is the last displacement byte of MOV DX,[DI+0000h], not a function entry. The generator output now verifies F8E7h–F929h. The INT 14h vector installation/caller remains unresolved.


## Candidate-window refresh — 2026-11-16

The generated candidate listing now contains 168 code windows plus 18 data windows (186 headers total). Their distinct union is 10,700 bytes across 56 pages; this is not a semantic coverage percentage. The F9xx serial window is aligned at F8E7h–F929h, with F92Ah–F935h emitted as the handler table. The INT 14h vector source remains open.


## FDC command-sequence update — 2026-11-16

D499h is now identified as a three-attempt MFM READ ID transaction: command 4Ah plus drive/head, followed by seven result bytes. D40Ah–D462h supplies data-rate tokens for 03F7h and per-drive state values, not command opcodes. D520h–D5D9h probes an enhanced 765-compatible FDC (VERSION 10h returns 90h), reads DUMPREG, unlocks FIFO config, sends CONFIGURE 13h with 00 08 00, sets PERPENDICULAR MODE 12h, then locks the configuration. Still open: low-bit [BX+90h] meanings, the runtime INT 40h vector.


## FDC drive-type state-machine refinement — 2026-11-16

D3B5h checks CMOS 0Eh bits C0h and, when clear, extracts the selected nibble from CMOS 10h. D3CFh maps normal drive types to READ ID data-rate probes: type 1 selects 250-kbps code 2; type 2 tries 0/1; type 3 tries 0/2; type 4/default tries 3/0/2. The CMOS 0Eh alternate path D46Dh tries 0/1/2/3. D3FAh establishes [BX+90h] bit 4 as success and bits 7:6 as rate code. Caller C84Bh invokes D3CFh when bit 4 is clear; C855h maps D7h/17h/other tokens to SPECIFY command bytes 03 AF 02 / 03 BF 02 / 03 DF 02. Remaining low-nibble semantics and the meaning of CMOS 0Eh C0h remain open.


## INT 40h dynamic vector chain — 2026-11-16

A95Eh installs CS:A08Dh at INT 13h and copies the displaced INT 13h offset:segment to INT 40h at ES:0100h/0102h. A08Dh forwards floppy DL<80h requests through INT 40h. Thus INT 40h is the prior INT 13h handler, not a hardcoded C610h address. A95Eh's direct caller is 134Eh; the routine does not set ES=0000h itself, so the caller's ES precondition must be proven. EC59h JMPs to C610h, making C610h a strong candidate, but the runtime vector remains unverified.


## D4EAh rate-field confirmation — 2026-11-16

D4EAh independently confirms [0090h+drive] bits 7:6 as the per-drive data-rate selector. It compares them with global [008Bh], updates the global rate cache when changed, converts the selector to bits 1:0 and writes it to port 03F7h through D517h. Remaining [BX+90h] low-nibble meanings are still open.


## CMOS perpendicular-mode source resolution — 2026-11-16

EEAAh is a protected CMOS read wrapper around EE94h (port 70h selector, port 71h data). D5A1h reads CMOS 0Eh; bit 7 (RTC power lost) or bit 6 (checksum invalid) suppresses drive-specific perpendicular flags. Otherwise it reads CMOS 10h; drive A high nibble type 05h sets parameter bit 2, drive B low nibble type 05h sets bit 3. The resulting byte is sent with PERPENDICULAR MODE 12h. EEAAh source is no longer an open question; low-nibble [BX+90h] semantics and the CMOS 0Eh fallback behavior is mapped.


## A95Eh caller/ES provenance — 2026-11-16

A95Eh is called at 134Eh inside function 131Fh, itself called from 1BAAh. The 1BAAh caller does not initialize ES. 131Fh is an alternate entry into a separate instruction stream; it checks CMOS 0Eh/92h and calls A95Eh at 134Eh. The ES=0000h setup at 1303h belongs to a different preceding linear stream and is bypassed by the 131Fh entry. The 1BAAh caller does not initialize ES, so the IVT write remains conditional on inherited ES=0000h, which is not yet proven. Candidate windows now include 131Fh–1364h. INT 40h remains a dynamic copy of the previous INT 13h vector, not a hardcoded C610h target.


## 131Fh alternate-entry/ES correction — 2026-11-16

The call at 1BAAh enters 131Fh, an overlapping stream that reaches A95Eh at 134Eh after CMOS checks. It does not execute the separate linear stream's ES=0000h setup at 1303h. Therefore ES=0000h remains unproven at A95Eh; the vector copy is conditional until a runtime IVT/ES trace confirms it.


## Candidate-window / CMOS status refresh — 2026-11-16

Generated candidate listing: 168 code windows + 18 data ranges; 10,700-byte union across 56 pages. The direct-call alternate entry at 131Fh is included through 1364h. CMOS 0Eh bit 7/6 gating and EEAAh CMOS reads are mapped; remaining FDC token uncertainty is the low nibble of [BX+90h].


## INT 14h vector-reference scan — 2026-11-16

No direct near CALL/JMP xref, literal F8E7h word reference or far pointer F000:F8E7h was found in the 64-KiB ROM. The F8E7h UART dispatcher remains an INT 14h-style candidate, not a proven installed IVT target; runtime IVT slot 0000:0054h/0056h capture is required.


## 2100h memory-alias entry correction — 2026-11-16

The 2100h code is a memory-alias probe with stack-threaded chipset register updates (see AMI486_MEMORY_CHIPSET_INITIALIZATION_20261116.md). The exact initial bytes include STOSB at 2106h and 2107h; the earlier address-ledger byte excerpt omitted them and is corrected. No direct near CALL/JMP target or literal F000:2100h far pointer exists; caller and initial DS/ES/DI/AL remain open.


## Continuation update — Setup editor and POST summary regions (2026-11-17)

Two previously under-described regions now have byte-backed reports:

- `analysis/disasm/AMI486_SETUP_EDITOR_RENDERING_EXTENSION_20261117.md`: extends phase 12 through 10DEh; confirms event-code dispatch at 0D84h, previous/next helpers at 0E19h/0E47h, item renderer at 0E7Ch and option-list renderer at 0EE2h–10DEh. E18Ch is the absolute selected-record index; E185 is the viewport row.
- `analysis/disasm/AMI486_POST_SUMMARY_DISPLAY_20261117.md`: maps POST summary display from 3F4Ah/3F7Bh, CPU identification at 4142h, numeric processor/Weitek path at 41E4h/421Eh, device formatting and the box-drawing/string data at 4231h–45FFh.
- Setup pointer-table boundaries are now separated: short caption pointers 318Ch–31A3h (12 entries), long-description pointers 342Eh–3443h (11 entries), extra no-write pointer 3444h, handler pointers 3446h–345Bh (11 entries).
- Candidate generator: 187 seeded code windows, 35 deduplicated data ranges, 15,639-byte union across 79 pages (sampling footprint only; not semantic completion).

**Phase 97 remains unstarted.** The next work is still to classify uncovered/ambiguous byte ranges, trace indirect entries and validate alternate streams. Work selection must be driven by the address ledger, not phase-number progression.


## Address-ledger continuation — 2026-11-17

The Capstone candidate generator has been expanded: 386 code windows, 74 data ranges. Recomputed candidate footprint is 35,960/65,536 bytes (54.87%) across 169 pages, comprising 22,989 unique code-window bytes, 13,084 unique data-range bytes and 113 overlap bytes. This is a sampling footprint only, not semantic coverage.

New text/table classifications are documented in AMI486_ADDRESS_LEDGER_20261116.md section 11. The 2D11h timing benchmark is now an aligned candidate window; its runtime entry and stack precondition remain unresolved. The next step remains range-driven reconciliation of unclassified bytes and alternate entries, not a numbered phase.


## Low-ROM range investigation — 2026-11-17

0000h–00EEh is now classified as AMI BIOS identity/copyright/pattern data. 00EFh begins an executable-looking stream with an INT 10h call and stack-frame setup, but no direct ROM CALL/JMP target or literal 00EFh pointer was found. Its runtime entry and DS:E000h source block remain unresolved. The candidate generator was first updated to seed 00EFh–01EEh; that interim window was subsequently extended through 0235h and regenerated. See the final report AMI486_LOW_ROM_SETUP_VIDEO_ENTRY_20261117.md.


The low-ROM 00EFh candidate seed is generated through 0235h, including the aligned RET. The generated listing and manifest are verified; current byte-mask totals are recorded in this checkpoint's latest update.


## Low-ROM screen-presentation decode completed — 2026-11-17

The generated candidate window 00EFh–0235h is now byte-aligned through RET. The report AMI486_LOW_ROM_SETUP_VIDEO_ENTRY_20261117.md documents the display/cursor preservation path and the 0AF5h callback-record walker. No direct near CALL/JMP entry or literal 00EFh pointer was found; incoming stack convention remains unresolved.

Current generated candidate footprint: 386 code windows, 74 data ranges, 22,989 unique code-window bytes, 13,084 unique data-range bytes, 113 overlap bytes, 35,960-byte union (54.87%) across 169 pages. This remains a sampling footprint, not semantic completion.


## Temporary IVT/calendar refresh — 2026-11-17

Report: AMI486_TEMPORARY_IVT_CALENDAR_REFRESH_20261117.md. 626Bh installs temporary INT 10h/1Ah/1Ch handlers; 62BDh restores the previous vectors. INT 1Ch uses BDA ticks and an active-handler counter to trigger 6616h calendar refresh when safe. Raw 6616h code is verified through RET at 6757h; the generator source requests a 0142h window, but the generated listing now includes 6616h–6757h (0142h bytes).


## Disassembler alias correction — 2026-11-17

Found 31 candidate-window lines where Capstone's 16-bit output mislabeled unprefixed opcode 98h as CWDE and 99h as CDQ. Correct mnemonics are CBW and CWD. Both the candidate generator and full linear workflow have been patched to normalize those exact byte sequences. Await generated-artifact verification before treating the correction as complete.


## 16-bit CBW/CWD correction verified — 2026-11-17

Both generator paths were patched. The regenerated candidate listing has zero CWDE/CDQ labels; bare 98h/99h are emitted as CBW/CWD. The full-linear listing blob changed after the workflow update; the manifest remains at 29,731 records and 65,536/65,536 byte coverage.


## Screen-renderer helper map — 2026-11-17

Report: AMI486_SCREEN_RENDERER_HELPERS_20261117.md. The 562Bh–566Ah table is a 16-entry attribute palette; F2/F3 cycles it and 5821h applies the chosen attributes to the text screen. 04B0h computes HDD size from geometry and rounds to MiB; 0A15h renders numeric fields with KB/MB suffixes. The new palette table is included in the 58-range data map.


## Continued address-ledger work — 2026-11-17

New byte-backed region reports:
- analysis/disasm/AMI486_ADDRESS_LEDGER_REGION_4628_55A7_20261117.md — hard-disk Setup utility, bad-track editor and POST memory test.
- analysis/disasm/AMI486_ADDRESS_LEDGER_REGION_8E89_93F7_20261117.md — timing classifier, PIT2 benchmark and INT 15h AH=80h–91h service table/handlers.

Current candidate map was regenerated successfully by GitHub Actions: 386 code windows, 74 data ranges, 35,960-byte union (54.87%); this is not semantic completion. Candidate listing SHA: 64c64b7250b8c9271635f38230a89a43a71b34ec.

Next selected range: 93F8h–9FFFh (3,080 bytes), continuing the controller/video BIOS cluster. Do not resume numbered phases; keep working from uncovered byte ranges and confirmed references.


## Further address-ledger work — 2026-11-17

New reports:
- analysis/disasm/AMI486_ADDRESS_LEDGER_REGION_93F8_9870_20261117.md — PS/2 auxiliary-device services and IRQ12 packet handling.
- analysis/disasm/AMI486_ADDRESS_LEDGER_REGION_9848_A017_20261117.md — INT 10h video BIOS dispatch table and service handlers.
- analysis/disasm/AMI486_ADDRESS_LEDGER_REGION_B7B1_C5FA_20261117.md — Advanced CMOS/Chipset Setup labels, metadata and callback table.

The generator now emits the 8EA7h, 90BAh, 94FAh, 9589h, 9784h, 9848h and B7B2h tables as data ranges. Latest successful artifact: 386 code windows, 74 data ranges, 35,960-byte union (54.87%), 169 pages touched, 98 fully covered. Candidate listing SHA: 64c64b7250b8c9271635f38230a89a43a71b34ec.

Next selected gap: D65Bh–E400h (3,494 bytes). Continue from byte classification and reference evidence; do not return to numbered phase sequencing.


## Address-ledger continuation — D655h–E3FFh (2026-11-17)

Report: `AMI486_ADDRESS_LEDGER_REGION_D655_E3FF_20261117.md`.

- D65Bh is inside the instruction at D657h; the aligned continuation is D655h.
- D6A8h–D6BDh is the 11-word D6A2h selector table; D6BEh is its error target.
- D6C4h/D6DEh are a stack/register/segment integrity test; the D7xx–DAA1h stream contains 8042, CMOS, chipset and PIT POST work with explicit stack-return words classified as data.
- DAA2h–DFFFh is 1,374 zero bytes. E000h/E005h are jump stubs, E05Bh is the reset entry, E00Eh/E0CBh are ROM strings, E160h–E25Fh is descriptor-like data and E260h–E2BFh is the 96-byte protected-mode parameter block copied before INT 15h/AH=89h.
- D906h is a confirmed direct JMP to 8400h after the EE9Dh helper returns through stack slot D904h. 8400h clears/restores CMOS 8Eh–FFh; AND BP,FFC7h preserves BP.13. The producer remains unresolved.
- Candidate mask: 597 code windows, 153 data ranges, 46,985-byte union (71.69%), 66 uncovered intervals, 210 pages touched and 135 fully covered. This is not semantic completion.
- Historical next-gap selection before the E862h–F52Dh expansion; this interval has since been mapped.


## Address-ledger continuation — E862h–F52Dh (2026-11-17)

Report: `AMI486_ADDRESS_LEDGER_REGION_E862_F52D_20261117.md`.

The former E865h–F52Dh gap is now classified into polling helpers, parity diagnostics, RTC/PIC/timer handlers, INT 1Ah-compatible services, CMOS helpers, the 0F05h protected-mode-assisted path, Setup/CMOS editor code, encoded strings, video/ROM checks and fatal POST diagnostics. Embedded strings, stack/data tables, padding and opaque blocks are separated from bounded code windows. Several interrupt vector mappings and opaque data consumers remain unresolved.

Historical candidate-mask snapshot before the Hard Disk Setup expansion: 508 code windows, 136 data ranges, 42,884-byte union (65.44%). Superseded by the current 597-window mask.


## Address-ledger continuation — Hard Disk Setup region (2026-11-17)

Report: `AMI486_ADDRESS_LEDGER_REGION_696F_72D8_20261117.md`.

The former D697Dh–D7144h gap is mapped as a Hard Disk Setup/INT 13h diagnostic subsystem. E1ACh is a three-value UI selector; the 6BD8h near-call table dispatches to 6B14h, 71E4h and 6CE3h; the direct dispatcher caller is 6936h. The subsystem includes disk read/write/verify paths, a 13-byte status table and a repeated 40-sector throughput benchmark.

Historical snapshot after the Hard Disk Setup expansion but before the 19B0h–23CEh expansion: 541 code windows, 140 data ranges, 45,118-byte union (68.84%). Superseded by the current 597-window mask below.


## Address-ledger continuation — 19B0h–23CEh POST/ALi/A20 region (corrected 2026-11-17)

Overview: `AMI486_ADDRESS_LEDGER_REGION_19B0_23CE_20261117.md`.  
Focused byte map: `AMI486_ADDRESS_LEDGER_REGION_19F8_20FB_20261117.md`.

The former 19F8h–20FFh candidate gap is fully covered. The local POST chain confirms D9D9h -> 1AFBh, the CMOS B3h profile selection, option-ROM scanning, the 8750h–87A3h ALi register table, the LGDT/GDT setup and the A20-bracketed memory-alias probe.

Critical alignment corrections:
- 1B24h, not 1B20h, sets SP=1B2Ah; the helper returns at 1B2Ch.
- 20C6h sets SP=20CCh and jumps to F66Ah; the return resumes at 20CEh.
- 20D2h sets SP=20D8h and jumps to EEEFh; the return resumes at 20DAh.
- 20DAh loads ES=0008h from the GDT. AX=4410h is an ALi register 10h/value 44h write, not a segment selector.
- 20F4h sets SP=20FAh and jumps to 8DDCh; the word at 20FAh returns to 20FCh. The first ES:66-prefixed dword store starts at 20FEh; 2100h is inside that instruction, not an independent entry.
- The 20D8h return word is consumed by EEEFh, not 8DDCh. The 20FAh return word is now separately classified as data.
- The B3h path skips the small profile list when bits 2 and 3 are both clear; otherwise it chooses 8E4Eh–8E61h or 8E76h–8E79h. The 1B2Ch tail programs PIT channel 1 via ports 43h/41h.

Historical candidate mask before the INT 13h diskette expansion: 597 code windows, 154 data ranges, 31,189 unique code bytes, 15,829 unique data bytes, 117 overlap bytes, 46,901-byte union (71.57%), 69 uncovered intervals, 210 pages touched and 133 fully covered pages. Superseded by the diskette-region update below.


## Address-ledger continuation — INT 13h diskette subsystem (2026-11-17)

Detailed map: `AMI486_ADDRESS_LEDGER_REGION_CA15_D103_20261117.md`.

The former CA16h–D0FFh gap (1,770 bytes) is now covered. The region maps the INT 13h drive-geometry/parameter response, CMOS-selected media profiles, six 13-byte diskette parameter records, controller-presence checks, FDC command/status tests, per-drive media detection, motor/readiness timing and INT 1Eh geometry comparisons. C8CAh is both a parameter-table view and an executable continuation after CALL D0D9h at C8C7h. CB09h and CBF8h remain candidate entries without direct near xrefs. D0D9h continues through D103h (POP AX/RET).

Current candidate mask: 610 code windows, 163 data ranges, 32,861 unique code bytes, 15,940 unique data bytes, 130 overlap bytes, 48,671-byte union (74.27%), 68 uncovered intervals, 216 pages touched and 140 fully covered pages. This is not semantic completion. Next largest gap: 873Ch–8DCEh (1,683 bytes).


## Address-ledger progress — 873Ch–8DCEh completed in candidate mask (2026-11-17)

Completed the region pass and committed:
- `analysis/disasm/AMI486_ADDRESS_LEDGER_REGION_873C_8DCE_20261117.md`
- Updated `AMI486_ADDRESS_LEDGER_20261116.md`, `DISASM_INDEX.md`, phase 5 and phase 6 reports.
- Expanded candidate seeds and explicit data/stack-return ranges in `tools/disasm_ami486_candidate_windows.py`; GitHub Actions regenerated the listing successfully.

The 873Ch–8DCEh interval (1,683 bytes) now has no uncovered byte in the candidate code/data union. This is not proof that every byte's runtime meaning is resolved. In particular, 8893h–8898h, optional runtime-table provenance, ALi register names and some upstream entry references remain open.

Key correction: 85B3h falls through from 85BFh into the 76-record worker at 85C0h; it does not return after 85D6h. In the stock image, 85F5h applies five records, 85CBh has count zero, 85D6h is a no-op because 82B0h=0, then 85C0h applies 76 records and returns at 862Fh. The 8750h–87A3h 21-record ALi write view is an overlapping use of the first 21 entries of the 76-record suffix.

Latest candidate mask:
- 678 code windows / 205 data ranges
- 34,292 unique code bytes / 16,419 unique data bytes
- 213 overlap bytes; 50,498-byte union (77.05%)
- 70 uncovered intervals; 223 pages touched / 147 fully covered

Next largest uncovered interval: **2436h–29F5h (1,472 bytes)**. Continue by address-ledger gaps and unresolved overlaps, not by creating phase numbers. **Phase 97 has not been started.**
