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

## 3. Historical pages without explicit phase-address references (2026-11-16 snapshot)

The following 103 pages are the current *reference-scan gaps*, not proven analysis gaps:

0e00h–0eFFh, 2100h–22FFh, 2a00h–2dFFh, 3100h–32FFh, 3500h–3bFFh, 3d00h–3dFFh, 3f00h–3fFFh, 4200h–43FFh, 4500h–45FFh, 4a00h–4aFFh, 4e00h–4eFFh, 5900h–59FFh, 6000h–61FFh, 6800h–70FFh, 7200h–72FFh, 7800h–79FFh, 7b00h–7eFFh, 8100h–81FFh, 9500h–97FFh, 9900h–9bFFh, 9d00h–9eFFh, a000h–a9FFh, ab00h–afFFh, b100h–b2FFh, b400h–b4FFh, b800h–b9FFh, bb00h–bcFFh, c100h–c4FFh, c600h–c7FFh, c900h–cbFFh, ce00h–cfFFh, d100h–d5FFh, db00h–deFFh, e400h–e4FFh, e600h–e7FFh, eb00h–ecFFh, f200h–f2FFh, f900h–f9FFh, fb00h–fbFFh, fd00h–feFFh

These ranges are candidates for prioritization. They must be checked against raw bytes and the master linear decode before being labelled unexplored.

## 4. Raw-byte discoveries in reference-scan gaps

The following samples were read directly from the checked-in ROM, not inferred from the phase index.

### 4.1 20FCh–2100h — memory-test entry and prefix alignment (corrected 2026-11-17)

The actual entry is the stack-return continuation at 20FCh. At 20F4h the BIOS sets SP=20FAh and jumps to 8DDCh; the word at 20FAh–20FBh is 20FCh, so RET resumes there. The aligned bytes are:

