# AMI486 POST hardware summary display — 3F4Ah–45FFh

Date: 2026-11-17  
ROM: `ami486.bin`, 65,536 bytes  
ROM SHA-256: `91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b`  
Decoder evidence: independently seeded Capstone x86 16-bit windows, checked against raw ROM bytes.

## 1. Scope and control-flow anchors

This region is the POST hardware-summary screen renderer and its CPU/device-formatting helpers.

- 3F4Ah directly calls 3F7Bh, then loads SI=45D8h and calls 3F5Eh to print the bottom border. It then calls 19FBh and returns at 3F56h.
- 3F7Bh prints the top border at 4231h, prints the Main Processor label, calls the CPU-identification helper at 4142h, then renders memory, numeric-processor, floppy, hard-disk, display, BIOS-date, serial-port and parallel-port fields.
- 3F7Bh returns at 4141h. The separate CPU-identification routine begins at 4142h.
- 3F87h calls 4142h; 3FA7h calls 41E4h. 41F6h and 4216h call 421Eh.
- The outer 3F4Ah wrapper is a direct caller of 3F7Bh. No claim is made here about the runtime caller that enters 3F4Ah.

## 2. Screen frame and embedded data

The frame is stored as box-drawing/control data, not executable code:

| Range | Raw content / role |
|---|---|
| 4231h–427Ch | C9h followed by CDh horizontal-line bytes |
| 427Dh–4282h | BBh, CR/LF, BAh and spaces at the banner's upper/right edge |
| 4283h–42CBh | `AMIBIOS System Configuration (C) 1985-1993, American Megatrends Inc.,` |
| 42CCh–42CFh | BAh, CR/LF and CCh frame junction |
| 42D0h–431Ah | CDh horizontal separator bytes |
| 431Bh–431Fh | B9h, CR/LF, NUL and BAh border/control bytes |
| 4320h–45D7h | POST field labels and value strings |
| 45D8h–45FFh | C8h/CDh/CFh bottom-frame graphics |

The field labels at 4320h onward are interleaved with BAh/B3h vertical-border bytes and NUL terminators. The CPU names and device values occupy later strings in the same block.

## 3. Main summary renderer

The main routine at 3F7Bh performs these operations in order:

1. Prints the top border at 4231h through 3F5Eh.
2. Prints the Main Processor label (SI=431Fh) and calls 4142h to select a CPU-name string.
3. Prints Base Memory Size (SI=43AFh), reads a word at physical 0467h with DS=0000h, and prints the number through 412Ah followed by the `KB` suffix helper 4119h.
4. Prints Numeric Processor (SI=4337h) and calls 41E4h.
5. Prints Ext. Memory Size (SI=43C7h), invokes INT 15h AH=88h, and prints the returned size through 412Ah/4119h.
6. Prints Floppy Drive A (SI=434Fh), reads CMOS register 90h and passes its high nibble to 40C6h.
7. Prints Hard Disk C (SI=43DFh), reads CMOS 92h and passes its high nibble to 40ACh with AH=99h.
8. Prints Floppy Drive B (SI=4367h), restores the saved CMOS 90h byte and passes its low nibble to 40C6h.
9. Prints Hard Disk D (SI=43F7h), passes the low nibble of CMOS 92h to 40ACh with AH=9Ah.
10. Prints Display Type (SI=437Fh), selects a display-type string from the BDA video-segment field and INT 11h equipment flags.
11. Prints Serial Port(s) and enumerates four BDA words from 0000:0400h.
12. Prints the AMIBIOS Date label and outputs eight bytes from CS:FFF5h.
13. Prints Parallel Port(s) and enumerates three BDA words from 0000:0408h.
14. Returns at 4141h; the caller at 3F4Ah prints the bottom border from 45D8h.

The base-memory value source is recorded exactly as physical 0467h; its relationship to standard BDA fields is not inferred. The eight-byte date source at CS:FFF5h is confirmed by the instruction stream.

## 4. CPU identification helper at 4142h

