# ami486.bin — POST reset checkpoints controlled by CS:[8281].40h

Date: 2026-11-17  
ROM: `ami486.bin`, 64 KiB, branch `main`.

## Two POST checkpoints reach overlapping entries in the same reset routine

### Checkpoint after POST code 53h

Exact byte alignment:

```asm
5270: E6 80                   OUT 80h,AL
5272: 2E F6 06 81 82 40       TEST BYTE PTR CS:[8281],40h
5278: 74 03                   JZ 527Dh
527A: E9 59 38                JMP 8AD6h
```

The near jump's next IP is `527Dh`; adding `3859h` gives `8AD6h`. If the bit is clear, POST continues at `527Dh`. If set, execution enters the reset routine at its second `CLI`.

### Second POST checkpoint

```asm
5470: B8 8F 06                MOV AX,068Fh
5473: E8 25 9A                CALL EE9Bh
5476: 2E F6 06 81 82 40       TEST BYTE PTR CS:[8281],40h
547C: 74 03                   JZ 5481h
547E: E9 53 36                JMP 8AD4h
```

The near jump's next IP is `5481h`; adding `3653h` gives `8AD4h`. This enters two bytes before the pair of CLI instructions, at an overlapping instruction stream.

### Final ROM transition checkpoint

At `F069h`, the same bit is tested. If set, the near jump targets `8AD5h`, the start of the two-CLI reset entry. If clear, the BIOS takes the descriptor-table / CR0.PE-clearing path.

## Reset routine and overlapping entries

The byte stream at `8AD4h` is:

```asm
8AD4: 6B FA FA       IMUL DI,DX,-6       ; overlapping entry only
8AD7: 33 C9          XOR CX,CX
8AD9: E3 00          JCXZ 8ADBh
8ADB: E4 64          IN AL,64h
8ADD: A8 02          TEST AL,02h
8ADF: E0 F8          LOOPNZ 8AD9h
8AE1: B0 FE          MOV AL,FEh
8AE3: E6 64          OUT 64h,AL
8AE5: F4             HLT
8AE6: EB FD          JMP 8AE5h
```

The normal entry at `8AD5h` begins with `CLI; CLI`, then reaches `XOR CX,CX` at `8AD7h`. The first POST checkpoint enters at `8AD6h`, skipping the first CLI; the second enters at `8AD4h`, executing an overlapping `IMUL` before both CLI instructions; the final transition checkpoint enters at `8AD5h`.

The reset body waits for the 8042 input-buffer-full bit (status bit 1) to clear, sends command `FEh` to port `64h`, then halts in a loop. This is the 8042 keyboard-controller reset pulse path.

## What this proves

- `CS:[8281].40h` is a reset-request condition at two POST checkpoints and at the final CPU-mode transition point.
- The POST branches use unusual overlapping entry points into the same reset body; preserve exact target offsets when reconstructing the original control flow.
- The flag is not the CMOS-save gate. CMOS-save at `1C06h` tests `CS:[8280]&40h`.

## Setter search status

A full scan of the ROM for direct references to operand address `8281h` found the known TEST instructions but no direct immediate store forms such as `MOV CS:[8281],imm8`, `OR CS:[8281],imm8`, `AND CS:[8281],imm8`, or direct `MOV CS:[8281],AL`. A scan of the corresponding `8280h` references likewise found tests, not a direct setter.

This does **not** prove the flag cannot be changed. Remaining possibilities include an indirect write through a pointer, a block copy covering the flag byte, or a runtime mapping/initialization mechanism.

## Next investigation

1. Trace the POST paths leading to checkpoints 53h and the second test, identifying the preceding validation routines.
2. Search for pointer-based writes/copies into the data window containing `CS:8280–8281`.
3. Determine whether a failed memory/chipset/CPU-mode validation sets the reset request, or whether the byte is supplied by an external initialization mechanism.

No ROM bytes changed.
