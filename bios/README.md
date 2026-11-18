# BIOS workspace

The BIOS is developed independently for Project134. The original AMI486 ROM is an immutable behavioral reference; it is not modified by the build.

## Visual Studio build

Open `Project134.sln` in Microsoft Visual Studio 2026 and build `Project134.BIOS`.

Visual Studio/MSBuild orchestrates NASM to emit a flat 16-bit x86 ROM image. MSVC does not compile or link the BIOS code.

Prerequisite: NASM available as `nasm.exe` on `PATH`. If installed elsewhere, pass `/p:NasmExe="C:\\path\\to\\nasm.exe"` to MSBuild.

Build output:
- `out\\Debug\\Project134.bin`
- `out\\Release\\Project134.bin`

## Reconstruction status — Stage 3

The source now uses the reset-vector and first-stage entry addresses observed in the target ROM:

- ROM size: 65,536 bytes.
- Reset vector at ROM offset `FFF0h`: far jump to `F000:E05B`.
- Reset gateway at ROM offset `E05Bh`: near jump to `F000:D604`.
- Initial 8042-clear POST branch at `88CEh–8A03h` (310 bytes copied verbatim from the immutable reference ROM), plus reset-continuation entries at `8A04h` and `8A20h`, POST continuation/helper cluster at `8A75h–8CCCh`, indirect dispatch pointer/trampoline at `82DAh` and `19ABh–19AFh`, ALi indexed-I/O helper cluster at `8CCDh–8DECh`, and CMOS/PIC helpers at `EE94h–EF35h`.
- Early POST entry at ROM offset `D604h` and continuation through `D776h`: byte-backed dispatcher, stack-threaded RAM test, CMOS/8042 checks, and the first POST `80h` status writes.

The reset-vector and reconstructed code windows are checked byte-for-byte against the immutable reference by `validate_rom.ps1`.

**PCem status: early POST is now executing, but boot is not yet demonstrated.** The latest run with the reconstructed ROM produces POST port-80h values `01h` and `02h`. It then pauses at `F000:D71E` after 7,869,468 instructions. This is an intentional delay loop in the reference stream: `D716` loads the byte at `CS:8284h` (observed as `87h` in the CPU dump), `D71E` executes `LOOP # BIOS workspace

The BIOS is developed independently for Project134. The original AMI486 ROM is an immutable behavioral reference; it is not modified by the build.

## Visual Studio build

Open `Project134.sln` in Microsoft Visual Studio 2026 and build `Project134.BIOS`.

Visual Studio/MSBuild orchestrates NASM to emit a flat 16-bit x86 ROM image. MSVC does not compile or link the BIOS code.

Prerequisite: NASM available as `nasm.exe` on `PATH`. If installed elsewhere, pass `/p:NasmExe="C:\\path\\to\\nasm.exe"` to MSBuild.

Build output:
- `out\\Debug\\Project134.bin`
- `out\\Release\\Project134.bin`

## Reconstruction status — Stage 2

The source now uses the reset-vector and first-stage entry addresses observed in the target ROM:

- ROM size: 65,536 bytes.
- Reset vector at ROM offset `FFF0h`: far jump to `F000:E05B`.
- Reset gateway at ROM offset `E05Bh`: near jump to `F000:D604`.
- Initial 8042-clear POST branch at `88CEh–8A03h` (310 bytes copied verbatim from the immutable reference ROM), plus reset-continuation entries at `8A04h` and `8A20h`, ALi indexed-I/O helper cluster at `8CCDh–8DECh`, and CMOS/PIC helpers at `EE94h–EF35h`.
- Early POST entry at ROM offset `D604h` and continuation through `D776h`: byte-backed dispatcher, stack-threaded RAM test, CMOS/8042 checks, and the first POST `80h` status writes.

The reset-vector and entry bytes are checked by `validate_rom.ps1`.

, and `D720` decrements AL before repeating. The register/segment state (`DS=ES=SS=AAAAh`, `SP=D709h`) is consistent with the preceding stack-threaded segment-register test at `D6C4h–D70Ch`; it is not, by itself, evidence of stack corruption. The user paused emulation while the delay loop was still running (`CX=98E7h`, `AL=87h`). Therefore this log does not show a BIOS hang or a completed POST. Resume the same run and allow this delay to finish; capture the next POST-80h values and final CPU state. E9h output is not expected unless the original BIOS explicitly writes to that debug port.

## Next implementation boundary

Continue reconstructing the reset/POST call graph from the exact disassembly, starting with the `88CEh` branch now present and all of its direct and indirect destinations; then continue with the remaining early-POST targets. Preserve alternate entries, stack-crafted returns, register/flag contracts and POST port-80h writes. Only mark a routine complete when its bytes, incoming references and outgoing control flow are reconciled.

## Reference ROM

The original `ami486.bin` remains unchanged. Keep it separate from generated output and do not overwrite it. Any binary compatibility payload must be explicitly identified as inherited rather than native reconstruction.

## Validation

The post-build PowerShell validator checks:
- exact output size (currently 65,536 bytes);
- immutable reference ROM identity (SHA-256 `91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b`);
- the implemented windows `88CEh–8A03h`, `8A04h–8A1Fh`, `8A20h–8A74h`, `8CCDh–8DEBh`, `EE94h–EF35h` and `D604h–D776h` against the reference ROM, not only its first instructions;
- the reference reset-vector bytes at `FFF0h`;
- the reset gateway at `E05Bh`;
- the first verified POST instructions at `D604h`.

A successful assembly/layout check is not evidence of a successful BIOS boot. PCem differential testing remains required.
