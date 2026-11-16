# AMI486 address ledger — first semantic pass

Date: 2026-11-16  
Source: `ami486.bin`, 65,536 bytes, SHA-256 `91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b`  
Prior phase corpus: 96 semantic reports.

## 1. Purpose and status

This is the first ROM-wide address ledger. It separates **document-reference coverage** from **semantic byte classification**. It is deliberately not a code/data map yet.

The 96 phase reports were searched in batches for explicit hexadecimal address tokens ending in `h`. This produces:
- 153 of 256 pages with at least one explicit phase address reference;
- 103 pages with no matching explicit `hhhh h`-style token in those reports.

A page marked `R` only means that at least one address from that page is explicitly cited in a phase report. It does **not** mean the whole 256-byte page was inspected or classified. A page marked `—` is not proven unexamined: addresses may be written without an `h` suffix, and the phase may discuss a routine by behavior rather than by its address.

## 2. Page reference matrix

Legend:
- `R` = explicit `hhhh` address reference found in at least one phase report.
- `—` = no such explicit token found by this narrow scan.
- Every page remains semantically **UNCLASSIFIED** until its bytes and all reachable entry streams are checked.

| +0 | +1 | +2 | +3 | +4 | +5 | +6 | +7 | +8 | +9 | +A | +B | +C | +D | +E | +F |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 00 R | 01 R | 02 R | 03 R | 04 R | 05 R | 06 R | 07 R | 08 R | 09 R | 0a R | 0b R | 0c R | 0d R | 0e — | 0f R |
| 10 R | 11 R | 12 R | 13 R | 14 R | 15 R | 16 R | 17 R | 18 R | 19 R | 1a R | 1b R | 1c R | 1d R | 1e R | 1f R |
| 20 R | 21 — | 22 — | 23 R | 24 R | 25 R | 26 R | 27 R | 28 R | 29 R | 2a — | 2b — | 2c — | 2d — | 2e R | 2f R |
| 30 R | 31 — | 32 — | 33 R | 34 R | 35 — | 36 — | 37 — | 38 — | 39 — | 3a — | 3b — | 3c R | 3d — | 3e R | 3f — |
| 40 R | 41 R | 42 — | 43 — | 44 R | 45 — | 46 R | 47 R | 48 R | 49 R | 4a — | 4b R | 4c R | 4d R | 4e — | 4f R |
| 50 R | 51 R | 52 R | 53 R | 54 R | 55 R | 56 R | 57 R | 58 R | 59 — | 5a R | 5b R | 5c R | 5d R | 5e R | 5f R |
| 60 — | 61 — | 62 R | 63 R | 64 R | 65 R | 66 R | 67 R | 68 — | 69 — | 6a — | 6b — | 6c — | 6d — | 6e — | 6f — |
| 70 — | 71 R | 72 — | 73 R | 74 R | 75 R | 76 R | 77 R | 78 — | 79 — | 7a R | 7b — | 7c — | 7d — | 7e — | 7f R |
| 80 R | 81 — | 82 R | 83 R | 84 R | 85 R | 86 R | 87 R | 88 R | 89 R | 8a R | 8b R | 8c R | 8d R | 8e R | 8f R |
| 90 R | 91 R | 92 R | 93 R | 94 R | 95 — | 96 — | 97 — | 98 R | 99 — | 9a — | 9b — | 9c R | 9d — | 9e — | 9f R |
| a0 — | a1 — | a2 — | a3 — | a4 — | a5 — | a6 — | a7 — | a8 — | a9 — | aa R | ab — | ac — | ad — | ae — | af — |
| b0 R | b1 — | b2 — | b3 R | b4 — | b5 R | b6 R | b7 R | b8 — | b9 — | ba R | bb — | bc — | bd R | be R | bf R |
| c0 R | c1 — | c2 — | c3 — | c4 — | c5 R | c6 — | c7 — | c8 R | c9 — | ca — | cb — | cc R | cd R | ce — | cf — |
| d0 R | d1 — | d2 — | d3 — | d4 — | d5 — | d6 R | d7 R | d8 R | d9 R | da R | db — | dc — | dd — | de — | df R |
| e0 R | e1 R | e2 R | e3 R | e4 — | e5 R | e6 — | e7 — | e8 R | e9 R | ea R | eb — | ec — | ed R | ee R | ef R |
| f0 R | f1 R | f2 — | f3 R | f4 R | f5 R | f6 R | f7 R | f8 R | f9 — | fa R | fb — | fc R | fd — | fe — | ff R |

