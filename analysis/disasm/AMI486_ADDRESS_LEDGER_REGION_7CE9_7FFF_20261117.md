# AMI486 address ledger — zero-filled ROM tail 7CE9h–7FFFh

Date: 2026-11-17  
Repository: JTCyborg/Project134, branch main  
ROM: ami486.bin, 65,536 bytes; SHA-256 91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b

## 1. Byte verification

The former largest uncovered interval 7CE9h–7FFFh is exactly 791 bytes (8000h - 7CE9h). A byte-for-byte scan of ami486.bin confirms:
- Total bytes: 791
- 00h bytes: 791
- Nonzero bytes: 0
- First byte at 7CE9h: 00h
- Last byte at 7FFFh: 00h

There are no instruction bytes, strings, signatures or embedded tables in this interval. It is a zero-filled ROM area, classified as padding/reserved space rather than executable code.

## 2. Generator integration

The candidate generator now records [7CE9h, 8000h) as a single 791-byte zero-filled data range. No code seed is added. This is an exact byte classification, not an inferred function.

GitHub Actions run 44084573238 completed successfully. The regenerated manifest reports 811 candidate windows, 238 data ranges, 39,090 unique code-window bytes, 19,703 unique data-range bytes, 293 overlap bytes, and a 58,500-byte union (89.26%). There are 67 uncovered intervals; the next largest is 639Ch–6615h (634 bytes).
