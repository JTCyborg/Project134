# BIOS workspace

The BIOS is developed independently for Project134. The original AMI486 ROM is an immutable behavioral reference; it is not modified by the build.

## Visual Studio build

Open `Project134.sln` in Microsoft Visual Studio 2026 and build `Project134.BIOS`.

Visual Studio/MSBuild orchestrates NASM to emit a flat 16-bit x86 ROM image. MSVC does not compile or link the BIOS code.

Prerequisite: NASM available as `nasm.exe` on `PATH`. If installed elsewhere, pass `/p:NasmExe="C:\\path\\to\\nasm.exe"` to MSBuild.

Build output:
- `out\\Debug\\Project134.bin`
- `out\\Release\\Project134.bin`

## Reconstruction status — Stage 0

The source now uses the reset-vector and first-stage entry addresses observed in the target ROM:

- ROM size: 65,536 bytes.
- Reset vector at ROM offset `FFF0h`: far jump to `F000:E05B`.
- Reset gateway at ROM offset `E05Bh`: near jump to `F000:D604`.
- Early POST entry at ROM offset `D604h`: reconstructed instruction stream through the dispatch at `D6A2h`, including the 8042 status probe, CMOS/NMI accesses, stack setup and indirect dispatch.

The reset-vector and entry bytes are checked by `validate_rom.ps1`.

**This is not yet a functional or PCem-bootable BIOS.** The early POST code branches to additional routines at `88CEh`, `8A04h`, `D6DEh`, `D724h`, `EEE7h`, `8A20h` and other destinations that have not yet been reconstructed into source. The remaining ROM is currently filled with `FFh`. Do not select this image as the AMI486 machine BIOS yet.

## Next implementation boundary

Continue reconstructing the reset/POST call graph from the exact disassembly, starting with all direct destinations reached from `D604h`. Preserve alternate entries, stack-crafted returns, register/flag contracts and POST port-80h writes. Only mark a routine complete when its bytes, incoming references and outgoing control flow are reconciled.

## Reference ROM

The original `ami486.bin` remains unchanged. Keep it separate from generated output and do not overwrite it. Any binary compatibility payload must be explicitly identified as inherited rather than native reconstruction.

## Validation

The post-build PowerShell validator checks:
- exact output size (currently 65,536 bytes);
- immutable reference ROM identity (SHA-256 `91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b`);
- the complete implemented early POST byte window `D604h–D6A6h` against the reference ROM, not only its first instructions;
- the reference reset-vector bytes at `FFF0h`;
- the reset gateway at `E05Bh`;
- the first verified POST instructions at `D604h`.

A successful assembly/layout check is not evidence of a successful BIOS boot. PCem differential testing remains required.
