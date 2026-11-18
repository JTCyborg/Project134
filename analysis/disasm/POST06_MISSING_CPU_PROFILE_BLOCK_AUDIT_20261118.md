# Project134 — POST checksum reconstruction audit: CPU/cache profile block 8300h–8377h

Date: 2026-11-18
Branch: main
Purpose: identify a concrete missing executable interval contributing to the POST06 ROM checksum mismatch.

## Finding

The newer corrected address ledger `AMI486_ADDRESS_LEDGER_REGION_81EE_8378_20261117.md` supersedes the earlier `...81EE_8377...` interpretation.

Correct boundaries:

- 81EEh–8325h: structured Advanced CMOS / CPU-profile data.
- 8300h–8305h: BX-preserving wrapper.
- 8306h–8325h: CPU-profile selector.
- 8326h–8377h: profile-record walker and CMOS register 8Eh update path.
- 8378h: continuation / separately seeded entry.

The earlier ledger incorrectly treated 8328h and 832Eh as entry points. They are inside instructions; do not use those seeds.

## Source integration audit

Current `bios/src/reset.asm` on main has:

- configuration bytes at 8280h–8287h;
- callback words beginning at 82D0h;
- then a `times 0x8400 - ($ - rom_start) db 0xFF` fill before the 8400h implementation.

There is no NASM implementation for 8300h–8377h between those declarations. Consequently the current reconstruction leaves the original CPU/cache profile selector and CMOS 8Eh update routine absent and fills this interval with FFh. This is a concrete missing executable region; it is not merely a validator discrepancy.

## Established behavior from the corrected ledger

- 8300h preserves BX around a call to 8306h.
- 8306h selects a CPU/cache profile using AL and the 0055h boundary derived from B55Dh–B508h.
- 8326h loads the initial profile pointer from CS:[82C6h].
- 832Fh is an alternate entry into the shared walker with BX=B7D0h.
- The shared walker uses 20h-byte records and consumes fields around offsets +1Ch through +1Fh.
- The routine reads and updates CMOS register 8Eh through ports 70h/71h.
- 8378h is the next continuation boundary.

The exact symbolic meanings of CMOS bits C0h/80h and every profile-record field are not established.

## Why no executable patch is included in this commit

The corrected ledger gives control-flow and semantic boundaries, but not a complete byte-verified instruction listing for every byte 8300h–8377h. Reconstructing this code from the summary alone would risk introducing wrong opcodes, displacements, or overlapping-entry behavior. No speculative NASM instructions or checksum compensation are added.

## Next verification step

Obtain a byte-accurate disassembly/listing for 8300h–8377h from the original `ami486.bin`, then implement the exact instruction stream in `reset.asm`. After the user's Visual Studio build, compare the resulting 8300h–8377h bytes against the original and recalculate the full 64-KiB checksum. Do not adjust a checksum word to bypass POST06.
