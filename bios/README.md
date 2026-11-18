# BIOS workspace

Project134 reconstructs the AMI486 BIOS as original NASM source. The immutable
`ami486.bin` and the disassembly archive are analysis references only.

## Source policy

- All executable BIOS code must be written as NASM instructions and labels.
- Do not insert machine-code byte sequences copied from the reference ROM.
- Do not use `db` to reproduce executable instructions from the original ROM.
- `db 0xFF` is permitted only for unimplemented/erased ROM space and alignment.
- Reference disassembly is used to recover control flow, operands, call targets,
  register effects and data boundaries.
- The original ROM may be used for behavioral comparison and validation, never
  as a source of bytes for the reconstructed image.

## Visual Studio build

Open `Project134.sln` in Microsoft Visual Studio 2026 and build
`Project134.BIOS`. MSBuild invokes NASM to produce a flat 16-bit, 64-KiB ROM.

Expected output:
- `out\\Debug\\Project134.bin`
- `out\\Release\\Project134.bin`

Prerequisite: `nasm.exe` on `PATH`.

## Reconstruction restart — NASM-only baseline

The previous byte-block implementation has been replaced by a clean source
baseline in `bios/src/reset.asm`.

Implemented in assembly:
- Reset vector at ROM offset `FFF0h`: far jump to `F000:E05B`.
- Reset gateway at `E05Bh`: near jump to `F000:D604`.
- Initial POST instructions at `D604h`: `CLI`, `CLD`, 8042 status read,
  bit-2 test and dispatch.
- Address labels for the next POST entries.

Not yet implemented:
- 8042-clear branch at `88CEh`.
- CMOS/reset continuation at `8A04h`.
- POST/RAM-test continuation from `D6DEh).
- Remaining BIOS services, data tables, vectors and option-ROM support.

All unimplemented areas are filled with `FFh`; this baseline is not bootable.
No NASM build, ROM validation or PCem run has been claimed for this restart.
The next work item is to translate the reset/POST disassembly into NASM,
starting at `D604h`, preserving the documented ROM offsets and control flow.
