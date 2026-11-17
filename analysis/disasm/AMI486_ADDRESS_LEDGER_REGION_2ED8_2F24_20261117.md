# AMI486 address ledger — ROM-shadow loop tail and Setup relocation transition (2ED8h–2F23h)

Date: 2026-11-17  
Repository: JTCyborg/Project134, branch main  
Source: ami486.bin, 65,536 bytes  
SHA-1: 480c7520c93e6c7ed437cf3ad214da7503f82ec6

## 1. Region split

The uncovered interval contains two code blocks separated by one unreferenced zero byte:
- 2ED8h–2EF0h: continuation of the earlier ROM-segment/selector loop.
- 2EF1h: 00h; no direct branch or call target observed.
- 2EF2h–2F23h: independent Setup exit/relocation routine, directly called from F109h.

The existing Setup confirmation strings begin at 2F24h.

## 2. ROM-shadow / segment-selector loop tail — 2ED8h–2EF0h

This is a continuation of the path already calling the selector helper at 83AEh. It:
- branches around the mask operation unless CS=F000h;
- in the F000h path, complements BH and ANDs it into the byte at [SI+E000h], then restores BH;
- tests BL and DI to decide whether to repeat or return to the earlier loop labels;
- compares CS against F000h and jumps back to 2EABh on the alternate path.

The routine's complete higher-level purpose remains tied to the previously mapped ROM/segment selection path; this tail alone does not establish the exact chipset register semantics.

## 3. Setup exit / relocation transition — 2EF2h–2F23h

Direct near-CALL site: F109h. Adjacent strings at 2F24h and 2F43h ask whether to write CMOS and exit or quit without saving.

The routine:
- clears direction flag and sets DS=0000h;
- saves the current SS at 0000:0469h and SP at 0000:0467h;
- sets ES=DS=SS=0100h and installs SP=DFFEh;
- copies 7000h words from CS:0000h to 0100:0000h using CS:REP MOVSW;
- zero-fills 0FF1h bytes at 0100:E000h;
- jumps to 3C5Eh.

This is a Setup exit/relocation handoff. The code at 3C5Eh is the next execution stage; its full behavior is outside this interval.

## 4. Disassembly

```asm
2ED8  75 08             jne 2EE2
2EDA  F6 D7             not bh
2EDC  20 BC 00 E0       and byte ptr [si+E000], bh
2EE0  F6 D7             not bh
2EE2  0A DB             or bl, bl
2EE4  74 CB             je 2EB1
2EE6  0B FF             or di, di
2EE8  74 05             je 2EEF
2EEA  3D 00 F0          cmp ax, F000
2EED  74 BF             je 2EAE
2EEF  EB BA             jmp 2EAB

2EF1  00                db 00 ; unreferenced byte, classification provisional

2EF2  FC                cld
2EF3  33 C0             xor ax, ax
2EF5  8E D8             mov ds, ax
2EF7  8C 16 69 04       mov [0469], ss
2EFB  89 26 67 04       mov [0467], sp
2EFF  B8 00 01          mov ax, 0100
2F02  8E C0             mov es, ax
2F04  8E D8             mov ds, ax
2F06  FA                cli
2F07  8E D0             mov ss, ax
2F09  BC FE DF          mov sp, DFFE
2F0C  FB                sti
2F0D  33 F6             xor si, si
2F0F  33 FF             xor di, di
2F11  B9 00 70          mov cx, 7000
2F14  2E F3 A5          rep movsw
2F17  BF 00 E0          mov di, E000
2F1A  B9 F1 0F          mov cx, 0FF1
2F1D  32 C0             xor al, al
2F1F  F3 AA             rep stosb
2F21  E9 3A 0D          jmp 3C5E
```

## 5. Data adjacency

The byte at 2EF1h is a zero with no direct call or branch target observed. The Setup exit confirmation text starts at 2F24h and is already classified as data:
- 2F24h: "Write to CMOS and Exit (Y/N) ?"
- 2F43h: "Want to Quit without Saving? ..."

The exact end of the second string remains as defined by the existing data range through 2F66h.

## 6. Generator integration and projected coverage

Add two code windows: 2ED8h/19h and 2EF2h/32h. Add a one-byte provisional data range at 2EF1h–2EF2h. The existing 2F24h–2F66h Setup prompt range remains unchanged.

Projected range-mask result:
- Candidate windows: 901
- Data ranges: 249
- Unique code-window bytes: 44,609
- Unique data-range bytes: 20,512
- Code/data overlap: 334 bytes
- Code/data union: 64,787 / 65,536 (98.86%)
- Uncovered intervals: 42
- Pages touched/full: 256 / 256, 220 / 256
- Next largest uncovered intervals: AAEFh–AB33h and 8E09h–8E4Dh (69 bytes each)

These are range-mask projections, not generated manifest results; the updated generator and full Capstone candidate listing must be regenerated.