## 3. Pages without explicit phase-address references

The following 103 pages are the current *reference-scan gaps*, not proven analysis gaps:

0e00h–0eFFh, 2100h–22FFh, 2a00h–2dFFh, 3100h–32FFh, 3500h–3bFFh, 3d00h–3dFFh, 3f00h–3fFFh, 4200h–43FFh, 4500h–45FFh, 4a00h–4aFFh, 4e00h–4eFFh, 5900h–59FFh, 6000h–61FFh, 6800h–70FFh, 7200h–72FFh, 7800h–79FFh, 7b00h–7eFFh, 8100h–81FFh, 9500h–97FFh, 9900h–9bFFh, 9d00h–9eFFh, a000h–a9FFh, ab00h–afFFh, b100h–b2FFh, b400h–b4FFh, b800h–b9FFh, bb00h–bcFFh, c100h–c4FFh, c600h–c7FFh, c900h–cbFFh, ce00h–cfFFh, d100h–d5FFh, db00h–deFFh, e400h–e4FFh, e600h–e7FFh, eb00h–ecFFh, f200h–f2FFh, f900h–f9FFh, fb00h–fbFFh, fd00h–feFFh

These ranges are candidates for prioritization. They must be checked against raw bytes and the master linear decode before being labelled unexplored.

## 4. Raw-byte discoveries in reference-scan gaps

The following samples were read directly from the checked-in ROM, not inferred from the phase index.

### 4.1 2100h — memory-test code candidate

At 2100h the bytes begin:

```
2100: C7 06 00 00 55 55 26 66 C7 06 00 01 FF FF
2110: FF FF 26 66 81 3E 00 00 55 55 0F 85 67 00
2120: 26 66 C7 06 00 00 AA AA 55 55 26 66 C7 06
```

This is clearly an executable-looking pattern-write/compare stream with 16-/32-bit operand/address prefixes and conditional branches. It is a high-priority alternate entry / memory-test candidate. Its exact entry boundary, complete extent and caller set still need CFG verification.

### 4.2 A000h–AFFFh — mixed code, pointer data, message text and keyboard tables

Raw samples show several distinct content types inside this 4 KiB area:

- `A000h–A0FFh`: instruction-dense bytes, including BIOS interrupt and register-save/restore sequences.
- `A0F1h–A124h`: 26-entry native little-endian INT 13h function table. The A0A0h dispatcher indexes it with incoming AH (0–19h) via `CS:[DI-5F0Fh]`. Targets: `A197, A20B, A216, A226, A23E, A25F, A18E, A18E, A1A4, A337, A372, A381, A474, A19E, A18E, A18E, A4D3, A501, A18E, A18E, A52B, A1A9, A18E, A18E, A18E, A57B`. A100h is an interior address in this table, not its beginning.
- `A125h–A18Dh`: padded message text including **“Format !!!”**, **“BootSector Write !!!”**, and **“Possible VIRUS: Continue (Y/N)?”**. This is confirmed embedded text/data, not executable code.
- `A18Eh`: aligned bytes `B8 00 01 88 26 74 00 F9 C3`; shared INT 13h unsupported/error stub. It sets AH=01h, stores status 01h at DS:0074h, sets CF and returns.
- `A200h–ACFFh`: instruction-dense routines; raw samples include repeated I/O and conditional control flow. Treat as code candidates with embedded data not yet excluded.
- `AD00h–AE5Fh`: keyboard translation data candidates. The bytes contain scan-code-like values and recognizable QWERTY/ASDF/Z/X/C/V/B/N/M and numeric-key sequences.
- `AE60h–AFFFh`: returns to instruction-dense code, including BIOS interrupt calls and control-flow branches.

The A100h words must not be mistaken for a fully understood native little-endian pointer table. The raw pairs, when byte-reversed, match plausible code entries such as A1A4h, A137h, A372h, A381h, A49Eh, A18Eh, A1D3h, A401h and A5A9h. This is a strong byte-swapped-table hypothesis, not yet a proven table contract.

### 4.3 D100h–D5FFh — floppy-controller/DMA subsystem

