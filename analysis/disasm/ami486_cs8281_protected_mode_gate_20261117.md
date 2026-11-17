# ami486.bin — CS:[8281].40h CPU-mode path selector

Date: 2026-11-17  
ROM: `ami486.bin`, 64 KiB, branch `main`.

## Confirmed flag and consumers

The byte at `CS:8281` is distinct from `CS:8280`. Its bit `40h` is tested by multiple routines, including POST and low-level CPU-mode code. The ROM image starts with `CS:8280=2Fh` and `CS:8281=00h`.

The final-segment consumer at `F069` is decisive because the two outcomes are visible in the instruction stream:

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

The relative target of the `F071` near jump is `8AD5h` (next IP `F074h` plus signed displacement `9A61h`). Thus:

- If `CS:[8281].40h` is **set**, the code jumps to `8AD5h` and skips the sequence at `F074–F099`.
- If the bit is **clear**, it executes the sequence that loads a descriptor table, accesses CR0, clears bit 0 of CR0 (PE), performs a far jump to `F000:F090`, loads another descriptor table, and jumps to `E05Bh`.

This is a mode-transition / return-to-real-mode sequence on the clear-bit path. It is not evidence that setting the flag enables protected mode. The exact meaning of the alternate path at `8AD5h` remains to be established.

## Corroborating consumers

- Around `8CA9`, code uses `0F 01 E0` (SMSW), tests machine-status bits, and accesses CR0 with `0F 20 C0` / `0F 22 C0`.
- Around `D657` and `D724`, the same flag gates code containing SMSW and CR0 operations.
- Around `914F`, the flag gates a path containing `LGDT`, CR0 access, and a 32-bit operand-size prefix.
- Around `8BEC–8CA9`, multiple routines use operand-size-prefixed 32-bit register preservation and CR0-related logic.

The defensible current interpretation is therefore:

**`CS:[8281].6` is a global selector controlling which CPU-mode/control-register path the firmware takes.**

It is not yet safe to call it a CPU-generation capability bit (386 vs 486), a “protected-mode available” flag, or a “currently in protected mode” flag. The branch at `F069` alone does not establish those semantics.

## POST references

The POST checks around `5272` and `5478` consult the same bit and select alternate paths. They are separate from the CMOS-save routine at `1C06`, which tests `CS:[8280]&40h`.

## Setter remains unresolved

A scan of all occurrences of the address bytes `81 82` found the repeated direct TEST pattern, but no obvious direct immediate store to `CS:[8281]`. A setter may use a pointer, copy a larger state/configuration block, or be outside this ROM. The CPU probe and the alternate routine at `8AD5h` are the next tracing targets.

## BIOS replacement implications

A replacement BIOS must preserve the distinction between these two bytes and must not assign a meaning to `CS:[8281].6` based only on its name or the CPU family implied by the ROM filename. Before reproducing this behavior, identify the setter, trace `8AD5h`, and map all consumers. The flag is an internal firmware contract, not a standardized BIOS interface.

No ROM bytes changed.
