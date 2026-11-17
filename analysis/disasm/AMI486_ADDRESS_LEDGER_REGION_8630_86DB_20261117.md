# AMI486 address ledger — CMOS option checks and stack-threaded checksum verification (8630h–86DAh)

Date: 2026-11-17  
Repository: JTCyborg/Project134, branch main  
Source: ami486.bin, 65,536 bytes  
SHA-1: 480c7520c93e6c7ed437cf3ad214da7503f82ec6  
ROM SHA-256 recorded by the existing ledger: 91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b

## 1. Scope and exact segmentation

The 171-byte interval is not one linear function. It contains four small CMOS option-check routines followed by a stack-threaded checksum verifier. Four words inside the latter are return slots and are explicitly classified as data.

| Range | Classification |
|---|---|
| 8630h–8648h | CMOS 8Eh/90h option check |
| 8649h–8661h | CMOS 8Eh/94h option check, flag bit 1 |
| 8662h–867Ah | CMOS 8Eh/94h option check, flag bit 0 |
| 867Bh–868Ah | CS:8280h bit-3 check and CPU-profile helper |
| 868Bh–8692h | Checksum-verifier entry trampoline |
| 8693h–869Fh | First checksum continuation |
| 86A0h–86A1h | Crafted return word 86A2h |
| 86A2h–86A9h | CMOS read continuation |
| 86AAh–86ABh | Crafted return word 86ACh |
| 86ACh–86C3h | First checksum compare and second checksum setup |
| 86C4h–86C5h | Crafted return word 86C6h |
| 86C6h–86CDh | CMOS read continuation |
| 86CEh–86CFh | Crafted return word 86D0h |
| 86D0h–86DAh | Second checksum compare and exit to D2EAh |
| 86DBh onward | Next separately seeded entry |

## 2. CMOS option checks — 8630h, 8649h, 8662h

All three helpers read CMOS register 8Eh through EE94h and test bits C0h. Depending on that state, they may read CMOS register 90h or 94h and compare selected bits against the BIOS configuration byte at CS:8280h.

- 8630h checks CS:8280h bit 2, with CMOS register 90h as the alternate condition.
- 8649h checks CMOS register 94h bit 3 and CS:8280h bit 1.
- 8662h checks CMOS register 94h bit 2 and CS:8280h bit 0.

Each routine returns with flags from the final TEST/OR operation. They are condition helpers; they do not write the CMOS values.

Direct CALL references to 8630h were found at 1327h and 1577h.

## 3. CPU-profile option helper — 867Bh–868Ah

The helper tests bit 3 of CS:8280h. If the bit is clear, it returns. If set, it loads AL from CS:B511h and calls the CPU-profile helper at 8300h, then returns.

This ties the CMOS option byte to the CPU/cache profile selection logic mapped in the 81EEh–8377h phase.

## 4. Stack-threaded CMOS checksum verifier — 868Bh–86DAh

The entry at 868Bh saves AX into DX, sets DI=8693h and transfers to the existing checksum accumulator at 17F2h. The checksum helper returns through DI to the continuation at 8693h.

The continuation then uses crafted stack return words to perform CMOS reads through EE94h:

1. At 8693h, if BX is nonzero, it selects the AEh/AFh checksum pair, sets SP=86A0h and jumps to EE94h. The word at 86A0h is 86A2h, so the CMOS helper returns to the continuation at 86A2h.
2. At 86A2h, it exchanges AH/AL, sets SP=86AAh and jumps to EE94h again. The word at 86AAh is 86ACh.
3. At 86ACh, it compares AX with BX. On a match, it sets DI=86B6h and transfers to the second checksum accumulator at 180Fh.
4. The second continuation selects the BEh/BFh checksum pair, sets SP=86C4h and jumps to EE94h. The word at 86C4h is 86C6h.
5. At 86C6h, it exchanges AH/AL, sets SP=86CEh and jumps to EE94h again. The word at 86CEh is 86D0h.
6. At 86D0h, it compares AX with BX and branches to the common result path. The routine restores AX from DX and jumps to D2EAh.

The four words at 86A0h, 86AAh, 86C4h and 86CEh are not ordinary instruction bytes. They are return addresses deliberately consumed by the CMOS read helper. The generator therefore emits them as data ranges and starts independent code windows after each word.

## 5. Cross-reference ledger

| Source | Target | Meaning |
|---:|---:|---|
| 1327h | 8630h | Direct CALL to CMOS option check |
| 1577h | 8630h | Direct CALL to CMOS option check |
| 867Bh | 8300h | CPU/cache profile helper |
| 868Dh | 17F2h | First CMOS checksum accumulator; continuation DI=8693h |
| 86B3h | 180Fh | Second CMOS checksum accumulator; continuation DI=86B6h |
| 86D8h | D2EAh | Final checksum-verifier continuation |

## 6. Generator integration

The candidate generator now seeds the four CMOS option helpers and the stack-threaded checksum continuation in bounded pieces. It classifies the four crafted return words as data:

- 86A0h–86A1h = 86A2h
- 86AAh–86ABh = 86ACh
- 86C4h–86C5h = 86C6h
- 86CEh–86CFh = 86D0h

Generator update commit: 1ced033a4465751b83b7a5d1fc793e31d679aa63.

The manifest has not yet been regenerated after this addition. No new global coverage percentage or CI pass is claimed.

## 7. Remaining uncertainties

- The precise board-level meaning of the bits in CS:8280h and their corresponding CMOS values.
- The exact status convention returned through D2EAh.
- Whether the two checksum pairs are validated independently or form one combined setup-integrity condition in the calling path.
