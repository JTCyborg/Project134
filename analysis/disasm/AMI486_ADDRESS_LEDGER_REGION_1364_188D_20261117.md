# AMI486 address ledger — POST initialization region 1364h–188Dh

Date: 2026-11-17  
Repository: JTCyborg/Project134, branch main  
ROM: ami486.bin, 65,536 bytes; SHA-256 91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b

## 1. Entry and boundaries

The former uncovered interval was 1365h–188Dh (1,321 bytes). The actual instruction entry is 1364h: the preceding POST path at 135Dh pushes 1364h, pushes FA4Eh, and executes RET. The FA4Eh integrity helper returns to 1364h after the 76-byte complement comparison succeeds. The first instruction is therefore B0 94 (MOV AL,94h), which straddles the old gap boundary.

The principal POST stream is split around an embedded eight-byte lookup table:
- 1364h–15CDh: POST continuation.
- 15CEh–15D5h: eight-byte XLAT lookup table.
- 15D6h–1655h: POST continuation.
- 1656h onward: separately called helpers and local continuations.

## 2. Main POST continuation: 1364h–1655h

The stream emits POST progress values 94h–A2h to port 80h and performs these operations:

1. Updates BDA conventional-memory size at 0040:0013h, consulting the CS:8280h configuration bit and values obtained through the 8300h configuration accessor. The selected memory size is normalized and stored in BDA.
2. Runs the 1E73h/1E9Ah/1E9Dh chipset and shadow-configuration paths. When enabled, scans C800h–DFFFh using F6D9h, reads CMOS 8Dh, and calls the F5A9h diagnostic path.
3. Reads RTC time through INT 1Ah/AH=02h, validates seconds/minutes/hours, converts packed BCD values with helper 16C7h, and computes the BIOS tick count at BDA:006Ch/006Eh. Invalid RTC fields set BP bit 40h and take the CMOS correction path.
4. Initializes I/O-resource records from CS:8240h/8248h, probes candidate ports, and updates BDA I/O fields.
5. Performs FPU detection using FNINIT/FNSTSW. A successful status test sets the BDA FPU-present bit and adjusts the slave PIC mask.
6. Checks CMOS/ALi state, updates BDA:0016h/0017h/0096h/0097h, and emits POST 9Eh–A2h. It also calls chipset setup paths at 1EC8h and 203Fh/2042h.
7. When the relevant BDA flag is set, reads configuration bytes CS:B508h–B50Ah, uses INT 16h/AH=03h with AL=05h, calls the 1F47h configuration path, resets the video mode, scans E000h–E7FFh, and completes the POST display path through 3F4Ah/F724h.

The exact hardware meaning of every chipset register is not inferred from port numbers alone; the code-level behavior above is the established map.

## 3. Embedded XLAT table: 15CEh–15D5h

The eight bytes are:

```text
12 0F 0C 0A 08 04 02 00
```

The code at 15F6h sets BX=15CEh and executes XLAT after masking a configuration value to 0–7. This proves the block is a lookup table, not instructions. It maps the low three bits of the selected configuration value to the byte sequence above.

## 4. POST warning/display helper: 1656h

This helper is called from 120Dh and 158Ch. It initializes the display path, waits through the F571h timing helper, iterates 16 words from a CS:SI table while testing BP flags, and dispatches selected entries through 16C0h.

When the warning flags require user intervention, it displays the strings:
- 7A8Bh: "RUN SETUP UTILITY"
- 7A9Dh: "Press <F1> to RESUME"

It then waits for INT 16h/AH=00h and checks scan code 3Bh (F1). It returns a status through CX/ZF after restoring the display mode. This is a POST configuration-warning / resume prompt, not an ordinary text-output routine.

## 5. Small helper routines and xrefs