The FDC/DMA routines are called from the legacy floppy INT 13h handler at C610h (notably C8BBh/C936h -> D156h and C913h -> D4EAh/D381h/D197h/D156h/D216h/D270h/D2BDh). A95Eh saves the displaced INT 13h vector at INT 40h; A08Dh forwards DL<80h requests through INT 40h. C610h is the strong matching in-ROM floppy handler candidate; the actual runtime pointer stored at 0000:0100h still needs an IVT snapshot. See AMI486_FDC_DMA_SUBSYSTEM_20261116.md.

### 4.4 6800h — executable code candidate

At 6800h the bytes begin `86 C4 8B F8 C3 3B F7 74 37 ...`, followed by arithmetic, BIOS INT 10h calls and a divide-based conversion sequence. This is a code candidate despite the absence of explicit phase-address tokens for page 68.

### 4.5 F900h–F9FCh — BIOS serial service / UART dispatch

F900h–F929h is an IRET-terminated six-function dispatcher. F92Ah–F935h is a six-word table. The handlers use DX-relative UART registers +0/+1/+3/+4/+5/+6 (RBR/THR/DLL, IER/DLM, LCR, MCR, LSR, MSR). AH=00h programs the exact 110–9600 baud divisor table; AH=01h transmits; AH=02h receives; AH=03h returns LSR/MSR; AH=04h/05h manage modem-control outputs. This is the BIOS INT 14h serial-service family; IVT installation/caller provenance remains unresolved. See AMI486_INT14_SERIAL_BIOS_20261116.md.

## 5. Immediate priority order

1. **INT 40h runtime target**: capture the initialized IVT value at 0000:0100h and confirm the legacy floppy handler segment:offset (C610h is the strong in-ROM candidate).
2. **FDC command semantics**: decode D40Ah–D462h and D520h–D5DCh against the 8272/765 command format; verify DMA mode at every D156h call.
3. **INT 14h vector provenance**: locate the IVT installation/caller for the now-mapped F900h serial service.
4. **Chipset register semantics**: identify the chipset family and map registers 10h/11h/16h used by the 2100h–23E1h memory-alias/configuration path.
5. **Remaining regions**: map incoming callers for the RTC/date-time renderer (6700h/6774h/67AEh), the F9xx serial handler, and other unclassified pages. Continue by uncovered byte ranges, not phase numbers.

## 6. Rules for subsequent updates

For each interval record:
- start/end offsets and exact source bytes;
- one or more aligned instruction streams (never assume a single global alignment);
- confirmed data/string/table subranges;
- incoming direct and indirect references;
- outgoing direct and indirect calls/jumps;
- unresolved bytes and alternate-entry candidates;
- confidence and evidence source.

Do not infer that an entire 256-byte page is code because one function starts there. Do not infer data from linear-decoder output alone. No whole-ROM semantic percentage is currently defensible. The seeded-window union is 8,618/65,536 bytes (13.15%) but this is a sampling footprint, not a ROM semantic-coverage percentage.


## 7. Seeded Capstone decode — first executable evidence

The GitHub Actions workflow now generates `ami486_candidate_windows_20261116.txt` from independently seeded 16-bit windows. The first successful run produced 24 windows; the expanded run adds entry candidates and normalizes relative near-branch targets with 16-bit IP wraparound. This remains a bounded linear inspection aid, not a CFG.

Confirmed from the decoded bytes:
- A1B3h resets the ATA device through control port 01F6h, waits, reads error/features port 01F1h, and then probes device selectors 80h/81h.
- A337h writes sector-count/device parameters to 01F2h/01F6h and issues ATA command 91h through the command path.
- A406h transfers a 512-byte sector using `REP OUTSW` to port 01F0h; the optional trailing path writes four additional bytes.
- A501h and A52Bh issue ATA commands and inspect status/error state; A52Bh uses command 90h and reads 01F1h.
- A621h writes the feature/error register at 01F1h; A62Dh polls status at 01F7h; A655h selects a drive and checks status.
- A847h renders the embedded A125h/A148h prompt via BIOS INT 10h. This ties the “Possible VIRUS” message to the ATA/boot-sector protection path.
- A95Eh replaces INT 13h at 0000:004Ch with F000:A08Dh, saves the displaced INT 13h vector at INT 40h (0000:0100h), installs INT 76h/IRQ14 at F000:E845h, and configures INT 41h/INT 46h fixed-disk parameter table pointers at E401h-based 16-byte records. A08Dh forwards floppy DL<80h requests through INT 40h.
- D100h–D5FFh is the FDC/DMA subsystem called by the legacy floppy INT 13h handler at C610h; C8BBh/C936h call D156h DMA setup. A08Dh forwards DL<80h requests to the saved old INT 13h vector in INT 40h.
- AE60h onward enters a keyboard/INT 15h related handler path; AD00h–AE5Fh remains translation-table data candidate.

