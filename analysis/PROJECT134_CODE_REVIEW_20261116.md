# Project134 code review — 2026-11-16

## Scope

Read-only review of the current `main` tree outside the AMI reference archive, including:
- `Project134.sln`
- `bios/Project134.BIOS.vcxproj`
- `bios/src/reset.asm`
- `bios/tools/build_bios.ps1`
- `bios/tools/validate_rom.ps1`
- `.github/workflows/ami486-full-disasm.yml`
- `tools/disasm_ami486_full.ps1`
- `README.md`, `bios/README.md`, `docs/VISUAL_STUDIO_BUILD.md`, `docs/PROJECT134_PLAN.md`, and `docs/AMI486_REFERENCE.md`

The recursive tree contains 1,576 entries. Excluding `docs/627.10` and generated analysis/reference material, the current implementation source is a single assembly file, `bios/src/reset.asm`, plus the PowerShell build/validation scripts. There is no PCem C/C++ source baseline, no Z80 core, no Spectrum platform implementation, and no functional BIOS subsystem code in this repository snapshot.

## Findings

### 1. BIOS target is intentionally only a build-pipeline bootstrap

`reset.asm` emits a 64-KiB flat image, places a small real-mode entry at offset E000h, establishes SS:SP=0000:7C00h, sets DS=ES=F000h, then halts forever.

This is internally consistent as a minimal assembly/build smoke test. It does not perform POST, chipset setup, memory discovery, interrupt setup, device initialization, or Spectrum emulation.

**Do not use this image as the AMI486 replacement BIOS.** The README correctly warns about this.

### 2. Reset-vector difference is deliberate but must remain explicit

The bootstrap's validator requires reset bytes `EA 00 E0 00 F0`, which jump to F000:E000. The reference `ami486.bin` has reset bytes `EA 5B E0 00 F0`, which jump to F000:E05B.

The current validator therefore proves only that the bootstrap matches its own provisional layout. It does not validate compatibility with the AMI486 reference ROM. This is not a defect while the bootstrap remains clearly isolated; it becomes a blocker if anyone treats its PASS as AMI486 reset-path validation.

### 3. Visual Studio / NASM build scaffold

The solution maps Debug|x64 and Release|x64 to the Makefile project. The project anchors output paths to its own directory, invokes NASM in flat-binary mode, and declares the generated ROM as NMakeOutput. The PowerShell build script:
- resolves NASM from an explicit path, PATH, vcpkg cache or standard install folders;
- checks the NASM exit code and output existence;
- invokes the ROM validator.

The validator checks exact image size and reset-vector bytes. This is appropriate for the stated smoke-test purpose.

Small maintainability note: the `$LASTEXITCODE` check after invoking the PowerShell validator is not a reliable way to detect a PowerShell-script failure; a terminating `throw` already propagates to the caller, while `$LASTEXITCODE` is primarily the last native-process exit code. This is redundant rather than a demonstrated build failure.

### 4. Full-disassembly GitHub workflow

The workflow validates a 65,536-byte ROM, computes SHA-256, decodes every byte in Capstone 16-bit mode, writes undecodable bytes as `db`, and records exact byte coverage. It correctly labels the result a **linear decode**, not semantic code coverage.

The workflow does not construct a control-flow graph or classify code/data. That limitation is documented in the generated coverage audit and should remain explicit in downstream reports.

### 5. Repository/plan state is behind the actual evidence

The plan still describes full disassembly and checksum work as open in its current-evidence paragraph, even though the repository now has:
- a byte-complete linear listing and manifest;
- a ROM SHA-256 record;
- a POST-flow note and 65 semantic-map phase reports.

The semantic CFG, complete code/data classification, exact Project133 runtime baseline and POST/device validation are still open. The plan should distinguish completed linear coverage from incomplete semantic reconstruction rather than treating both as one task.

### 6. No executable integration target exists yet

The project currently has no checked-in emulator runtime or automated BIOS execution test. The Visual Studio build proves that NASM can produce the provisional image; it does not prove that PCem loads it, maps it, fetches its reset vector, or runs any BIOS behavior.

The exact Project133 commit/configuration and a reproducible runtime trace remain required before claiming an AMI486 platform baseline.

## Review outcome

No source change was made to the bootstrap or build scripts during this review. No confirmed functional defect was found in the intentionally minimal assembly bootstrap. The main risk is scope confusion: build-pipeline success and complete linear byte coverage must not be mistaken for a working BIOS or completed semantic disassembly.

## Recommended next review targets

1. Reconcile `docs/PROJECT134_PLAN.md` with the now-completed linear listing/checksum and still-open semantic CFG.
2. Inspect the Project133 AT/ALi1429 implementation at the exact commit used by the user, without modifying Project133.
3. Continue semantic CFG/code-data classification of `ami486.bin`, preserving alternate entry streams and stack-crafted returns.
4. Add an automated emulator smoke test only after the exact PCem baseline and ROM loading configuration are pinned.
5. Keep the BIOS bootstrap explicitly marked as non-operational until a real POST path and hardware initialization are independently implemented and tested.
