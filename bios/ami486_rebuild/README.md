# AMI486 native BIOS reconstruction

## Goal

Create an independently maintained, buildable BIOS image that preserves the original AMI486 firmware's:
- externally observable POST and runtime behavior;
- initialization order and hardware programming model;
- interrupt/vector interfaces and BIOS Data Area contracts;
- ROM layout, entry points, reset vector, and exact image length.

The original `ami486.bin` remains immutable reference input. This reconstruction lives separately and must never overwrite the reference image.

## Development environment

- Primary IDE: Microsoft Visual Studio 2026.
- Target artifact: a flat 16-bit x86 ROM image, not a normal MSVC executable.
- The Visual Studio project should orchestrate the assembler, ROM-layout/validation scripts, and emulator tests through build targets.
- MSVC's normal compiler/linker are not the BIOS code generator. Use an assembler that can emit flat binary and explicit 16-bit x86 code; NASM is the initial candidate. Finalize the assembler and its version when the first source module and reproducible build are added.
- Keep all build paths configurable; do not hard-code a developer-specific installation path.

## Reference image

- Source: repository-root `ami486.bin`
- Git blob: `480c7520c93e6c7ed437cf3ad214da7503f82ec6`
- The binary endpoint returned a Base64 payload of 88,841 characters in this session. Its length is not valid Base64 (not divisible by four), so the payload is treated as incomplete and no decoded file size or checksum is claimed here.
- Before generating a clone, verify the exact byte length and cryptographic hash from a complete binary download. Then map the file against the chipset's ROM decode and reset-vector alias before choosing a final linker origin.
- Existing disassembly notes: `analysis/disasm/`

## Reconstruction strategy

This is a behavior-preserving reimplementation, not a patch of the reference ROM and not a byte-for-byte copy presented as original source.

1. Keep the reference image and its hash unchanged.
2. Establish the physical ROM map: image size, mirrored/aliased regions, reset-vector location, checksums, and writable flash/EPROM constraints.
3. Build a complete address/function inventory from the disassembly. Each range is classified as verified, partially verified, or unknown.
4. Reimplement verified routines in source, preserving calling conventions, register/flag outputs, memory side effects, port I/O order, delays, and error behavior.
5. For not-yet-understood ranges, do not invent replacements. Preserve their bytes in a separately tracked compatibility payload until they can be reconstructed. Mark such regions as inherited, not native.
6. Link to the exact original image size and layout. Fail the build on size, vector, reset-entry, or map violations.
7. Differential-test the new image against the original in the emulator: instruction-level traces, port writes, IVT/BDA/CMOS changes, POST milestones, and interrupt results.
8. Only call the result a functional replacement after boot and subsystem tests pass on the target emulator/hardware.

## First implementation boundary

The current verified work provides a useful start for the hard-disk INT 13h path:
- INT 13h hook/dispatcher at A08Dh and function table at A0F1h;
- DPT creation at 5AB5h and active DPT vector selection;
- DPT dereference helper at A5B7h;
- AH=02h read path enters A76Ch and consumes DPT byte +08h;
- AH=03h write path begins at A808h but is not yet fully traced.

Do not implement the disk service as complete until read, write, verify, format, reset, retry, timeout, and status/error paths are traced.

## Required source layout (planned)

- `src/entry.asm` — reset entry and ROM entry stubs
- `src/post/` — POST and platform initialization
- `src/interrupts/` — IVT setup and BIOS interrupt handlers
- `src/disk/` — INT 13h, ATA/CHS, DPT handling
- `src/video/` — video initialization and INT 10h
- `src/keyboard/` — keyboard controller and INT 16h
- `src/timer/` — PIT, IRQ0, INT 08h/1Ch
- `src/cmos/` — RTC/CMOS configuration
- `linker/` — exact ROM map and assertions
- `tests/` — emulator trace and regression tests
- `compat/` — explicitly marked inherited byte ranges, if required during transition

## Acceptance criteria

- Output length exactly matches the reference image length and its documented physical mapping.
- Reset vector and all fixed vectors/entry points land at the intended addresses.
- No unclassified ROM ranges remain before claiming full native reconstruction.
- All verified POST and interrupt tests pass.
- Differential trace has no unexplained differences in port I/O, IVT, BDA, CMOS, memory initialization, or externally visible status.
- Unknown/inherited code is reported explicitly; it is never silently described as reimplemented.

## Current status

The native NASM reconstruction is still incomplete and is not qualified to boot. The source now contains an instruction-level transcription of the CPU/cache profile selector and CMOS 8Eh path at 8300h–83FFh. The validator requires this interval to match the reference ROM byte-for-byte, but a fresh NASM/Visual Studio build has not yet been run to confirm that check. Other ROM regions remain unimplemented or differ from the reference.

The Visual Studio build now produces two distinct artifacts:

- `Project134.native-candidate.bin` — output assembled from `bios/src/reset.asm`; retained for instruction-level development and validation. It is not represented as a working BIOS.
- `Project134.bin` — by default, a byte-for-byte copy of the known-working `ami486.bin` reference. This provides a bootable compatibility baseline while native regions are reconstructed. Use `-NativeOnly` only when deliberately testing the incomplete candidate.

The default output is verified against the reference SHA-256 before the build reports success. This is an interim compatibility image, not an independently reconstructed BIOS. Native replacement status must be reported separately from bootability.
