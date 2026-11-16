# BIOS workspace

The BIOS is developed independently for Project134. The original AMI486 ROM is a reference binary only; it is not source code and must not be modified or treated as an implementation source.

## Visual Studio build

Open `Project134.sln` in Microsoft Visual Studio and build the `Project134.BIOS` project.

The project uses NASM to emit a flat 16-bit x86 ROM image. Visual Studio/MSBuild orchestrates the build; MSVC MASM is not used because the BIOS output is a raw 16-bit real-mode binary.

Prerequisite:
- NASM installed and available as `nasm.exe` on `PATH`.

If NASM is installed elsewhere, set the MSBuild property `NasmExe` to its full executable path (Project Properties → NMake → Build Command Line is not required; pass `/p:NasmExe="C:\path\to\nasm.exe"` to MSBuild).

Build output:
- `out\Debug\Project134.bin`
- `out\Release\Project134.bin`

## Bootstrap status

`src/reset.asm` is a deliberately minimal bootstrap image used to validate the Visual Studio build pipeline and reset-vector placement. It initializes a safe real-mode stack and halts. It is **not** a functional PC BIOS and is not yet approved for use as the AMI486 machine ROM.

The current 64 KiB layout and F0000h..FFFFFh mapping are provisional assumptions. Before using the image in PCem, verify the exact ROM size, ROM-set loading path, mapping and reset-vector behaviour against the Project133 reference configuration.

## Validation

The post-build PowerShell validator checks:
- exact output size (currently 65536 bytes);
- reset-vector bytes at ROM offset FFF0h;
- far-jump target F000:E000.

Generated images are build artifacts and should not be hand-edited.

## Reference ROM

After the user reattaches and confirms the exact reference file, store it byte-for-byte as:
- `reference/ami486.bin`
- `reference/ami486.sha256`

Do not commit a reference ROM until its provenance and redistribution rights are confirmed.