The first A000h seed decodes the initial bytes as unusual but syntactically valid instructions. Its true entry boundary remains unconfirmed; prefer the aligned entries established by direct calls/branches in the seeded listing.


## 8. Subsystem report and corrected storage separation

Detailed byte-backed analysis: [AMI486_STORAGE_AND_DISPATCH_REGIONS_20261116.md](AMI486_STORAGE_AND_DISPATCH_REGIONS_20261116.md).

Important correction to the initial gap hypothesis: A000h–AFFFh is **IDE/ATA hard-disk code**, not floppy code. It accesses 01F0h–01F7h and 03F6h; A406h performs a 256-word data-out transfer, AC00h issues ATA IDENTIFY DEVICE (ECh) and performs a 256-word data-in transfer. A847h displays the embedded Format/BootSector Write/Possible VIRUS prompt and A8F4h accepts Y/N. A95Eh is an INT 13h vector-hook candidate (ES base still to verify).

D100h–D5FFh is the separate floppy-controller/DMA subsystem: FDC ports 03F2h/03F4h/03F5h/03F7h plus DMA ports 0Ch/0Bh/05h/04h.

F92Ah–F935h is a six-word little-endian dispatch table with targets F936h, F986h, F9C4h, F977h, F999h and F9D3h. F977h overlaps the F936h stream as an alternate entry. The F900h wrapper ends in IRET; its actual vector entry remains unknown.

The current seeded Capstone output contains 146 unique bounded code windows plus 6 separately emitted data ranges (152 window headers total). The windows cover 7,974 unique code-candidate bytes and 671 data-candidate bytes, with 27 bytes overlapping between code/data windows; the union is 8,618 distinct ROM bytes across 46 pages. This is only the union of selected seeded windows, not total semantic coverage. Near-branch targets are normalized to 16-bit IP wraparound.


## INT 13h dispatch correction

The initial classification of A100h–A123h as a separate byte-swapped table was wrong. A08Dh is the hooked INT 13h entry; DL<80h is forwarded to INT 40h. A0A0h dispatches by AH through the 26-entry little-endian table at A0F1h–A124h. A100h is an interior byte of the table. The exact targets and selectors are documented in AMI486_STORAGE_AND_DISPATCH_REGIONS_20261116.md.


## INT 13h service contract progress

The 26-entry table's main service targets are now mapped against the actual ATA command bytes and transfer direction. Read (AH=02) uses command 20h and REP INSW; write (AH=03) uses 30h and REP OUTSW; verify (04) uses 40h; format (05) uses 50h after a guard/prompt; get parameters (08), initialize parameters (09/91h), read/write long (0A/0B using 22h/32h), seek (0C/70h), reset (0D), ready/status (10), recalibrate (11/10h), diagnostics (14/90h), and disk type/capacity (15, AH=03h plus CX:DX sector count) are supported by the decoded streams. AH=19h remains open. See AMI486_STORAGE_AND_DISPATCH_REGIONS_20261116.md.


## INT 13h region entry-to-return ledger

A08Dh is the hooked hard-disk INT 13h entry; A0A0h is its AH dispatcher; A0F1h–A124h is the 26-word handler table; A125h–A18Dh is prompt data; A18Eh is the shared unsupported/error stub. The function/helper entry-to-return map from A197h through A946h is now recorded in AMI486_STORAGE_AND_DISPATCH_REGIONS_20261116.md. In particular, A399h is the ATA read data-in path and A406h the data-out path. The AH=05h format and protected write path share the Y/N warning renderer at A847h/A8F4h.


## FDC/DMA subsystem map

See [AMI486_FDC_DMA_SUBSYSTEM_20261116.md](AMI486_FDC_DMA_SUBSYSTEM_20261116.md). D156h programs DMA channel 2 (ports 0Ch/0Bh/05h/04h/81h, then unmasks channel 2 via 0Ah); D243h writes FDC FIFO command bytes, D294h reads result bytes, D270h collects result blocks, D2FDh sends Sense Interrupt Status (08h), D348h toggles DOR 03F2h, D3B5h reads CMOS floppy type register 10h, and D499h performs a three-attempt command/result transaction. D40Ah–D462h command-byte meanings and the INT 40h vector target remain unresolved.


