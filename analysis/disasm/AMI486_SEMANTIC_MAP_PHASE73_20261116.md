# AMI486 semantic map — phase 73 (2026-11-16)

## 1. Correction: crafted return address from RAM test 29BBh

Phase 72 incorrectly stated that the RET at 29EAh returns to 01F1h. Rechecking the exact bytes corrects this:

```asm
27C4  MOV SP,27CAh
27C7  JMP 29BBh
27CA  CC 27       ; word 27CCh, consumed by RET
27CC  JZ 27DEh
27CE  ...
```

The stack points at 27CAh; therefore RET pops 27CCh. It does not return into 01F1h. The earlier interpretation of an overlapping-code continuation at 01F1h is withdrawn.

## 2. Correct semantics of the 29BBh memory-pattern test

The routine is a two-pattern test, not an infinite loop on a successful memory test:

```asm
29BB  XOR SI,SI
29BD  MOV CX,2000h
29C0  REP LODSD
29C3  MOV AX,55AAh
29C6  MOV CX,2000h
29C9  XOR DI,DI
29CB  REP STOSW
29CD  MOV CX,2000h
29D0  XOR DI,DI
29D2  REPE SCASW
29D4  JNZ 29DFh
29D8  NOT AX
29DA  CMP AX,55AAh
29DD  JNZ 29C6h
29DF  MOV AX,0
29E2  MOV DI,0
29E5  MOV CX,2000h
29E8  REP STOSW
29EA  RET
```

- First pass writes 55AAh to 8192 words (16 KiB) at ES:0000 and verifies them.
- If the scan succeeds, AX is still 55AAh. NOT AX produces AA55h; CMP against 55AAh is unequal, so JNZ repeats at 29C6h.
- Second pass writes AA55h and verifies it. NOT AX then produces 55AAh; CMP is equal, so execution falls through to clear the tested 16 KiB and RET.
- If either scan finds a mismatch, REPE SCASW exits with ZF=0; JNZ branches to the clear-and-return tail. String stores and RET preserve the comparison flags for the caller.

Thus the return status is conveyed in ZF: ZF=1 for both successful patterns, ZF=0 on a mismatch.

At 27CCh the crafted return continuation is `JZ 27DEh`. Successful verification takes the JZ and skips the memory-error flag. A mismatch does not take it and executes `OR BP,4000h` at 27CEh, setting BP bit 14. This is now a direct, instruction-level connection between the 29BBh RAM test and the existing BP.14 error flag analysis.

The initial `REP LODSD` reads 8192 dwords (32 KiB) from DS:0000 before the 16-KiB write/verify sequence. Its precise purpose is not established; do not conflate this preliminary read with the 16-KiB pattern test.

## 3. Correction: helper 29EDh reads CMOS index B6h

Phase 72 described the helper as setting DH=B6h. The bytes show the actual instruction:

```asm
29ED  MOV AX,B6B6h
29F0  CALL EE94h
29F3  TEST AL,01h
29F5  RET
```

The helper sets AL=B6h (AH is also B6h), calls EE94h, and returns the state of bit 0 in the CMOS value read.

The actual EE94h routine is:

```asm
EE94  OUT 70h,AL
EE96  JCXZ EE98h
EE98  JCXZ EE9Ah
EE9A  IN AL,71h
EE9C  RET
```

The two `JCXZ +0` encodings are zero-displacement no-ops. The routine selects CMOS/NVRAM index B6h through port 70h and reads the corresponding data byte from port 71h. Therefore 29EDh tests CMOS byte B6h bit 0.

Direct near CALL sites to 29EDh found by scanning the full 64-KiB image:
- 1A1Dh
- 1C72h
- 1F4Dh
- 23F2h

Each caller uses the same helper result; the helper itself only returns AL bit 0 as a condition. The meaning of CMOS B6h bit 0 remains unknown pending surrounding caller-path analysis and any BIOS setup/configuration code that writes index B6h.

## 4. Confirmed control-flow interpretation at 2998h

The PIT sampler ends with bytes FF E7 at 2998h, i.e. `JMP DI`. In the 28F2h memory-segment scan, DI is set to 2911h or 291Bh before entering the shared PIT sample block. The sampler dispatches back to that continuation. Bytes from 299Ah are not a straight-line continuation of this path.

## 5. Work queue

- Trace the four callers of 29EDh to determine why CMOS B6h bit 0 is checked.
- Search all CMOS-index writes to port 70h and determine whether B6h is modified or merely read.
- Continue the DA5Eh/DA61h dynamic-entry and BP.13 provenance search. The 29BBh test now explains BP.14 only; it does not explain BP.13.
- Revisit 299Ah segment-read routine entry separately; no direct near CALL/JMP or literal pointer to 299Ah was found in the raw-image scan.
