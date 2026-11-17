# ami486.bin — CS:[8281].40h CPU-mode gate

Date: 2026-11-17  
ROM: `ami486.bin`, 64 KiB, branch `main`.

## Strongest semantic evidence

The repeated `TEST BYTE PTR CS:[8281],40h` checks are not merely generic POST options. The final-segment consumer at `F069` directly selects whether the BIOS enters a protected-mode setup path:

```asm
F069: TEST BYTE PTR CS:[8281],40h
F070: JZ   F075
F072: JMP  8AD6h       ; real-mode/fallback path (relative target)
F075: LGDT [E268]
F07B: MOV  AX,0040h
F07E: MOV  DS,AX
F080: MOV  ES,AX
F082: MOV  SS,AX
F084: MOV  EAX,CR0
F087: AND  EAX,0FFFFFFFEh
F08D: MOV  CR0,EAX
F090: JMP  F000:F090h
```

The byte stream at the transition area must be decoded with its actual instruction origin; the listing above is a semantic outline, not a claim that every displayed offset has been independently reassembled. The decisive facts are the test at `F069`, the conditional branch around the near jump, and the fall-through sequence containing `LGDT`, `MOV EAX,CR0`, and `MOV CR0,EAX`.

Correction to target calculation: the near jump immediately after the conditional branch transfers to the low-ROM routine around `8AD3h`; the protected-mode setup is the fall-through path when bit `40h` is set.

## Other consumers corroborate the interpretation

- Around `8CA9`, the routine uses `0F 01 E0` (SMSW), tests the low machine-status bits, and accesses CR0 with `0F 20 C0` / `0F 22 C0`. This is explicitly machine-status/control-register logic.
- Around `D657` and `D724`, the same flag gates code containing SMSW and CR0 operations.
- Around `914F`, the flag gates a path using `LGDT`, CR0 access, and a 32-bit operand-size prefix. This is consistent with a protected-mode or CPU-mode transition/helper.
- Around `8BEC–8CA9`, several routines use operand-size-prefixed 32-bit register preservation and CR0-related code.

Taken together, the best-supported working interpretation is:

**`CS:[8281].6` is a global gate for the BIOS's 386-class 32-bit / protected-mode-capable execution path.**

This is stronger than the previous neutral label “unknown mode flag”, but it is not proof that the bit specifically identifies an Intel 486. The code demonstrates 386+ mechanisms (32-bit operand-size prefixes, CR0, LGDT); distinguishing 386, 486, and compatible CPUs requires tracing the detection routine that sets the bit.

## POST references

The POST tests at `5272` and `5478` consult the same flag before selecting alternate branches. Their branches should be traced against the low-level routines above; do not treat these tests as the CMOS-save gate.

## Setter remains unresolved

The 64 KiB ROM scan found the repeated direct read pattern but no obvious direct immediate store to `CS:[8281]`. A setter may use a pointer, copy a larger configuration/CPU-state block, or be outside this ROM. Continue by tracing the CPU identification / feature-probe path and writes to the containing `CS:8280` structure.

## BIOS replacement implications

A replacement BIOS must not blindly set this bit. It should set the capability only after a real CPU probe establishes that the required instructions and CR0 behavior are available. If the replacement targets only real mode, it can deliberately avoid the protected-mode branch, but must also ensure every other consumer of the flag receives a consistent value. The flag is part of the legacy firmware's internal contract, not a standardized BIOS interface.

No ROM bytes changed.