## Keyboard subsystem map

See [AMI486_KEYBOARD_SUBSYSTEM_20261116.md](AMI486_KEYBOARD_SUBSYSTEM_20261116.md). AD00h–AE5Fh is keyboard translation data; AE6Fh onward invokes INT 15h AH=4Fh and handles E0h/E1h prefixes and ACK/RESEND bytes. B242h/B253h map lock/modifier scan codes; B26Ah/B273h enable/disable the 8042 interface; B33Dh sends EDh/F4h LED/scanning commands; B3E2h is an INT 16h dispatcher; B399h/B4A9h manage the BIOS ring buffer.


## INT 13h/40h/76h vector wiring and fixed-disk tables

The A95Eh installer replaces INT 13h (0000:004Ch) with F000:A08Dh and saves the displaced INT 13h vector in the INT 40h slot (0000:0100h). A08Dh forwards DL<80h requests through INT 40h, thereby chaining floppy requests to the original BIOS handler. A95Eh also installs INT 76h/IRQ14 at F000:E845h and sets INT 41h/INT 46h parameter-table pointers to 16-byte records based at E401h, selected from CMOS 92h/99h/9Ah. The IRQ14 handler sends slave/master PIC EOIs and invokes INT 15h AX=9100h. Details: AMI486_STORAGE_AND_DISPATCH_REGIONS_20261116.md.


## Legacy floppy INT 13h handler at C610h

C610h is the in-ROM legacy floppy INT 13h handler candidate. It dispatches AH=00h–05h, AH=08h and AH=15h–18h through the 11-word table at C5FAh, then returns through C648h–C68Fh IRET. C8BBh/C936h call D156h; C913h calls the D4EAh/D381h/D197h/D156h/D216h/D270h/D2BDh FDC path. A95Eh saves the previous INT 13h vector into INT 40h and A08Dh forwards DL<80h requests there. The actual runtime INT 40h offset:segment remains to be captured, but C610h is the strong matching floppy handler. See AMI486_FDC_DMA_SUBSYSTEM_20261116.md.


## Memory alias / chipset initialization map

See [AMI486_MEMORY_CHIPSET_INITIALIZATION_20261116.md](AMI486_MEMORY_CHIPSET_INITIALIZATION_20261116.md). The 2100h/2187h/2253h/22DBh streams test pattern aliasing at 8 MiB, 64 MiB and low offsets 2/4/8 KiB. Their branch paths use stack-threaded returns into shared indexed-chipset I/O helpers: 8DCFh reads via ports 22h/23h, 8DDCh writes. The 222Dh sequence reads register 16h, ORs 30h and writes it back, then writes 44h to register 11h. The 2381h path updates registers 10h/11h and proceeds to a CR0.PE-clear transition at 23B6h/F66Eh. Chipset vendor/register meanings remain unconfirmed.


## RTC date/time and text rendering map

See [AMI486_CLOCK_AND_TEXT_RENDERING_20261116.md](AMI486_CLOCK_AND_TEXT_RENDERING_20261116.md). 6774h calls INT 1Ah AH=04h to read date; 67AEh calls INT 1Ah AH=02h to read time. 6700h displays BP-relative fields and calls 6805h sequential numeric renderer; 6841h prints decimal digits, 68B0h prints hex bytes, 6860h/68C8h use INT 10h for character/attribute output. 67D8h arithmetic is recorded exactly but not yet named as BCD conversion.


## Serial BIOS / UART dispatch map

See [AMI486_INT14_SERIAL_BIOS_20261116.md](AMI486_INT14_SERIAL_BIOS_20261116.md). F900h–F929h is an IRET-terminated six-function dispatch wrapper; the F92Ah table targets F936h, F986h, F9C4h, F977h, F999h and F9D3h. The handlers use DX-relative UART offsets +0/+1/+3/+4/+5/+6, including DLAB, DLL/DLM, LCR, MCR, LSR and MSR. This is strongly consistent with BIOS INT 14h serial services; the vector source is not yet proven.


## INT 14h service family

The F900h–F9FCh dispatcher is now classified as the BIOS INT 14h serial-service family from the AH function table, DX port-base convention, UART DLAB/DLL/DLM/LCR/IER/THR/RBR/MCR/LSR/MSR accesses, and exact 110–9600 baud divisor table. IVT installation remains unverified. See AMI486_INT14_SERIAL_BIOS_20261116.md.


