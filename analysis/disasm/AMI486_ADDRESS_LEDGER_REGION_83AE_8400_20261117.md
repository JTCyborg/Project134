# AMI486 address ledger — selector fallback and indexed descriptor lookup (83AEh–83FFh)

Date: 2026-11-17  
Repository: JTCyborg/Project134, branch main  
Source: ami486.bin, 65,536 bytes  
SHA-1: 480c7520c93e6c7ed437cf3ad214da7503f82ec6

## 1. Boundary and control-flow relationship

The preceding candidate at 8378h ends at 83ADh. The next byte, 83AEh, begins a distinct helper. It ends through RET at 83C0h on the nonzero-selector path. A second entry begins at 83C1h and ends at RET 83FFh.

The 83AEh helper's zero-selector branch jumps to 83F7h, the shared final two-byte load sequence and RET belonging to the 83C1h descriptor lookup. Thus the 83AEh and 83C1h entries share the epilogue at 83F7h–83FFh.

## 2. Selector fallback resolver — 83AEh–83C0h

Direct near-CALL sites found by scanning the ROM: 2E84h, 2EC4h and 86F2h.

Behavior:
- Initializes BX to B7D0h.
- If AL is zero, branches to the shared tail at 83F7h, which returns the word at CS:[BX+1Ch] / CS:[BX+1Dh], i.e. the two-byte value at CS:B7ECh.
- If AL is nonzero, zero-extends AL into AX, sets BX to B55Dh- B508h = 0055h, compares AX against 0055h, and returns at 83C0h.

The observed direct callers load AL from CS:B513h, CS:B519h or CS:B52Ch and then use the returned AX. The comparison flags are not used by those immediate caller instruction sequences, so the precise higher-level policy behind the 0055h comparison remains unresolved.

## 3. Indexed variable-length descriptor lookup — 83C1h–83FFh

No direct near-CALL target to 83C1h was found in the raw-byte scan. Its body is nevertheless code: it is a separate entry ending at 83FFh, and the 83AEh zero-selector path enters its shared tail at 83F7h.

The routine:
- Initializes BX to B7D0h.
- Uses the incoming carry flag at 83C4h to select whether to retain that base or subtract the B55Dh-B508h (0055h) offset.
- Loads the descriptor-table base pointer from CS:[82C6h].
- Iterates AL times through 20h-byte descriptor records.
- Reads the record flag at CS:[BX+1Eh] and variable-list length at CS:[BX+1Fh].
- Advances over the variable list when bit 7 of the flag is set, scanning 16-bit entries until a zero terminator.
- Returns descriptor bytes at offsets +1Ch and +1Dh in AX.

This is a variable-length descriptor/table lookup path; the exact descriptor schema and the provenance of the CS:[82C6h] pointer remain to be established.

## 4. Disassembly

```asm
83AE  BB D0 B7          mov bx, B7D0
83B1  0A C0             or al, al
83B3  74 42             je 83F7
83B5  32 E4             xor ah, ah
83B7  BB 5D B5          mov bx, B55D
83BA  81 EB 08 B5       sub bx, B508
83BE  3B C3             cmp ax, bx
83C0  C3                ret

83C1  BB D0 B7          mov bx, B7D0
83C4  72 12             jb 83D8
83C6  BB 5D B5          mov bx, B55D
83C9  81 EB 08 B5       sub bx, B508
83CD  2B C3             sub ax, bx
83CF  2E 8B 1E C6 82    mov bx, word ptr cs:[82C6]
83D4  0A C0             or al, al
83D6  74 20             je 83F8
83D8  2E 8A 67 1E       mov ah, byte ptr cs:[bx+1E]
83DC  2E 02 5F 1F       add bl, byte ptr cs:[bx+1F]
83E0  80 D7 00          adc bh, 00
83E3  83 C3 20          add bx, 20
83E6  F6 C4 80          test ah, 80
83E9  74 09             je 83F4
83EB  43                inc bx
83EC  43                inc bx
83ED  2E 83 7F FE 00    cmp word ptr cs:[bx-2], 0000
83F2  75 F8             jne 83EC
83F4  FE C8             dec al
83F6  75 E0             jne 83D8
83F8  2E 8A 47 1C       mov al, byte ptr cs:[bx+1C]
83FC  2E 8A 67 1D       mov ah, byte ptr cs:[bx+1D]
83FF  C3                ret
```

## 5. Generator integration and projected coverage

The generator adds two exact windows: 83AEh/13h and 83C1h/3Fh. The windows are adjacent and together cover 83AEh–83FFh. The zero-selector branch from 83AEh into 83F7h is explicitly documented as a shared tail.

Projected range-mask result:
- Candidate windows: 897
- Data ranges: 248
- Unique code-window bytes: 44,454
- Unique data-range bytes: 20,515
- Code/data overlap: 334 bytes
- Code/data union: 64,635 / 65,536 (98.63%)
- Uncovered intervals: 44
- Pages touched/full: 256 / 256, 217 / 256
- Next largest uncovered intervals: ABB4h–ABFFh and 2ED8h–2F23h (76 bytes each)

The range figures are projected from the exact 82-byte interval; the updated generator must be executed before these numbers are treated as generated manifest results.
