# Project134 — BIOS Development Plan

## Mission

Develop a ZX Spectrum-compatible platform using the PCem AMI486 machine model as the starting platform reference. Project134 is a separate repository. Project133 must remain unchanged.

The development is BIOS-first: platform initialization, compatibility services, hardware configuration and later hardware extensions are to be implemented at the BIOS/platform firmware level wherever the existing PCem machine interfaces permit. Do not modify the PCem core or disable existing PCem functionality as a shortcut. Any unavoidable core change must be identified and agreed before implementation.

The original Spectrum software accesses memory, ROM, I/O ports and timing directly. Therefore BIOS services alone are not sufficient: the BIOS/platform configuration must also expose compatible Z80-visible memory, ports, interrupts, video, keyboard and sound behaviour.

## Phase 0 — Project baseline

- [ ] Confirm the upstream PCem source baseline and revision.
- [ ] Inspect the AMI486 machine registration, initialization and device setup.
- [x] Locate `ami486.bin` in the Project134 repository and record its provenance; full binary validation/disassembly remains open.
- [x] Add the AMI BIOS 6.27.10 collection as an architectural reference; keep it separate from the target AMI486 ROM/source identification.
- [ ] Identify ROM loading, reset-vector mapping and BIOS execution path in the exact PCem/Project133 runtime.
- [x] Create the separate Project134 repository and record this plan without changing Project133.
- [ ] Import/establish the PCem source baseline and create an isolated Project134 machine/profile.
- [ ] Record a reproducible runtime baseline.
- [x] Create the Visual Studio/NASM BIOS build scaffold and confirm a successful Debug|x64 build in the user's Visual Studio environment (2026-11-16).
- [x] Add a Visual Studio solution and NASM/MSBuild BIOS bootstrap target; local build verification is still pending.

**Exit criteria:** Project134 builds and starts the selected AMI486 baseline reproducibly; the BIOS ROM and startup path are identified.

## Phase 1 — Complete 486 POST and hardware validation

No Spectrum-specific implementation in this phase. First establish that the inherited 486 platform and its existing BIOS work correctly.

### 1.1 BIOS entry and POST
- [ ] Verify reset and reset-vector execution.
- [ ] Trace BIOS entry and POST sequence.
- [ ] Identify POST checkpoints, status codes and fatal-error paths.
- [ ] Confirm BIOS ROM mapping and writable shadow/working regions where applicable.

### 1.2 CPU and execution environment
- [ ] Verify the selected 486 CPU model and feature reporting.
- [ ] Verify real-mode execution and relevant CPU modes supported by the BIOS.
- [ ] Verify FPU presence/behaviour as configured.
- [ ] Verify exception and interrupt delivery.
- [ ] Verify instruction timing and delay mechanisms used during POST.

### 1.3 Memory and chipset
- [ ] Verify conventional and extended memory map.
- [ ] Verify RAM read/write and boundary behaviour.
- [ ] Verify ROM areas, BIOS aliases and shadowing.
- [ ] Verify chipset/system-control registers used by the machine.
- [ ] Verify DMA and bus behaviour where present.

### 1.4 Core platform devices
- [ ] PIC and interrupt routing.
- [ ] PIT and system timer.
- [ ] RTC/CMOS and battery-backed configuration.
- [ ] Keyboard controller and keyboard input path.
- [ ] Video adapter initialization and text output.
- [ ] Floppy, IDE and other configured storage controllers.
- [ ] Serial/parallel interfaces and other configured devices.
- [ ] PCI and expansion devices, if present in the selected AMI486 configuration.

### 1.5 Reliability checks
- [ ] Cold boot.
- [ ] Warm reset.
- [ ] Repeated POST.
- [ ] No unexplained fatal POST errors.
- [ ] Capture and retain diagnostic logs and the known-good configuration.

**Exit criteria:** the selected AMI486 configuration completes its expected POST and all devices required by that baseline have documented, tested behaviour. Any unsupported or irrelevant device is explicitly recorded rather than silently assumed to work.

## Phase 2 — Define the ZX Spectrum hardware model and compatibility mapping

