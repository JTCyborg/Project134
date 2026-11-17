# AMI486 address ledger — CMOS Setup staging, checksum and CMOS writeback (84BEh–85B2h)

Date: 2026-11-17  
Repository: JTCyborg/Project134, branch main  
Source: ami486.bin, 65,536 bytes  
SHA-1: 480c7520c93e6c7ed437cf3ad214da7503f82ec6  
ROM SHA-256 recorded by the existing ledger: 91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b

## 1. Boundary correction

The previous candidate window at 84BEh was clipped at 84C9h, leaving the final byte of a three-byte near JMP uncovered. The bytes are:

- 84BEh: 83 C6 04 — ADD SI,0004h
- 84C1h: 2E 3B 36 C2 82 — CMP SI,CS:[82C2h]
- 84C6h: 72 CB — JB 8493h
- 84C8h: E9 42 54 — JMP D90Dh

Therefore 84CAh is the high displacement byte of the JMP at 84C8h, not an instruction entry. The next independent candidate stream begins at 84CBh with CLI.

The generator now extends the 84BEh window from 0Ch to 0Dh bytes, covering 84BEh–84CAh, and seeds 84CBh–85B2h as a separate 0E8h-byte window.

## 2. CMOS Setup staging routine — 84CBh–852Fh

The routine begins:

- CLI
- Saves SI and DI, then copies DS into ES.
- Sets DI=E010h.
- Reads CMOS register 8Eh through the existing CMOS read helper EE94h.
- Tests bits C0h of the returned value.

Two data-source paths follow:

1. If bits C0h are clear, it reads a sequence of CMOS registers beginning at 90h and stores the returned bytes at ES:E010h. The loop count is derived from CS:[82B3h] minus 8Fh.
2. If either bit in C0h is set, it copies 30h bytes from CS:8210h to ES:E010h.

It then calls three local helpers at 85B4h, 85CEh and 85D7h, followed by calls to D538h and 1A92h. It copies 80h bytes from E000h to E080h, clears bit 0 of E1AAh, calls E4E9h, and sets that bit again if the helper reports the alternate status. It restores DI/SI, enables interrupts and returns at 852Fh.

This is a staging/normalization path for the BIOS Setup CMOS/configuration image. The exact meanings of the two CMOS 8Eh selector bits are not assigned here.

## 3. Validation/reset path — 8530h–8547h

8530h calls 1A92h, saves the returned flags, calls the checksum updater at 8550h, then restores the original flags. If the saved ZF is set, it returns at 8547h. Otherwise it clears the warm-boot flag word at 0000:0472h and jumps to F000:E05Bh (the BIOS reset entry).

The flag save/restore is significant: the branch tests the status from 1A92h, not flags produced by the checksum updater.

## 4. Byte-sum helper — 8548h–854Fh

8548h clears AX, loads each byte from DS:SI with LODSB, adds it to BX, and loops CX times. It returns with the accumulated sum in BX. It performs no independent range validation.

## 5. Configuration checksum and CMOS writeback — 8550h–85B2h

8550h calculates two byte sums using the helper at 8548h:

- E010h–E02Dh: 30h bytes; the byte sum is byte-swapped and stored at E02Eh.
- E034h–E03Dh: 0Ah bytes, followed by E040h for CS:[82B3h]-00BFh bytes when that count is nonzero; the combined sum is byte-swapped and stored at E03Eh.

It then disables interrupts, clears the word at E00Eh, and writes the staged configuration bytes to CMOS starting at register 8Eh through the CMOS write helper reached by the call at 85AAh. The loop count is CS:[82B3h]-008Dh. When SI reaches E032h, it skips two bytes and increments the CMOS register index twice, preserving the gap in the staged layout. The routine finishes with STI, restores SI and returns at 85B2h.

## 6. Entry/boundary ledger

| Address | Role |
|---:|---|
| 84BEh | Existing CMOS 8Eh loop continuation |
| 84C8h | Near JMP to D90Dh; its final displacement byte is at 84CAh |
| 84CBh | Candidate entry for CMOS Setup staging routine |
| 852Fh | Return from staging routine |
| 8530h | Validation path; may clear warm-boot flag and reset |
| 8548h | Byte-sum helper |
| 8550h | Configuration checksum and CMOS writeback |
| 85B2h | Return from checksum/writeback routine |
| 85B3h | Next separate helper entry |

## 7. Generator integration and coverage

The generator now:
- extends 84BEh to 0Dh bytes so the JMP at 84C8h is not split;
- adds 84CBh with a bounded 0E8h-byte window ending immediately before 85B3h.

The update is committed as 8870769cf5fe72ff720f5cca99c29ca012baea13. The post-change manifest has not yet been regenerated, so no new global coverage figure or CI pass is claimed here.

## 8. Remaining uncertainties

- Exact names/semantics of CMOS 8Eh bits C0h.
- Exact meanings of the staged bytes in E010h onward and the CMOS registers written by the loop.
- Provenance of the 84CBh entry; this local analysis establishes its routine structure but does not by itself prove the external caller.
- Hardware-specific interpretation of the E4E9h status test.
