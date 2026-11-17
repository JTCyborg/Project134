# ami486.bin — POST reset checkpoints controlled by CS:[8281].40h

Date: 2026-11-17  
ROM: `ami486.bin`, 64 KiB, branch `main`.

## Checkpoint after POST code 53h

```asm
5270: E6 80                   OUT 80h,AL
5272: 2E F6 06 81 82 40       TEST BYTE PTR CS:[8281],40h
5278: 74 03                   JZ 527Dh
527A: E9 59 38                JMP 8AD6h
527D: E9 E8 9D                JMP F068h
```

The set-bit path enters the 8042 reset routine at its second `CLI` (`8AD6h`). The clear-bit path jumps to `F068h`, executes `CLI`, and reaches the final mode/reset decision at `F069h`.

## Second checkpoint: CMOS marker write, then reset test

The exact instruction boundaries are:

```asm
5472: B8 8F 06                MOV AX,068Fh
5475: E8 25 9A                CALL EE9Dh
5478: 2E F6 06 81 82 40       TEST BYTE PTR CS:[8281],40h
547E: 74 03                   JZ 5483h
5480: E9 53 36                JMP 8AD6h
5483: E9 E2 9B                JMP F068h
```

The call at `5475h` targets `EE9Dh`. The helper is a CMOS write primitive:

```asm
EE9D: E6 70       OUT 70h,AL       ; CMOS index
EE9F: 86 C4       XCHG AH,AL       ; CMOS data into AL
EEA5: E6 71       OUT 71h,AL       ; write data
EEA7: 86 C4       XCHG AH,AL
EEA9: C3          RET
```

The two delay pairs are at `EEA1–EEA4`. With `AX=068Fh`, this writes `CMOS[8Fh]=06h`. The next instruction tests `CS:[8281]&40h`.

If the flag is set, the jump reaches `8AD6h`, the second `CLI` in the 8042 reset routine. If clear, execution jumps to `F068h`, executing the `CLI` before the final flag test.

This is a significant ordering clue: the BIOS writes the extended CMOS marker `8Fh=06h` immediately before the second reset-request test. It does **not** prove that the CMOS write sets the flag; the helper writes CMOS through ports `70h/71h` and does not write `CS:[8281]`.

## Final mode/reset checkpoint

```asm
F068: FA                      CLI
F069: 2E F6 06 81 82 40       TEST BYTE PTR CS:[8281],40h
F06F: 74 03                   JZ F074h
F071: E9 61 9A                JMP 8AD5h
```

Set bit: jump to `8AD5h` (the first `CLI` in the reset routine).  
Clear bit: continue at `F074h`, which loads a descriptor table, clears CR0.PE, far-jumps, reloads a descriptor table, and continues at `E05Bh`.

## Reset routine

```asm
8AD5: FA          CLI
8AD6: FA          CLI
8AD7: 33 C9       XOR CX,CX
8AD9: E3 00       JCXZ 8ADBh
8ADB: E4 64       IN AL,64h
8ADD: A8 02       TEST AL,02h
8ADF: E0 F8       LOOPNZ 8AD9h
8AE1: B0 FE       MOV AL,FEh
8AE3: E6 64       OUT 64h,AL
8AE5: F4          HLT
8AE6: EB FD       JMP 8AE5h
```

The routine waits for the 8042 input-buffer-full bit (status bit 1) to clear, sends command `FEh` to port `64h`, then halts in a loop while awaiting hardware reset.

## What is established

- `CS:[8281].40h` is a reset-request condition checked at multiple POST points and at the final CPU-mode transition point.
- Both early POST set-bit branches enter the reset body at `8AD6h`; the final transition enters at `8AD5h`.
- Both early clear-bit branches converge at `F068h`, before the final flag test.
- The second check is preceded by a write of `CMOS[8Fh]=06h`.
- The CMOS-save routine at `1C06h` is separate: it tests `CS:[8280]&40h`.

## Setter search status

A scan of direct references to `8281h` found the known TEST instructions but no obvious direct immediate store forms (`MOV/OR/AND CS:[8281],imm8`, direct `MOV CS:[8281],AL`). This does not rule out pointer-based writes, block copies, or initialization outside this ROM.

## Next investigation

1. Trace the code that writes `CMOS[8Fh]=06h` and determine whether the value is a reset/POST progress marker or a persistent mode marker.
2. Trace the preceding POST validation routines and the earlier checkpoint after code `53h`.
3. Search for indirect writes/copies into the `CS:8280–8281` state window and identify the producer of bit `40h`.

No ROM bytes changed.
