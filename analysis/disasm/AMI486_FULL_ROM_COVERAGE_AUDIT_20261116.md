# AMI486 full-ROM disassembly coverage audit

Date: 2026-11-16  
Target: `ami486.bin`  
Image size: 65,536 bytes  
Git blob: `480c7520c93e6c7ed437cf3ad214da7503f82ec6`

## Findings

The repository contains three kinds of disassembly artifacts:

- `ami486_reset.disasm.txt`: starts at offset `E05B`, ends at `FFFF`, 3,993 lines.
- `ami486_post_entry.disasm.txt`: starts at offset `D604`, ends at `FFFF`, 5,252 lines.
- `ami486_branches.disasm.txt`: 919 lines of selected branch and alternate-entry excerpts.

Both large listings are linear 16-bit disassemblies and both run through the end of the ROM. The reset listing is a suffix of the POST listing's address range; these files overlap and are not contiguous segments.

## Coverage calculation

- ROM offsets: `0000-FFFF` (65,536 bytes).
- Earliest offset in the two large linear listings: `D604`.
- Uncovered prefix: `0000-D603` = 54,788 bytes.
- Selected excerpts exist in the uncovered prefix, but they do not establish byte-complete coverage.

Therefore the repository does **not** yet contain a full disassembly of `ami486.bin`.

## Why no fabricated master listing was created

The exact ROM exists in GitHub, but the available GitHub file interface returns binary content only as base64 text and does not mount the decoded bytes into the local disassembler environment. The current execution environment also has no outbound network access for downloading the raw ROM. Consequently, running NASM `ndisasm` on the missing prefix cannot be done reliably here.

A guessed decode or a concatenation of the two overlapping suffix listings would falsely claim completeness. Neither was done.

## Required completion procedure

1. Obtain the exact 65,536-byte `ami486.bin` from the repository.
2. Verify SHA-256 and byte count.
3. Generate a 16-bit linear listing for offsets `0000-FFFF`.
4. Retain the reset and POST entry-point listings as separate views; do not overwrite them.
5. Reconcile overlapping instruction streams, branch targets and alternate entries.
6. Mark data regions separately (tables, strings, vectors, padding and embedded payloads).
7. Update `DISASM_INDEX.md` with exact byte coverage and the verified image hash.

## Integrity rules

- Never mark bytes as code solely because a linear decoder produced a mnemonic.
- Keep alternate-entry disassemblies separate when streams overlap.
- Distinguish linear decode from confirmed reachable code.
- Do not overwrite archived listings.
