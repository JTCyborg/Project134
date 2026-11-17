# AMI486 address ledger — POST video/adapter initialization and overlapping continuation (5E3Dh–5F64h)

Date: 2026-11-17  
Repository: JTCyborg/Project134, branch main  
Source: ami486.bin, 65,536 bytes  
SHA-1: 480c7520c93e6c7ed437cf3ad214da7503f82ec6  
ROM SHA-256 recorded by the existing ledger: 91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b

## 1. Boundary correction

The prior seed at 5E3Dh ended at 5E87h and split the conditional branch at 5E86h:

- 5E86h: 75 17 — JNZ 5E9Fh
- 5E87h: 17 — displacement byte

Thus 5E88h, the first byte of the former uncovered interval, is not an instruction entry. The generator window at 5E3Dh has been extended from 4Bh to 128h bytes, ending at 5F64h inclusive, immediately before the separately seeded helper at 5F65h.

## 2. Main POST video/adapter stream — 5E3Dh–5F64h

The entry reads the BDA video configuration byte at 0040:0012h, tests bit 6, and selects the video-memory base B800h or B000h. It updates the BDA video-state byte at 0040:0010h and emits POST checkpoints through port 80h.

The sequence emits POST values 2Fh and 30h while probing the selected video path through helper 5FA7h and helper F598h. The conditional branches at 5E56h and 5E86h select the subsequent path. The latter branch targets 5E9Fh.

The continuation from 5E89h emits POST code 32h, calls the display/adapter helpers, and updates the video-state bits at 0040:0010h. It checks CMOS register 8Eh through EE95h, uses helper 864Ah, and emits POST code 33h. The following path emits POST code 34h, tests the BDA video-state bits, reads CMOS 8Eh again, updates the video-state byte and invokes INT 10h to apply the selected video mode.

The later checkpoints are:
- 35h and 36h around the video-mode/cursor setup;
- 37h around INT 10h AH=03h/AH=02h cursor-position operations;
- 38h and F3h around the subsequent BIOS/display helper calls;
- 39h around another INT 10h cursor query;
- 3Ah before helper 5FD6h and helper 54E5h;
- 3Bh immediately before the final near JMP at 5F62h.

The final instruction at 5F62h is E9 39 F1, a near JMP to 509Eh. The existing 509Eh entry is the continuation target; the jump is not a return.

## 3. Alternate overlapping stream — 5EB6h

The unconditional short JMP at 5E6Dh targets 5EB6h. This target is inside the immediate/displacement bytes of the linear instruction beginning at 5EB4h:

- Linear stream at 5EB4h: E8 D8 00 — CALL 5F8Fh
- Alternate entry at 5EB6h: byte 00 becomes the first opcode byte.

Therefore the region contains two distinct instruction alignments. The alternate entry at 5EB6h begins with a valid 16-bit instruction stream and continues through the video-state checks before rejoining the common path near 5F01h. It is retained as a separate candidate seed rather than forcing the alternate bytes into the primary linear decode.

This is a confirmed control-flow overlap, not a reason to reinterpret the CALL at 5EB4h as data. The exact reason for the BIOS's overlapping branch layout remains unresolved.

## 4. Cross-reference ledger

| Source | Target | Meaning |
|---:|---:|---|
| 5E37h | 5F65h | Direct CALL to the separately seeded diagnostic/check helper |
| 5E53h | 5FA7h | Adapter/status check |
| 5E6Dh | 5EB6h | Unconditional short branch into the overlapping stream |
| 5E83h | 5FA7h | Second adapter/status check |
| 5E86h | 5E9Fh | Conditional branch within the main stream |
| 5F62h | 509Eh | Final POST continuation JMP |

## 5. Generator integration

The candidate generator now:
- extends the 5E3Dh main window to 128h bytes, covering 5E3Dh–5F64h;
- adds 5EB6h as a separate 4Fh-byte alternate-entry window, ending immediately before the common instruction stream at 5F05h;
- retains 5F65h and 5FA7h as separate helper entries.

Generator update commit: b9d2e85c35663cf6138cfb1ef6a2496e31cb1e7a.

The manifest has not yet been regenerated after this addition. No new global coverage percentage or CI pass is claimed.

## 6. Remaining uncertainties

- Exact hardware meaning of the BDA video-state bits manipulated at 0040:0010h/0012h.
- Exact semantics of the CMOS 8Eh tests in this POST path.
- Full function-level meaning of helpers 5FA7h, F598h, 864Ah, 5F8Fh, 5FD6h and 54E5h.
- Why the alternate stream at 5EB6h intentionally or incidentally overlaps the CALL displacement at 5EB4h.