| Entry | Behavior established from instructions | Direct CALL references found |
|---|---|---|
| 16B7h | INT 10h/AH=0Fh obtains current video mode, then AH=00h resets that mode | 12B9h, 1613h, 16AFh, 1714h |
| 16C0h | Calls 410Eh and F52Eh to emit a selected POST text item | 166Fh, 1680h, 1686h |
| 16C7h | Converts packed BCD in AL to binary using nibble split and AAD 0Ah | 142Eh, 1436h, 1442h |
| 16D1h | Reads two CMOS values through EEAAh with AL/AH exchange | 1198h, 11ACh, 11B4h |
| 16DAh | Walks four I/O-resource words at CS:8248h and invokes 16F4h | 11F8h, 147Fh |
| 16F4h | Calls F6B8h to validate a candidate I/O resource and stores DX when accepted | 16EEh |
| 1700h | Probes the status port at DX+2, tests mask 38h, stores accepted base address | 1499h |
| 1714h | Video reset, diagnostic input, and three-step status path; detailed prompt semantics unresolved | 1233h, F104h |
| 1763h / 176Bh | Two entries into a descriptor builder that writes ES:DI fields and CMOS-derived bytes | A9BBh / A9F8h |
| 17E9h | Emits the next CH-derived byte through the EEAAh CMOS access path | internal calls from 17B3h–17D5h |
| 17F2h | Accumulates CMOS register values from 90h through ADh, then jumps through DI | 1839h |
| 180Fh | Accumulates CMOS values beginning at B4h, skips BFh/C0h when the loop reaches BEh, and stops at CS:82B3h | 184Dh |
| 1836h | Selects continuation 183Bh, invokes 17F2h, writes checksum high/low bytes to CMOS AEh/AFh | 14F9h, 1C3Eh |
| 184Ah | Selects continuation 184Fh, invokes 180Fh, writes checksum bytes to CMOS BEh/BFh | 1C41h |
| 185Ah | Writes 04h then 00h to ATA device-control port 3F6h with delay loops | 131Dh, AB3Fh, ABA3h |
| 1870h | Polls 8042 status port 64h and drains output bytes from port 60h, up to six reads | 10FAh, 9812h |

The xref list is based on scanning the ROM for relative CALL encodings and validating computed targets. These references are strong candidates; the caller's full surrounding instruction stream should be retained in the function database before assigning higher-level names.

## 6. CMOS checksum behavior

The 17F2h loop selects CMOS registers 90h–ADh through port 70h, reads port 71h, and accumulates values in BX. The 1836h continuation writes BH/BL to CMOS AEh/AFh.

The 180Fh loop begins at B4h and uses CS:82B3h as its upper bound. When CX reaches BEh it skips BFh and C0h before continuing. The 184Ah continuation writes BH/BL to CMOS BEh/BFh.

These are explicit checksum accumulator/store paths. The exact set of configuration fields covered by the second loop depends on the ROM byte at CS:82B3h and must be preserved as a variable bound rather than hard-coded as B4h–BEh.

## 7. Hardware initialization helpers

- 185Ah resets the ATA device-control register through port 3F6h, with a short delay after asserting bit 2 and a longer delay after clearing it.
- 1870h waits for output-buffer-full at 8042 status port 64h and reads port 60h to drain pending bytes; BX limits the drain to six iterations.
- 16DAh/16F4h and 1700h enumerate and probe I/O resource candidates. The four-entry source table is at CS:8248h; additional base candidates are read from CS:8240h. 1700h checks status bits 38h at base+2 before storing the base address.

## 8. Candidate generator and coverage

The generator now includes the main POST entry at 1364h, the post-table continuation at 15D6h, and bounded helper entries through 1870h. The lookup table at 15CEh–15D5h is a separate data range, so the code window is split rather than decoding the table as instructions.

GitHub Actions run 44083305295 completed successfully. Its manifest reports 772 candidate windows, 229 data ranges, 38,219 unique code-window bytes, 18,020 unique data-range bytes, 298 overlap bytes, and a 55,941-byte union (85.36%). There are 69 uncovered intervals; the next largest is E481h–E830h (944 bytes).

## 9. Next work

1. Continue with E481h–E830h (944 bytes), the largest remaining uncovered interval.
2. Trace the CMOS checksum callers and verify the upper-bound byte at CS:82B3h.
3. Identify the 16-entry warning table at CS:7896h and map its flag bits to the warning strings.
4. Confirm the I/O-resource table at CS:8240h/8248h against all call sites.
5. Preserve the FPU, RTC, PIC and ATA initialization behavior as separate routines in the independent implementation.
