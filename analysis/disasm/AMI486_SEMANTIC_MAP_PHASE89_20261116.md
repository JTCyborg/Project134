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

The cursor values selected by 026Fh are advanced by four before the next record is read. For the two observed starting values, the first records are at 0BA9h and 0BB1h; both contain next-cursor 0644h and callback target 0BA5h. Thus 0BA5h is an indirect target reached through this table path.

Important unresolved overlap: the bytes beginning at 0BA5h also form a dense sequence of four-byte-looking values (for example 0BA5h: 44 06 AD 0B 44 06 A5 0B ...). A linear decode at 0BA5h produces plausible individual 8086 instructions but does not by itself prove executable code. The indirect CALL target and the apparent record/data layout conflict; 0BA5h must remain an alternate-entry/code-data overlap candidate until its full execution and return path are traced. Do not label the table entries as ordinary callbacks yet.

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
02E2  MOV DX,0A16h
02E5  CALL 05A4h
02E8  PUSHF
02E9  AND BYTE [BP+10h],0Fh
02ED  SHL AL,4
02F0  JMP 0300h
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

The data path edits the high nibble of BP+10h using the input/display path at 05A4h with DX=0A16h. It preserves the old low nibble, merges the new high nibble, clears BP+14h bits 6–7, then sets bit 6 only when both the new high nibble (AL) and retained low nibble (AH) are nonzero. This is a confirmed relationship between BP+10h and BP+14h; the user-visible field meaning is still unknown.

Stack contract remains open. In this aligned stream, PUSHF at 02E8h is visible, but there is no local PUSH AX before POP AX at 0316h. The call chain 05A4h -> 05B4h and any nested callback effects must be closed before declaring whether this is a normal callback return or an intentional stack/continuation protocol.

## 5. Callback 02F1h: overlapping low-nibble entry

02F1h is the displacement byte of the short jump beginning at 02F0h (EB 0E). Entering at 02F1h therefore starts a separate stream with opcode 0Eh:

```asm
02F1  PUSH CS
02F2  MOV AL,[BP+10h]
02F5  MOV DX,0B16h
02F8  CALL 05A3h
02FB  PUSHF
02FC  AND BYTE [BP+10h],0F0h
0300  PUSH AX
0301  MOV AH,[BP+10h]
0304  OR [BP+10h],AL
0307  AND BYTE [BP+14h],3Fh
030B  OR AL,AL
030D  JZ 0317h
030F  OR AH,AH
0311  JZ 0317h
0313  OR BYTE [BP+14h],40h
0317  POP AX
0318  POPF
0319  RET
```

This stream updates the low nibble of BP+10h, retaining the high nibble. It recomputes BP+14h bit 6 by the same nonzero-both-nibbles test as 02DBh. DX=0B16h distinguishes this input/display position from the 02DBh path's 0A16h.

The leading PUSH CS is not part of the 02DBh stream. It remains on the stack at the local RET boundary; the exact intended transfer/stack contract is unresolved. Do not describe 02F1h as a conventional near-call/near-return callback until the caller and continuation behavior are proven.

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