- [ ] Select the initial Spectrum target model (48K is the proposed starting point; confirm before implementation).
- [ ] Specify the Z80-visible memory map and ROM/RAM layout.
- [ ] Specify I/O port decoding and contention/observable timing requirements.
- [ ] Specify interrupt generation and timing.
- [ ] Specify ULA/video memory, display timing and border behaviour.
- [ ] Specify keyboard matrix and input mapping.
- [ ] Specify beeper and other initial sound hardware.
- [ ] Map these requirements onto the AMI486-derived platform interfaces.
- [ ] Separate host/PCem infrastructure from Spectrum-visible hardware semantics.
- [ ] Identify any requirement that cannot be implemented through the BIOS/platform firmware interfaces; document it for explicit review rather than silently changing PCem core.

**Exit criteria:** an agreed hardware specification and compatibility matrix exist for the first Spectrum model.

## Phase 3 — BIOS/platform firmware implementation

- [ ] Define the Project134 BIOS image format, memory placement and entry points.
- [ ] Implement platform startup and Spectrum hardware configuration.
- [ ] Implement the Spectrum-visible ROM and RAM mapping.
- [ ] Implement required Z80 execution/compatibility integration through the agreed platform interfaces.
- [ ] Implement I/O port and interrupt compatibility.
- [ ] Implement video/ULA initialization and timing.
- [ ] Implement keyboard and sound support.
- [ ] Add BIOS diagnostics and traceable error reporting.
- [ ] Keep original PCem functionality intact.

**Exit criteria:** BIOS/platform firmware initializes the agreed Spectrum hardware model and exposes the required compatibility behaviour.

## Phase 4 — Software compatibility and first launch

- [ ] Verify Z80 reset and execution entry.
- [ ] Verify the selected Spectrum ROM image and BASIC startup.
- [ ] Verify memory and I/O behaviour with small diagnostic programs.
- [ ] Verify screen output, border, keyboard, beeper and interrupts.
- [ ] Verify tape image loading (TAP/TZX) using the agreed loader path.
- [ ] Test representative original software.
- [ ] Record compatibility results and unresolved differences.

**Exit criteria:** the target Spectrum reaches a usable BASIC environment and runs verified test software; compatibility claims are limited to what has actually been tested.

## Phase 5 — Hardware expansion

- [ ] Add 128K banking and model-specific behaviour.
- [ ] Add AY sound where applicable.
- [ ] Add TR-DOS and disk interfaces.
- [ ] Add further Spectrum-family and expansion hardware in separately tested increments.

**Exit criteria:** each extension has a documented specification and regression tests without breaking the baseline model.

## Phase 6 — Stabilization and release

- [ ] Full POST and startup regression.
- [ ] Spectrum hardware regression suite.
- [ ] Software compatibility regression.
- [ ] Cold/warm reset and repeated-run tests.
- [ ] Document BIOS interfaces, memory map, ports and configuration.
- [ ] Tag a reproducible stable release.

## Source register and mandatory research workflow

The following sources are mandatory inputs to every relevant design or implementation decision. Do not silently substitute one for another.

| Source | Role | What it can establish | What it cannot establish |
|---|---|---|---|
| [Project134/docs/627.10](627.10) | AMI BIOS 6.27.10 architectural reference collection | BIOS subsystem organization, POST/CMOS/CPU design patterns, shared interfaces and diagnostic checklists | It is not proven to be the source of `ami486.bin`; SIS530-specific code is not evidence for ALi 1429 |
| [`ami486.bin`](../ami486.bin) | Target AMI486 ROM behavioral reference | Actual bytes, strings, vectors, disassembly, tables and observed POST behavior once analyzed | Strings alone do not prove implementation behavior; do not copy proprietary implementation |
| [AMI486_REFERENCE.md](AMI486_REFERENCE.md) | PCem AMI486 model notes | Recorded upstream model registration and known chipset/profile facts | Does not replace verification against the exact Project133 revision |
| Project133 checkout (read-only) | Exact emulator integration reference | Actual PCem revision, ROM-set/profile configuration, loader, mapping and runtime behavior | Must never be modified as part of Project134 |
| Upstream PCem source and ALi 1429 implementation | Emulator/hardware-model reference | Machine registration, chipset callbacks, device models and emulated register behavior | Verify revision and local differences before relying on it |
| Project134 source/build/logs | Authoritative implementation and test evidence | What this project actually implements and what has been built/tested | A successful assembly build alone does not prove BIOS boot or hardware compatibility |

### Mandatory source-review procedure

