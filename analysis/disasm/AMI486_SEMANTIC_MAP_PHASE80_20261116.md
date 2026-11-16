# AMI486 semantic map — phase 80 (2026-11-16)

## 1. Corrected exact CALL targets at 5D6Ah..5D9Ch

Phase 79's CALL-target arithmetic was wrong because it used misaligned instruction offsets. Recalculation from the exact byte addresses shows that the calls enter the CMOS helpers correctly:

| CALL site | Target | Meaning |
|---|---:|---|
| 5D6Dh | EE94h | CMOS read helper |
| 5D75h | EE9Dh | CMOS write helper |
| 5D7Ah | EE94h | CMOS read helper |
| 5D84h | EE94h | CMOS read helper |
| 5D89h | EE94h | CMOS read helper |
| 5D91h | EE9Dh | CMOS write helper |
| 5D99h | EE9Dh | CMOS write helper |

EE94h is the complete CMOS read routine (OUT 70h,AL; delays; IN AL,71h; RET). EE9Dh is the complete write routine (OUT 70h,AL; exchange AH into AL; delays; OUT 71h,AL; restore AX; RET). None of these calls targets EE93h.

## 2. Exact aligned routine and data flow

```asm
5D5E  MOV DI,0020h
5D61  INC SP
5D62  PUSH DS
5D63  STOSW                 ; preceding PUSHA at 5D5F, DI=0020h
5D63  MOV AX,CS
5D65  STOSW                 ; stores CS at ES:0022h
5D66  MOV AL,FEh
5D68  OUT 21h,AL
5D6A  MOV AX,00B8h
5D6D  CALL EE94h            ; read CMOS[B8h], returns AX=00:data
5D70  MOV DI,AX             ; DI = zero-extended old CMOS[B8h]
5D72  MOV AX,00B8h
5D75  CALL EE9Dh            ; write 00h to CMOS[B8h]
5D78  MOV AL,8Eh
5D7A  CALL EE94h            ; read CMOS[8Eh]
5D7D  TEST AL,C0h
5D7F  JNZ 5D9Eh              ; skip adjustment if either bit 6/7 set
5D81  MOV AX,BFBEh
5D84  CALL EE94h            ; read CMOS[BEh], AL = BE value
5D87  XCHG AH,AL            ; AH = BE value, AL = BFh index
5D89  CALL EE94h            ; read CMOS[BFh], AX = BE:BF word
5D8C  SUB AX,DI             ; subtract old CMOS[B8h] (zero-extended)
5D8E  PUSH AX
5D8F  MOV AL,BEh
5D91  CALL EE9Dh            ; write result high byte to CMOS[BEh]
5D94  POP AX
5D95  XCHG AH,AL
5D97  MOV AL,BFh
5D99  CALL EE9Dh            ; write result low byte to CMOS[BFh]
```

The entry context immediately before the first STOSW is `MOV DI,0020h; INC SP; PUSH DS`. The two STOSW instructions store the current AX and CS in ES:0020h and ES:0022h respectively. There is no PUSHA at this location; the earlier PUSHA annotation was an address-alignment error. The later `MOV DI,AX` at 5D70h replaces DI with the zero-extended value read from CMOS B8h.

The first CMOS access therefore reads the old B8h byte into DI, and the next write clears CMOS B8h to zero. If CMOS[8Eh] bits 6 and 7 are both clear, the code reads the word CMOS[BEh:BFh], subtracts the saved old B8h byte (zero-extended), and writes the adjusted word back to BEh:BFh.

## 3. Consequence for BEh:BFh interpretation

This is a second confirmed writer of CMOS BEh:BFh, distinct from the checksum-sum routine at 17F0h/1810h. It is not a subtraction of CS or a fixed BFBEh constant: BFBEh is the pair of CMOS indices used to read the existing word. The subtractand is the old CMOS[B8h] byte.

Thus BEh:BFh is demonstrably context-dependent/shared storage, or is processed by multiple firmware stages with a defined ordering. Do not label it a dedicated checksum field until its readers, initialization order, and the role of CMOS[B8h] and CMOS[8Eh] are resolved.

## 4. Correction status

Withdraw the phase 79 interpretation that calls at 5D83h/5D88h were RET-only stubs and that the block subtracts CS from a BFBEh constant. Both conclusions were caused by a one-byte address-alignment error. Phase 79's conclusion that BEh:BFh has multiple writers remains correct, but its description of the second writer is superseded by this phase.

## 5. Next targets

- Trace the producer and meaning of CMOS[B8h] and the gate byte CMOS[8Eh].
- Find all readers and writers of CMOS[BEh:BFh], and establish ordering relative to the range-sum writer.
- Trace E5DBh status returned in AL at 5D54h and its bit-5 gate.
- Continue BP.13 provenance and dynamic entry into DA5Eh/DA61h.
