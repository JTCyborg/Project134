# AMI486 semantic map — phase 70 (2026-11-16)

## 1. Correct instruction alignment at F000:F068

The phase 69 question about DS at F06Ah is resolved by re-decoding from the actual entry boundary F000:F068, rather than accepting the linear-sweep boundary at F066h.

Raw bytes:

```
F068: FA
F069: 2E F6 06 81 82 40
F06F: 74 03
F071: E9 61 9A
F074: 2E 0F 01 16 68 E2
F07A: B8 40 00
F07D: 8E D8
F07F: 8E C0
F081: 8E D0
F083: 0F 20 C0
F086: 24 FE
F088: 0F 22 C0
F08B: EA 90 F0 00 F0
F090: 2E 0F 01 1E B8 E2
F096: E9 C2 EF
```

Correct entry-aligned decode:

```asm
F068  CLI
F069  CS: TEST byte [8281h],40h
F06F  JZ  F074
F071  JMP F000:8AD5h        ; near target in same CS
F074  CS: LGDT [E268h]
F07A  MOV AX,0040h
F07D  MOV DS,AX
F07F  MOV ES,AX
F081  MOV SS,AX
F083  MOV EAX,CR0
F086  AND AL,FEh            ; clear CR0.PE
F088  MOV CR0,EAX
F08B  JMP FAR F000:F090
F090  CS: LIDT [E2B8h]
F096  JMP E05Bh
```

The branch at F068 is therefore **not** an unprefixed DS-relative read. It explicitly reads CS:8281h. With the stock ROM byte at F000:8281 = 00h, JZ is taken and the keyboard-controller reset branch is not taken. This closes the segment-state uncertainty raised in phase 69.

The F074 path loads GDTR and IDTR descriptors from CS-relative ROM data, sets DS/ES/SS to 0040h, clears CR0.PE, then transfers to F000:F090 and jumps back to the reset/POST entry at E05Bh. This is a protected-mode exit / reset-to-real-mode trampoline, not an ordinary POST feature test.

## 2. Alignment caveat

A linear sweep from F066h decodes bytes F066–F069 as an unrelated instruction, thereby missing the actual CLI + CS override sequence beginning at F068h. The correct decode depends on an alternate entry at F068h. This is a concrete example of why the linear 65,536-byte decode cannot be treated as a complete control-flow graph.

A byte-pattern scan found candidate relative-branch encodings whose computed destinations land near F068h (including offsets 1E41h, 527Dh, 5483h, and 91CEh). These are **not** promoted to confirmed incoming edges: the scan did not establish instruction boundaries at each source. They need validation against entry-aligned local disassembly / actual caller paths.

## 3. BP.13 / DA5Eh status

This trampoline analysis does not establish a producer for BP.13 and does not create a proven edge into DA5Eh/DA61h. Those remain open. The stock clear-bit branch at F068 instead loops through F074–F096 back to E05Bh.

## Next

1. Validate each candidate incoming reference to F068h using independent instruction-boundary evidence.
2. Trace why/when the F068h protected-mode exit trampoline is invoked.
3. Resume the independent BP.13 write and DA5Eh/DA61h indirect-entry analysis.
