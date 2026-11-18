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
- Reset-mode branch at `8A04h–8A1Fh`.
- CMOS marker read/clear and dispatch at `D615h–D654h`.
- CMOS marker dispatcher instruction stream at `8A20h–8A75h`.
- Keyboard-controller reset wait at `8AD5h–8AE6h`.
- CMOS read/write helpers at `EE94h` and `EE9Dh`.
- 8259 PIC initialization at `EEE7h–EF35h`.
- CR0/cache-control branch and indexed dispatch at `D655h–D6A4h`.
- POST delay completion and checkpoints `D724h–D774h`.

The translations above follow the available instruction listing. The following
regions are still incomplete and prevent a meaningful PCem boot test:
- `88CEh–8A03h`: primary 8042-clear branch, including stack-threaded
  continuations and helper dependencies.
- `8A78h–8AD4h`: secondary CMOS/POST routines reached after checkpoint 05h.
- `D6A8h–D6C0h`: CMOS-indexed near-jump table; entries need semantic resolution.
- `D6DEh–D723h`: overlapping destructive memory/register test streams.
- Shared routines at `8CCDh` and `8DDCh`, plus additional POST/error handlers.
- Remaining RAM test, chipset initialization, interrupt services, BIOS vectors
  and data.

## Test readiness

**Not ready for a PCem boot test.** The primary branch at `88CEh`, the
stack-threaded helper routines, the indexed dispatch table and the memory-test
continuation are incomplete. A run now would stop in unimplemented ROM space
or execute incomplete dispatch behavior.

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
NASM must be available to the build. Do not infer a successful build from source
edits or Git commits; record actual build output separately.