Before implementing or changing any BIOS subsystem:

1. Identify the target behavior from `ami486.bin` (when relevant) and the actual AMI486/ALi 1429 PCem model.
2. Consult `docs/627.10` for the corresponding BIOS architecture and subsystem responsibilities. Search the whole collection where appropriate; do not rely only on the three files already inspected.
3. Classify every consulted 6.27.10 item as **generic architecture/interface**, **device-generic**, **chipset/OEM-specific**, or **binary/object-only**. Do not treat SIS530 or other chipset-specific code as ALi 1429 programming evidence.
4. Record the exact file paths, relevant routines/definitions, applicable findings, and any mismatch in the relevant Project134 design note or source comments.
5. Author Project134 implementation independently. Do not copy or redistribute proprietary source; do not port platform-specific tables/routines without proving hardware correspondence and checking provenance/permissions.
6. Validate against the exact PCem/Project133 revision and runtime trace. If evidence is missing, leave the task open and request the needed artifact/log rather than guessing.

### Source review status

- [x] Add the 6.27.10 collection as a mandatory architectural reference.
- [x] Inspect `ASM1/BIOS.ASM`, `ASM2/CMOS.ASM`, `CPUCORE/CPUEQU.EQU`.
- [x] Inspect `INCLUDE/CPUDATA.ASM`, `INCLUDE/IO.EQU`, `INCLUDE/RT.EQU`, `INCLUDE/PCI.EQU`, and `IO.112/IO.SSP` through `IO3.SSP`.
- [x] Inventory the collection: 1,293 files; distinguish source, setup scripts, prebuilt objects, utilities and chipset-specific material.
- [ ] Review remaining relevant readable source modules in `INCLUDE` and `IO.112`, classifying each before use.
- [ ] Map generic reference concepts to actual AMI486/ALi 1429 hardware and emulator interfaces.
- [ ] Compare the 6.27.10 POST architecture against a disassembly and runtime trace of the exact `ami486.bin`.

## Working rules

1. Work in phase order; do not begin later phases until the current phase exit criteria are met.
2. Mark a task complete only after evidence: build output, trace/log, diagnostic test or reproducible runtime result.
3. Preserve known-good commits and configurations at phase boundaries.
4. Do not change Project133.
5. Do not disable existing PCem features to simplify Project134.
6. Keep changes BIOS/platform-firmware-first. Any required PCem-core modification must be explained and approved before implementation.
7. Update this plan as decisions are made; preserve completed status and record why any step is changed.

## Current status

- [ ] Phase 0 — Project baseline
- [ ] Phase 1 — 486 POST and hardware validation
- [ ] Phase 2 — Spectrum hardware model
- [ ] Phase 3 — BIOS/platform firmware
- [ ] Phase 4 — Software compatibility and first launch
- [ ] Phase 5 — Hardware expansion
- [ ] Phase 6 — Stabilization and release

**Current evidence:** the upstream PCem AMI486 model registration has been inspected and recorded in [docs/AMI486_REFERENCE.md](AMI486_REFERENCE.md). It identifies the AT initialization path and ALi 1429 chipset callback, but the exact Project133 source revision and runtime configuration are still unverified. The `docs/627.10` collection has been inventoried (1,293 files) and key BIOS/CMOS/CPU/interface materials inspected; it remains an architectural reference, not the proven source of the target ROM. The target `ami486.bin` was fetched from this repository and had an initial static inspection: 64 KiB, AMI copyright/date strings (1993), and reset vector bytes `EA 5B E0 00 F0` (far jump to F000:E05B). A full disassembly, checksum record, POST trace and loader/mapping verification remain open.\n\nThe Visual Studio Debug|x64 BIOS scaffold build is verified, including automatic NASM discovery and ROM validation (2026-11-16). This only verifies the build pipeline: the generated 64 KiB F000:E000 bootstrap is provisional and is not yet an operational AMI486 BIOS.\n\n**Next actions (in order):** (1) record the exact Project133 `git rev-parse HEAD`, ROM-set 46 configuration and machine profile; (2) inspect the actual ROM loader, mapping and reset path; (3) record a reproducible checksum and disassemble `ami486.bin` from F000:E05B; (4) continue 6.27.10 source review for the subsystem being implemented, then correlate it with the target ROM and ALi 1429 emulator behavior before coding.
