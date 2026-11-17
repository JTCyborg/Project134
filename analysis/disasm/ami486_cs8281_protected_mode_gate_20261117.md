# ami486.bin — CS:[8281].40h reset / CPU-mode path selector

Date: 2026-11-17  
ROM: `ami486.bin`, 64 KiB, branch `main`.

## Confirmed flag and decisive consumer

The byte at `CS:8281` is distinct from `CS:8280`. Its bit `40h` is tested by multiple routines, including POST and low-level CPU-mode code. The ROM image starts with `CS:8280=2Fh` and `CS:8281=00h`.

At `F069`, the bit selects between a reset path and a CPU-mode transition path:

```asm
F069: 2E F6 06 81 82 40    TEST BYTE PTR CS:[8281],40h
F06F: 74 03                JZ   F074
F071: E9 61 9A             JMP  8AD5h
F074: 2E 0F 01 16 68 E2    LGDT FWORD PTR CS:[E268]
F07A: B8 40 00             MOV  AX,0040h
F07D: 8E D8                MOV  DS,AX
F07F: 8E C0                MOV  ES,AX
F081: 8E D0                MOV  SS,AX
F083: 0F 20 C0             MOV  EAX,CR0
F086: 24 FE                AND  AL,0FEh
F088: 0F 22 C0             MOV  CR0,EAX
F08B: EA 90 F0 00 F0       JMP  F000:F090
F090: 2E 0F 01 1E B8 E2    LGDT FWORD PTR CS:[E2B8]
F096: E9 C2 EF             JMP  E05Bh
```

The relative target of the `F071` near jump is `8AD5h` (next IP `F074h` plus signed displacement `9A61h`). The destination decodes as:

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

The destination waits for the 8042 input-buffer-full bit (status bit 1) to clear, sends command `FEh` to port `64h` (the 8042 pulse-output-port command used to assert the system reset line), then halts in a loop. This is a hardware reset request, not a protected-mode entry.

Therefore:

- If `CS:[8281].40h` is **set**, execution branches to the 8042 reset sequence at `8AD5h`.
- If the bit is **clear**, execution follows the descriptor-table / CR0 path at `F074–F099`, clears CR0.PE, far-jumps, reloads the descriptor table, and continues at `E05Bh`.

The clear-bit path is consistent with a protected-to-real-mode transition or controlled return to the BIOS entry flow. The set-bit path is conclusively a reset request.

## Other consumers

- Around `8CA9`, code uses `0F 01 E0` (SMSW), tests machine-status bits, and accesses CR0 with `0F 20 C0` / `0F 22 C0`.
- Around `D657` and `D724`, the same flag gates code containing SMSW and CR0 operations.
- Around `914F`, the flag gates a path containing `LGDT`, CR0 access, and a 32-bit operand-size prefix.
- Around `8BEC–8CA9`, multiple routines use operand-size-prefixed 32-bit register preservation and CR0-related logic.

The defensible interpretation is now narrower:

**`CS:[8281].6` is a global reset/mode-transition control flag. At the final reset checkpoint, a set bit requests a hardware reset through the 8042; a clear bit permits the BIOS to execute its CR0.PE-clearing return path.**

This still does not establish what condition causes the bit to be set (CPU incompatibility, a failed mode transition, a chipset state, or another POST condition).

## POST references

The checks around `5272` and `5478` consult the same bit and select alternate paths. They must be traced back to their producers and downstream destinations. They are separate from the CMOS-save routine at `1C06`, which tests `CS:[8280]&40h`.

## Setter remains unresolved

A scan of occurrences of the address bytes `81 82` found the repeated direct TEST pattern but no obvious direct immediate store to `CS:[8281]`. A setter may use a pointer, copy a larger state/configuration block, or be outside this ROM.

Next targets:

1. Trace the POST paths around `5272` and `5478` into their callees and determine what condition leads to the reset request.
2. Find the code that sets or copies the `CS:8280–8281` state bytes.
3. Correlate the flag with CPU detection and mode-transition failure handling.

## BIOS replacement implications

A replacement BIOS must not blindly set this bit: doing so reaches a hardware reset loop. Preserve the reset semantics only after identifying the setter and the reason for the reset. The flag is an internal firmware contract, not a standardized BIOS interface.

No ROM bytes changed.
