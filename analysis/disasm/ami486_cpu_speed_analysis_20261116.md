# AMI486 CPU speed test — caller and CMOS analysis

Date: 2026-11-16  
ROM: `ami486.bin` (64 KiB)  
Branch: `main`

## Scope

Track the four reported near-call sites targeting `8F12`, the measurement routine `8F50`, and the relation to Setup CMOS option `B6`. This note separates confirmed instruction-level facts from unresolved reachability.

## Confirmed routine behavior

- `8F12` calls `8F50`.
- `8F50` uses PIT channel 2 and generated instruction buffers at `1000:0000` and `1000:0800` to time repeated DIV operations.
- `8F50` returns a value in `AX`.
- `8F12` compares that result against thresholds `0010, 0014, 0019, 0021, 0028, 0032, 0042`, builds a classification in `DI`, writes it to port `80h`, and stores it at `0040:E2`.
- `8F50` ends with near `RET`; it is called near from `8F12`. Its temporary benchmark routines are invoked with far calls.

## Static callers reported by the ROM scan

The scan identified four call sites targeting `8F12`:

| Reported call site | Target | Context / status |
|---|---|---|
| `1C44` | `8F12` | Inside routine beginning at `1C06`; no local `B6.0` check immediately before the call. |
| `1C79` | `8F12` | Gated by CMOS register `8E` bits `C0h`, then by a call to `29ED` and a zero-flag branch. |
| `1F54` | `8F12` | Inside routine `1F47`; calls `29ED` at `1F4D`, skips the speed test when that call returns ZF=1. |
| `23F7` (reported) | `8F12` | Caller context needs byte-offset reconciliation against the current disassembly; do not rely on the reported address until reconciled. |

### Caller 1C44

The local sequence is:

```asm
1C3E  CALL 1836
1C41  CALL 184A
1C44  CALL 8F12
1C47  CALL 25C4
1C4A  MOV [00E6],AX
1C4D  RET
```

The write to `[00E6]` occurs after `CALL 25C4`; it must not be described as a direct save of the speed-test result.

The routine starts at `1C06` with an indirect call through `CS:[82DE]`. The static ROM value at `82DE` resolves to `19AD`, whose byte is `C3` (`RET`). No confirmed static caller of `1C06` has been identified yet. Runtime initialization or a dynamically patched pointer remains possible but unproven.

### Caller 1C79

Confirmed sequence:

```asm
1C64  MOV AL,8E
1C66  CALL EE94
1C69  TEST AL,C0
1C6B  JZ 1C72
1C6F  JMP 1DD3
1C72  CALL 29ED
1C75  JZ 1C85
1C79  CALL 8F12
1C7C  CALL 2537
1C7F  CALL 256A
```

The `29ED` entry reads CMOS register `B6` and tests bit 0:

```asm
29ED  MOV AX,B6B6
29F0  CALL EE94
29F3  TEST AL,01
29F5  RET
```

The byte stream at `29ED` is an overlapping/alternate-entry region; keep this interpretation tied to the call target and observed disassembly rather than treating every linear decode around it as a single instruction stream.

### Caller 1F54

Confirmed sequence:

```asm
1F47  MOV AX,C503
1F4A  CALL 8DDC
1F4D  CALL 29ED
1F50  JZ 1F60
1F54  CALL 8F12
1F57  CALL 2588
1F5A  CALL 25A6
```

This caller also explicitly gates the speed test on the result of the `29ED` CMOS-`B6.0` test.

## Setup option B6

The Setup table at `BCD4` contains this record:

- Label: `AUTO Config Function`
- CMOS register: `B6`
- Mask: `01`
- Default byte shown in record: `84`

The explanatory text says that enabling the function automatically sets the following items:

1. AT Bus Clock
2. DRAM Read/Write Wait State
3. SRAM Read/Write Wait State
4. Cycle Check Point

Important qualification: the Setup record establishes the meaning of `B6.0` as the AUTO Config Function enable. It does **not**, by itself, establish that every CPU speed-test call site is globally controlled by this option. Direct instruction evidence shows that callers `1C79` and `1F54` invoke the `29ED` test before calling `8F12`. The relationship of the other reported caller(s) must be traced independently.

## Corrections to earlier interpretation

- Do not state that all four calls to `8F12` are gated by `B6.0`. This is directly demonstrated for `1C79` and `1F54`, not for `1C44`; the reported `23F7` context remains to be reconciled.
- Do not state that `[00E6]` stores the direct CPU-test result: `CALL 25C4` intervenes.
- Do not state that `1C06` is confirmed to be reached during POST. Its static pointer slot currently resolves to a RET stub, and no static caller has yet been proven.
- A static near-CALL scan establishes code references, not runtime execution.

## Open questions / next analysis

1. Find all writes/initialization paths for `CS:[82DE]` and identify any runtime patching of this function pointer.
2. Find the actual incoming control-flow edge to `1C06` (or establish that it is reached through a dynamically installed callback).
3. Reconcile the reported `23F7` call-site offset with the byte-accurate disassembly and trace its preceding condition, especially the call reported near `29ED/29EE`.
4. Trace consumers of BDA `0040:E2` to identify whether the classification is used for CPU display, timing setup, or both.
5. Keep the AUTO Config option semantics separate from the general purpose of the CPU benchmark until all callers and consumers are proven.

## Source files in this repository

- `analysis/disasm/ami486_cpu_speed_callers_context.txt`
- `analysis/disasm/ami486_hook_entry_8A78_20261116_01.txt`
- `analysis/disasm/ami486_dynamic_hook_1C5E_1DD3_20261116_01.txt`
- `analysis/disasm/ami486_ram_timing_origin_156A_20261116_01.txt`
- `analysis/disasm/ami486_post_after_ram_timing_20261116_01.txt`
- `analysis/disasm/ami486_cmos_cpu_speed_context_20261116_125515.txt`
- `analysis/disasm/ami486_setup_table_BCD4_20261116_01.txt`
- `analysis/disasm/ami486_vector_targets_20261116_01.txt`
