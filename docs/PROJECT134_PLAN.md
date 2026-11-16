# Project134 — BIOS Development Plan

## Mission

Develop a ZX Spectrum-compatible platform using the PCem AMI486 machine model as the starting platform reference. Project134 is a separate repository. Project133 must remain unchanged.

The development is BIOS-first: platform initialization, compatibility services, hardware configuration and later hardware extensions are to be implemented at the BIOS/platform firmware level wherever the existing PCem machine interfaces permit. Do not modify the PCem core or disable existing PCem functionality as a shortcut. Any unavoidable core change must be identified and agreed before implementation.

The original Spectrum software accesses memory, ROM, I/O ports and timing directly. Therefore BIOS services alone are not sufficient: the BIOS/platform configuration must also expose compatible Z80-visible memory, ports, interrupts, video, keyboard and sound behaviour.

## Phase 0 — Project baseline

- [ ] Confirm the upstream PCem source baseline and revision.
- [ ] Inspect the AMI486 machine registration, initialization and device setup.
- [ ] Identify the currently working AMI486 BIOS ROM and its provenance.
- [x] Add the AMI BIOS 6.27.10 collection as an architectural reference; keep it separate from the target AMI486 ROM/source identification.
- [ ] Identify ROM loading, reset-vector mapping and BIOS execution path.
- [x] Create the separate Project134 repository and record this plan without changing Project133.
- [ ] Import/establish the PCem source baseline and create an isolated Project134 machine/profile.
- [ ] Record a reproducible build and runtime baseline.
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

**Current evidence:** the upstream PCem AMI486 model registration has been inspected and recorded in [docs/AMI486_REFERENCE.md](AMI486_REFERENCE.md). It identifies the AT initialization path and ALi 1429 chipset callback, but does not yet establish the exact Project133 source revision or runtime configuration. The AMI BIOS 6.27.10 collection under [docs/627.10](627.10) has also been inspected as an architectural reference only; it is not verified as the source of the target AMI486 ROM, and its platform-specific code is not assumed to match ALi 1429.\n\n**Next action:** build the new `Project134.sln` in the user's Visual Studio installation and resolve any environment/toolchain errors. Then obtain the exact `ami486.bin` again and record the Project133 source commit plus ROM-set 46 configuration; inspect the actual ROM loader/reset mapping before selecting the final image size or testing the bootstrap in PCem. The 64 KiB/F0000h bootstrap layout is provisional and is not yet a usable AMI486 BIOS.
