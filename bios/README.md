# Project134 — AMI486 BIOS reconstruction

## Mandatory source policy

The reconstructed BIOS is authored only in NASM assembly.

- No machine-code blocks copied from `ami486.bin`.
- No `db` instruction streams copied from the reference ROM.
- `ami486.bin` and disassembly outputs are analysis/behavior references only.
- `db 0xFF` is used solely to reserve unimplemented/erased ROM space.
- Keep the flat ROM image exactly 65,536 bytes and preserve original entry offsets.
- Translate control flow, stack-threaded continuations, data tables and helper
  routines explicitly; do not replace unknown routines with guessed behavior.

## Current reconstruction status

The clean NASM-only restart is in progress.

Implemented as assembly in `bios/src/reset.asm`:
- Reset vector at ROM offset `FFF0h`: far jump to `F000:E05B`.
- Reset gateway at `E05Bh`: near jump to `F000:D604`.
- Initial POST dispatch at `D604h` with the original 8042 status-bit branch.
- Reset/CMOS marker path at `8A04h` through `8A1Fh`.
- CMOS marker read and initial dispatch at `D615h` through `D64Fh`.
- PIC helper handoff at `D646h`–`D654h`.

Still missing critical executable regions:
- `88CEh` 8042-clear branch and its shared helper dependencies.
- `8A20h` CMOS dispatch helper and its dependencies.
- `D6DEh` stack/register test, delay loop and subsequent POST.
- RAM test, chipset initialization, interrupt services, BIOS vectors and data.
- Remaining POST continuation after `D724h`.

## Test readiness

**Not ready for a PCem boot test yet.** The current image is an incomplete
reconstruction and reaches erased `FFh` regions on either primary reset path.
A PCem run now would only confirm the known missing-code stop, not validate BIOS
functionality.

The first meaningful PCem test checkpoint will be announced only after:
1. both initial POST branches (`88CEh` and `8A04h`) are implemented;
2. the full path through `D724h` and its called helpers is present;
3. NASM build and structural validation pass;
4. a static control-flow audit confirms no reachable placeholder holes before
   the first stable POST checkpoint.

After that checkpoint, PCem can be used to compare POST80 progress and CPU state
against the reference BIOS. A later milestone will be required for boot testing.

## Build

Use the existing Visual Studio 2026 solution and the `bios/tools/build_bios.ps1`
script. NASM must be available to the build. Do not infer a successful build
from source edits or Git commits; record the actual build output separately.
