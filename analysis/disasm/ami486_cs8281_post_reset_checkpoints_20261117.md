# ami486.bin — POST reset checkpoints controlled by CS:[8281].40h

Date: 2026-11-17  
ROM: `ami486.bin`, 64 KiB, branch `main`.

## Two POST checkpoints reach the same 8042 reset routine

The flag test is not confined to the final ROM transition area. Two earlier POST paths branch to the same reset routine:

### Checkpoint after POST code 53h

```asm
5270: E6 80             OUT 80h,AL          ; AL was 53h
5272: 2E F6 06 81 82 40 TEST BYTE PTR CS:[8281],40h
5279: 74 03             JZ 527Eh
527B: E9 59 38          JMP 8AD7h
```

Correction on byte alignment: the exact sequence begins at `5272h`; `JZ` lands at `527Eh`, and the near jump begins at `527Bh`. Its next IP is `527Eh`; adding signed displacement `3859h` yields `8AD7h`. The destination is inside the reset routine, after its initial CLI instructions and at the `XOR CX,CX` / 8042 status-poll sequence.

### Second POST checkpoint

```asm
5478: 2E F6 06 81 82 40 TEST BYTE PTR CS:[8281],40h
547F: 74 03             JZ 5484h
5481: E9 53 36          JMP 8AD7h
```

The second jump also reaches `8AD7h` (next IP `5484h` plus `3653h`). This is the same reset routine entry point.

### Final ROM transition checkpoint

At `F069h`, the same bit is tested. If set, the near jump targets `8AD5h`, the beginning of the reset routine (including its CLI instructions). If clear, the BIOS takes the descriptor-table / CR0.PE-clearing path described in the companion note.

## Reset routine

The routine around `8AD5h` is:

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

This waits for the 8042 input buffer to become free, sends command `FEh` to port `64h`, then halts forever while awaiting reset. Note that the early POST jumps enter at `8AD7h`, skipping the two CLI instructions; the final transition jump enters at `8AD5h`.

## What this proves

- `CS:[8281].40h` is a reset-request condition at two POST checkpoints and at the final CPU-mode transition point.
- The flag is not the CMOS-save gate. CMOS-save at `1C06h` tests `CS:[8280]&40h`.
- A set bit leads to the 8042 reset loop; a clear bit continues through the normal POST / mode-transition path at these sites.

## Setter search status

A full scan of the ROM for direct references to the operand address `8281h` found the known TEST instructions but no direct immediate store forms such as `MOV CS:[8281],imm8`, `OR CS:[8281],imm8`, `AND CS:[8281],imm8`, or direct `MOV CS:[8281],AL`. The same pass found the `8280h` references documented separately; those are also tests, not a direct setter.

This does **not** prove the flag cannot be changed. Remaining possibilities include an indirect write through a pointer, a block copy that covers the flag byte, or a runtime mapping/initialization mechanism.

## Next investigation

1. Trace the two POST paths leading to checkpoints 53h and the second test, identifying the preceding validation routine(s).
2. Search for pointer-based writes/copies into the ROM data window containing `CS:8280–8281`.
3. Determine whether a failed memory/chipset/CPU-mode validation sets the reset request, or whether this byte is supplied by an external initialization mechanism.

No ROM bytes changed.
