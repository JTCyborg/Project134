# AMI486 semantic map — phase 79 (2026-11-16)

## 1. Correct decode of POST block 5D50h..5DA0h

The prior interpretation of 5D81h..5D9Ch as reading the existing CMOS BEh:BFh value is withdrawn. The actual bytes show that the apparent calls at 5D83h and 5D88h target EE93h, which is a single RET instruction. They do not read CMOS.

Relevant aligned stream:

```asm
5D50  MOV AL,25h
5D52  OUT 80h,AL
5D54  CALL E5DBh
5D57  MOV [0012h],AL
5D5A  TEST AL,20h
5D5C  JNZ 5D9Eh
5D5E  MOV DI,0020h
5D61  PUSHA
5D62  PUSH DS
5D63  STOSW                 ; ES:0020 receives original AX
5D64  MOV AX,CS
5D66  STOSW                 ; ES:0022 receives CS
5D67  MOV AL,FEh
5D69  OUT 21h,AL
5D6B  MOV AX,00B8h
5D6E  CALL EE93h            ; RET-only delay stub
5D71  MOV DI,AX             ; DI = CS, from preceding MOV AX,CS
5D73  MOV AX,00B8h
5D76  CALL EE93h            ; RET-only delay stub
5D79  MOV AL,8Eh
5D7B  CALL EE93h            ; RET-only delay stub
5D7E  TEST AL,C0h
5D80  JNZ 5D9Dh
5D82  MOV AX,BFBEh
5D85  CALL EE93h            ; RET-only delay stub
5D88  XCHG AH,AL            ; AX = BFBEh (same value here)
5D8A  CALL EE93h            ; RET-only delay stub
5D8D  SUB AX,DI             ; subtract CS
5D8F  PUSH AX
5D90  MOV AL,BEh
5D92  CALL EE9Dh            ; CMOS[BEh] = AH
5D95  POP AX
5D96  XCHG AH,AL
5D98  MOV AL,BFh
5D9A  CALL EE9Dh            ; CMOS[BFh] = AH
```

Correction to the compact decode above: the raw byte at 5D88h is `86 C4` (XCHG AH,AL), followed by the CALL at 5D8Ah. The arithmetic is therefore performed on the byte-swapped BFBEh value (numerically BFBEh; the two bytes are distinct), minus DI.

The sequence sets DI from CS, not from a previously read CMOS value. The immediate arithmetic is:
- AX starts as BFBEh.
- XCHG AH,AL makes AX=BFBEh? No: the MOV at 5D82h is `B8 BE BF`, so AX=BFBEh; XCHG makes AX=BE BFh (BEBFh).
- SUB AX,DI subtracts the current CS value.
- The resulting word is written high byte to CMOS BEh and low byte to CMOS BFh.

For a conventional POST execution with CS=F000h, the stored value would be 2EBFh (BEBFh - F000h modulo 10000h). This is a derived example, not a claim that CS is invariant on every entry.

## 2. Entry condition and side effects

The block is guarded by status bits:
- At 5D5Ah, TEST AL,20h; if set, the code jumps over the initialization block.
- At 5D7Eh, TEST AL,C0h; if either high bit is set, it jumps over the CMOS BEh:BFh update.

The first branch also skips the low-memory ES:0020h/ES:0022h stores and the PIC mask write. The exact meaning of AL returned from CALL E5DBh still needs tracing; it is saved at DS:0012h and used as the first gate.

## 3. Meaning of the CMOS BEh:BFh update — limited conclusion

This code writes a word derived from the constant BEBFh and the current CS segment into CMOS BEh:BFh, subject to the AL status gate. It is not a checksum read/compare/update path. The value resembles a segment-relative relocation/POST marker, but that semantic label remains a hypothesis until consumers of CMOS BEh:BFh are mapped.

The separate checksum routine from phase 78 still computes the sum of CMOS B4h..BDh and C0h..E0h and writes that sum to BEh:BFh. The presence of this additional writer means BEh:BFh is not safely describable as a dedicated checksum field without understanding call order and competing uses. Phase 78's checksum-write fact remains correct as a local routine fact, but the global interpretation must be downgraded: BEh:BFh is a shared CMOS field or context-dependent field.

## 4. Next steps

- Trace E5DBh to determine the status byte AL and its bit meanings.
- Find the readers of CMOS BEh:BFh and establish which writer runs last on each boot path.
- Trace the caller/entry into the 17F0h/1810h checksum writer.
- Continue BP.13 provenance and dynamic entry into DA5Eh/DA61h.
