# AMI486 semantic map — phase 77 (2026-11-16)

## 1. Indirect CMOS-loop dispatch: new control-flow caveat

The code immediately following the second CMOS sum loop is not safely classifiable as ordinary sequential fall-through. At 1837h the bytes decode:

```asm
1837  MOV DI,183Bh
183A  JMP SHORT 17F3h
```

The target 17F3h is the second byte of the two-byte instruction `33 DB` at 17F2h (`XOR BX,BX`). The normal aligned CMOS loop entry is 17F2h, not 17F3h. Therefore this is an overlapping/alternate entry, and the resulting stream must not be silently merged with the aligned 17F2h decode. In particular, the 17F3h stream begins `DB B4 00...`, unlike the CMOS loop. It may be an intentional alternate x86 instruction stream, but its actual runtime reachability and CPU/FPU assumptions are not established.

This explains why treating the post-loop bytes as a simple linear caller was unsafe. The loop's `JMP DI` must be followed through runtime DI state; static byte scanning is insufficient.

## 2. More alternate DI dispatchers

Additional nearby byte sequences include:

```asm
184B  MOV DI,184Fh
184E  JMP SHORT 1810h
1850  MOV AL,BEh
1852  MOV AH, BH
1854  CALL EE9Eh
1857  MOV AL,BFh
1859  JMP SHORT 1845h
```

These are candidate entry/dispatch sequences in the same overlapping region. The raw bytes show explicit DI setup and short jumps, but their relationship to the aligned CMOS-sum loops needs a path proof. Do not assign CMOS meaning to every byte in the alternate stream.

## 3. Implications for checksum interpretation

The two aligned loops remain established as:
- 17F2h: sum CMOS indices 90h..ADh, then indirect jump through DI.
- 1810h: sum B4h..BDh and C0h..E0h, then indirect jump through DI.

However, no verified caller/continuation currently proves that BX is compared with a stored checksum. The apparent dispatcher at 1837h is overlapping code and cannot yet be used as evidence of a conventional checksum call sequence.

## 4. Open items retained

- Resolve the alternate entry at 17F3h and determine whether it is executable on the target CPU.
- Trace DI values at every reachable entry into 17F2h and 1810h.
- Find consumers of BX after each indirect dispatch.
- Continue the independent BP.13 producer search and dynamic entry into DA5Eh/DA61h.


## Correction: helper target

The relative CALL displacements in this dispatcher resolve to **EE9Eh**, not D69Eh. This is an alternate entry one byte into the CMOS write helper at EE9Dh: it skips `OUT 70h,AL` and enters at `XCHG AH,AL`, then proceeds through the delays and `OUT 71h,AL`. Thus these call sites write the data byte to the currently selected CMOS index; they do not select a new index themselves. The AL/AH setup immediately before each call is therefore significant, and the index-selection state must be traced from the preceding code.
