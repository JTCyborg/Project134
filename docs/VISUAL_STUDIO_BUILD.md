# Project134 — Visual Studio build environment

## Decision

Project134 is developed and built from Microsoft Visual Studio on Windows. Visual Studio is the IDE and MSBuild orchestrates the BIOS build.

The BIOS is 16-bit x86 real-mode code and must be emitted as a flat binary ROM. The project therefore uses NASM in flat-binary mode (`-f bin`) rather than assuming that the Visual Studio MASM integration can directly produce the required ROM image.

## Prerequisite

NASM for Windows is required. The build script resolves it in this order: an explicit `NasmExe` path, `PATH`, the vcpkg NASM cache under `%VCPKG_ROOT%\\downloads\\tools\\nasm` or `C:\\vcpkg\\downloads\\tools\\nasm`, then the standard Program Files locations. When vcpkg contains multiple cached NASM versions, the highest detected version is selected. No per-user Visual Studio setting is required.

## Build

1. Open `Project134.sln` in Microsoft Visual Studio.
2. Select `Debug | x64` or `Release | x64`.
3. Build the `Project134.BIOS` project.
4. In the Build Output window, confirm that the script prints the NASM path, source path, output path and `BUILD SUCCESS`.

The output directory is anchored to the BIOS project location, not `$(SolutionDir)`:
- `out\Debug\Project134.bin`
- `out\Release\Project134.bin`

The build script creates the output directory, resolves NASM, checks its exit code, verifies that the ROM exists and runs the reset-vector validator. A missing NASM executable or missing output is a build error, not a successful empty build.

If NASM is installed elsewhere, set the MSBuild property `NasmExe` to its full executable path (for example, pass `/p:NasmExe="C:\Tools\NASM\nasm.exe"` to MSBuild).

## Current limitations

- The 64 KiB ROM size and F0000h mapping are provisional until the exact PCem ROM loader and reference ROM are inspected.
- The bootstrap only proves assembly, image layout and reset-vector validation. It does not implement POST, chipset setup, memory tests, device initialization or Spectrum compatibility.
- Do not select this bootstrap as the normal AMI486 ROM in PCem yet.
- Do not modify Project133. Use it only as the reference/test environment.
