# AMI486 semantic map — phase 61 (2026-11-16)

## Scope

Continue tracing the incoming BP word at 5194h, identify all local writers before the bitmap frame is saved, and test for static direct references to the 509Eh–50A0h memory/POST block.

## 1. Confirmed control flow from 509Eh to the BP test

The inspected code is contiguous:

```asm
509E  mov ax,028Fh
50A1  call EE9D              ; CMOS write helper
50A4  mov al,40h
50A6  out 80h,al
50A8  call F3DB
50AB  mov al,41h
50AD  out 80h,al
...
50CD  mov ah,89h
50D3  int 15h                ; BIOS protected-mode interface
50D5  mov al,43h
50D7  out 80h,al
50D9  je 50E1
50DB  mov si,7AB2h
50DE  jmp F509               ; failure path
50E1  call 5506
...
5189  push 5190h
518C  push FA4Eh
518F  ret                     ; stack-crafted call to FA4E
5190  mov al,4Bh
5192  out 80h,al
5194  or bp,bp
5196  jns 51F3
```

The INT 15h/AH=89h call at 50D3h is a real-mode-to-protected-mode interface call. Its status flags determine whether execution continues at 50E1h or exits through F509h. This provides an important runtime gate for the later BP test, but the call's documented interface does not itself establish a BP result.

## 2. BP writers in the local path

From 509Eh through 5194h, the visible instructions do not write BP. The helper calls in this interval must still be treated as potential register clobberers unless their implementation or ABI proves preservation. The key calls are:

- EE9D at 50A1h: CMOS write helper.
- F3DB at 50A8h: helper not yet fully audited in this phase.
- INT 15h/AH=89h at 50D3h: protected-mode interface.
- 5506h at 50E1h: interrupt-mask/IF helper.
- 5305h at 5121h: memory probe helper.
- 534Ch at 5144h and 5152h: write/test memory helper.
- 5371h at 5167h and 517Fh: memory scan helper.
- FA4Eh via stack-crafted RET at 518Fh: helper already examined in phase 53; PUSHAW frame/validation routine.

Therefore the statement “BP is unchanged from the caller” is not yet proven. The machine-code path has no direct BP assignment, but calls and INT 15h can affect registers unless their actual implementations preserve BP.

## 3. Meaning of the BP sign test

At 5194h:

```asm
5194  or bp,bp
5196  jns 51F3
```

This tests the sign bit, BP.15. It does not specifically test BP.13. If BP is negative, the code enters the memory-test branch beginning at 5198h. If nonnegative, it enters 51F3h, temporarily sets BP=1, then restores the original BP at 5239h before the common frame is saved at 525Fh.

At 525Fh, PUSHAW saves the current BP. The frame is restored at 5289h before the 52C1h→E2C6h route. Thus the saved value contains whatever BP value survives the helpers and the selected memory-test branch.

## 4. Static cross-reference result

A search of the complete linear disassembly for direct near CALL/JMP targets found no direct branch to:

- 509Eh / 50A0h
- 50E1h
- 5189h / 5190h
- 5194h
- 51F3h
- 525Fh
- 5280h
- 52C1h

The only ordinary local branch into the shared tail is 51F1h→523Eh. This is consistent with a code region entered through an indirect dispatch, a far/stack-crafted transfer, or a runtime vector, but does not prove which mechanism is used.

A raw-byte scan for little-endian near pointers 509Eh, 50A0h, 50E1h, 5194h and 5189h found no corresponding static words in the 64 KiB image. This rules out only simple literal offset tables; it does not rule out computed pointers, far pointers with different segment bases, patched RAM vectors, or stack-created return addresses.

## 5. Revised BP.13 provenance statement

The strongest proven statement is:

- BP.13 is consumed by the 16-iteration handler bitmap loop at 1662h.
- The BP word used there is restored from the PUSHAW frame saved at 525Fh.
- That frame is restored at 5289h before the E2C6h/E3xx/10E0h POST route.
- The incoming BP at 5194h is tested for sign; no local explicit BP assignment occurs before that test.
- However, the intervening helper calls and INT 15h/AH=89h have not all been proven to preserve BP. It is therefore premature to claim that the BP value at 5194h is exactly the same as the value at the entry to 509Eh, or that it came unchanged from an upstream caller.

## 6. Next targets

1. Audit F3DB and the EE9D/F509 helper call paths for BP preservation.
2. Audit the INT 15h/AH=89h implementation at 933Ah and its return contract for BP.
3. Trace the runtime entry to 509Eh/50A0h through the relevant indirect/far dispatch or stack frame.
4. Once the BP-preserving boundary is known, walk backward to the first definite writer of BP.13.

## Confirmed vs unresolved

### Confirmed
- 50D3h executes INT 15h/AH=89h; ZF controls success continuation at 50E1h versus failure path F509h.
- 5194h tests BP.15, not BP.13.
- The nonnegative path temporarily writes BP=1 and restores the prior BP at 5239h.
- PUSHAW at 525Fh captures the value after the two paths converge; POPAW at 5289h restores it before E2C6h.
- No direct static near CALL/JMP targets into the listed entry offsets were found.
- No simple raw little-endian near-offset words for the candidate entry offsets were found.

### Unresolved
- Whether any called helper or INT 15h/AH=89h modifies BP before 5194h.
- The actual runtime entry to the 509Eh block.
- The first producer of BP.13.
