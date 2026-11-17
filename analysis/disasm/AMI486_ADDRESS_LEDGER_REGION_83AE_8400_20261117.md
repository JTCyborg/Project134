# AMI486 address ledger — selector-to-descriptor resolver (83AEh–83FFh)

Date: 2026-11-17  
Repository: JTCyborg/Project134, branch main  
Source: ami486.bin, 65,536 bytes  
SHA-1: 480c7520c93e6c7ed437cf3ad214da7503f82ec6

## 1. Corrected boundary

The initial split at 83C1h was incorrect. Raw bytes show that 83C0h begins `BB D0 B7` (MOV BX,B7D0h), not a RET or a new function. The byte sequence at 83BEh–83BFh is `3B C3` (CMP AX,BX), and execution falls through into 83C0h. The routine has one entry at 83AEh and one RET at 83FFh.

The conditional branch at 83B3h reaches the shared tail at 83F7h. The second stage beginning at 83C0h consumes the carry flag produced by the comparison at 83BEh. It is therefore a single selector-to-descriptor resolver, not two independent routines.

## 2. Direct callers

Near-CALL sites found by scanning the ROM: 2E84h, 2EC4h and 86F2h.

The callers load AL from CS:B513h, CS:B519h and CS:B52Ch respectively, then use AX returned by this routine.

## 3. Behavior

- Starts with BX=B7D0h.
- If AL is zero, branches directly to 83F7h and returns the default word from CS:[B7D0h+1Ch], i.e. CS:B7ECh/B7EDh.
- Otherwise zero-extends AL into AX, loads BX= B55Dh-B508h = 0055h and compares AX against 0055h.
- At 83C0h, reloads BX=B7D0h. The JB at 83C3h consumes the carry flag from the comparison: selectors below 55h retain their value; selectors at or above 55h subtract 55h.
- Loads the descriptor-table pointer from CS:[82C6h].
- Walks AL 20h-byte records. Each record uses +1Eh as a flag and +1Fh as a variable-list length.
- If bit 7 of the flag is set, advances over a zero-terminated list of 16-bit values.
- Returns the selected record's bytes at +1Ch and +1Dh in AX.

The precise meaning of the descriptor bytes and the source/initialization of CS:[82C6h] remain unresolved.

## 4. Disassembly

```asm
83AE  BB D0 B7          mov bx, B7D0
83B1  0A C0             or al, al
83B3  74 42             je 83F7
83B5  32 E4             xor ah, ah
83B7  BB 5D B5          mov bx, B55D
83BA  81 EB 08 B5       sub bx, B508
83BE  3B C3             cmp ax, bx
83C0  BB D0 B7          mov bx, B7D0
83C3  72 12             jb 83D7
83C5  BB 5D B5          mov bx, B55D
83C8  81 EB 08 B5       sub bx, B508
83CC  2B C3             sub ax, bx
83CE  2E 8B 1E C6 82    mov bx, word ptr cs:[82C6]
83D3  0A C0             or al, al
83D5  74 20             je 83F7
83D7  2E 8A 67 1E       mov ah, byte ptr cs:[bx+1E]
83DB  2E 02 5F 1F       add bl, byte ptr cs:[bx+1F]
83DF  80 D7 00          adc bh, 00
83E2  83 C3 20          add bx, 20
83E5  F6 C4 80          test ah, 80
83E8  74 09             je 83F3
83EA  43                inc bx
83EB  43                inc bx
83EC  2E 83 7F FE 00    cmp word ptr cs:[bx-2], 0000
83F1  75 F8             jne 83EB
83F3  FE C8             dec al
83F5  75 E0             jne 83D7
83F7  2E 8A 47 1C       mov al, byte ptr cs:[bx+1C]
83FB  2E 8A 67 1D       mov ah, byte ptr cs:[bx+1D]
83FF  C3                ret
```

## 5. Generator integration and coverage

The generator now uses one candidate window at 83AEh with an exact 52h-byte limit, covering 83AEh–83FFh. The prior 83C1h seed was removed because it began in the middle of MOV BX,B7D0h.

Projected range-mask result:
- Candidate windows: 896
- Data ranges: 248
- Unique code-window bytes: 44,454
- Unique data-range bytes: 20,515
- Code/data overlap: 334 bytes
- Code/data union: 64,635 / 65,536 (98.63%)
- Uncovered intervals: 44
- Pages touched/full: 256 / 256, 217 / 256
- Next largest uncovered intervals: ABB4h–ABFFh and 2ED8h–2F23h (76 bytes each)

The prior generated candidate listing contains the superseded split at 83C1h and must be regenerated after this corrected single-window definition. The range-mask figures are projections until that run.
