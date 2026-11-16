# AMI486 ROM — Disassembly Index

Target ROM: ami486.bin
ROM size: 65536 bytes
Disassembler: NASM ndisasm 3.01
Mode: 16-bit

## Archived source listings

| File | Start address | Description |
|---|---:|---|
| ami486_reset.disasm.txt | F000:E05B | Reset entry and initial code |
| ami486_post_entry.disasm.txt | F000:D604 | POST entry investigation |
| ami486_branches.disasm.txt | Multiple | Branch targets and alternate entry points |

## Address investigation

| Address | Current finding | Status |
|---|---|---|
| F000:FFF0 | Far jump to F000:E05B | Confirmed |
| F000:E05B | Near jump to F000:D604 | Confirmed |
| F000:D604 | POST entry candidate; CLI, CLD, KBC status check | Partial |
| F000:D60C | Unconditional jump to F000:88CE | Confirmed |
| F000:88CE | CPU/stack and mode checks; overlapping code/data possible | Partial |
| F000:8A04 | Checks CR0.PE; reset/halt path or alternate initialization | Partial |
| F000:8A20 | Checks initialization state and dispatches helper | Partial |
| F000:8A75 | Jump to F000:D74C | Confirmed |
| F000:8A78 | Indirect jump through CS:82DA | Confirmed |
| F000:D6DE | POST code 1; stack test sequence | Partial |
| F000:D74C | Keyboard controller and warm-boot checks | Partial |
| F000:D77B | ROM checksum loop | Partial |
| F000:D7AB | Keyboard controller self-test | Partial |
| F000:F4A5 | Error reporting and diagnostic/beep path | Partial |
| F000:F659 | Wait for keyboard controller input buffer | Partial |
| F000:F6D9 | Option ROM header/checksum validation and dispatch | Partial |
| F000:1AF8 | Jump to F000:D82F | Confirmed |
| F000:1B90 | Option ROM scanning candidate | Partial |

## Rules

- Never overwrite archived source listings.
- Do not repeat a disassembly already present in this archive.
- Add new address ranges as separate files.
- Distinguish confirmed control flow from linear-disassembly guesses.
- Do not mark a routine fully understood until its callers, inputs, outputs and side effects are checked.

## Update 2026-11-16 — POST flow

| Address | Finding | Status |
|---|---|---|
| F000:D604 | KBC status bit 2 dispatch | Confirmed |
| F000:88CE | SMSW / CR0.PE check | Confirmed |
| F000:891E | JMP F000:D60F | Confirmed |
| F000:D60F | JMP F000:D6DE | Confirmed |
| F000:8904 | Dispatch to EE94 | Confirmed |
| F000:8906 | Dispatch to EE94 | Confirmed |
| F000:8919 | Dispatch to EE9D | Confirmed |
| F000:8DCF | ALi1429 register read helper | Strongly supported |
| F000:8DDC | ALi1429 register write helper | Strongly supported |
| F000:8DED | ALi1429 register read sequence | Strongly supported |

Detailed report: AMI486_POST_FLOW_20261116_01.md

## Full-ROM coverage audit — 2026-11-16

Target image: `ami486.bin` (65,536 bytes; Git blob SHA `480c7520c93e6c7ed437cf3ad214da7503f82ec6`).

### Existing listing coverage

| Listing | First offset | Last offset | Lines | Meaning |
|---|---:|---:|---:|---|
| `ami486_reset.disasm.txt` | `E05B` | `FFFF` | 3,993 | Linear 16-bit listing from reset entry |
| `ami486_post_entry.disasm.txt` | `D604` | `FFFF` | 5,252 | Linear 16-bit listing from POST entry |
| `ami486_branches.disasm.txt` | multiple | multiple | 919 | Selected branch/alternate-entry excerpts |

The reset and POST listings overlap heavily: both continue linearly to `FFFF`. They are not independent contiguous ROM partitions and must not be concatenated as if they cover the complete image.

### Missing full-ROM range

The existing two linear listings do not cover offsets `0000-D603` (54,788 bytes). The branch listing and focused analysis files contain selected excerpts from that region, not a byte-complete disassembly.

### Status and required method

- **Full 64-KiB disassembly: NOT COMPLETE.**
- Existing listings are preserved as historical entry-point listings.
- Do not label a listing as complete based only on reaching `FFFF`; its starting offset matters.
- To finish, run NASM `ndisasm -b 16` against the exact `ami486.bin` for the missing range `0000-D603`, then reconcile code/data and alternate-entry regions against the existing listings.
- The GitHub file connector can retrieve text files and base64-encode binary files, but cannot provide a local binary file to the disassembler in this execution environment. No synthetic or guessed bytes are to be substituted.
- Verify the input image SHA-256 and byte length before generating the final master listing. Preserve the existing reset/POST listings unchanged.

### Next deliverables

1. A byte-complete linear listing covering `0000-FFFF`.
2. A separate control-flow/alternate-entry map so overlapping instruction streams remain explicit.
3. A code/data classification map for tables, strings, padding, option-ROM payloads and embedded structures.
4. A revised index with verified coverage and source-image hash.



## Full-ROM linear disassembly generator — 2026-11-16

A reproducible generator is now tracked at `tools/disasm_ami486_full.ps1`.

Run from the repository root in PowerShell:

```powershell
.\tools\disasm_ami486_full.ps1 -RomPath .\ami486.bin -Ndisasm ndisasm
```

The script requires the exact 65,536-byte ROM and NASM `ndisasm`, decodes in 16-bit mode from offset `0000`, verifies that the listing accounts for exactly 65,536 input bytes, and writes:
- `analysis/disasm/ami486_full_linear.disasm.txt`
- `analysis/disasm/ami486_full_linear.disasm.manifest.txt`

The manifest records the local ROM SHA-256, disassembler path, mode, origin, line count and decoded byte count. The generated linear listing is a mechanical decode only; it does not establish code reachability or distinguish embedded data from instructions. Preserve the existing reset/POST entry-point listings as separate views.


## Automated full-ROM disassembly

A GitHub Actions workflow (`.github/workflows/ami486-full-disasm.yml`) generates `ami486_full_linear_16bit.disasm.txt` directly from the checked-in 64-KiB ROM using NASM `ndisasm -b 16`. The listing is a complete **linear byte decode**, not a claim that every decoded byte is executable code; embedded tables, strings, vectors and overlapping entry points must be classified separately. The workflow verifies exact byte coverage and commits the generated listing.
