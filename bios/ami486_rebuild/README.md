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
- Verified image length: 65,536 bytes.
- Verified SHA-256: `91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b`.
- The complete reference image is included in the reproducible Windows CI artifact and remains immutable. The source is assembled as a flat 16-bit ROM image with its original F000h-relative offsets.
- Existing disassembly notes: `analysis/disasm/`

## Reconstruction strategy

This is a behavior-preserving reimplementation, not a patch of the reference ROM and not a byte-for-byte copy presented as original source.

1. Keep the reference image and its hash unchanged.
2. Establish the physical ROM map: image size, mirrored/aliased regions, reset-vector location, checksums, and writable flash/EPROM constraints.
3. Build a complete address/function inventory from the disassembly. Each range is classified as verified, partially verified, or unknown.
4. Reimplement verified routines in source, preserving calling conventions, register/flag outputs, memory side effects, port I/O order, delays, and error behavior.
5. For not-yet-understood ranges, do not invent replacements. Preserve their bytes directly from the immutable reference ROM with explicit `incbin` slices. These regions are inherited, not native; replace them with NASM only after instruction/data boundaries and behavior are verified.
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

The current NASM candidate is **byte-identical to the original 64-KiB ROM**. GitHub Actions run [`44384426423`](https://github.com/JTCyborg/Project134/actions/runs/44384426423) completed successfully:

- Full comparison: 65,536/65,536 bytes equal.
- POST06 16-bit word checksum: `0000h`.
- Candidate and reference SHA-256: `91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b`.
- NASM structural validation: 65,536 bytes.
- PCem was not launched by this CI job; runtime boot confirmation remains a separate test.

This is **not yet a fully independent native reconstruction**. The verified NASM listing contains 55,218 bytes (84.26%) inherited from explicit `incbin "ami486.bin"` slices and 10,318 bytes (15.74%) emitted directly by source as instructions, explicit data, and fill. The source-emitted bytes have been compared against the reference. Inherited code is preserved, not reimplemented.

The current source now contains these newly verified regions:

- `2065h–2F23h`: POST memory/CMOS/selector paths, including the previously transcribed `29F6h–2D10h` handlers, memory benchmark/PIT measurement routines at `2D11h–2E72h`, B513/B519 Setup selector handlers at `2E74h–2EF0h`, and the existing PIT helpers and Setup relocation handoff.
- `2F24h–3043h`: Setup exit prompts, saved-stack restoration, BDA clear helper, and temporary IVT/INT 13h AH=14h path.
- `3C5Ch–3F49h`: Setup main menu, shared header renderer, value parser, and metric formatter.
- `3F4Ah–4230h`: POST system-configuration display, CPU/equipment identification, decimal/hex output, and display helpers.
- `8300h–83FFh`: CPU/cache profile selector and CMOS 8Eh update path.

See `analysis/disasm/PROJECT134_BYTE_EXACT_BUILD_AUDIT_20261118.md` for the exact build and inherited-range inventory. The next selected executable interval is `4628h–4890h`, the Setup hard-disk utility menu and display helpers. Its entry at `4628h` is confirmed by the Setup handler table; strings and lookup tables before it remain inherited.

The Visual Studio build produces two artifacts:

- `Project134.native-candidate.bin` — assembled from `bios/src/reset.asm`. At the verified revision it is byte-identical to the original ROM; 85.39% of its bytes are still inherited through explicit reference slices.
- `Project134.bin` — the default boot image, copied from the known-working `ami486.bin` reference before native assembly. It has the same SHA-256 as the assembled candidate at this revision.

Both files contain the same ROM bytes at this revision. Use `-NativeOnly` only when deliberately testing the assembled candidate as the primary output.
