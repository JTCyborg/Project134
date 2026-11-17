# AMI486 address ledger — Diskette BIOS dispatch/transfer continuation (C780h–C8AFh)

Date: 2026-11-17  
Repository: JTCyborg/Project134, branch main  
Source: ami486.bin, 65,536 bytes  
SHA-1: 480c7520c93e6c7ed437cf3ad214da7503f82ec6  
ROM SHA-256 recorded by the existing ledger: 91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b

## 1. Boundary correction

The existing C780h window used the default 80h-byte limit and stopped at C7FFh. The last bytes are:

- C7F0h: E9 E8 00 — near JMP to C8DBh.
- C7FFh: 75 13 — JNZ C814h.
- C800h: 13h — displacement byte of that JNZ, not an instruction entry.
- C801h: 50h — PUSH AX, the sequential fall-through after the branch.

The window at C780h has therefore been extended to 130h bytes, covering C780h–C8AFh inclusive and stopping immediately before the separately seeded C8B0h entry.

## 2. Dispatch/transfer behavior

The continuation is part of the legacy diskette BIOS dispatch/transfer path. It uses a saved BP-based parameter frame, controller/status helpers in the Dxxx region, the diskette parameter table and FDC/DMA state.

Observed operations include:
- polling/retry branches that return to C7E9h;
- a conditional branch from C7FFh to C814h;
- status tests and updates to the low-memory flag byte at 003Eh;
- media/signature comparisons against D7h and 17h, with the selected status value placed in AH;
- setup of transfer parameters in SI/DI and a call into the D2xx helper path;
- loading the INT 1Eh diskette parameter table pointer from 0000:0078h;
- computing a transfer-size value from the request parameters and the parameter-table shift count;
- a final branch into the C8B0h DMA-transfer dispatcher when the request mode requires it.

The exact meanings of all request-frame fields and the media-signature values remain tied to the existing INT 13h handler analysis; this pass records the byte/control-flow boundary and does not rename those fields speculatively.

## 3. Control-flow edges

| Source | Target | Meaning |
|---:|---:|---|
| C7F0h | C8DBh | Near JMP into the separately seeded continuation window |
| C7FFh | C814h | Conditional branch within the extended window |
| C80Ah | C7E9h | Retry/back-edge |
| C83Bh | C7E9h | Retry/back-edge |
| C844h | C82Fh | Internal retry/alternate path |
| C84Fh | C838h | Conditional retry |
| C87Fh | C838h | Conditional retry |
| C8A4h | C838h | Retry/back-edge |
| C8ACh | C8B2h | Branch into the next diskette DMA dispatch window |

C8DBh is within the separately seeded C8B0h window and lies after the overlapping diskette parameter data view at C8CAh–C8D6h. C8B2h is likewise inside the C8B0h window.

## 4. Generator integration

The candidate generator now gives C780h a 130h-byte window, ending at C8AFh. This includes the previously clipped JNZ displacement at C800h and preserves the adjacent C8B0h entry boundary.

Generator update commit: 88fc71605b7f660154b429cd8199a21ef4458a7d.

The manifest has not yet been regenerated after this addition. No new global coverage percentage or CI pass is claimed.

## 5. Remaining uncertainties

- Exact names and semantics of the BP-frame request fields.
- The specific media types represented by the D7h/17h signatures.
- Full semantics of the D2xx helper calls and the C8DBh continuation.
- The precise point at which this path hands control to the C8B0h DMA dispatcher for each INT 13h function.
