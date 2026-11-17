# ami486.bin — CPU model identification routine at 4142h

Date: 2026-11-17  
ROM: `ami486.bin`, 64 KiB, branch `main`.

## Entry and caller

The routine begins at `4142h` and is called from `3F87h`:

```asm
3F80: BE 1F 43       MOV SI,431Fh
3F83: E8 D7 FF       CALL 3F5Dh
3F86: E8 B8 01       CALL 4142h
3F89: 50             PUSH AX
3F8A: BE AF 43       MOV SI,43AFh
3F8D: E8 CD FF       CALL 3F5Dh
```

The caller is in the BIOS system-information display path. The CPU routine returns a string pointer in SI; the caller continues rendering the CPU information. The routine is therefore a CPU-model identification/reporting helper, not the POST state-byte initializer.

## Detection sequence

```asm
4142: 9C             PUSHF
4143: FA             CLI
4144: B8 00 F0        MOV AX,F000h
4147: 50             PUSH AX
4148: 9D             POPF
4149: 9C             PUSHF
414A: 58             POP AX
414B: 80 E4 F0        AND AH,F0h
414E: BE 9F 44        MOV SI,449Fh       ; default label: 80386SX
4151: 75 03           JNZ 4156h
4153: E9 89 00        JMP 41DFh
4156: 0F 01 E0        SMSW AX
4159: 0A E4           OR AH,AH
415B: 74 48           JZ 41A5h
```

The first test probes whether the upper FLAGS bits can be changed by loading `F000h`. If the tested high bits are zero, the routine takes the early classification path at `41DFh`. Otherwise it executes `SMSW` and branches according to the machine-status word.

## CR0 / 386-vs-486 probe

The path at `415Dh` saves AX and EAX, clears bit 4 in AL, writes the value to CR0, reads CR0 back, tests bit 4, and restores the original CR0:

```asm
415D: 50             PUSH AX
415E: 0F 20 C0        MOV EAX,CR0
4161: 66 50           PUSH EAX
4163: 24 EF           AND AL,0EFh
4165: 0F 22 C0        MOV CR0,EAX
4168: 0F 20 C0        MOV EAX,CR0
416B: A8 10           TEST AL,10h
416D: 66 58           POP EAX
416F: 0F 22 C0        MOV CR0,EAX
4172: 58              POP AX
4173: BE 7F 44        MOV SI,447Fh       ; default 80486SX label
4176: 75 15           JNZ 418Dh
```

This is a deliberate CR0 bit-4 write/readback probe. It is used to select between the 80486SX / 80386DX / Cyrix-family labels below. The routine restores the original CR0 before returning. Do not treat the probe as a general-purpose CPU feature test to copy blindly into a replacement BIOS; CR0 semantics must be handled according to the actual processor family.

## Label selection branches

The routine returns pointers into the embedded CPU-name strings:

- `449Fh` → `80386SX` (default before the FLAGS test).
- `447Fh` → `80486SX` (default after the CR0 probe).
- `448Fh` → `80386DX`.
- `44CFh` / `44DFh` → `Cx486DLC` / `Cx486DLC2`.
- `44AFh` / `44BFh` → `Cx486SLC` / `Cx486SLC2`.
- `444Fh` → `80286`.
- `445Fh` and `446Fh` point to the `80486DX2` and `486DX or 487SX` labels.
- `443Fh` points to the `80486` label.
- `44EFh` is the `Cx486S` label; `44FFh` is `Cx486S2`.

The Cyrix subfamily branches read CMOS index `B3h` through helper `EE94h` and test bits `02h`, `04h`, and `08h`. Those bits participate in model-string selection; their exact board/vendor meaning is not established here.

The routine also invokes `INT 11h` to inspect the equipment word and uses additional CMOS / helper checks before selecting later labels. The full branch tree should be preserved as control flow rather than reducing it to a single “486 detected” test.

## Relationship to CS:[8281]

This routine is a useful CPU-detection lead because it probes FLAGS, SMSW, and CR0, but its visible output is a model-name pointer in SI. Its direct code contains no absolute write to `CS:[8281]`. Its only direct caller found by scanning near CALL instructions is `3F87h`, the system-information display path.

Therefore it does **not** currently explain the producer of `CS:[8281].40h`. Continue looking for a separate initialization or state-copy path; do not infer that this display-oriented CPU probe sets the shared state byte.

## Replacement BIOS relevance

This routine documents legacy CPU-family reporting behavior and a CR0 bit-4 probe. It is reference material for the CPU identification layer, but not yet a safe implementation template for the replacement BIOS. A new BIOS should use explicit CPU feature detection with restoration of every modified control register and should not rely on the original string-selection heuristics.
