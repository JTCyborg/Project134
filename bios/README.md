# BIOS workspace

The BIOS is developed independently for Project134. The original AMI486 ROM is an immutable behavioral reference and is never modified by the build.

## Visual Studio build

Open `Project134.sln` in Microsoft Visual Studio 2026 and build `Project134.BIOS`.

Visual Studio/MSBuild invokes NASM to emit a flat 16-bit x86 ROM image. MSVC does not compile or link the BIOS code.

Prerequisite: `nasm.exe` on `PATH`. If NASM is installed elsewhere, pass `/p:NasmExe="C:\\path\\to\\nasm.exe"` to MSBuild.

Build output:
- `out\\Debug\\Project134.bin`
- `out\\Release\\Project134.bin`

## Reconstruction status — Stage 4

The reconstructed image is 65,536 bytes and preserves the original ROM address layout. Implemented windows are copied verbatim from the immutable `ami486.bin` reference:

| ROM offsets | Restored content |
|---|---|
| `19ABh–19AFh` | POST indirect-dispatch trampoline and RET stubs |
| `2646h–26BDh` | GDT descriptors and protected-mode 1 MiB memory-read helper |
| `82DAh–82DBh` | POST dispatch pointer selecting `19ABh` |
| `88CEh–8A03h` | Initial 8042-clear POST branch (310 bytes) |
| `8A04h–8A1Fh` | Reset continuation and CMOS[8Fh] branch |
| `8A20h–8A74h` | CMOS dispatch helper |
| `8A75h–8CCCh` | POST continuation, dispatch stubs and chipset/device helper code (600 bytes) |
| `8CCDh–8DECh` | ALi indexed-I/O helper cluster |
| `8DEDh–8E0Ch` | ALi indexed-I/O read/write tail helpers and `JMP DI` trampoline |
| `D604h–D776h` | Early POST dispatcher, stack-threaded RAM test, CMOS/8042 checks and POST 80h writes |
| `E05Bh–E05Dh` | Reset gateway: near jump to `D604h` |
| `EE94h–EF35h` | CMOS/PIC helpers |
| `F659h–F690h` | 8042 status-wait and command-byte helpers |
| `FFF0h–FFF4h` | Reset vector: far jump to `F000:E05B` |

`bios/tools/validate_rom.ps1` checks the immutable reference ROM SHA-256, output size, reset vector and every restored byte window listed above. It must be run against the built ROM and original `ami486.bin`.

## POST path established by static analysis

1. CPU reset enters `F000:E05B`, which jumps to `F000:D604`.
2. The 8042 status selects the branch at `88CEh` or `8A04h`.
3. The early RAM/CMOS/8042 path emits POST codes `01h` and `02h`.
4. The delay loop at `D71Eh` decrements the delay count loaded from `CS:8284h`; changing AL/CX values in successive PCem snapshots confirmed forward progress.
5. After the delay, `D724h` tests `CS:8281h`, emits POST `03h`, and jumps through `D749h` to `8A75h`.
6. `8A75h` redirects to `D74Ch`; POST `04h` is emitted, then the path reaches `8A78h`.
7. `8A78h` reads the pointer at `CS:82DAh` (`19ABh)); the trampoline at `19ABh` jumps through DI to `8A81h`, which enters the indexed-I/O helper path.
8. The restored path uses the ALi indexed-I/O helpers and the protected-mode memory-read routine at `2686h`, then returns through the DI-threaded continuation. The alternate 8042 command entries at `8ACFh/8AD2h` use the restored helpers at `F66Ah/F66Eh`.

This establishes the next static control-flow segment; it does not establish successful runtime completion.

## PCem status

The latest available `pcem.log` snapshot, captured before the Stage 4 source updates, reports POST port-80h values `01h` and `02h`, with CPU at `F000:D71E`, `AL=59h`, `CX=1BA0h`, and approximately 10,916,287 instructions. This is progress inside the intentional delay loop, not proof of a hang or successful boot.

**No NASM build, validator run, or PCem test has yet been confirmed after the Stage 4 commits.** Rebuild in Visual Studio 2026, run the ROM validator, then test that exact output ROM in PCem and capture the next CPU/POST snapshot. The `Bad getpccache 000A0000` message is not treated as the cause of a BIOS failure without further evidence.

## Current limitation

The image is still incomplete. Unrestored ROM destinations and data referenced by later POST/setup paths remain filled with `FFh`; the image is not yet claimed to be PCem-bootable.
