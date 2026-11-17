# AMI486 address ledger — Advanced CMOS CPU/cache profile data 81EEh–8377h

Date: 2026-11-17  
Repository: JTCyborg/Project134, branch main  
ROM: ami486.bin, 65,536 bytes; SHA-256 91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b

## 1. Region layout

The 394-byte uncovered interval divides into:
- 81EEh–8327h: 314 bytes of structured configuration/profile data.
- 8328h–832Dh: six-byte BX-preserving wrapper.
- 832Eh–8377h: 74-byte CPU-profile/CMOS helper; it continues at 8378h outside the old gap.

The data block is not a linear x86 instruction stream. It contains zero-filled areas, configuration words, I/O base addresses and pointers into CPU/cache profile records.

## 2. Structured data block

The data includes:
- A leading CR/LF marker and large zero-filled areas.
- Configuration words around 8211h–823Ch.
- An I/O base-address list at 823Dh–824Eh:
  - 03B6h
  - 03F8h
  - 02F8h
  - 03E8h
  - 02E8h
  - 03BCh
  - 0378h
  - 0278h

The latter values include the conventional COM1–COM4 and LPT base addresses; 03B6h is retained as a separate board-specific/video-related port value pending a full consumer trace.

The pointer/record area at 82C6h onward contains offsets into the profile data around 19A2h–19AFh. The first pointer at CS:82C6h is 19A3h, which addresses a record containing the strings:
- "20 KB CACHE MEMORY"
- "MHz CPU Clock"
- "MHz DX2 CPU"

These strings confirm that this table family describes CPU/cache configuration profiles. Other pointers in the area include 19A2h, 19ABh, 19A5h, 19ADh, 19A7h, 19AEh, 19A9h and 19AFh. The full semantics of every record field remain to be mapped.

## 3. Wrapper and CMOS 8Eh profile helper

8328h is a six-byte wrapper:
- PUSH BX
- CALL 832Eh
- POP BX
- RET

832Eh is the profile selector/configuration helper. It:
1. Tests the incoming AL value and returns early for zero.
2. Normalizes AX and compares it with the profile-selection boundary derived from B55Dh–B508h.
3. Loads the first profile record through CS:82C6h.
4. Walks 32-byte records, using record bytes at offsets 1Eh/1Fh as flags/advance information.
5. Skips flagged entries when the record indicates that the profile is not directly selectable.
6. Selects the requested record and accesses its control bytes at offsets 1Ch/1Dh.
7. Reads CMOS register 8Eh through ports 70h/71h and updates the relevant configuration bits. The routine continues at 8378h.

The helper is therefore tied to CPU clock/cache profile selection and CMOS 8Eh configuration. The exact mapping from each profile record to a displayed CPU frequency is not yet proven for every record.

## 4. Entry provenance

No direct relative CALL/JMP xref to 8328h or 832Eh was found in the raw scan. The table and strings establish the CPU/cache profile role, but the exact indirect caller path (likely through the Advanced CMOS Setup data/handler path) remains to be traced. Treat the two code seeds as bounded entry candidates, not as proof of a standalone public BIOS entry.

## 5. Generator integration

The candidate generator now:
- classifies 81EEh–8327h as structured CPU/cache/board configuration data;
- seeds 8328h as the BX-preserving wrapper;
- seeds 832Eh through 8377h as the CMOS 8Eh CPU-profile helper.

The CI manifest is the verification gate for this update; the next largest uncovered interval will be taken from the completed run.
