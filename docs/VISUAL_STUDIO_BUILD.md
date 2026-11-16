# Project134 — Visual Studio build environment

## Decision

Project134 is developed and built from Microsoft Visual Studio on Windows. Visual Studio is the IDE and MSBuild orchestrates the BIOS build.

The BIOS is 16-bit x86 real-mode code and must be emitted as a flat binary ROM. The project therefore uses NASM in flat-binary mode (`-f bin`) rather than assuming that the Visual Studio MASM integration can directly produce the required ROM image.

## Prerequisite

Install NASM for Windows and make `nasm.exe` available on `PATH`. The project also accepts an explicit executable path through the MSBuild property `NasmExe`.

## Build

1. Open `Project134.sln`.
2. Select `Debug | x64` or `Release | x64`.
3. Build the `Project134.BIOS` project.
4. Confirm that the post-build validator reports a pass.

The current bootstrap output is `out/<Configuration>/Project134.bin` (the exact directory is controlled by the solution output path).

## Current limitations

- The 64 KiB ROM size and F0000h mapping are provisional until the exact PCem ROM loader and reference ROM are inspected.
- The bootstrap only proves assembly, image layout and reset-vector validation. It does not implement POST, chipset setup, memory tests, device initialization or Spectrum compatibility.
- Do not select this bootstrap as the normal AMI486 ROM in PCem yet.
- Do not modify Project133. Use it only as the reference/test environment.
