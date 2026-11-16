# AMI486 semantic map — phase 89 (2026-11-16)

## 1. Callback 026Fh: Setup "Options" bit-field path

The aligned entry at 026Fh is:

```asm
026F  BF 14 00       MOV DI,0014h
0272  BE D7 77       MOV SI,77D7h
0275  BA 16 0D       MOV DX,0D16h
0278  B0 04          MOV AL,04h
027A  EB 00          JMP 027Ch
027C  84 03          TEST [BP+DI],AL
027E  BB AD 0B       MOV BX,0BADh
0281  74 21          JZ 02A4h
0283  BB A5 0B       MOV BX,0BA5h
0286  EB 1C          JMP 02A4h
```

The string at 77D7h begins " Options:". DI=14h and AL=04h make the tested/updated field BP+14h bit 2. The callback selects one of two cursor values (0BADh or 0BA5h) according to that bit, then enters the common dispatcher at 05B4h.

At 02A4h the code saves DI and AX, calls 05B4h, restores the mask into CL and DI, then clears bit 2 of BP+14h. If returned AL is nonzero, it sets bit 2 again. PUSHF/POPF preserve the dispatcher's returned flags. This establishes a bit-2 option-selection path; it does not yet establish the human-readable meaning of that option.

## 2. Secondary dispatcher 05B4h and its data/entry ambiguity

The dispatcher body is:

```asm
05B4  CALL 05E0h
05B7  ADD BX,4
05BA  MOV AX,CS:[BX]
05BD  MOV [BP+02h],AX
05C0  MOV AX,CS:[BX+2]
05C4  CALL AX
05C6  PUSHF
05C7  JAE 05DBh
05C9  JZ 05DBh
05CB  CMP AH,01h
05CE  JZ 05DBh
05D0  POPF
05D1  MOV BX,[BP+02h]
05D4  CMP AH,51h
05D7  JZ 05B7h
05D9  JMP 05BAh
05DB  CALL 05EEh
05DE  POPF
05DF  RET
```

The cursor values selected by 026Fh are advanced by four before the next record is read. The relevant records are:

| Record | Next cursor | Indirect target | Entry meaning established so far |
|---:|---:|---:|---|
| 0BA9h | 0BADh | 064Ah | Selects the " Not Installed" string at 74E5h, then enters the common prompt/input path at 02BAh |
| 0BB1h | 0BD5h | 06AEh | Field callback that may update BP+23h through the shared input helper |

The table bytes are therefore records, not a code entry at 0BA5h. The earlier interpretation of 0BA5h as the indirect target is withdrawn. The complete threaded traversal and all record outcomes remain to be traced.

## 3. Prompt/input subroutine entries around 0288h

Two aligned entries select different CS-resident prompt strings and converge on 02BAh:

- 0288h: MOV SI,74F6h; JMP 02BAh
- 028Eh: MOV SI,7502h; JMP 02BAh

The shared path at 02BAh saves SI, calls 084Fh and 08CDh, restores SI, then calls 0862h with flags saved. It retries when AH is 3Ch or 3Dh; otherwise it returns AL from CS:[SI]. The word table at 0294h..02A3h contains the repeated offsets 029Ch, 0288h, 029Ch, 0288h, 0294h, 028Eh, 0294h, 028Eh. Its exact consumer/entry interpretation is not yet established.

These entries are adjacent to the 026Fh option path but are not reached by its currently proven conditional edges. Preserve them as separate alternate-entry candidates.

## 4. Callback 02DBh: high-nibble update of BP+10h

The aligned stream begins:

```asm
02DB  MOV AL,[BP+10h]
02DE  SHR AL,4
02E1  MOV DX,0A16h
02E4  CALL 05A3h
02E7  PUSHF
02E8  AND BYTE [BP+10h],0Fh
02EC  SHL AL,4
02EF  JMP 02FFh
02FF  PUSH AX
0300  MOV AH,[BP+10h]
0303  OR [BP+10h],AL
0306  AND BYTE [BP+14h],3Fh
030A  OR AL,AL
030C  JZ 0316h
030E  OR AH,AH
0310  JZ 0316h
0312  OR BYTE [BP+14h],40h
0316  POP AX
0317  POPF
0318  RET
```

