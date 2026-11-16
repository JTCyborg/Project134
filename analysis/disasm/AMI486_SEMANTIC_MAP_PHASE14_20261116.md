# AMI486 semantic map — phase 14 (2026-11-16)

## Scope

Follow-up of the post-load chain from phase 13. This phase decodes `0A35`, `1A8F`, `1A90`, and `E7E8`, and checks the exact CMOS helpers called by `0A35`.

## Critical correction: E7E8 is not a configuration-image validator

Phase 13 described `E7E8` as validating/updating the setup-image state. That was too broad and is corrected here.

The call at `8521` occurs after the `E000–E07F` working image has been copied to `E080–E0FF`. The target `E7E8` does **not** inspect that image. It runs a keyboard-controller transaction:

1. `E7E8` disables interrupts and calls `E819`.
2. `E819` sends command byte `CAh` to the 8042 command/status port `64h` through helper `F635`.
3. It waits for output-buffer data using `F602`; if available, reads port `60h` and returns the byte with CF clear. If not, it returns CF set.
4. `E7E8` accepts only response `04h` (`AL XOR 04h == 0`). On success it returns AX=0 with CF clear.
5. On failure it writes `EFh` to port `64h`, reads port `64h` back, tests status bit 1, restores interrupts and returns that status in AL.

Thus `E1AA.0` is a state bit set/cleared according to this keyboard-controller test result, not a checksum or Setup-image validity bit. The exact hardware meaning of the 8042 command `CAh` and response `04h` is not established by the ROM alone.

## 0A35: CMOS/RTC and memory inventory, not ALi1429 register programming

`0A35` begins with `CLI` and uses the BIOS CMOS helpers at `FFFF:EEB9` and `FFFF:EEAA`. These helpers access CMOS through ports `70h/71h`:

- `EE94`: write index to port `70h`, read data from port `71h`.
- `EE9D`: write index to port `70h`, then write data to port `71h`.
- `EEAA`: protected CMOS read wrapper; preserves flags, disables interrupts, performs a read, and restores the selected NMI/index state.
- `EEB9`: protected CMOS write wrapper with the same NMI/index handling.

Operations performed by `0A35`:

| Code | Operation |
|---|---|
| `A36–A3A` | Write CMOS register `8Ah = 26h` |
| `A3C–A40` | Read CMOS register `8Bh` |
| `A42–A49` | Set bit 1 in the returned value, preserve bit 0, and write it back to CMOS `8Bh` |
| `A4B–A4E` | Read CMOS register `8Dh` |
| `A50–A53` | Read CMOS register `8Ch` |
| `A56–A5D` | Call BIOS INT 1Ah services AH=05h and AH=03h, with helper routines `6774` and `67AE` around them |
| `A64–A7B` | Store conventional memory size from BDA `0040:0013` at `E015`; call INT 15h AH=88h and store returned extended-memory size at `E017` |
| `A7E` | Duplicate the extended-memory size at `E030` |
| `A81–AA9` | Read equipment word at BDA `0040:0042`; normalize display-adapter bits and update `E014` |

The `8Ah–8Dh` CMOS accesses are separate from the ALi1429 indexed register interface at ports `22h/23h`. This routine inventories CMOS/RTC and memory/equipment state into the RAM setup image; it does not perform the chipset register writeback sought in the previous phase.

The precise semantics of the RTC services and helper routines `6774/67AE` require a separate decode; do not infer them solely from INT 1Ah AH values without checking this BIOS's interrupt convention.

## 1A8F and 1A90: pre-save normalization

- `1A8F` is a single-byte `RET`. Its call from `850E` has no effect in this ROM image.
- `1A90` is called by the save path `852F` before checksums and CMOS serialization. It reads ALi1429 indexed registers `12h` and `13h` using `8DCF`, then adjusts the RAM image:
  - If register `12h` bit 2 is set and register `13h` low nibble is zero, subtract `0100h` from word `E017`; otherwise subtract `0080h`.
  - If `E042.2` is set, it checks for the `55AAh` ROM signature at `C000:0000`. If absent, it clears `E035.2`.
  - Depending on `E035.2` and `E034 & 2Ah`, it adds `0100h` or `0080h` back to `E017`.
- This is a pre-save normalization of the extended-memory value and a video-option consistency check. It reads ALi1429 state but does not write ALi1429 registers.

## What the traced chain actually does

The load sequence around `84CB` is now:

1. Load stored CMOS settings into `E010...`, or copy ROM defaults when CMOS status requires defaults.
2. Call `0A35` to refresh CMOS/RTC, memory-size and equipment-derived fields in the working image.
3. Call `1A8F` (no-op in this ROM).
4. Copy `E000–E07F` to `E080–E0FF`.
5. Call `E7E8` to test the keyboard controller; set `E1AA.0` only when the test succeeds.

The save sequence around `852F` is different:

1. Call `1A90` to normalize staged memory/video settings.
2. Compute checksums and write the staged bytes to CMOS via `854F`.
3. Restart through `E05B` if the saved-state flags request it.

Neither `0A35` nor `1A90` is the missing bulk chipset-apply routine. The known ALi1429 direct RMW sequence remains the separate block `1C5E–1DD0` documented in phase 9.

## ALi1429 apply-path status

Confirmed direct indexed writes still include the register RMW operations in `1C5E–1DD0`, using `8DCF/8DDC` and ports `22h/23h`. The routines examined in this phase do not add another write path.

The next useful trace target is the caller/control-flow path that reaches `1C5E`, plus the runtime code that consumes the CMOS bytes after the reboot. The Setup editor itself stages values; the save routine writes CMOS; hardware programming may occur in a later POST initialization path rather than immediately on leaving Setup.