\`\`\`asm
20FC  B2 FF                         MOV DL,FFh
20FE  26 66 C7 06 00 00 55 55 AA AA  ES: MOV DWORD PTR [0000h],AAAA5555h
2108  26 66 C7 06 00 01 FF FF FF FF  ES: MOV DWORD PTR [0100h],FFFFFFFFh
2112  26 66 81 3E 00 00 55 55 AA AA  ES: CMP DWORD PTR [0000h],AAAA5555h
211C  0F 85 67 00                    JNE 2187h
\`\`\`

The opcode byte at 2100h is inside the instruction beginning at 20FEh; 2100h is not an independent entry. The two AA bytes at 2106h–2107h are the high half of the immediate AAAA5555h, not STOSB instructions. The previous DS word-store/STOSB interpretation and unresolved-entry statement are withdrawn. The preceding local setup loads ES=0008h from the GDT, a base-zero writable 4-GiB data segment. The first pattern is therefore a 32-bit ES write, not a DS:[0000h] word write. Internal branches to 2187h and 222Dh are confirmed. See AMI486_MEMORY_CHIPSET_INITIALIZATION_20261116.md and AMI486_ADDRESS_LEDGER_REGION_19F8_20FB_20261117.md for the complete corrected path.

### 4.2 A000h–AFFFh — mixed code, pointer data, message text and keyboard tables

Raw samples show several distinct content types inside this 4 KiB area:

- `A000h–A0FFh`: instruction-dense bytes, including BIOS interrupt and register-save/restore sequences.
- `A0F1h–A124h`: 26-entry native little-endian INT 13h function table. The A0A0h dispatcher indexes it with incoming AH (0–19h) via `CS:[DI-5F0Fh]`. Targets: `A197, A20B, A216, A226, A23E, A25F, A18E, A18E, A1A4, A337, A372, A381, A474, A19E, A18E, A18E, A4D3, A501, A18E, A18E, A52B, A1A9, A18E, A18E, A18E, A57B`. A100h is an interior address in this table, not its beginning.
- `A125h–A18Dh`: padded message text including **“Format !!!”**, **“BootSector Write !!!”**, and **“Possible VIRUS: Continue (Y/N)?”**. This is confirmed embedded text/data, not executable code.
- `A18Eh`: aligned bytes `B8 00 01 88 26 74 00 F9 C3`; shared INT 13h unsupported/error stub. It sets AH=01h, stores status 01h at DS:0074h, sets CF and returns.
- `A200h–ACFFh`: instruction-dense routines; raw samples include repeated I/O and conditional control flow. Treat as code candidates with embedded data not yet excluded.
- `AC5Bh–ACFFh`: first keyboard scan-code translation table; code at B031h loads BX=AC60h. AC5Ch–AC5Fh is retained as an unresolved prefix/header. `AD00h–AE5Fh` is a separate keyboard translation-data region with recognizable QWERTY/ASDF/Z/X/C/V/B/N/M and numeric-key sequences.
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

Do not infer that an entire 256-byte page is code because one function starts there. Do not infer data from linear-decoder output alone. No whole-ROM semantic percentage is currently defensible. At the initial snapshot the seeded-window union was 10,700 bytes (16.33%). That historical figure is superseded by the current 35,960-byte (54.87%) candidate footprint in section 11; neither figure is semantic completion.


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
- AE60h onward enters a keyboard/INT 15h related handler path; AC60h–ACFFh and AD00h–AE5Fh remain separate translation-table data regions.

The first A000h seed decodes the initial bytes as unusual but syntactically valid instructions. Its true entry boundary remains unconfirmed; prefer the aligned entries established by direct calls/branches in the seeded listing.


## 8. Subsystem report and corrected storage separation

Detailed byte-backed analysis: [AMI486_STORAGE_AND_DISPATCH_REGIONS_20261116.md](AMI486_STORAGE_AND_DISPATCH_REGIONS_20261116.md).

Important correction to the initial gap hypothesis: A000h–AFFFh is **IDE/ATA hard-disk code**, not floppy code. It accesses 01F0h–01F7h and 03F6h; A406h performs a 256-word data-out transfer, AC00h issues ATA IDENTIFY DEVICE (ECh) and performs a 256-word data-in transfer. A847h displays the embedded Format/BootSector Write/Possible VIRUS prompt and A8F4h accepts Y/N. A95Eh is an INT 13h vector-hook candidate (ES base still to verify).

D100h–D5FFh is the separate floppy-controller/DMA subsystem: FDC ports 03F2h/03F4h/03F5h/03F7h plus DMA ports 0Ch/0Bh/05h/04h.

F92Ah–F935h is a six-word little-endian dispatch table with targets F936h, F986h, F9C4h, F977h, F999h and F9D3h. F977h overlaps the F936h stream as an alternate entry. The F8E7h wrapper ends in IRET at F929h; its actual vector entry remains unknown.

Historical snapshot: 168 code windows plus 18 data ranges (186 headers) produced a 10,700-byte union. The 2026-11-17 generated artifact is 386 code windows plus 74 data ranges (460 headers); the recomputed union is 35,960 bytes across 169 pages. See section 11 for exact byte-mask counts. Neither figure is semantic coverage. Near-branch targets are normalized to 16-bit IP wraparound.


## INT 13h dispatch correction

The initial classification of A100h–A123h as a separate byte-swapped table was wrong. A08Dh is the hooked INT 13h entry; DL<80h is forwarded to INT 40h. A0A0h dispatches by AH through the 26-entry little-endian table at A0F1h–A124h. A100h is an interior byte of the table. The exact targets and selectors are documented in AMI486_STORAGE_AND_DISPATCH_REGIONS_20261116.md.


## INT 13h service contract progress

The 26-entry table's main service targets are now mapped against the actual ATA command bytes and transfer direction. Read (AH=02) uses command 20h and REP INSW; write (AH=03) uses 30h and REP OUTSW; verify (04) uses 40h; format (05) uses 50h after a guard/prompt; get parameters (08), initialize parameters (09/91h), read/write long (0A/0B using 22h/32h), seek (0C/70h), reset (0D), ready/status (10), recalibrate (11/10h), diagnostics (14/90h), and disk type/capacity (15, AH=03h plus CX:DX sector count) are supported by the decoded streams. AH=19h remains open. See AMI486_STORAGE_AND_DISPATCH_REGIONS_20261116.md.


## INT 13h region entry-to-return ledger

A08Dh is the hooked hard-disk INT 13h entry; A0A0h is its AH dispatcher; A0F1h–A124h is the 26-word handler table; A125h–A18Dh is prompt data; A18Eh is the shared unsupported/error stub. The function/helper entry-to-return map from A197h through A946h is now recorded in AMI486_STORAGE_AND_DISPATCH_REGIONS_20261116.md. In particular, A399h is the ATA read data-in path and A406h the data-out path. The AH=05h format and protected write path share the Y/N warning renderer at A847h/A8F4h.


## FDC/DMA subsystem map

See [AMI486_FDC_DMA_SUBSYSTEM_20261116.md](AMI486_FDC_DMA_SUBSYSTEM_20261116.md). D156h programs DMA channel 2 (ports 0Ch/0Bh/05h/04h/81h, then unmasks channel 2 via 0Ah); D243h writes FDC FIFO command bytes, D294h reads result bytes, D270h collects result blocks, D2FDh sends Sense Interrupt Status (08h), D348h toggles DOR 03F2h, D3B5h reads CMOS floppy type register 10h, and D499h performs a three-attempt command/result transaction. D40Ah–D462h is now mapped as data-rate/state-token selection feeding a D499h READ ID transaction; D520h–D5D9h is an enhanced FDC VERSION/DUMPREG/UNLOCK/CONFIGURE/PERPENDICULAR/LOCK sequence. Remaining gaps are low-nibble state-token semantics and the runtime INT 40h chain value.


## Keyboard subsystem map

See [AMI486_KEYBOARD_SUBSYSTEM_20261116.md](AMI486_KEYBOARD_SUBSYSTEM_20261116.md). AC60h–ACFFh is an additional scan-code table referenced by B031h; AD00h–AE5Fh is a separate translation-data region. AE6Fh onward invokes INT 15h AH=4Fh and handles E0h/E1h prefixes and ACK/RESEND bytes. B242h/B253h map lock/modifier scan codes; B26Ah/B273h enable/disable the 8042 interface; B33Dh sends EDh/F4h LED/scanning commands; B3E2h is an INT 16h dispatcher; B399h/B4A9h manage the BIOS ring buffer.


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
| AC5Bh–ACFFh | First keyboard scan-code table and prefix bytes | AMI486_KEYBOARD_SUBSYSTEM_20261116.md |
| AD00h–AE5Fh | Second keyboard translation data region | AMI486_KEYBOARD_SUBSYSTEM_20261116.md |
| AE6Fh onward / B1E9h–B4xxh | Scan-code intercept, 8042 commands, BIOS keyboard buffer and INT 16h services | AMI486_KEYBOARD_SUBSYSTEM_20261116.md |
| 2100h–23E1h | Memory-alias probes, stack-threaded indexed chipset I/O, CR0.PE transition | AMI486_MEMORY_CHIPSET_INITIALIZATION_20261116.md |
| 6700h–68E2h | RTC date/time display and numeric/hex text rendering helpers | AMI486_CLOCK_AND_TEXT_RENDERING_20261116.md |
| D100h–D5FFh | FDC FIFO, DMA channel 2, CMOS floppy type, reset and status/error handling | AMI486_FDC_DMA_SUBSYSTEM_20261116.md |
| E401h–E480h | First eight 16-byte fixed-disk parameter records | AMI486_STORAGE_AND_DISPATCH_REGIONS_20261116.md |
| E845h–E864h | INT 76h / IRQ14 handler | AMI486_STORAGE_AND_DISPATCH_REGIONS_20261116.md |
| F8E7h–F9FCh | BIOS INT 14h serial-service dispatcher and UART handlers | AMI486_INT14_SERIAL_BIOS_20261116.md |

The previous candidate-window artifact had 187 code windows and 41 data ranges, with a 15,639-byte union across 79 pages. This historical snapshot is superseded by the 386/74 artifact and 35,960-byte union in section 11.


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

The previous generator snapshot reported 187 code windows and 35 deduplicated data ranges (15,639 bytes across 79 pages). This is historical and superseded by the current reproducible 386-window/74-range artifact in section 11.


## 11. Data-region expansion — 2026-11-17

The candidate-window generator now emits 74 explicitly identified data ranges, including the following newly byte-checked groups:

| Range | Classification | Evidence / limits |
|---|---|---|
| 188Eh–18E4h | Four POST resource-conflict messages: Parallel, Serial, Floppy, Hard Disk | NUL-terminated text with CR/LF separators |
| 19B0h–19C9h | Compact numeric/threshold byte table preceding CPU/cache labels | Raw values retained; exact table contract unresolved |
| 19CAh–19F7h | Cache-memory and CPU-clock display strings | Includes “KB CACHE MEMORY”, “MHz CPU Clock”, “MHz DX2 CPU” |
| 2F24h–2F65h | Setup exit confirmation prompts | “Write to CMOS and Exit (Y/N)?” and “Want to Quit Without Saving (Y/N)?” |
| 3624h–36A3h | Secondary Setup keyboard legend and F-key captions | Contains B5h/C6h UI control bytes; not plain ASCII |
| 37C3h–3805h | Setup page legends and border/control bytes | Separate page variants; embedded CP437 navigation symbols |
| 3806h–381Bh | Menu border fill and disk-utility exit legend | Includes CDh border bytes and control prefix |
| 3873h–387Ch | Five hard-disk menu string pointers | Five little-endian pointers into the labels at 381Ch–3865h |
| 387Dh–38ACh | Hard-disk utility menu strings | Three NUL-terminated labels |
| 38ADh–38B8h | Three hard-disk menu descriptors | Four bytes per descriptor: label pointer plus selector/flag bytes |
| 38B9h–38C2h | Five callback pointers | Targets 4AEEh, 4B68h, 4B96h, 4BB1h, 5985h |
| 38C3h–3934h | Bad-track editor labels | NUL-terminated headings and action labels |
| 3935h–3944h | Eight-word bad-track action table | Four string pointers followed by four callback targets |
| 3945h–3C5Bh | Bad-track prompts and error strings | Mixed text and lookup data |
| 8EA7h–8EB0h | Five-word interrupt-dispatch table | Overlaps the linear decode at the 8E89h IRET dispatcher |
| 90BAh–90DDh | INT 15h AH=80h–91h dispatch table | Eighteen little-endian handler offsets |
| 59C0h–59C5h | Three-word prompt pointer table | Raw little-endian words 59C6h, 59E3h and 5A19h resolve to the three prompt strings |
| 59C6h–5A4Bh | Setup load-original/default-values prompts | Three NUL-terminated confirmation strings |
| 7145h–714Dh | Inline “KB/sec ms” throughput label | No terminating NUL before following code at 714Eh |
| 732Bh–737Eh | POST summary navigation legend and frame bytes | Mixed control prefix, navigation glyphs, CDh fill, CR/LF |
| 7380h–78B5h | POST summary labels, Setup help, disk-type choices, calendar names and adjacent pointer tables | Mixed text/structured lookup bytes; not a single string |
| 78B6h–7CE8h | POST error strings, boot/password prompts and keyboard-controller warning | NUL-terminated text block |
| 8000h–81EDh | AMI BIOS identity/OEM block | Includes duplicated-letter AMIBIOS signature, date, copyright, ALI1429 ID strings and padded banner |
| B528h–B55Eh | ASCII character/glyph lookup bytes | Sequential control/printable character values; not a prose string |

The updated generator also removes the redundant 2D00h and misaligned 2D80h exploratory seeds and adds an aligned 2D11h candidate window through 2DF4h. The 2D11h stream is described in section 3 of AMI486_CHIPSET_SETUP_TIMING_OPTIONS_20261116.md; its runtime entry and stack precondition remain unproven.

### Current reproducible candidate footprint

The regenerated manifest reports 386 code windows and 74 data ranges (460 headers). A byte-mask recomputation from the generated listing yields:
- unique code-window bytes: 22,989;
- unique data-range bytes: 13,084;
- overlap: 113;
- union: 35,960 bytes (54.87%);
- touched 256-byte pages: 169/256;
- fully covered 256-byte pages: 98/256.

Do not interpret 54.87% as BIOS semantic completion. The code windows are independent linear decodes; the data ranges include confirmed strings/tables and some mixed blocks whose internal table consumers remain open.


### 11.1 Low-ROM identity block and first code candidate

Raw bytes at 0000h–00EEh form a mixed AMI identity/copyright block rather than a confirmed instruction stream. It contains the repeated-letter AMIBIOS marker, date `04/04/93`, copyright `1985–1993`, American Megatrends attribution, trademark notice and the trailing `UVW` bytes. The candidate generator now emits 0000h–00EEh as a separate hex/data range.

At 00EFh the bytes switch to an executable-looking stream:

```
00EF: 06 1E 16 07 B4 03 B7 00 CD 10 51 52 81 EC 80 00
00FF: 8B EC 8B FC B9 20 00 BE 00 E0 F3 A5 BB 45 30 B8
```

The initial aligned instructions are PUSH ES, PUSH DS, PUSH SS, POP ES, MOV AH,03h, MOV BH,00h, INT 10h, PUSH CX, PUSH DX, SUB SP,0080h, MOV BP,SP, MOV DI,SP, MOV CX,0020h, MOV SI,E000h, REP MOVSW. This is a candidate code stream seeded separately at 00EFh; it is **not yet a proven function entry**. A raw-byte scan found no direct near CALL/JMP target or literal little-endian 00EFh pointer in the ROM. The caller/entry mechanism and the meaning of the copied DS:E000h block remain unresolved. Do not infer reachability from the new seed.

The generator update has been regenerated and verified by a successful GitHub Actions run. The current manifest is 386 code windows and 74 data ranges; the candidate listing SHA is 64c64b7250b8c9271635f38230a89a43a71b34ec.


## 11.2 Low-ROM screen-presentation stream — 2026-11-17

Detailed byte-aligned report: [AMI486_LOW_ROM_SETUP_VIDEO_ENTRY_20261117.md](AMI486_LOW_ROM_SETUP_VIDEO_ENTRY_20261117.md).

- `0000h–00EEh` is an AMI BIOS identity/copyright/pattern data block; `00EFh–0235h` is a separately seeded executable-looking screen-presentation stream.
- The stream saves/restores a 64-byte block at `DS:E000h` through an 80h-byte stack allocation, reads the current INT 10h cursor state, writes Setup/System Configuration field labels and values, and restores cursor state before returning.
- It walks four-byte `next/callback` records beginning directly at `BX=0AF5h`. This differs from the 05B4h dispatcher, which starts at the selected base plus four. The first raw record at 0AF5h is `next=0AEDh, callback=6373h`.
- Runtime entry is still unproven: no direct near CALL/JMP target or literal 00EFh pointer was found. The visible epilogue pops BP/SI/DI that are not pushed within this stream, so the required caller stack frame remains unresolved.
- Do not equate this renderer with the separate 3F7Bh POST summary renderer solely because the screen labels overlap.


### 11.3 Temporary interrupt hooks and calendar refresh — 2026-11-17

Detailed byte-backed report: [AMI486_TEMPORARY_IVT_CALENDAR_REFRESH_20261117.md](AMI486_TEMPORARY_IVT_CALENDAR_REFRESH_20261117.md).

- `626Bh` installs temporary INT 10h/1Ah/1Ch handlers at F000:62ECh, F000:62FCh and F000:631Ch; it saves the previous six IVT words at 0280h–028Ah.
- `62BDh`, the actual CALL target at 0210h, restores those six IVT words and returns with STI. The earlier 6220h target annotation is withdrawn.
- The INT 10h/1Ah hooks forward through existing INT A0h/A1h vectors and bracket the calls with a nesting counter at 028Eh.
- The INT 1Ch hook uses the BIOS tick count, defers while the nesting counter is nonzero, and calls 6616h to refresh a calendar/date display; it then invokes INT A2h.
- `6616h` reads the BIOS date through INT 1Ah AH=04h (6774h), validates BCD through 68E2h, converts through 68FDh, and uses CS tables 6164h/616Bh for calendar placement.
- The raw 6616h stream has been checked through RET at 6757h. The generator source requests a 0142h window, but the generated listing still shows the previous 0080h window; this generation mismatch remains open.


### 11.4 16-bit sign-extension mnemonic correction — 2026-11-17

The candidate-window generator and full-linear GitHub Actions workflow now normalize unprefixed opcodes:
- `98h` -> `CBW` (not `CWDE`)
- `99h` -> `CWD` (not `CDQ`)

The previous candidate listing contained 31 such mislabeled lines. After regeneration, the candidate listing contains zero `cwde`/`cdq` mnemonics. The full linear listing blob changed after the workflow update; its manifest still reports 29,731 decode records and complete 65,536-byte linear coverage. Operand-size-prefixed forms are not rewritten.


### 11.5 Palette table and screen field helper expansion — 2026-11-17

Detailed helper contracts: [AMI486_SCREEN_RENDERER_HELPERS_20261117.md](AMI486_SCREEN_RENDERER_HELPERS_20261117.md).

- `562Bh–566Ah` is a 16-entry × 4-byte attribute palette table selected by `[E037h]&0Fh`.
- F2/F3 input at 08CDh increments/decrements the palette index through 56AEh; the four selected bytes expand into eight attribute variants at E1A2h–E1A9h.
- 5821h applies selected attribute bits to a rectangular text region while preserving the character bytes.
- 04B0h computes hard-disk capacity from sectors × heads × cylinders, divides by 2048 sectors per MiB and rounds to nearest MiB; it saturates at FFFFh on overflow and prints the result with an MB suffix.
- 0A15h prints a fixed-width decimal field followed by a space and KB suffix; 0975h prints a space and MB suffix.
- 03D4h is a field editor with record callbacks; 08CDh handles F2/F3 and arrow/Enter scan codes.


## 12. Region-ledger expansion — 2026-11-17

Two major gaps have now been traced from aligned code and raw tables:

- [AMI486_ADDRESS_LEDGER_REGION_4628_55A7_20261117.md](AMI486_ADDRESS_LEDGER_REGION_4628_55A7_20261117.md): Setup hard-disk utility, five callback offsets at 38B9h, bad-track action table at 3935h, E436h three-byte records, POST transition and memory-pattern helpers at 552Dh.
- [AMI486_ADDRESS_LEDGER_REGION_8E89_93F7_20261117.md](AMI486_ADDRESS_LEDGER_REGION_8E89_93F7_20261117.md): overlapping five-word dispatch table at 8EA7h, timing classifier and PIT2 benchmark at 8F12h–90B0h, INT 15h AH=80h–91h dispatch at 9220h, and handlers for AH=83h/84h/86h/87h/88h/89h.

The generator now seeds these aligned entries and emits the pointer tables separately from instruction streams. The 8EA7h table is intentionally recorded as an overlapping data view; the 90BAh table is 18 words.

Current largest uncovered contiguous intervals in the regenerated candidate map:
- B7B1h–C5F9h: 3,657 bytes
- D65Bh–E400h: 3,494 bytes
- E865h–F52Dh: 3,273 bytes
- 93F8h–9FFFh: 3,080 bytes
- 81EEh–8DCEh: 3,041 bytes
- 697Dh–7144h: 1,992 bytes

The next selected interval is 93F8h–9FFFh: it is the immediate continuation of the INT 15h/controller cluster and contains keyboard-controller and video-BIOS service paths. The other larger gaps remain queued by reference density and subsystem continuity, not by numeric phase order.

These metrics describe independently seeded candidate windows and explicitly classified data ranges only. They do not prove that the remaining bytes are data, nor that all included windows are reachable code.


## 13. Setup catalog and INT 10h video expansion — 2026-11-17

Additional byte-backed reports:
- [AMI486_ADDRESS_LEDGER_REGION_93F8_9870_20261117.md](AMI486_ADDRESS_LEDGER_REGION_93F8_9870_20261117.md): PS/2 auxiliary-device services, eight-function mouse command table, sample-rate table, IRQ12 packet decoder and callback pointer.
- [AMI486_ADDRESS_LEDGER_REGION_9848_A017_20261117.md](AMI486_ADDRESS_LEDGER_REGION_9848_A017_20261117.md): INT 10h video dispatcher and 20-entry AH=00h–13h handler table, cursor/page/scroll/text/pixel services.
- [AMI486_ADDRESS_LEDGER_REGION_B7B1_C5FA_20261117.md](AMI486_ADDRESS_LEDGER_REGION_B7B1_C5FA_20261117.md): Advanced CMOS and Advanced Chipset Setup data pages, 15-word callback table at B7B2h, and two previously unseeded far callback targets (29F6h and 86DBh).

The generated candidate artifact now emits all confirmed tables separately:
- 8EA7h–8EB0h: five-word interrupt-style callback table;
- 90BAh–90DDh: 18-word INT 15h AH=80h–91h dispatch table;
- 94FAh–9509h: eight-word PS/2 mouse service table;
- 9589h–958Fh: sample-rate values;
- 9784h–9793h: IRQ12 packet-dispatch table;
- 9848h–986Fh: 20-word INT 10h dispatch table;
- B7B2h–B7CFh: 15-word Advanced Setup callback table.

Current byte-mask metrics: 386 code windows, 74 data ranges, 22,989 unique code-window bytes, 13,084 unique data-range bytes, 113 overlap bytes, 35,960-byte union (54.87%), 169 pages touched and 98 pages fully covered. Candidate listing blob SHA: 64c64b7250b8c9271635f38230a89a43a71b34ec.

Historical gap ranking at the 2026-11-16 snapshot: D65Bh–E400h, E865h–F52Dh and 697Dh–7144h were then queued. The E865h–F52Dh and 697Dh–7144h intervals have since been mapped in sections 15–16; use the latest mask below for current priorities.


## 14. POST CMOS 8Fh / CMOS 8Eh and protected-mode data — 2026-11-17

Byte-backed report: [AMI486_ADDRESS_LEDGER_REGION_D655_E3FF_20261117.md](AMI486_ADDRESS_LEDGER_REGION_D655_E3FF_20261117.md).

The previous D65Bh–E400h candidate-mask gap is now classified into aligned POST code, stack-return data, a CMOS 8Fh selector table, zero padding, ROM strings, descriptor-like records and a separate POST chipset-port stream. D65Bh itself is not an entry: it lies inside the instruction beginning at D657h. The D6A8h–D6BDh table is the eleven-word D6A2h indirect-jump table already examined in phases 51–52. DAA2h–DFFFh is verified zero padding.

A new direct transfer was found: D8FEh prepares the stack return to D906h; D906h emits POST status 0Fh and directly JMPs to 8400h. The 8400h routine is therefore a confirmed non-table entry into the CMOS 8Eh initialization path. It clears CMOS registers 8Eh–FFh, restores the 32-byte 8Eh–ADh block from the ROM table at 820Eh and merges additional table-driven fields. Its `AND BP,FFC7h` clears bits 3–5 but preserves BP.13, so the BP.13 producer remains unresolved. Phase 52 and the index have been corrected accordingly.

Historical snapshot before the E862h–F52Dh and Hard Disk Setup expansions: 440 code windows / 120 data ranges, 39,603 unique union bytes (60.43%), 183 pages touched and 109 fully covered. This is retained for chronology only; the current mask is recorded in sections 15–16.


## 15. Interrupt, CMOS/RTC, protected-mode and video diagnostic block — 2026-11-17

Report: [AMI486_ADDRESS_LEDGER_REGION_E862_F52D_20261117.md](AMI486_ADDRESS_LEDGER_REGION_E862_F52D_20261117.md).

The former E865h–F52Dh candidate gap is now represented by bounded code windows and explicit data ranges. The mapped content includes polling helpers, parity/NMI diagnostics, RTC/PIC/timer handlers, INT 1Ah-compatible time/date services, CMOS access helpers, a protected-mode-assisted 0F05h path, CMOS Setup editing, an encoded evaluation-copy message, video/ROM signature checks and fatal POST diagnostics. Strings, padding, the opaque EFC7h–F041h block, F0A3h parameter tables and the F3BCh signature bytes are separated from executable windows. The report deliberately leaves interrupt-vector installation and opaque-table consumers open where no direct evidence was found.

Historical candidate-mask snapshot before the Hard Disk Setup expansion: 508 code windows, 136 data ranges, 27,247 unique code-window bytes, 15,754 unique data-range bytes, 117 overlap bytes, 42,884-byte union (65.44%), 70 uncovered intervals, 195 pages touched and 118 fully covered. Superseded by section 16.


## 16. Hard Disk Setup / INT 13h diagnostic and throughput region — 2026-11-17

Report: [AMI486_ADDRESS_LEDGER_REGION_696F_72D8_20261117.md](AMI486_ADDRESS_LEDGER_REGION_696F_72D8_20261117.md).

The D697Dh–D7144h gap is now mapped as part of the Hard Disk Setup subsystem. The UI at 4628h–46E8h cycles E1ACh through three options and displays drive geometry headings and “No Hard Disk Installed” / “Hard Disk Type can be changed from”. The direct dispatcher caller is 6936h; it calls 6BDEh, which selects one of three handlers through the three-word table at 6BD8h: 6B14h, 71E4h or 6CE3h. The subsystem includes an INT 13h wrapper at 6C15h, disk request/transfer loops at 6D94h/6E30h, status-token lookup at 6CB4h, and a 40-sector repeated-read benchmark at 7033h that prints “KB/sec ms” at 7145h.

Historical candidate-mask snapshot after the Hard Disk Setup expansion but before the 19B0h–23CEh expansion: 541 code windows, 140 data ranges, 29,460 unique code-window bytes, 15,775 unique data-range bytes, 117 overlap bytes, 45,118-byte union (68.84%), 71 uncovered intervals, 203 pages touched and 125 fully covered. Superseded by section 17.


## 17. POST/cache/ALi/option-ROM/A20 region — 2026-11-17

Overview: [AMI486_ADDRESS_LEDGER_REGION_19B0_23CE_20261117.md](AMI486_ADDRESS_LEDGER_REGION_19B0_23CE_20261117.md).  
Focused byte map and alignment correction: [AMI486_ADDRESS_LEDGER_REGION_19F8_20FB_20261117.md](AMI486_ADDRESS_LEDGER_REGION_19F8_20FB_20261117.md).

The former 19F8h–20FFh gap is fully covered. The region includes cache/CPU-speed display, CMOS B3h profile selection, option-ROM scanning and checksum validation, manual CMOS-to-ALi configuration, POST A1h/A4h handlers, the 8750h–87A3h 21-record ALi write view (overlapping the first 21 records of the 76-record suffix within the 81-record 873Ch array) and the A20-bracketed protected-mode memory-address probe.

The exact stack-return words are at 1B04h (->1B06h), 1B2Ah (->1B2Ch), 2096h (->2098h), 20C2h (->20C4h), 20CCh (->20CEh), 20D8h (->20DAh) and 20FAh (->20FCh). D9D9h directly jumps to 1AFBh. The 20DAh transition loads ES=0008h; AX=4410h is an ALi register 10h/value 44h write, not a segment selector. The memory-probe entry is 20FCh; the first ES:66-prefixed dword store starts at 20FEh and crosses 2100h.

Historical mask before the INT 13h diskette expansion: 597 code windows, 154 data ranges, 31,189 unique code bytes, 15,829 unique data bytes, 117 overlap bytes, 46,901-byte union (71.57%), 69 uncovered intervals, 210 pages touched and 133 fully covered pages. Superseded by section 18.


## 18. INT 13h diskette / drive-parameter subsystem — 2026-11-17

Detailed map: [AMI486_ADDRESS_LEDGER_REGION_CA15_D103_20261117.md](AMI486_ADDRESS_LEDGER_REGION_CA15_D103_20261117.md).

The former CA16h–D0FFh gap (1,770 bytes) is now covered by byte-aligned code windows and explicit data ranges. CA15h is the fall-through entry, CA17h is a confirmed branch target, and the region contains INT 13h geometry/parameter selection, CMOS drive-state handling, controller-presence checks, floppy command/status routines, motor/readiness control and INT 1Eh geometry comparison.

The two tables at CAA7h are:
- Geometry/signature words: 2709h, 4F0Fh, 4F09h, 4F12h, 4F24h.
- Parameter-record pointers: CABBh, C8CAh, CAD5h, CAE2h, CAFCh.

Six 13-byte parameter records occupy CABBh–CB08h. The C8CAh record is a data view that overlaps an executable continuation after CALL D0D9h at C8C7h. CB09h and CBF8h are coherent code candidates without direct near xrefs; entry provenance remains open. D0D9h ends at D103h, including POP AX/RET.

Current mask after the 873Ch–8DCEh expansion: 678 code windows, 205 data ranges, 34,292 unique code bytes, 16,419 unique data bytes, 213 overlap bytes, 50,498-byte union (77.05%), 70 uncovered intervals, 223 pages touched and 147 fully covered pages. The next largest uncovered interval is 2436h–29F5h (1,472 bytes). This remains a candidate inspection mask, not semantic completion.


## 19. CMOS/ALi configuration arrays, POST chipset helpers and controller dispatch — 873Ch–8DCEh (2026-11-17)

Detailed byte map: [AMI486_ADDRESS_LEDGER_REGION_873C_8DCE_20261117.md](AMI486_ADDRESS_LEDGER_REGION_873C_8DCE_20261117.md).

The former 1,683-byte candidate gap now has zero uncovered bytes in the code/data inspection mask. The region includes:
- The 81-entry four-byte array at 873Ch–887Fh, its five-entry prefix, 76-entry suffix and count words at 8880h/8882h/8884h/8886h; 8888h is the E0h key threshold.
- Four confirmed consumer views of the same bytes: 8400h CMOS default application, 8378h key lookup returning byte +3, 85FEh masked E000h/E080h configuration-buffer update, and the 208Dh 21-record ALi write table at 8750h–87A3h. The 21-record ALi view overlaps the first 21 records of the 76-entry suffix; it is not a separate physical table allocation.
- A 14-row AUTO Config lookup view at 87A9h with 20-byte row stride and fields at +0/+4/+8/+0Ch, extending through 88BBh. Row 11 overlaps the 8886h count/8888h threshold area; rows 12/13 overlap executable bytes at 8898h–88BBh.
- The 85B3h wrapper's fall-through into the 76-record suffix at 85C0h; in the stock ROM it processes 5 + 0 + 0 + 76 = 81 records and returns at 862Fh. Phase 6 was corrected in place.
- POST CMOS B3h/ALi C2h-C3h operations, CMOS 8Fh reset path, B3h-selected ALi profile path, 82DAh hook sequence, INT 15h keyboard hook, controller/port configuration helpers, CR0 cache-state continuations, 8042 transaction helper and ALi indexed-register callbacks.

Crafted stack-return words are separated from code continuations. Bytes 8893h–8898h, runtime table provenance and ALi register meanings remain unresolved. The candidate mask is an inspection aid, not a semantic-completion percentage.


## 20. Upper-ROM checksum, bitmap and metadata tail — FA4Eh–FFFFh (2026-11-17)

Detailed byte map: [AMI486_ADDRESS_LEDGER_REGION_FA4E_FFFF_20261117.md](AMI486_ADDRESS_LEDGER_REGION_FA4E_FFFF_20261117.md).

The former candidate-mask gap FA53h–FFFFh has been inspected, with the checksum entry at FA4Eh included because it is reached by the POST stack-threaded transfer at E34Dh/E350h. FA4Eh compares 76 bytes at FA00h–FA4Bh against the bitwise complement of FF70h–FFBBh. The BX increment at FA5Ah is before the indexed read, so the compared low-memory interval begins at FA00h, not F9FFh. A matching sequence returns through POPA/RET at FA4Ch–FA4Dh; a mismatch falls through to RET at FA64h with the PUSHA frame still on the stack.

FA6Eh–FE6Dh is a 1-KiB structured bitmap/glyph candidate (128 eight-byte records); the bitmap ends at FE6Dh and the three-byte near JMP begins at FE6Eh. FE71h–FEA0h is structured data, FEA1h–FEA7h is a short record, and FEA8h–FEE3h is zero-filled. FEE3h–FF32h is now confirmed as a 40-word POST IVT offset table: 32 offsets for vectors 00h–1Fh and eight offsets for 70h–77h; FF33h–FF4Fh is zero padding. FF59h–FF6Fh contains the printable identification string (1992AMI,404-263-8181; FF70h–FFBBh is the verified complement data. FFC7h–FFEFh duplicates FE75h–FE9Dh. FFF0h–FFF4h is the reset vector EA 5B E0 00 F0, and FFF5h–FFFCh is the date 04/04/93.

This closes the byte-inspection pass for the largest remaining gap in the 79.30% candidate-mask snapshot. The candidate generator now includes the FA4Eh and FE6Eh seeds plus the confirmed bitmap/data ranges. The generator was extended to calculate the exact code/data union mask and largest uncovered intervals. GitHub Actions run 44082883079 completed successfully: 753 windows, 228 data ranges, 36,898 unique code-window bytes, 18,012 unique data-range bytes, 290 overlap bytes, and a 54,620-byte union (83.34%), with 70 uncovered intervals and 236 touched / 161 fully covered pages. The next largest uncovered interval is 1365h–188Dh (1,321 bytes). This remains candidate-mask coverage, not semantic completion. No whole-ROM semantic completion percentage is claimed.


## 21. POST/Setup and IVT initialization — 5A4Ch–5FE3h (2026-11-17)

Detailed map: [AMI486_ADDRESS_LEDGER_REGION_5A4C_5FE3_20261117.md](AMI486_ADDRESS_LEDGER_REGION_5A4C_5FE3_20261117.md).

Mapped the former 1,432-byte gap as Setup/configuration callbacks (5AA2h, 5AB5h, 5AECh, 5B7Ch, 5BD5h), stack-threaded POST memory-test continuations (5BF8h–5C68h), keyboard-controller initialization, IVT/BDA/PIC setup, option-ROM/shadow-window scanning, and video-adapter selection. Four crafted return words at 5C02h, 5C24h, 5C56h and 5C66h are data, not linear instructions.

The POST copies a 40-word offset table from FEE3h–FF32h into IVT vectors 00h–1Fh and 70h–77h, after filling vectors 00h–77h with the common CS:EA97h entry. The 5E88h–5F64h block and called helpers at 5F65h/5FA7h remain opaque; no unsupported code/data label was assigned.

The candidate generator now contains bounded entries and stack-return data boundaries for this region. GitHub Actions run 44082883079 passed and produced 753 windows / 228 data ranges, 54,620 covered bytes (83.34%), 70 uncovered intervals. The next largest uncovered interval is 1365h–188Dh (1,321 bytes).


## 22. POST initialization, RTC, FPU, CMOS and I/O — 1364h–188Dh (2026-11-17)

Detailed map: [AMI486_ADDRESS_LEDGER_REGION_1364_188D_20261117.md](AMI486_ADDRESS_LEDGER_REGION_1364_188D_20261117.md).

The actual entry is 1364h, reached by the stack-threaded continuation at 135Dh after the FA4Eh integrity check. The 1364h–1655h POST stream updates conventional-memory size, validates RTC time and converts BCD time to BIOS ticks, enumerates I/O resources, detects the FPU, performs CMOS/ALi configuration, scans option-ROM/shadow windows and continues video setup. An eight-byte XLAT table at 15CEh–15D5h is split out as data. Helper 1656h displays RUN SETUP UTILITY / Press <F1> to RESUME and waits for F1 when warning flags require it. Other mapped helpers include BCD conversion, CMOS pair reads, I/O resource probes, CMOS checksum accumulation/storage, ATA device-control reset and 8042 output-buffer drain.

The second CMOS checksum loop has a variable upper bound at CS:82B3h and skips BFh/C0h when CX reaches BEh; preserve that behavior rather than hard-coding a range. Candidate generation was updated to split the embedded lookup table and seed the helper entries. GitHub Actions run 44083305295 passed: 772 windows / 229 data ranges, 55,941 covered bytes (85.36%), 69 uncovered intervals. The next largest gap is E481h–E830h (944 bytes).


## 23. Fixed-disk parameter table and 8042 helpers — E481h–E830h (2026-11-17)

Detailed map: [AMI486_ADDRESS_LEDGER_REGION_E481_E830_20261117.md](AMI486_ADDRESS_LEDGER_REGION_E481_E830_20261117.md).

E481h–E6F0h continues the 16-byte fixed-disk parameter table already recorded at E401h–E480h: 39 more records, 47 records total across E401h–E6F0h. E6F2h is a near JMP to F758h. E729h–E738h is an eight-word UART baud-divisor table (110–9600 baud); E739h is the INT 14h trampoline to F8E3h. The remaining E6F5h–E728h and E73Ch–E7E7h blocks remain opaque data. E7E8h–E82Dh contains 8042 keyboard-controller helpers, E82Eh is the INT 16h trampoline to B3DEh, and EFD2h is the INT 17h trampoline to F85Eh.

The candidate generator now splits the table, padding, jump, payload and helper entries. GitHub Actions run 44084310128 passed: 811 windows / 237 data ranges, 57,709 covered bytes (88.06%), 68 uncovered intervals. The next largest uncovered interval is 7CE9h–7FFFh (791 bytes). The fixed-disk record field semantics and payload consumer remain open.


## 24. 8042, option-ROM, boot and BIOS interrupt services — F5AEh–F8E6h (2026-11-17)

Detailed map: [AMI486_ADDRESS_LEDGER_REGION_F5AE_F8E6_20261117.md](AMI486_ADDRESS_LEDGER_REGION_F5AE_F8E6_20261117.md).

Mapped the 8042 command/data/status helpers F5BCh–F670h, generic I/O port test F691h/F6B8h, option-ROM scanner F6D9h, INT 19h bootstrap F758h, four-retry INT 13h read helper F810h, INT 11h/12h handlers F84Dh/F841h, INT 14h serial handler trampoline E739h→F8E3h, INT 15h trampoline F859h→90B4h, INT 16h trampoline E82Eh→B3DEh, and INT 17h printer handler trampoline EFD2h→F85Eh. The INT 14h dispatcher uses six handler offsets at F92Ah–F935h. F82Ch–F840h and F85Ch–F85Dh are padding; F5AEh–F5B1h remains opaque.

The candidate generator now includes bounded seeds and data/padding boundaries for this region. GitHub Actions run 44084310128 passed: 811 windows / 237 data ranges, 57,709 covered bytes (88.06%), 68 uncovered intervals. The next largest uncovered interval is 7CE9h–7FFFh (791 bytes).


## 25. Zero-filled ROM tail — 7CE9h–7FFFh (2026-11-17)

Detailed verification: [AMI486_ADDRESS_LEDGER_REGION_7CE9_7FFF_20261117.md](AMI486_ADDRESS_LEDGER_REGION_7CE9_7FFF_20261117.md).

The entire 791-byte interval 7CE9h–7FFFh is verified as 00h (791 zero bytes, zero nonzero bytes). It is padding/reserved ROM space, not code or an embedded table. The candidate generator now includes it as a single zero-filled data range. GitHub Actions run 44084573238 passed: 811 windows / 238 data ranges, 58,500 covered bytes (89.26%), 67 uncovered intervals. The next largest uncovered interval is 639Ch–6615h (634 bytes).


## 26. RTC date/time Setup editor — 639Ch–6615h (2026-11-17)

Detailed map: [AMI486_ADDRESS_LEDGER_REGION_639C_6615_20261117.md](AMI486_ADDRESS_LEDGER_REGION_639C_6615_20261117.md).

Mapped the RTC Setup editor continuation: day/month/year fields use INT 1Ah AH=04h/AH=05h; hour/minute/second use AH=02h/AH=03h. The visible UI explicitly specifies 24-hour time and date/year ranges. Helper 6774h validates RTC date (1901–2099; invalid values default to 1980-01-01); 67AEh validates time (invalid values default to 00:00:00); 65BFh/65C4h validate month/day with February leap-year handling. The adjacent 6616h display routine calculates weekday from the 6164h/616Bh tables and uses weekday/month abbreviations at 7829h/7845h.

Candidate generation now includes bounded seeds for the editor and its field-rendering/date-validation helpers. GitHub Actions run 44084872234 passed: 819 windows / 238 data ranges, 59,134 covered bytes (90.23%), 66 uncovered intervals. The next largest uncovered interval is AF86h–B1E8h (611 bytes).


## 27. INT 09h keyboard IRQ scan-code handler — AF86h–B1E8h (2026-11-17)

Detailed map: [AMI486_ADDRESS_LEDGER_REGION_AF86_B1E8_20261117.md](AMI486_ADDRESS_LEDGER_REGION_AF86_B1E8_20261117.md).

The IVT INT 09h entry at E987h jumps to AF60h. The AF60h prelude selects the AF84h/B2E5h path, AF87h/B1DFh common exit, AF8Ah/B1E4h alternate exit, or the main scan-code body at AF8Dh. The body updates BDA keyboard state bytes 0017h/0018h/0019h, handles SysRq via INT 15h/AH=85h, Ctrl+Alt+Delete via warm-boot flag 0000:0072h=1234h and jump to F000:E05Bh, Ctrl-Break via INT 1Bh, PrintScreen and extended-key paths, and Alt-numeric entry. The shared IRQ tail clears BDA:0096h as appropriate, sends PIC EOI and restores the interrupt frame.

The candidate generator now includes the split branch and bounded entries for the main handler and alternate epilogues. GitHub Actions run 44085161932 passed: 825 windows / 238 data ranges, 59,745 covered bytes (91.16%), 65 uncovered intervals. The next largest uncovered interval is 10DFh–131Eh (576 bytes).


## 28. POST 8042/CMOS/video initialization — 10DFh–131Eh (2026-11-17)

Detailed map: [AMI486_ADDRESS_LEDGER_REGION_10DF_131E_20261117.md](AMI486_ADDRESS_LEDGER_REGION_10DF_131E_20261117.md).

Mapped the POST continuation that initializes/tests the 8042 keyboard controller (command byte, FFh reset, FAh ACK, AAh self-test), initializes keyboard-buffer pointers and PIC mask, validates CMOS memory/configuration against BDA values, enumerates I/O resources, displays the Setup warning through 1656h when BP error flags are set, and continues chipset/video setup through 1C4Eh/1C4Fh/1C50h/1C5Eh, INT 11h and INT 10h. The CALL at 131Dh to 135Ah is included completely by extending the candidate window one byte beyond the old gap. The initial 10DFh entry provenance remains unresolved; the first three bytes are retained rather than discarded.

GitHub Actions run 44085575642 passed: 826 windows / 238 data ranges, 60,321 covered bytes (92.04%), 64 uncovered intervals. The next largest uncovered interval is 066Bh–084Eh (484 bytes).


## 29. BIOS Setup numeric/text field editor — 066Bh–084Eh (2026-11-17)

Detailed map: [AMI486_ADDRESS_LEDGER_REGION_066B_084E_20261117.md](AMI486_ADDRESS_LEDGER_REGION_066B_084E_20261117.md).

Mapped the BP-relative field setters at 066Bh/068Ah/069Ch/06AEh, generic numeric editor 06C9h, render/cursor helpers 0731h/0744h/0749h, keyboard input loop 076Bh–080Eh, decimal parser/range checker 080Fh–0844h, and text-editor prologue 0845h→0892h. The numeric editor is called by Setup routines at 4BA3h/4F4Ch/4F67h, including fixed-disk parameter editing through CS:E422h/E436h. The text entry is called from 05E5h; its exact field meaning remains unresolved.

GitHub Actions run 44085877262 passed: 837 windows / 238 data ranges, 60,805 covered bytes (92.78%), 63 uncovered intervals. The next largest uncovered interval is 3C5Ch–3E3Dh (483 bytes).


## 30. BIOS Setup main menu — 3C5Ch–3E3Eh (2026-11-17)

Detailed map: [AMI486_ADDRESS_LEDGER_REGION_3C5C_3E3E_20261117.md](AMI486_ADDRESS_LEDGER_REGION_3C5C_3E3E_20261117.md).

Mapped the 12-option BIOS Setup main menu entered by JMP 2F21h→3C5Eh. It uses label pointers at 342Eh–3445h and 12 handler offsets at 3446h–345Dh. The options cover Standard/Advanced CMOS, chipset, power, peripheral settings, BIOS and power-on defaults, password, hard-disk detection/formatting, and write/no-write exit. The menu loop updates selection state at E187h/E188h, handles navigation/Enter/Esc, dispatches through the handler table, and displays the WARNING INFORMATION page with Setup safety instructions. The two leading bytes at 3C5Ch–3C5Dh are zero padding; 3E3Eh is the menu routine's RET.

The generator now includes the full 12-entry handler table and the bounded menu loop. GitHub Actions run 44086115994 passed: 838 windows / 239 data ranges, 61,288 covered bytes (93.52%), 62 uncovered intervals. The next largest uncovered interval is 0236h–03D3h (414 bytes).


## 31. Standard CMOS Setup field handlers — 0236h–03D3h (2026-11-17)

Detailed map: [AMI486_ADDRESS_LEDGER_REGION_0236_03D3_20261117.md](AMI486_ADDRESS_LEDGER_REGION_0236_03D3_20261117.md).

Mapped the video display type field (options at 769Dh), keyboard-test Installed/Not Installed field (77D7h), an Enabled/Disabled bit-6 option, and four fixed-disk type nibble selectors at 02DBh/02F1h/0319h/0351h. The shared disk-type chooser at 0367h supports fixed types 01h–46h and user-defined type 47h, with geometry fields for the custom type. The 0294h–02A3h eight-word block is retained as an unresolved dispatch/offset table, not linear code. The Standard CMOS Setup handler at 00ECh dispatches through the 16-entry table at 0AF5h; four entries point into this region.

GitHub Actions run 44086705207 passed: 851 windows / 240 data ranges, 61,702 covered bytes (94.15%), 61 uncovered intervals. The next largest uncovered interval is 81EEh–8377h (394 bytes).


## 32. Advanced CMOS CPU/cache profile data and CMOS 8Eh selector — 81EEh–8377h (2026-11-17)

Detailed map: [AMI486_ADDRESS_LEDGER_REGION_81EE_8378_20261117.md](AMI486_ADDRESS_LEDGER_REGION_81EE_8378_20261117.md).

Corrected the previous boundary error. The data block ends at 8325h, not 8327h. Executable entries are 8300h (BX-preserving wrapper), 8306h (profile-index selector) and 8326h (shared profile-record walker). The 831Bh branch enters the walker at 832Fh with BX=B7D0h. The path that subtracts 0055h from AX falls through into 8326h; there is no RET at 8325h. The walker uses 20h-byte profile records and updates CMOS register 8Eh. The old seeds 8328h and 832Eh were removed because they split instructions.

Generator boundary correction: a263b7baf68c45be27e3d1aefde63efd0fdc7251. Corrected semantic report: 6232d1771e4b9552bc7df9fbeceb6c10635ff23d.

The last generated manifest (commit 81616282fb759ee64603a84a7fc43f1c5170961c) reports 858 windows, 242 data ranges, 62,431 covered bytes (95.26%), and 60 uncovered intervals. That manifest predates the later 84CBh boundary correction below and is not the final current coverage result.

## 33. Advanced CMOS Setup descriptor table and page initializers — 0B2Dh–0C7Ch (2026-11-17)

Detailed map: [AMI486_ADDRESS_LEDGER_REGION_0B2D_0C7D_20261117.md](AMI486_ADDRESS_LEDGER_REGION_0B2D_0C7D_20261117.md).

Mapped the 45-entry descriptor/handler table at 0B2Dh–0BE0h and the code/data overlap at 0BDEh. The final table record begins at 0BDDh (words 8300h/CA3Eh); executable code begins at 0BDEh and consumes three bytes of that record. Corrected the following entry boundaries: 0C04h, 0C2Bh and 0C52h are one-byte RET stubs, not page initializer entries. The actual initializers begin at 0C05h (B7CCh gate), 0C2Ch (B7CEh gate) and 0C53h (CPU clock/cache profile page). Each configures the E191h–E197h parameter block and calls the shared page engine at 0C7Dh.

Generator boundary correction: 0f65a99fd1a1675c6bcae794eb2ff3e1c0da8388. A post-correction manifest has not yet been generated.

## 34. CMOS Setup staging, checksum and CMOS writeback — 84BEh–85B2h (2026-11-17)

Detailed map: [AMI486_ADDRESS_LEDGER_REGION_84BE_85B3_20261117.md](AMI486_ADDRESS_LEDGER_REGION_84BE_85B3_20261117.md).

The 84BEh window was clipped in the middle of the near JMP at 84C8h. Extended it by one byte to include the final displacement byte at 84CAh; the JMP target is D90Dh. The next candidate stream starts at 84CBh. Mapped the CMOS Setup staging path, which loads configuration bytes from CMOS or the profile defaults into E010h, runs helper/update calls, copies the 80h-byte E000h buffer, calculates checksums for the staged blocks, and writes the configuration back to CMOS beginning at register 8Eh. The separate 8530h validation path preserves flags from 1A92h and clears the warm-boot flag/jumps to the BIOS reset entry if the saved status is not successful.

Generator boundary correction: 8870769cf5fe72ff720f5cca99c29ca012baea13. The next manifest must be regenerated before reporting a new global coverage percentage or selecting the next largest uncovered interval.


## 35. Setup exit prompts and temporary INT 13h/IVT path — 2F66h–3043h (2026-11-17)

Detailed map: [AMI486_ADDRESS_LEDGER_REGION_2F66_3044_20261117.md](AMI486_ADDRESS_LEDGER_REGION_2F66_3044_20261117.md).

Classified 2F66h as the final NUL byte of the two Setup exit prompts. The handler at 2F67h is called from 3D73h and asks “Write to CMOS and Exit” followed by “Want to Quit Without Saving”; either affirmative response restores the saved Setup SS:SP from BDA 0469h/0467h. The helper at 2F8Fh clears selected BDA/low-memory fields. The routine at 2FA3h, called from 4A6Bh, saves four IVT vectors, temporarily substitutes INT 13h and INT 41h/46h vectors, invokes INT 13h AH=14h, then restores the original vectors. The string block begins at 3044h.

Generator update: fe81b16853fccc3a4befc7736982bd04fca58d1a. This update, along with the 0B2Dh and 84BEh boundary corrections, has not yet been followed by a regenerated manifest. The last generated manifest (81616282fb759ee64603a84a7fc43f1c5170961c) showed 62,431/65,536 bytes (95.26%) and 60 uncovered intervals before these additions. The exact added ranges imply a projected union of 62,887 bytes (95.96%) and 57 remaining intervals; this was arithmetic from the prior manifest, not a verified generator/CI result. Section 36 below closes the next 5E88h–5F64h gap; the projection is updated there.

## 36. POST video/adapter initialization and overlapping alternate stream — 5E3Dh–5F64h (2026-11-17)

Detailed map: [AMI486_ADDRESS_LEDGER_REGION_5E3D_5F65_20261117.md](AMI486_ADDRESS_LEDGER_REGION_5E3D_5F65_20261117.md).

Extended the 5E3Dh POST video/adapter window across the split conditional branch at 5E86h–5E88h. The main stream selects B000h/B800h video memory, updates BDA video-state bits, tests CMOS 8Eh, invokes BIOS video/cursor services, emits POST codes 2Fh–3Bh and jumps to 509Eh. The unconditional short JMP at 5E6Dh also targets 5EB6h, which overlaps the displacement byte of the linear CALL at 5EB4h. Added 5EB6h as a separate alternate decode stream rather than forcing one instruction alignment.

Generator update: b9d2e85c35663cf6138cfb1ef6a2496e31cb1e7a. The latest generated manifest still predates this update. Based on the previous projected union of 62,887 bytes, this 221-byte extension gives a projected union of 63,108/65,536 bytes (96.30%) and 56 uncovered intervals. The next largest remaining interval is expected to be 18E5h–19AFh (203 bytes). These are range-union calculations, not a regenerated manifest or CI result.

## 37. I/O resource-conflict probes and CPU/cache profile dispatch stubs — 18E5h–19AFh (2026-11-17)

Detailed map: [AMI486_ADDRESS_LEDGER_REGION_18E5_19B0_20261117.md](AMI486_ADDRESS_LEDGER_REGION_18E5_19B0_20261117.md).

Mapped the I/O pattern-test helper at 18E5h, four-port probe at 18FDh, and the conflict aggregator at 1914h. These routines scan the board I/O tables at CS:8248h and CS:8240h, test configured ports through F691h, and check fixed controller ports 03F4h/01F4h. The adjacent strings identify parallel, serial, floppy and hard-disk conflicts, though the exact status-bit-to-message mapping remains unresolved. Also mapped the 0170h/0171h I/O helpers at 1980h/198Fh and the profile dispatch pointer table at 19A2h–19AAh, whose targets are JMP DI at 19ABh and RET stubs at 19ADh–19AFh.

Generator update: 6e4e5beb9e33a52b1618c1e901f57d4246c59bf7. The latest generated manifest still predates this phase. The prior projected union was 63,108 bytes (96.30%); adding this 203-byte region gives a projected 63,311/65,536 bytes (96.60%) and 55 uncovered intervals. The next largest remaining interval is expected to be C800h–C8AFh (176 bytes). These figures are range-union arithmetic, not a regenerated manifest or CI result.

## 38. Diskette BIOS dispatch/transfer continuation — C780h–C8AFh (2026-11-17)

Detailed map: [AMI486_ADDRESS_LEDGER_REGION_C780_C8B0_20261117.md](AMI486_ADDRESS_LEDGER_REGION_C780_C8B0_20261117.md).

Extended the C780h diskette BIOS dispatch window from its default 80h bytes to 130h bytes. The prior window ended after the JNZ opcode at C7FFh and omitted its displacement byte at C800h; C800h is not an entry. The corrected window covers through C8AFh and stops before the separate C8B0h DMA dispatcher. Mapped the retry/control edges, including C7F0h JMP C8DBh, C7FFh JNZ C814h, repeated back-edges to C7E9h/C838h, and the branch at C8ACh into C8B2h. The routine uses the INT 1Eh diskette parameter table and the D2xx helper path to prepare transfer parameters.

Generator update: 88fc71605b7f660154b429cd8199a21ef4458a7d. The latest generated manifest still predates this phase. The previous projected union was 63,311 bytes (96.60%); adding this 176-byte interval gives a projected 63,487/65,536 bytes (96.87%) and 54 uncovered intervals. The next largest remaining interval is expected to be 8630h–86DAh (171 bytes). These are range-union calculations, not a regenerated manifest or CI result.

## 39. CMOS option checks and stack-threaded checksum verifier — 8630h–86DAh (2026-11-17)

Detailed map: [AMI486_ADDRESS_LEDGER_REGION_8630_86DB_20261117.md](AMI486_ADDRESS_LEDGER_REGION_8630_86DB_20261117.md).

Mapped the three CMOS option-check helpers at 8630h/8649h/8662h, which read CMOS 8Eh and conditionally 90h/94h before testing CS:8280h option bits. The helper at 867Bh checks bit 3 and calls the CPU-profile helper at 8300h. The continuation at 868Bh enters the existing checksum accumulators at 17F2h and 180Fh, then compares the CMOS AEh/AFh and BEh/BFh checksum pairs. Four embedded stack-return words (86A0h, 86AAh, 86C4h, 86CEh) are now explicitly classified as data; code windows begin after each return slot.

Generator update: 1ced033a4465751b83b7a5d1fc793e31d679aa63. The latest generated manifest still predates this phase. The previous projected union was 63,487 bytes (96.87%); adding this 171-byte interval gives a projected 63,658/65,536 bytes (97.13%) and 53 uncovered intervals. The next largest remaining interval is expected to be 714Eh–71E3h (150 bytes). These are range-union calculations, not a regenerated manifest or CI result.

## 40. POST/Setup metric display routines — 714Eh–71E3h (2026-11-17)

Detailed map: [AMI486_ADDRESS_LEDGER_REGION_714E_71E4_20261117.md](AMI486_ADDRESS_LEDGER_REGION_714E_71E4_20261117.md).

Mapped the two-value metric display routine at 714Eh (direct caller 711Ch) and the BP-framed display routine at 71A0h. The first uses the inline “KB/sec ms” label at 7145h–714Dh, cursor positioning, INT 10h output and format helper 7323h to display values from E3C9h/E3CBh. The second reserves a 10h-byte local frame, uses E3C6h/E3C7h for cursor placement and formats E1AFh through 7324h/72F2h. The RET at 71E3h is the end of this routine; 71E4h remains a separate dispatch entry.

Generator update: b9fe29583640d2967d2c5f1f41bdb126af1963cb. The latest generated manifest still predates this phase. The previous projected union was 63,658 bytes (97.13%); adding this 150-byte interval gives a projected 63,808/65,536 bytes (97.36%) and 52 uncovered intervals. The next largest remaining interval is expected to be 3EBFh–3F49h (139 bytes). These are range-union calculations, not a regenerated manifest or CI result.

## 41. Setup value parser and metric formatter — 3E99h–3F49h (2026-11-17)

Detailed map: [AMI486_ADDRESS_LEDGER_REGION_3E99_3F4A_20261117.md](AMI486_ADDRESS_LEDGER_REGION_3E99_3F4A_20261117.md).

Corrected the 3E3Fh window, which previously crossed the RET at 3E98h and included only the start of the next routine. It now ends at 3E98h. Added the parser at 3E99h–3EF1h, including its colon/space delimiter loop at 3EBFh and the 3EEBh back-edge, and the BP-framed metric/value formatter at 3EF2h–3F49h. The formatter uses helpers 5928h, 578Dh, 58A0h/58A1h, F571h and 5902h.

Generator update: 3c87a27e0d387c1cce8d39a6c64c4db2d699661e. The latest generated manifest still predates this phase. The previous projected union was 63,808 bytes (97.36%); adding this 139-byte interval gives a projected 63,947/65,536 bytes (97.58%) and 51 uncovered intervals. The next largest remaining interval is expected to be AC80h–ACFFh (128 bytes). These are range-union calculations, not a regenerated manifest or CI result.

## 42. Keyboard scan-code table prefix and AC60h translation map — AC5Bh–ACFFh (2026-11-17)

Detailed map: [AMI486_ADDRESS_LEDGER_REGION_AC5B_AD00_20261117.md](AMI486_ADDRESS_LEDGER_REGION_AC5B_AD00_20261117.md).

Corrected the AC00h ATA identify/read-transfer candidate boundary: the routine ends at AC5Ah with RET, so its code window is now 5Bh bytes. AC5Bh–ACFFh is data, not code. The confirmed 160-byte table at AC60h is referenced by the keyboard handler at B031h, which loads BX=AC60h before calling its mapping helper. It contains F0h/FFh markers and scan-code-like groups. The adjacent AC5Bh–AC5Fh prefix/header is retained as data but not semantically named. The existing AD00h–AE5Fh keyboard table remains a separate region.

Generator update: 7227215784dca6c9ffd34174cca3e3adaeb92a66. The latest generated manifest still predates this correction. The previous projected union was 63,947 bytes (97.58%); adding the 128-byte gap AC80h–ACFFh gives a projected 64,075/65,536 bytes (97.77%) and 50 uncovered intervals. Section 43 below closes the 61B2h–622Ah interval. The next largest interval must be selected from a regenerated manifest; no unverified next-gap estimate is carried forward. These are range-union calculations, not a regenerated manifest or CI result.

## 43. Calendar display grid template — 61B2h–622Ah (2026-11-17)

Detailed map: [AMI486_ADDRESS_LEDGER_REGION_61B2_622B_20261117.md](AMI486_ADDRESS_LEDGER_REGION_61B2_622B_20261117.md).

Extended the existing data range at 6194h–61B1h through 622Ah. The continuation contains the calendar's blank day cells, vertical separators, horizontal borders and box-drawing corners/junctions. The renderer begins at 622Bh and is called directly from the 00EFh screen-presentation stream. The interval is data, not code.

Generator update: dc1b930b4e68ccce53251df74f60be8f6cbfcdd0. The candidate-window manifest was subsequently regenerated and reconciled; see section 44 for the confirmed aggregate coverage.

## 44. Candidate-window range-mask manifest reconciled — 2026-11-17

The range-mask summary [ami486_candidate_windows_20261116.manifest.txt](ami486_candidate_windows_20261116.manifest.txt) has been refreshed from the current generator definitions. The per-window Capstone decode listing has not yet been rerun after the latest boundary corrections; this manifest reports the independently calculated coverage mask.

- Candidate windows: 890
- Data ranges: 248
- Unique code-window bytes: 44,201
- Unique data-range bytes: 20,517
- Code/data overlap: 334 bytes
- Code/data union: 64,384 / 65,536 bytes (**98.24%**)
- Uncovered intervals: 47
- Pages touched/full: 256 / 256, 214 / 256

Manifest blob SHA: dd56696866171ff2009bb32826db68bf4c11339e. The metrics match an independent range-union calculation from generator source 39fc3e561268696251e4ea8e5f8fd16684e47aaa.

The ten largest remaining uncovered intervals are:

| Length | Start–end (inclusive) |
|---:|---|
| 86 | 596Ah–59BFh |
| 83 | 72D8h–732Ah |
| 82 | 83AEh–83FFh |
| 76 | 2ED8h–2F23h |
| 76 | ABB4h–ABFFh |
| 69 | 8E09h–8E4Dh |
| 69 | AAEFh–AB33h |
| 67 | 566Bh–56ADh |
| 63 | 55ECh–562Ah |
| 38 | 2207h–222Ch |

Next region selected for analysis: 596Ah–59BFh (86 bytes). The 98.24% figure is byte-range coverage by independently seeded candidate windows and classified data ranges; it is not a claim that 98.24% of the BIOS has been semantically understood or proven reachable.

## 45. Drive-type/status display helper continuation — 475Ch–4890h (2026-11-17)

Detailed map: [AMI486_ADDRESS_LEDGER_REGION_475C_4891_20261117.md](AMI486_ADDRESS_LEDGER_REGION_475C_4891_20261117.md).

The 475Ch drive-type/status display helper was clipped at 4830h, immediately after the BA opcode of MOV DX,0003h. Extended its window from D5h to 135h bytes so the complete helper through RET at 4890h is included. The tail processes E411h/E413h/E416h/E41Dh/E41Fh fields through 09EBh, advances the E180h display-state pointer, calls 5BD5h, and uses the 37BDh fallback label when the returned value is FFFFh. The next independent renderer begins at 4891h.

Generator update: 86d414d730b3a35a9c339788033a4cc20ce77b98. Section 46 closes the 0454h–04AFh interval; the refreshed range-mask summary is recorded there. The per-window Capstone listing still needs a full regeneration to match the current generator source.


## 46. Setup field-record renderer and selector wrappers — 03D4h–04AFh (2026-11-17)

Detailed map: [AMI486_ADDRESS_LEDGER_REGION_03D4_04B0_20261117.md](AMI486_ADDRESS_LEDGER_REGION_03D4_04B0_20261117.md).

Extended the 03D4h screen-presentation field-record renderer from the default 80h-byte window to 0D6h bytes, covering the clipped CALL displacement at 0454h and the full routine through RET at 04A9h. The routine computes a 16-byte record offset from E401h and copies record fields into BP+40h–BP+47h. Added the six-byte E1A3h selector wrapper at 04AAh, called from 048Ah; it joins the common field-value calculation at 04BBh. The existing 04B0h entry and alternate 04B2h wrapper remain separate.

Generator update: fee1d36bc61ef71410e760d1bbb7b9d92608a9f8. The refreshed range-mask summary reports 64,384/65,536 bytes (98.24%), 47 uncovered intervals, and 214 fully covered 256-byte pages. The next largest gap is 596Ah–59BFh (86 bytes). The per-window Capstone listing remains pending regeneration.


## 47. Setup load-values confirmation prompt/input handler — 5959h–59BFh (2026-11-17)

Detailed map: [AMI486_ADDRESS_LEDGER_REGION_5959_59C0_20261117.md](AMI486_ADDRESS_LEDGER_REGION_5959_59C0_20261117.md).

Added an independent candidate window at 5959h, immediately after the RET at 5958h. The routine snapshots E1A3h into E19Fh, obtains the prompt layout through the existing string-length helper at 592Ah, computes and stores the display cursor in E180h, invokes the existing text/cursor helpers, and enters a keyboard-input loop. The input helper at 591Ah converts lowercase ASCII letters to uppercase. The handler echoes Y/N characters and continues waiting; ESC (1Bh) or Enter (0Dh) reaches the common return path at 59BAh–59BFh. Other keys are ignored.

The adjacent data already classified at 59C0h–5A4Bh is a three-word prompt pointer table followed by the strings:
- 59C6h: "Load Original Values (Y/N) ?"
- 59E3h: "Load BIOS Setup Default Values from ROM Table (Y/N) ?"
- 5A19h: "Load Power-On Default Values from ROM Table (Y/N) ?"

The new code window ends at 59BFh, immediately before the pointer table at 59C0h. It overlaps the prior 592Ah candidate window by 17 bytes (5959h–5969h); only the previously uncovered 596Ah–59BFh interval adds new coverage.

Generator update: baee67301ab87673ab39e188311e997d8c5b20ae. The projected range mask is 64,470/65,536 bytes (98.37%), with 46 uncovered intervals and 215 fully covered 256-byte pages. The next largest uncovered interval is 72D8h–732Ah (83 bytes). These are byte-range coverage metrics, not semantic-completion or reachability percentages. The updated generator has been committed; its Capstone candidate listing has not yet been rerun, so the manifest figures remain a projection until that run.


## 48. Register-context save/restore and decimal-output helpers — 72D8h–732Ch (2026-11-17)

Detailed map: [AMI486_ADDRESS_LEDGER_REGION_72D8_732D_20261117.md](AMI486_ADDRESS_LEDGER_REGION_72D8_732D_20261117.md).

Mapped four distinct helpers: the BP-relative register-context save routine at 72D8h, its restore counterpart at 72F1h, the recursive unsigned decimal printer at 730Ah, and the AX/BX/DX-preserving output wrapper at 7323h. Direct near-CALL sites were found for both context helpers and for the wrapper. The wrapper's final POP AX and RET are at 732Bh–732Ch, so the existing navigation-legend data range was incorrectly starting two bytes early; its start is corrected from 732Bh to 732Dh.

Generator update: 781d8b3eda465a66a6195dd129f258093d18fde5. The generator was executed and the range mask now reports 64,553/65,536 bytes (98.50%), with 45 uncovered intervals and 216 fully covered 256-byte pages. The next largest uncovered interval is 83AEh–83FFh (82 bytes). The full Capstone candidate listing was regenerated in commit 3f26611b497fe9cb7f2e96dd8b2a217dd3a9e977. These are byte-range coverage metrics, not semantic-completion or reachability percentages.


## 48. Register-context save/restore and decimal-output helpers — 72D8h–732Ch (2026-11-17)

Detailed map: [AMI486_ADDRESS_LEDGER_REGION_72D8_732D_20261117.md](AMI486_ADDRESS_LEDGER_REGION_72D8_732D_20261117.md).

Mapped four distinct helpers: the BP-relative register-context save routine at 72D8h, its restore counterpart at 72F1h, the recursive unsigned decimal printer at 730Ah, and the AX/BX/DX-preserving output wrapper at 7323h. Direct near-CALL sites were found for both context helpers and for the wrapper. The wrapper's final POP AX and RET are at 732Bh–732Ch, so the existing navigation-legend data range was incorrectly starting two bytes early; its start is corrected from 732Bh to 732Dh.

Generator update: pending commit. The projected range mask is 64,553/65,536 bytes (98.50%), with 45 uncovered intervals and 217 fully covered 256-byte pages. The next largest uncovered interval is 83AEh–83FFh (82 bytes). These are range-mask projections, not semantic-completion or reachability percentages. The Capstone listing still requires regeneration after running the updated generator.