The helper preserves flags and executes CLI during its test sequence. It:
- probes flag-bit behavior after loading F000h into AX and POPF;
- uses SMSW and reads CR0;
- temporarily clears CR0 bit 4, tests the resulting state, and restores the saved CR0 value;
- tests CMOS register B3h through EE94h on multiple branches;
- reads CS:[B513h] and calls 8300h on the final 486-family branch;
- selects a CPU-name pointer in the 443Fh–450Fh string table and displays it through 3F5Eh;
- restores flags and returns at 41E3h.

The selected literal labels include:
- 443Fh — `80486`
- 444Fh — `80486DX2`
- 445Fh — `486DX or 487SX`
- 446Fh — `80486SX`
- 447Fh — `80386DX`
- 448Fh — `80386SX`
- 449Fh — `80286`
- 44AFh/44BFh — `Cx486SLC` / `Cx486SLC2`
- 44CFh/44DFh — `Cx486DLC` / `Cx486DLC2`
- 44EFh/44FFh — `Cx486S` / `Cx486S2`

This proves the output choices and the tested machine state. It does not establish the complete electrical/CPU-family meaning of every CMOS B3h bit or the internal contract of 8300h.

## 5. Numeric processor and Weitek path

41E4h calls INT 11h and tests AL bit 1. It selects the literal `Present` string at 450Fh or `None` at 457Fh. It then calls 421Eh:
- 421Eh checks AH; if nonzero, it clears EAX, calls INT 11h, shifts EAX left by eight, and tests carry.
- On the carry path it selects SI=451Fh (`Weitek`) and returns with flags for the caller.
- 41F6h and 4216h are the two direct callers. The 41E4h path checks CF and has an additional repeated 0985h/INT 10h output sequence when the carry condition is set.

The literal string selection and flag flow are confirmed; the precise equipment-word bit represented by the shifted carry remains unresolved.

## 6. Device-value helpers

### 40C6h — floppy type selector

The low nibble of AX selects a string pointer:
- 0 -> 457Fh `None`
- 1 -> 452Fh `360 KB, 5¼-inch`
- 2 -> 453Fh `1.2 MB, 5¼-inch`
- 3 -> 454Fh `720 KB, 3½-inch`
- 4 -> 455Fh `1.44 MB, 3½-inch`
- 5 -> 456Fh `2.88 MB, 3½-inch`

The display strings contain CP437 fraction glyph bytes (ACh/ABh); they are not malformed ASCII.

### 40ACh — hard-disk type display

The helper masks AL to its low nibble. Zero selects `None`; 0Fh causes a read of the CMOS register whose selector is supplied in AH (99h for drive C, 9Ah for drive D); otherwise it zero-extends the nibble. The resulting number is printed through 412Ah.

### 407Ah — COM/LPT address enumeration

The caller uses SI=0400h/CX=4 for four COM-port words and SI=0408h/CX=3 for three LPT-port words, with DS=0000h. Each nonzero word is printed in hexadecimal through 3F6Ch/3F64h. If no nonzero port is found, the helper prints `None`.

## 7. Formatting helpers

- 412Ah recursively divides AX by ten and outputs decimal digits with INT 10h AH=0Eh.
- 4119h outputs the literal `KB` suffix and calls 40EFh to finish the line.
- 40EFh reads the current cursor position using INT 10h AH=03h, fills the remaining line up to column 4Ch through 098Ah, outputs character BAh, restores registers, then emits CR/LF.
- 40AC/40C6 choose display strings; 3F5Eh is the shared string-output call used throughout this screen.

## 8. Remaining unknowns

- The source/meaning of the word at physical 0467h displayed under Base Memory Size.
- Exact CPU-family semantics of the CMOS B3h tests and the 8300h helper.
- The exact equipment-word bit tested by 421Eh before selecting `Weitek`.
- The semantics of the post-frame call to 19FBh.
- The runtime caller/entry chain for the wrapper at 3F4Ah.

These open points do not affect the confirmed POST summary field order, the direct helper call graph, or the raw screen-data boundaries.
