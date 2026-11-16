# AMI486 semantic map — phase 72 (2026-11-16)

## 1. Correct alignment after the PIT sampler

Raw ROM bytes at 2998h:

```
2996  2B D8       SUB BX,AX
2998  FF E7       JMP DI
299A  1E          PUSH DS
299B  56          PUSH SI
299C  B8 00 10    MOV AX,1000h
299F  8E D8       MOV DS,AX
...
```

The previous linear listing incorrectly treated 2998h as a one-byte `db FF` and decoded from 2999h. The actual instruction is `JMP DI`. In the confirmed 28F2h caller:
- 290Bh sets DI=2911h, then jumps to 296Bh.
- 2915h sets DI=291Bh, then jumps to 296Bh.
- The PIT sample at 296Bh–2996h ends at 2998h with `JMP DI`, returning to the selected continuation.
- 2911h captures the first sample in DX; 291Bh computes the absolute delta, increments BP for each qualifying segment, and either repeats the sample or exits to 2937h.

This confirms the control-flow dispatch at 2998h and invalidates the earlier idea that the byte sequence beginning 2999h is a straight-line continuation of the PIT routine.

## 2. Separate routine beginning at 299Ah

The bytes beginning at 299Ah decode independently as:

```asm
299A  PUSH DS
299B  PUSH SI
299C  MOV AX,1000h
299F  MOV DS,AX
29A1  MOV BX,8
29A4  XOR SI,SI
29A6  MOV CX,8000h
29A9  REP LODSW
29AB  MOV AX,DS
29AD  ADD AX,1000h
29B0  MOV DS,AX
29B2  DEC BX
29B3  CMP BL,0
29B6  JNZ 29A4
29B8  POP SI
29B9  POP DS
29BA  RET
```

It reads eight 64-KiB segment windows (8 × 0x8000 words = 512 KiB) starting at DS=1000h, advancing DS by 1000h each pass. It preserves DS and SI. No direct near CALL/JMP to 299Ah and no literal 299Ah pointer were found in the raw image scan. Its actual entry mechanism remains unproven; do not assume it follows the PIT routine.

## 3. Confirmed alternate RAM test at 29BBh

A raw relative-branch calculation identifies a direct jump at 27C7h to 29BBh. The source sequence sets DS=ES=1000h and establishes a crafted stack before the jump:

```asm
27BC  MOV AX,1000h
27BF  MOV DS,AX
27C1  MOV ES,AX
27C3  NOP
27C4  MOV SP,27CAh
27C7  JMP 29BBh
```

The target is a separate RAM pattern test:

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
29D2  REP SCASW
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

The routine reads a block, fills ES:0000–3FFF with 55AAh, scans it, then clears 16 KiB and returns on the mismatch path. If the scan completes with all words matching, AX is still 55AAh; NOT AX makes AA55h, so CMP AX,55AAh is unequal and JNZ repeats at 29C6h. Thus the all-matching case loops, while a detected mismatch reaches the clear-and-return path. This unusual polarity is directly implied by the instructions; its intended diagnostic meaning is not yet established.

The crafted SP=27CAh means RET at 29EAh pops the word stored at 27CAh (the displacement bytes of the near JMP at 27C7h), producing IP=01F1h. This is an intentional overlapping-code continuation candidate: execution resumes at 01F1h, inside the short-JMP displacement sequence at 01F0h. The bytes at 01F1h then decode as `ADD AX,[BP+DI+4]` followed by the subsequent instruction stream. This stack/overlap relationship should be verified against the complete entry context before assigning high-level meaning.

## 4. Helper 29EDh

There are four direct near CALL sites to 29EDh in the raw image: 1A1Dh, 1C72h, 1F4Dh, and 23F2h. The routine is:

```asm
29ED  MOV DH,B6h
29EF  CALL EE94h
29F2  TEST AL,01h
29F4  RET
```

It invokes the common EE94h hardware/CMOS access helper with DH=B6h and returns AL bit 0 as the condition. The exact device/register semantics of B6h remain to be traced at EE94h.

## 5. Conclusions and next work

- The PIT routine's real continuation is the indirect `JMP DI` at 2998h.
- 299Ah is a distinct segment-read routine with no established incoming edge yet.
- 29BBh is reached directly from 27C7h and uses a crafted stack to return into overlapping code at 01F1h.
- The 29BBh pattern loop's all-match/mismatch behavior is now explicit, but its purpose and caller context need deeper tracing.
- 29EDh has four direct callers and is a separate one-bit hardware test helper.

Next: reconstruct the full 27A8h–27D8h caller path and the 01E8h–0208h overlapping continuation, trace EE94h for selector B6h, and continue the BP.13 / DA5Eh/DA61h search independently.