## 9. Corrected subsystem classifications and linked reports

The first-pass region descriptions above have been refined by raw-byte and caller analysis. Use the following as the current authoritative region summaries:

| Region | Current classification | Detailed report |
|---|---|---|
| A08Dh–A124h | Hooked hard-disk INT 13h handler, AH dispatcher and 26-entry function table | AMI486_STORAGE_AND_DISPATCH_REGIONS_20261116.md |
| A125h–A18Dh | Format / boot-sector warning text | AMI486_STORAGE_AND_DISPATCH_REGIONS_20261116.md |
| A18Eh | Shared INT 13h unsupported/error stub | AMI486_STORAGE_AND_DISPATCH_REGIONS_20261116.md |
| A197h–A946h | ATA reset/read/write/verify/format/seek/diagnostic/capacity handlers and shared helpers | AMI486_STORAGE_AND_DISPATCH_REGIONS_20261116.md |
| A95Eh onward | INT 13h/INT 40h chaining, INT 76h IRQ14 install, INT 41h/46h disk parameter tables | AMI486_STORAGE_AND_DISPATCH_REGIONS_20261116.md |
| C5FAh–C60Fh | Legacy floppy INT 13h AH dispatch table | AMI486_FDC_DMA_SUBSYSTEM_20261116.md |
| C610h onward | Legacy floppy INT 13h handler; direct callers of D100h–D5FFh FDC/DMA helpers | AMI486_FDC_DMA_SUBSYSTEM_20261116.md |
| AD00h–AE5Fh | Keyboard translation data | AMI486_KEYBOARD_SUBSYSTEM_20261116.md |
| AE6Fh onward / B1E9h–B4xxh | Scan-code intercept, 8042 commands, BIOS keyboard buffer and INT 16h services | AMI486_KEYBOARD_SUBSYSTEM_20261116.md |
| 2100h–23E1h | Memory-alias probes, stack-threaded indexed chipset I/O, CR0.PE transition | AMI486_MEMORY_CHIPSET_INITIALIZATION_20261116.md |
| 6700h–68E2h | RTC date/time display and numeric/hex text rendering helpers | AMI486_CLOCK_AND_TEXT_RENDERING_20261116.md |
| D100h–D5FFh | FDC FIFO, DMA channel 2, CMOS floppy type, reset and status/error handling | AMI486_FDC_DMA_SUBSYSTEM_20261116.md |
| E401h–E480h | First eight 16-byte fixed-disk parameter records | AMI486_STORAGE_AND_DISPATCH_REGIONS_20261116.md |
| E845h–E864h | INT 76h / IRQ14 handler | AMI486_STORAGE_AND_DISPATCH_REGIONS_20261116.md |
| F900h–F9FCh | BIOS INT 14h serial-service dispatcher and UART handlers | AMI486_INT14_SERIAL_BIOS_20261116.md |

The current candidate-window artifact has 146 unique bounded code windows and 6 separately emitted data ranges (152 headers). Its union is 8,618 bytes across 46 pages: 7,974 code-candidate bytes, 671 data-candidate bytes and 27 bytes of code/data overlap. This is a sampling footprint only, not semantic coverage.


## 9. F9xx dispatcher entry-boundary correction

The prior candidate-window seed at F900h was one byte misaligned. Raw bytes show F8FDh–F900h is the complete instruction `MOV DX,[BP+DI]`; therefore F900h is its final displacement byte, not a valid decode start. The guarded wrapper begins at F8E8h (CMP DX,04h; JAE F927h; CMP AH,06h; NOP; JAE F927h), and the valid path begins PUSHA at F8F2h. The common cleanup CALL is at F927h, IRET at F92Ah, and the six-word handler table starts immediately after the IRET at F92Ah? **Byte-boundary note:** the IRET is at F929h; the table begins at F92Ah. The generator was corrected to seed F8E8h for 42h bytes and no longer seeds F900h. The interrupt vector and service contract remain unproven.


## FDC DMA direction cross-reference

D156h writes the caller-supplied mode byte unchanged to DMA port 0Bh. C8BBh supplies 46h (8237 channel 2, single, memory-to-device); C936h/C913h supply 4Ah (channel 2, single, device-to-memory). This confirms FDC write/read DMA direction at these call sites. Detailed analysis: AMI486_FDC_DMA_SUBSYSTEM_20261116.md.
