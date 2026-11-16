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

The following 102 pages are the current *reference-scan gaps*, not proven analysis gaps:

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
- `A0F1h–A124h`: 26-entry native little-endian INT 13h function table. The A0A0h dispatcher indexes it with incoming AH (0–19h) via `CS:[DI-5F0Fh]`. Targets: `A197, A20B, A216, A226, A23E, A25F, A18E, A18E, A1A4, A337, A372, A381, A374, A19E, A18E, A18E, A4D3, A501, A18E, A18E, A52B, A1A9, A18E, A18E, A18E, A57B`. A100h is an interior address in this table, not its beginning.
- `A125h–A18Dh`: padded message text including **“Format !!!”**, **“BootSector Write !!!”**, and **“Possible VIRUS: Continue (Y/N)?”**. This is confirmed embedded text/data, not executable code.
- `A18Eh`: aligned bytes `B8 00 01 88 26 74 00 F9 C3`; a short executable helper candidate. Its side effect and caller contract remain to be established.
- `A200h–ACFFh`: instruction-dense routines; raw samples include repeated I/O and conditional control flow. Treat as code candidates with embedded data not yet excluded.
- `AD00h–AE5Fh`: keyboard translation data candidates. The bytes contain scan-code-like values and recognizable QWERTY/ASDF/Z/X/C/V/B/N/M and numeric-key sequences.
- `AE60h–AFFFh`: returns to instruction-dense code, including BIOS interrupt calls and control-flow branches.

The A100h words must not be mistaken for a fully understood native little-endian pointer table. The raw pairs, when byte-reversed, match plausible code entries such as A1A4h, A137h, A372h, A381h, A49Eh, A18Eh, A1D3h, A401h and A5A9h. This is a strong byte-swapped-table hypothesis, not yet a proven table contract.

### 4.3 D100h–D5FFh — floppy-controller I/O code candidate

The raw stream includes repeated immediate port references to `03F7h` and `03F4h`, `IN AL,DX`-style byte patterns, status-bit tests, retries and calls. This is strongly consistent with floppy-disk-controller access routines. Exact routine boundaries, calling convention and relation to the separate INT 40h floppy service remain to be traced.

### 4.4 6800h — executable code candidate

At 6800h the bytes begin `86 C4 8B F8 C3 3B F7 74 37 ...`, followed by arithmetic, BIOS INT 10h calls and a divide-based conversion sequence. This is a code candidate despite the absence of explicit phase-address tokens for page 68.

### 4.5 F900h — executable code candidate

At F900h the stream begins `00 23 D2 74 1F D1 EF 8B BD 7C 00 ...` and contains indirect-call opcode `FF D0` in the sampled continuation. This is a code candidate; the entry point and target provenance are not yet established.

## 5. Immediate priority order

1. **A000h–AFFFh**: map the mixed IDE/ATA hard-disk format/boot-sector path, separate the pointer-like words and keyboard tables, and trace the message callers.
2. **D100h–D5FFh**: identify all FDC routines and connect their callers to the A000h subsystem.
3. **2100h onward**: verify the memory-test alternate stream and caller.
4. **F900h–F9FFh** and **6800h–68FFh**: establish entry points and callers.
5. Continue through the remaining reference-scan gaps in address order, but only after a raw-byte classification pass.

## 6. Rules for subsequent updates

For each interval record:
- start/end offsets and exact source bytes;
- one or more aligned instruction streams (never assume a single global alignment);
- confirmed data/string/table subranges;
- incoming direct and indirect references;
- outgoing direct and indirect calls/jumps;
- unresolved bytes and alternate-entry candidates;
- confidence and evidence source.

Do not infer that an entire 256-byte page is code because one function starts there. Do not infer data from linear-decoder output alone. No whole-ROM semantic percentage is currently defensible.


## 7. Seeded Capstone decode — first executable evidence

The GitHub Actions workflow now generates `ami486_candidate_windows_20261116.txt` from independently seeded 16-bit windows. The first successful run produced 24 windows; the expanded run adds entry candidates and normalizes relative near-branch targets with 16-bit IP wraparound. This remains a bounded linear inspection aid, not a CFG.

Confirmed from the decoded bytes:
- A1B3h resets the ATA device through control port 01F6h, waits, reads error/features port 01F1h, and then probes device selectors 80h/81h.
- A337h writes sector-count/device parameters to 01F2h/01F6h and issues ATA command 91h through the command path.
- A406h transfers a 512-byte sector using `REP OUTSW` to port 01F0h; the optional trailing path writes four additional bytes.
- A501h and A52Bh issue ATA commands and inspect status/error state; A52Bh uses command 90h and reads 01F1h.
- A621h writes the feature/error register at 01F1h; A62Dh polls status at 01F7h; A655h selects a drive and checks status.
- A847h renders the embedded A125h/A148h prompt via BIOS INT 10h. This ties the “Possible VIRUS” message to the ATA/boot-sector protection path.
- A95Eh writes the INT 13h vector at 0000:004Ch and stores the displaced vector in low memory; full hook semantics still require the rest of the routine and caller path.
- D100h–D5FFh accesses ports 03F4h/03F7h and is a separate floppy-controller candidate. Do not merge it with the ATA routines at A000h–AFFFh.
- AE60h onward enters a keyboard/INT 15h related handler path; AD00h–AE5Fh remains translation-table data candidate.

The first A000h seed decodes the initial bytes as unusual but syntactically valid instructions. Its true entry boundary remains unconfirmed; prefer the aligned entries established by direct calls/branches in the seeded listing.


## 8. Subsystem report and corrected storage separation

Detailed byte-backed analysis: [AMI486_STORAGE_AND_DISPATCH_REGIONS_20261116.md](AMI486_STORAGE_AND_DISPATCH_REGIONS_20261116.md).

Important correction to the initial gap hypothesis: A000h–AFFFh is **IDE/ATA hard-disk code**, not floppy code. It accesses 01F0h–01F7h and 03F6h; A406h performs a 256-word data-out transfer, AC00h issues ATA IDENTIFY DEVICE (ECh) and performs a 256-word data-in transfer. A847h displays the embedded Format/BootSector Write/Possible VIRUS prompt and A8F4h accepts Y/N. A95Eh is an INT 13h vector-hook candidate (ES base still to verify).

D100h–D5FFh is the separate floppy-controller/DMA subsystem: FDC ports 03F2h/03F4h/03F5h/03F7h plus DMA ports 0Ch/0Bh/05h/04h.

F92Ah–F935h is a six-word little-endian dispatch table with targets F936h, F986h, F9C4h, F977h, F999h and F9D3h. F977h overlaps the F936h stream as an alternate entry. The F900h wrapper ends in IRET; its actual vector entry remains unknown.

The seeded Capstone output now contains 69 independent 0x80-byte windows and normalizes near-branch targets to 16-bit IP wraparound.


## INT 13h dispatch correction

The initial classification of A100h–A123h as a separate byte-swapped table was wrong. A08Dh is the hooked INT 13h entry; DL<80h is forwarded to INT 40h. A0A0h dispatches by AH through the 26-entry little-endian table at A0F1h–A124h. A100h is an interior byte of the table. The exact targets and selectors are documented in AMI486_STORAGE_AND_DISPATCH_REGIONS_20261116.md.
