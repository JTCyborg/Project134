# Project134 code and reference review — continued

Date: 2026-11-16
Scope: implementation/build files, plan consistency, linear disassembly artifacts, and additional AMI BIOS 6.27.10 shared definitions.

## 1. Project plan consistency corrected

The previous plan text incorrectly grouped byte-complete linear disassembly with semantic completion and still said the checksum/disassembly were pending. It also contained a contradictory pair of Visual Studio build statements.

Updated `docs/PROJECT134_PLAN.md` to distinguish:
- ROM identity and SHA-256 recorded;
- 65,536/65,536-byte linear decode complete;
- semantic code/data classification and CFG still incomplete;
- user's reported Debug|x64 build success from a separate, still-unverified clean rebuild and emulator boot.

Verified ROM facts from the committed manifest/audit:
- Size: 65,536 bytes.
- SHA-256: `91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b`.
- Linear decode: 29,731 records; byte coverage 0000-FFFF.
- This is not semantic coverage.

## 2. Additional 6.27.10 shared definitions reviewed

Read the following files as architectural/reference material:

| File | Confirmed contents | Applicability limit |
|---|---|---|
| `INCLUDE/MBIOSEQU.EQU` | BIOS module IDs, POST error bits, beep/error categories, conventional-memory stack constant | AMI 6.27.10 internal conventions; not proof of target ROM layout |
| `INCLUDE/DIM.EQU` | DIM 1.80 version, memory-layout notes, shadow granularity, NVRAM/ESCD data structures | DIM-specific map and shadow assumptions must not be applied globally |
| `INCLUDE/DEVNODE.EQU` | PnP system device-node structures and IDs for AT PIC, timer, DMA, keyboard, IDE, floppy, speaker, VGA, RTC, etc. | IDs describe possible device classes, not devices actually present in the target configuration |
| `INCLUDE/PCI.EQU` | PCI 2.10 constants, configuration offsets, BAR and expansion-ROM structures | Defines interfaces/structures, not ALi 1429 register programming or actual PCI topology |
| `INCLUDE/PNP.EQU` | ISA PnP index/write/read ports and register definitions | Does not prove that this ROM performs ISA PnP enumeration |
| `INCLUDE/ESCD.EQU` | ESCD 2.1 header, board/function records and configuration flags | Data format only; actual NVRAM persistence path must be separately traced |
| `INCLUDE/DMI.EQU` and `INCLUDE/SMB.EQU` | DMI/SMBIOS structures, types and fixed lengths | Describes system inventory tables, not hardware initialization |

### Important memory-layout warning

Two reference files describe different BIOS stack regions:
- `MBIOSEQU.EQU` defines `bios_stack_end=2000h` and comments that `0000:0700–1FFF` is a 6 KiB BIOS stack.
- `DIM.EQU` has a DIM memory-organization table that labels `0300h–03FFh` as a 256-byte BIOS stack.

These are not safe to combine into a single Project134 memory map. They are subsystem/version-specific comments/constants in a large modular BIOS collection. The target ROM and the actual PCem memory map must decide the Project134 layout.

## 3. Build and automation review — additional observations

- The Visual Studio project is a Makefile project invoking the PowerShell/NASM script. The NASM output is a flat 64 KiB binary; this is appropriate for the bootstrap's stated purpose.
- `reset.asm` places its entry at ROM offset E000h and emits a far reset-vector jump to F000:E000. It then halts. The implementation is internally consistent as a smoke-test bootstrap, not a functional BIOS.
- The PowerShell validator checks image size and the exact bootstrap reset-vector bytes. It must not be described as validating compatibility with the target ROM's F000:E05B entry.
- The GitHub Actions workflow generates a linear Capstone decode and manifest. Its explicit warning that linear decoding does not classify code/data is correct.
- The workflow's path filters avoid re-triggering on its own generated listing/manifest commits. The write permission and bot commit are consistent with that automation model.
- No emulator execution or BIOS POST test is part of this workflow.

No confirmed functional defect was found in the current intentionally minimal assembly bootstrap. The key risk remains treating a successful build or byte-complete linear decode as proof of a working BIOS.

## 4. Current implementation boundary

The current repository contains a build scaffold and documentation/reference material, but no integrated PCem runtime, no Z80 core, no Spectrum memory/ULA/keyboard/sound implementation, and no operational POST firmware. The plan correctly treats those as future work; the project must not claim Spectrum compatibility yet.

## 5. Next review targets

1. Continue the AMI486 semantic CFG and code/data classification, with priority on dynamic/indirect transfers and stack-crafted return paths.
2. Pin the exact Project133 local revision/configuration and obtain a runtime trace of the actual ROM.
3. Correlate actual target-ROM I/O writes with the ALi 1429 emulator implementation before defining chipset initialization.
4. Continue classifying readable 6.27.10 sources; do not port chipset/OEM-specific routines or assume that listed device IDs are present.
5. Keep the bootstrap explicitly marked as non-operational until real POST, device initialization and emulator execution tests exist.