The data path edits the high nibble of BP+10h using the input/display path at 05A3h with DX=0A16h. It preserves the old low nibble, merges the new high nibble, clears BP+14h bits 6–7, then sets bit 6 only when both the new high nibble (AL) and retained low nibble (AH) are nonzero. This is a confirmed relationship between BP+10h and BP+14h; the user-visible field meaning is still unknown.

The high-nibble path jumps over the independent low-nibble entry at 02F1h and lands at 02FFh. Both paths execute PUSH AX at 02FFh, then share POP AX; POPF; RET at 0316h..0318h. The stack is balanced on the visible paths. Both input calls target 05A3h, which in turn enters the secondary dispatcher at 05B4h.

## 5. Callback 02F1h: overlapping low-nibble entry

02F1h is the aligned start of the low-nibble callback. It follows the short jump at 02EFh (EB 0E), whose displacement byte is at 02F0h. The high-nibble path jumps to 02FFh, skipping this low-nibble stream:

```asm
02F1  MOV AL,[BP+10h]
02F4  MOV DX,0B16h
02F7  CALL 05A3h
02FA  PUSHF
02FB  AND BYTE [BP+10h],0F0h
02FF  PUSH AX
0300  MOV AH,[BP+10h]
0303  OR [BP+10h],AL
0306  AND BYTE [BP+14h],3Fh
030A  OR AL,AL
030C  JZ 0316h
030E  OR AH,AH
0310  JZ 0316h
0312  OR BYTE [BP+14h],40h
0316  POP AX
0317  POPF
0318  RET
```

This stream updates the low nibble of BP+10h, retaining the high nibble. It recomputes BP+14h bit 6 by the same nonzero-both-nibbles test as 02DBh. DX=0B16h distinguishes this input/display position from the 02DBh path's 0A16h.

The low-nibble path also reaches the shared PUSH AX at 02FFh and the common balanced epilogue at 0316h..0318h. There is no PUSH CS at 02F1h; the earlier stack-transfer interpretation is withdrawn.

## 6. Corrected callback status and next work

Confirmed:
- 026Fh is an "Options:" callback path that tests and updates BP+14h bit 2.
- 02DBh edits the high nibble of BP+10h.
- 02F1h is a distinct overlapping entry that edits the low nibble of BP+10h.
- Both nibble paths clear BP+14h bits 6–7 and set bit 6 only when both nibbles are nonzero.

Still unresolved:
- The indirect target 0BA5h and the apparent table/code overlap around 0BA5h..0BDFh.
- The full nested callback contract of 05A4h/05A3h -> 05B4h.
- The unusual stack/return behavior of 02DBh and 02F1h.
- The actual runtime outcomes through the main callback dispatcher at 01EDh..020Dh.
- The semantic label for BP+10h and the exact meaning of BP+14h bits 2 and 6.

Next: trace the nested 05A4h/05A3h input path and 05B4h's 0BA5h target from real entry boundaries, then reconcile the stack behavior against the outer 01EDh dispatcher before assigning callback return semantics.


## Phase 89 correction — secondary callback table (raw-offset recheck)

The first read of the 0BA5h region was misaligned by two bytes. Revalidation against the 65,536-byte ROM gives the four-byte records at 0BA5h, 0BA9h, 0BADh, 0BB1h, etc. In particular, the 026Fh-selected cursors lead to record 0BA9h (target 064Ah) or 0BB1h (target 06AEh), not to a CALL of 0BA5h. The apparent 0BA5h code/data conflict described above is withdrawn. The record table is now confirmed as a linked callback table; its full traversal still requires analysis.


## Raw-offset correction — callback pair

The initial phase-89 byte alignment was shifted by one. Correct entries are 02DBh (high nibble) and 02F1h (low nibble); both call 05A3h. The short jump is at 02EFh and targets 02FFh. The common code from 02FFh performs PUSH AX, loads the retained nibble into AH, merges AL into BP+10h, recomputes BP+14h bit 6, then restores AX/flags and returns. No stack imbalance is present in these two paths.
