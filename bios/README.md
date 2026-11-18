# Project134 — AMI486 BIOS reconstruction

## Mandatory source policy

The reconstructed BIOS is authored only in NASM assembly.

- No machine-code blocks copied from `ami486.bin`.
- No `db` instruction streams copied from the reference ROM.
- `ami486.bin` and disassembly outputs are analysis/behavior references only.
- `db 0xFF` is used solely to reserve unimplemented ROM space.
- Keep the flat ROM image exactly 65,536 bytes and preserve original entry offsets.
- Reconstruct code, control flow, stack-threaded continuations and data tables
  semantically. Never replace uncertain behavior with guessed instructions.

## Current reconstruction status

The clean NASM-only restart is in progress.

Translated into NASM in `bios/src/reset.asm`:
- Reset vector `FFF0h` and gateway `E05Bh`.
- Initial POST branch at `D604h`.
- Primary `8042h`/CMOS reset branch at `88CEh–8A03h`, including the
  stack-threaded ALi C2h/C3h probe and semantic `dw` return slots.
- Reset-mode branch at `8A04h–8A1Fh`.
- CMOS marker read/clear and dispatch at `D615h–D654h`.
- CMOS marker dispatcher instruction stream at `8A20h–8A75h`.
- Dynamic POST hook and stack-threaded ALi continuation at `8A78h–8AD4h`.
- Keyboard-controller reset wait at `8AD5h–8AE6h`.
- CMOS read/write helpers at `EE94h` and `EE9Dh`.
- 8259 PIC initialization at `EEE7h–EF35h`.
- CR0/cache-control branch and indexed dispatch at `D655h–D6A4h`.
- CMOS[8Fh] dispatch table at `D6A8h–D6BDh`, expressed as eleven `dw` targets.
- Stack/register/segment integrity test at `D6BEh–D723h`, including its
  `JMP SP` trampoline and the `D6FCh`/`D709h` continuations.
- CR0 cache-disable and 8042 wait/read helpers at `8CCDh–8D08h`.
- ALi1429 indexed mode helpers and read/write primitives at `8D09h–8E0Bh`.
- POST delay completion and checkpoints `D724h–D774h`.
- Memory checksum and 8042 initialization sequence `D777h–D82Ch`, including
  stack-return words and the `F60Fh`/`F659h` wait helpers.
- 8042 A20 output-port enable/disable routines `F66Ah–F690h`.

The translations above follow the available instruction listing. The following
regions are still incomplete and prevent a meaningful PCem boot test:
- Additional POST/error handlers and the remainder of the startup/boot path.
- Remaining RAM test, chipset initialization, interrupt services, BIOS vectors
  and data.

## Test readiness

**Not ready for a PCem boot test.** The reset path now reaches the POST 09h checkpoint after the initial memory
checksum and first 8042 exchanges. The later 8042 command sequence, CMOS/PIT
checks, chipset setup, and the low-ROM continuation at `1AF8h` remain incomplete. A run now would stop in unimplemented
ROM space or execute incomplete dispatch behavior.

The first PCem test will be announced only after:
1. both initial reset branches and their called helpers are translated;
2. the complete path through the first stable POST checkpoint is present;
3. NASM build and structural validation pass;
4. a static control-flow audit confirms no reachable placeholder holes before
   that checkpoint.

A successful first POST test is not equivalent to a fully bootable BIOS; later
milestones will cover memory sizing, chipset setup, interrupt vectors and boot.

## Build

Use the existing Visual Studio 2026 solution and `bios/tools/build_bios.ps1`.
NASM must be available to the build. The build and PCem have not been run in
this editing session; do not infer success from source edits or Git commits.
