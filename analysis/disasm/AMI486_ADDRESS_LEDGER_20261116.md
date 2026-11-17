# AMI486 address ledger — first semantic pass

Date: 2026-11-16  
Source: `ami486.bin`, 65,536 bytes, SHA-256 `91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b`  
Prior phase corpus: 96 semantic reports.

## 1. Purpose and status

This is the first ROM-wide address ledger. It separates **document-reference coverage** from **semantic byte classification** and now incorporates subsystem-level code/data classifications for selected regions (see section 9). It is not yet a complete code/data map: most bytes remain unclassified or only locally understood.

The 96 phase reports were searched in batches for explicit hexadecimal address tokens ending in `h`. This produces:
- 153 of 256 pages with at least one explicit phase address reference;
- 103 pages with no matching explicit `hhhh h`-style token in those reports.

A page marked `R` only means that at least one address from that page is explicitly cited in a phase report. It does **not** mean the whole 256-byte page was inspected or classified. A page marked `—` is not proven unexamined: addresses may be written without an `h` suffix, and the phase may discuss a routine by behavior rather than by its address.

## 2. Page reference matrix

Legend:
- `R` = explicit `hhhh` address reference found in at least one phase report.
- `—` = no such explicit token found by this narrow scan.
- A page marked R is not thereby fully classified. Some ranges inside referenced and unreferenced pages now have confirmed local classifications, but no 256-byte page is considered complete until all bytes, alternate streams and incoming references have been reconciled.

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
2100: C7 06 00 00 55 55 AA AA 26 66 C7 06 00 01 FF FF
2110: FF FF 26 66 81 3E 00 00 55 55 AA AA 0F 85 67 00
2120: 26 66 C7 06 00 00 AA AA 55 55 26 66 C7 06
```

This is an executable-looking pattern-write/compare stream with 16-/32-bit operand/address prefixes and conditional branches. The two AA bytes at 2106h–2107h are STOSB instructions and must not be omitted. A full raw scan found no direct near CALL/JMP target to 2100h and no literal F000:2100h far pointer; 2100h remains an entry candidate with unresolved indirect/stack entry and caller context. Internal branches to 2187h and 222Dh are confirmed. See AMI486_MEMORY_CHIPSET_INITIALIZATION_20261116.md for the byte-aligned decode and segment-state caveats.

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

The FDC/DMA routines are called from the legacy floppy INT 13h handler at C610h (notably C8BBh/C936h -> D156h and C913h -> D4EAh/D381h/D197h/D156h/D216h/D270h/D2BDh). A95Eh replaces INT 13h with CS:A08Dh and copies the displaced INT 13h offset:segment into the INT 40h slot at ES:0100h/0102h; A08Dh forwards DL<80h requests through INT 40h. Thus INT 40h is dynamically inherited from the previous INT 13h vector, not hardcoded. A95Eh does not set ES=0; the caller's ES precondition remains open. C610h is a strong matching in-ROM floppy-handler candidate (EC59h near-JMPs to C610h), but it is not proven as the saved runtime target. See AMI486_FDC_DMA_SUBSYSTEM_20261116.md.

### 4.4 6800h — executable code candidate

At 6800h the bytes begin `86 C4 8B F8 C3 3B F7 74 37 ...`, followed by arithmetic, BIOS INT 10h calls and a divide-based conversion sequence. This is a code candidate despite the absence of explicit phase-address tokens for page 68.

### 4.5 F8E7h–F9FCh — BIOS serial service / UART dispatch

F8E7h–F929h is the guarded IRET-terminated six-function dispatcher candidate. DX is the COM-port index (0..3); the wrapper reads the base word from BDA 0040:0000+2*DX and skips dispatch if it is zero. It also reads the per-port timeout byte at 0040:007Ch+DX and scales the low byte by four into DI. F92Ah–F935h is the six-word handler table. The handlers use DX-relative UART registers +0/+1/+3/+4/+5/+6 (RBR/THR/DLL, IER/DLM, LCR, MCR, LSR, MSR). AH=00h programs the exact 110–9600 baud divisor table; AH=01h transmits; AH=02h receives; AH=03h returns LSR/MSR; AH=04h/05h manage modem-control outputs. This is the BIOS INT 14h serial-service family; IVT installation/caller provenance remains unresolved. See AMI486_INT14_SERIAL_BIOS_20261116.md.

## 5. Immediate priority order

1. **INT 40h chain value**: verify ES=0000h at A95Eh's caller 134Eh and capture the displaced INT 13h offset:segment copied to 0000:0100h/0102h. C610h is a strong in-ROM candidate but not proven.
2. **FDC command semantics**: decode D40Ah–D462h and D520h–D5DCh against the 8272/765 command format; verify DMA mode at every D156h call.
3. **INT 14h vector provenance**: locate the IVT installation/caller for the now-mapped F8E7h serial service.
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

Do not infer that an entire 256-byte page is code because one function starts there. Do not infer data from linear-decoder output alone. No whole-ROM semantic percentage is currently defensible. The seeded-window union is 10,700/65,536 bytes (16.33%) but this is a sampling footprint, not a ROM semantic-coverage percentage.


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

F92Ah–F935h is a six-word little-endian dispatch table with targets F936h, F986h, F9C4h, F977h, F999h and F9D3h. F977h overlaps the F936h stream as an alternate entry. The F8E7h wrapper ends in IRET at F929h; its actual vector entry remains unknown.

The current seeded Capstone output contains 168 unique bounded code windows plus 18 separately emitted data ranges (186 window headers total). The windows cover 9,450 unique code-candidate bytes and 1,333 data-candidate bytes, with 83 bytes overlapping between code/data windows; the union is 10,700 distinct ROM bytes across 56 pages. This is only the union of selected seeded windows, not total semantic coverage. Near-branch targets are normalized to 16-bit IP wraparound.


## INT 13h dispatch correction

The initial classification of A100h–A123h as a separate byte-swapped table was wrong. A08Dh is the hooked INT 13h entry; DL<80h is forwarded to INT 40h. A0A0h dispatches by AH through the 26-entry little-endian table at A0F1h–A124h. A100h is an interior byte of the table. The exact targets and selectors are documented in AMI486_STORAGE_AND_DISPATCH_REGIONS_20261116.md.


## INT 13h service contract progress

The 26-entry table's main service targets are now mapped against the actual ATA command bytes and transfer direction. Read (AH=02) uses command 20h and REP INSW; write (AH=03) uses 30h and REP OUTSW; verify (04) uses 40h; format (05) uses 50h after a guard/prompt; get parameters (08), initialize parameters (09/91h), read/write long (0A/0B using 22h/32h), seek (0C/70h), reset (0D), ready/status (10), recalibrate (11/10h), diagnostics (14/90h), and disk type/capacity (15, AH=03h plus CX:DX sector count) are supported by the decoded streams. AH=19h remains open. See AMI486_STORAGE_AND_DISPATCH_REGIONS_20261116.md.


## INT 13h region entry-to-return ledger

A08Dh is the hooked hard-disk INT 13h entry; A0A0h is its AH dispatcher; A0F1h–A124h is the 26-word handler table; A125h–A18Dh is prompt data; A18Eh is the shared unsupported/error stub. The function/helper entry-to-return map from A197h through A946h is now recorded in AMI486_STORAGE_AND_DISPATCH_REGIONS_20261116.md. In particular, A399h is the ATA read data-in path and A406h the data-out path. The AH=05h format and protected write path share the Y/N warning renderer at A847h/A8F4h.


## FDC/DMA subsystem map

See [AMI486_FDC_DMA_SUBSYSTEM_20261116.md](AMI486_FDC_DMA_SUBSYSTEM_20261116.md). D156h programs DMA channel 2 (ports 0Ch/0Bh/05h/04h/81h, then unmasks channel 2 via 0Ah); D243h writes FDC FIFO command bytes, D294h reads result bytes, D270h collects result blocks, D2FDh sends Sense Interrupt Status (08h), D348h toggles DOR 03F2h, D3B5h reads CMOS floppy type register 10h, and D499h performs a three-attempt command/result transaction. D40Ah–D462h is now mapped as data-rate/state-token selection feeding a D499h READ ID transaction; D520h–D5D9h is an enhanced FDC VERSION/DUMPREG/UNLOCK/CONFIGURE/PERPENDICULAR/LOCK sequence. Remaining gaps are low-nibble state-token semantics and the runtime INT 40h chain value.


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

See [AMI486_INT14_SERIAL_BIOS_20261116.md](AMI486_INT14_SERIAL_BIOS_20261116.md). F8E7h–F929h is an IRET-terminated six-function dispatch wrapper candidate; the F92Ah table targets F936h, F986h, F9C4h, F977h, F999h and F9D3h. The handlers use DX-relative UART offsets +0/+1/+3/+4/+5/+6, including DLAB, DLL/DLM, LCR, MCR, LSR and MSR. This is strongly consistent with BIOS INT 14h serial services; the vector source is not yet proven.


## INT 14h service family

The F8E7h–F9FCh dispatcher is classified as the BIOS INT 14h serial-service family from the AH function table, DX COM-port index, BDA COM-base/timeout lookups, UART DLAB/DLL/DLM/LCR/IER/THR/RBR/MCR/LSR/MSR accesses, and exact 110–9600 baud divisor table. IVT installation remains unverified. See AMI486_INT14_SERIAL_BIOS_20261116.md.


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
| F8E7h–F9FCh | BIOS INT 14h serial-service dispatcher and UART handlers | AMI486_INT14_SERIAL_BIOS_20261116.md |

The current candidate-window artifact has 187 unique bounded code windows and 41 separately emitted data ranges. Their byte-mask union is 15,639 bytes across 79 pages: 11,414 code-window bytes, 4,319 data-range bytes and 94 bytes of overlap. This is a sampling footprint only, not semantic coverage.


## 9. F9xx dispatcher entry-boundary correction

The first candidate seed at F900h was misaligned; the attempted replacement at F8E8h was also one byte late. The verified entry candidate begins at F8E7h with `83 FA 04` (CMP DX,04h). F8E7h–F8E8h is the instruction's first two bytes; F8E8h is not an entry. F8FDh–F900h is `MOV DX,[DI+0000h]`, so F900h is its final displacement byte. With DS=0040h, DX is a COM-port index and the wrapper reads the COM base from BDA 0040:0000+2*DX; it then reads the timeout byte at 0040:007Ch+DX. Both range guards target the cleanup CALL at F926h; IRET is at F929h; the six-word handler table begins at F92Ah. The generator is now seeded at F8E7h for 43h bytes. The INT 14h vector source remains unproven.


## FDC DMA direction cross-reference

D156h writes the caller-supplied mode byte unchanged to DMA port 0Bh. C8BBh supplies 46h (8237 channel 2, single, memory-to-device); C936h/C913h supply 4Ah (channel 2, single, device-to-memory). This confirms FDC write/read DMA direction at these call sites. Detailed analysis: AMI486_FDC_DMA_SUBSYSTEM_20261116.md.


## FDC command/rate interpretation update — 2026-11-16

The D40Ah–D462h bytes are not raw FDC command opcodes. D3EDh/D499h derive the data-rate selector from AL[7:6] and write it to 03F7h; D3FAh stores the full AL token in [BX+90h]. D499h sends a two-byte 4Ah/drive-head READ ID command through D1C0h and reads seven result bytes through D270h. D520h–D5D9h is the enhanced 765-compatible controller sequence: VERSION 10h (expects 90h), DUMPREG 0Eh (ten result bytes), UNLOCK 14h, CONFIGURE 13h with 00 08 00, PERPENDICULAR MODE 12h and LOCK 94h. The remaining unknowns are the low-nibble semantics of [BX+90h] tokens and the actual INT 40h chain value.


## FDC drive-type and state-token refinement — 2026-11-16

The D3B5h helper checks CMOS 0Eh bits C0h first. If clear, it reads CMOS 10h and selects the high nibble for drive index 0 or the low nibble for nonzero index; CMP SP,SP deliberately returns ZF=1. If CMOS 0Eh bits C0h are set, D3CFh takes the alternate rate-probe path at D46Dh.

Normal CMOS type cases: type 1 stores 93h (rate code 2); type 2 probes rates 0 then 1 (success tokens 15h/74h, failure 02h); type 3 probes 0 then 2 (17h/97h, failure 07h); type 4/default probes 3,0,2 (D7h/17h/97h, failure C7h). The alternate CMOS-0Eh path probes 0,1,2,3 and stores 15h/74h/97h/D7h on success. D3FAh confirms token bit 4 is the success flag; bits 7:6 are the rate selector. C84Bh calls D3CFh when the per-drive token bit 4 is clear. After success, C855h selects FDC SPECIFY parameters: D7h -> 03 AF 02, 17h -> 03 BF 02, other observed tokens -> 03 DF 02. Remaining unknowns are the low-nibble meanings beyond these observed cases and the exact board-specific policy for the CMOS 0Eh C0h validity gate.


## INT 13h/INT 40h chain correction — 2026-11-16

A95Eh does not install a fixed C610h pointer into INT 40h. It swaps the current INT 13h offset at ES:004Ch with A08Dh, stores the old offset at ES:0100h, swaps the current INT 13h segment at ES:004Eh with CS, and stores the old segment at ES:0102h. The caller is at 134Eh. The code therefore chains INT 40h to the previous INT 13h vector dynamically. A95Eh does not initialize ES, so the caller's ES=0000h precondition must be proven. EC59h has the only direct in-ROM near JMP to C610h; this supports C610h as a candidate but does not establish the runtime vector target.


## D4EAh rate-field cross-check — 2026-11-16

D4EAh independently confirms that the top two bits of the per-drive byte at 0090h+drive are the data-rate selector: it compares those bits with global [008Bh], updates [008Bh] when they differ, rotates the two rate bits down to bits 1:0 and writes the selector through D517h to port 03F7h. The per-drive bit-4 success flag and SPECIFY timing-token cases are recorded in the FDC subsystem report. The remaining low-nibble flags are still open.


## CMOS source for FDC perpendicular-mode setup — 2026-11-16

EE94h writes the CMOS register selector to port 70h and reads the byte from port 71h; EEAAh is the protected read wrapper used by the FDC code. D5A1h reads CMOS 0Eh and skips drive-specific perpendicular-mode bits if bit 7 (RTC power lost) or bit 6 (CMOS checksum invalid) is set. Otherwise it reads CMOS 10h: drive A is the high nibble, drive B the low nibble. Type 05h (2.88-MB 3.5-inch) sets CH bit 2 for drive A or bit 3 for drive B before FDC command 12h. The former EEAAh source uncertainty is resolved; only low-nibble [BX+90h] meanings remain open within this FDC token family.


## A95Eh caller/ES trace — 2026-11-16

A95Eh is called at 134Eh within the function entered at 131Fh; 131Fh is directly called from 1BAAh. The 1BAAh caller saves/restores DS around a C000h option-ROM signature check but does not initialize ES. The 131Fh alternate entry reads CMOS 0Eh and 92h and conditionally calls A95Eh at 134Eh. The 1303h sequence that temporarily sets ES=0000h belongs to a different linear instruction stream before 131Fh and is not executed by a call entering at 131Fh. The 1BAAh caller does not initialize ES; therefore ES=0000h at A95Eh remains unproven. The candidate-window generator now includes 131Fh–1364h.


## 131Fh alternate-entry correction — 2026-11-16

131Fh is a direct CALL target from 1BAAh, but it is an overlapping entry into bytes that are part of another linear stream. The alternate stream beginning at 131Fh reaches A95Eh at 134Eh after checking CMOS 0Eh and 92h. The apparent ES=0000h setup at 1303h is in the preceding linear stream and is bypassed by the call to 131Fh; it cannot establish ES for A95Eh. The 1BAAh caller does not set ES. Keep the IVT-write interpretation conditional on ES=0000h at runtime.


## Candidate-window and CMOS-gate refresh — 2026-11-16

The generated candidate listing now contains 168 code windows and 18 data windows (186 headers), with a 10,700-byte union across 56 pages (9,450 code bytes, 1,333 data bytes, 83 overlap bytes). The 131Fh alternate entry is included as a separate window through 1364h. The CMOS 0Eh C0h gate behavior is now mapped: bit 7/6 status causes the BIOS to bypass CMOS 10h drive-type-specific setup and use its alternate probe path; EEAAh reads CMOS through ports 70h/71h. Remaining FDC state uncertainty is confined to the low nibble of [BX+90h].


## INT 14h vector-reference scan — 2026-11-16

A full raw-ROM scan found no direct near CALL/JMP target to F8E7h, no literal word reference F8E7h and no far pointer F000:F8E7h. The six-handler UART dispatcher is structurally an INT 14h-style service candidate, but its IVT slot 0000:0054h/0056h may be initialized externally or dynamically. Runtime IVT capture is required before calling it the installed INT 14h target.


## 2100h raw-byte transcription correction — 2026-11-16

The earlier 2100h ledger excerpt omitted bytes AA AA at 2106h–2107h. The correct sequence is C7 06 00 00 55 55 AA AA 26 66 C7 06 00 01 FF FF. These are two STOSB instructions before the ES:[0100h] sentinel write; see the memory/chipset report for the corrected aligned stream and caller-dependent AL/DI interpretation.


## 10. Setup editor and POST summary regions — 2026-11-17

### 10.1 Setup menu text and pointer structures

The Setup menu text region is now classified from raw bytes and the generated data windows:

| Range | Classification |
|---|---|
| 3044h–318Bh | 12 short Setup caption strings, including Standard/Advanced CMOS, Advanced CHIPSET, Power Management, Peripheral Management, defaults, password, disk utilities and both exit captions |
| 318Ch–31A3h | 12-word pointer table to the short captions above |
| 31A4h–342Dh | Long menu descriptions, including the affirmative and negative exit wording |
| 342Eh–3443h | 11-word pointer table to the 11 main-menu long descriptions |
| 3444h–3445h | Separate pointer 33FFh to the full “Do Not Write…” string |
| 3446h–345Bh | 11-word main-menu handler table |
| 345Ch–3472h | “v/BIOS SETUP UTILITIES” title string |
| 3473h | B5h title/keyboard-legend control byte |
| 3474h–34AAh | Keyboard navigation legend |
| 34ABh–3500h | No-CMOS warning and Setup warning text |
| 3501h–3623h | Setup entry/help instructions and “AMIBIOS SETUP PROGRAM” title |
| 36ABh–37C2h | Option-list headings, default-values prompt and hard-disk help strings |

The 11 long-description pointers at 342Eh–3443h target 31A4h, 31E6h, 3219h, 3256h, 3298h, 32D9h, 3325h, 336Fh, 339Bh, 33BCh and 3406h. The last target is seven bytes into the NUL-terminated string at 33FFh, selecting “Write the settings…”; the separate pointer at 3444h selects the full “Do Not Write…” text. The 11 handler pointers at 3446h–345Bh are 00ECh, 0BDEh, 0C05h, 0C2Ch, 0C53h, 5A7Ah, 5A7Ah, F1C8h, 5038h, 4628h and 2F67h. The consumer of the separate 12-entry short-caption pointer table at 318Ch remains to be traced.

### 10.2 Setup editor code extension

Detailed byte-aligned report: [AMI486_SETUP_EDITOR_RENDERING_EXTENSION_20261117.md](AMI486_SETUP_EDITOR_RENDERING_EXTENSION_20261117.md).

- 0C7Dh is the common editor entry (direct CALL from 0C79h).
- 0CFEh begins the five-byte state-initialization MOV; 0D08h is the visible-item loop; 0D84h is the event-code selector reached from 0D7Fh.
- 0E19h and 0E47h are decrement/increment wrap helpers; 0E7Ch draws one record label and translated option value; 0EE2h–10DEh renders the option list and auxiliary text.
- State refinement: E18Ch is the absolute selected visible-record index; E185h is its on-screen row. E18Eh is total visible records; E18Dh is visible rows; E18Fh is the active record pointer. The 0E19h/0E47h wrap/clamp arithmetic establishes the E18Ch/E185 distinction.
- 0E19h is the aligned entry, not 0E1Ah. The instruction at 0FFFh crosses 1000h; 1000h is not a separate entry.

### 10.3 POST hardware-summary display

Detailed byte-backed report: [AMI486_POST_SUMMARY_DISPLAY_20261117.md](AMI486_POST_SUMMARY_DISPLAY_20261117.md).

- 3F4Ah directly calls the summary renderer at 3F7Bh and prints the bottom border from 45D8h on return.
- 3F7Bh–4141h renders processor, numeric processor, base/extended memory, floppy A/B, hard disks C/D, display type, AMIBIOS date, serial and parallel ports.
- 4142h selects the CPU-name string; 41E4h checks numeric-processor presence; 421Eh is the Weitek string selector.
- 40C6h maps floppy type nibbles to 360-KB/1.2-MB/720-KB/1.44-MB/2.88-MB labels. 40ACh formats hard-disk type values and optionally reads CMOS 99h/9Ah.
- 407Ah enumerates BDA COM/LPT base-address words; 412Ah prints decimal values; 4119h prints the KB suffix; 40EFh fills the line and emits the vertical border/CRLF.
- 4231h–431Fh and 45D8h–45FFh are box-drawing/control data, not code. 4320h–45D7h contains the field labels and CPU/device strings.

### 10.4 Current candidate-window footprint

The generator now reports 187 unique seeded code windows and emits 41 data ranges. The byte-mask union is 15,639/65,536 bytes (23.86%) across 79 pages: 11,414 bytes touched by code windows, 4,319 by data ranges and 94 overlapping bytes. This is still a seeded sampling footprint only; it is not a semantic code/data completion percentage. No claim is made that the remaining bytes are all unexplored.
