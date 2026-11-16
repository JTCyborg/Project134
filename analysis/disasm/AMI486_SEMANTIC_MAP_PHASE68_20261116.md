# AMI486 semantic map — phase 68 (2026-11-16)

## Scope

Trace the `527Dh -> 8AD9h` branch and audit static references to the configuration byte at `CS:8281h`. Source image: `ami486.bin`, 65,536 bytes, repository blob SHA `480c7520c93e6c7ed437cf3ad214da7503f82ec6`.

## 1. 8AD9h is the keyboard-controller reset path

The relevant block is:

```asm
8AD5  CLI
8AD6  CLI
8AD7  XOR CX,CX
8AD9  JCXZ 8ADBh
8ADB  IN AL,64h
8ADD  TEST AL,02h
8ADF  LOOPNE 8AD9h
8AE1  MOV AL,FEh
8AE3  OUT 64h,AL
8AE5  HLT
8AE6  JMP 8AE5h
```

Because CX is explicitly zeroed at 8AD7h, JCXZ skips directly to the status read at 8ADBh. The LOOPNE instruction then decrements CX and repeats the status check while the tested bit condition permits; operationally, the routine waits on the 8042 input-buffer status bit before writing FEh to port 64h. It then halts in a permanent loop. This is a reset/shutdown terminal path, not a BIOS service callback.

The earlier caller at 527Dh reaches this path when the tested configuration bit is set. It is not a route to DA5Eh/DA61h.

## 2. Static consumers of CS:8281h

The disassembly contains these direct references:

- `D657: TEST byte [CS:8281h],40h`; if set, branch to D690h.
- `D724: TEST byte [CS:8281h],40h`; if set, skip the following CR0/MSW modification and continue at D73Bh.
- `8B11: TEST byte [CS:8281h],40h`; if set, skip the CMOS register 2Dh read at 8B19h–8B28h and return at 8B2Ch.
- `F06A: TEST byte [8281h],40h`; if set, jump to the reset path at 8AD5h.
- `F43D: TEST byte [CS:8281h],80h`; selects one of two display strings at F371h/F38Eh. This is a separate bit (bit 7).

The repeated bit-6 tests show that bit 6 is a shared POST/configuration switch affecting protected-mode-related setup and the terminal reset branch. The bit-7 test is only used by the displayed-text selection in the inspected path.

## 3. Writer audit result and limitation

A targeted scan of the checked-in ROM's direct absolute-memory encodings and a search of the available reset/POST/branch disassemblies found reads of `8281h`, but no instruction-boundary-confirmed direct store to `CS:8281h` or physical `0000:8281h`.

This does **not** prove the byte is immutable. It may be populated by an external firmware stage, runtime patch, an indirect store, block copy, or another address alias. No such producer is established in this pass. The correct conclusion is therefore: the ROM consumes bit 6 and bit 7, but the source of those bits remains unresolved.

## 4. BP.13 / DAxx status

- The 8AD5h–8AE6h terminal reset routine does not write BP.
- The 8281h bit-6 branches do not write BP.13.
- The path 527Dh -> 8AD9h cannot explain a normal entry into DA5Eh/DA61h.
- BP.13 provenance and the dynamic entry into DA5Eh/DA61h remain open.

## Next target

Trace the producers of the POST configuration byte around the F000:8280h area, including possible writes through the BIOS data-segment setup and the runtime/CMOS initialization paths. Separately inspect the 8B11h CMOS 2Dh read and determine what hardware/configuration feature bit 6 gates.
