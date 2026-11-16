# AMI486 semantic map — phase 80 (corrected, 2026-11-16)

## 1. Exact aligned sequence at 5D5Ch..5D9Bh

The previous version of this report had a one-byte alignment error in its instruction listing and a mistaken interpretation of bytes before the CMOS accesses. Re-decoding from the actual ROM offsets gives:

```asm
5D5C  MOV DI,0020h
5D5F  MOV AX,1E44h
5D62  STOSW                 ; ES:0020h = 1E44h
5D63  MOV AX,CS
5D65  STOSW                 ; ES:0022h = CS
5D66  MOV AL,FEh
5D68  OUT 21h,AL
5D6A  MOV AX,00B8h
5D6D  CALL EE94h            ; read CMOS[B8h]
5D70  MOV DI,AX             ; DI = zero-extended old CMOS[B8h]
5D72  MOV AX,00B8h
5D75  CALL EE9Dh            ; write zero to CMOS[B8h]
5D78  MOV AL,8Eh
5D7A  CALL EE94h            ; read CMOS[8Eh]
5D7D  TEST AL,C0h
5D7F  JNZ 5D9Ch              ; skip adjustment if bit 6 or 7 is set
5D81  MOV AX,BFBEh
5D84  CALL EE94h            ; read CMOS[BEh], AL = CMOS[BEh]
5D87  XCHG AH,AL            ; AL = BFh index, AH = BEh value
5D89  CALL EE94h            ; read CMOS[BFh], AX = CMOS[BEh:BFh]
5D8C  SUB AX,DI             ; subtract old CMOS[B8h], zero-extended
5D8E  PUSH AX
5D8F  MOV AL,BEh
5D91  CALL EE9Dh            ; write result high byte to CMOS[BEh]
5D94  POP AX
5D95  XCHG AH,AL
5D97  MOV AL,BFh
5D99  CALL EE9Dh            ; write result low byte to CMOS[BFh]
5D9C  MOV AL,26h             ; common continuation
5D9E  OUT 80h,AL
```

There is no PUSHA at 5D5Fh and no `INC SP; PUSH DS` prelude in this aligned decode. The immediate word 1E44h is loaded into AX and stored at ES:0020h. CS is then stored at ES:0022h.

## 2. CALL targets (verified from raw relative displacements)

| CALL site | Target | Meaning |
|---|---:|---|
| 5D6Dh | EE94h | CMOS read |
| 5D75h | EE9Dh | CMOS write |
| 5D7Ah | EE94h | CMOS read |
| 5D84h | EE94h | CMOS read |
| 5D89h | EE94h | CMOS read |
| 5D91h | EE9Dh | CMOS write |
| 5D99h | EE9Dh | CMOS write |

EE94h performs CMOS index selection through port 70h and reads port 71h. EE9Dh selects the index and writes the value through port 71h.

## 3. Data-flow conclusion

The routine saves CMOS[B8h] in DI, clears CMOS[B8h], then reads CMOS[8Eh]. If bits 6 and 7 of CMOS[8Eh] are clear, it reads CMOS[BEh:BFh], subtracts the saved old B8h byte, and writes the adjusted 16-bit result back to BEh:BFh.

This is a second confirmed writer of CMOS[BEh:BFh], distinct from the range-sum writer at 17F0h/1810h. BFBEh is the pair of CMOS indices used to read the existing word; it is not a constant arithmetic operand.

## 4. Superseded interpretations

- Phase 79's claim that the 5D83h/5D88h calls entered RET-only stubs is withdrawn.
- The earlier phase80 listing that placed the prelude at 5D5Eh and described INC SP/PUSH DS is also withdrawn. The correct entry-aligned sequence begins at 5D5Ch as listed above.
- Do not call BEh:BFh a dedicated checksum field. Its global meaning and update ordering remain unresolved.

## 5. Remaining targets

Trace CMOS[B8h] and CMOS[8Eh] producers/readers, all BEh:BFh consumers, and the ordering of the range-sum and adjustment writers. BP.13 provenance and dynamic entry into DA5Eh/DA61h remain unresolved.
