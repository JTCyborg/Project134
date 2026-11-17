# AMI486 address ledger — Advanced CMOS Setup descriptor table and page initializers (0B2Dh–0C7Ch)

Date: 2026-11-17  
Repository: JTCyborg/Project134, branch main  
Source: ami486.bin, 65,536 bytes  
SHA-1: 480c7520c93e6c7ed437cf3ad214da7503f82ec6  
ROM SHA-256 recorded by the existing ledger: 91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b

## 1. Scope and corrected entry boundaries

The interval contains a 45-record CMOS Setup descriptor/handler table followed by three gated Advanced CMOS page initializers and one CPU clock/cache profile page initializer.

The initial candidate seeds at 0C04h, 0C2Bh and 0C52h were not the starts of the page initializers. Each is a one-byte RET reached as the skip path of the preceding handler. The actual entries are:

| Address | Classification |
|---:|---|
| 0B2Dh–0BE0h | 45-record descriptor/handler table |
| 0BDEh–0C03h | Executable Advanced CMOS handler overlapping the final table record |
| 0C04h | One-byte RET skip path |
| 0C05h–0C2Ah | B7CCh-gated Advanced CMOS page initializer |
| 0C2Bh | One-byte RET |
| 0C2Ch–0C51h | B7CEh-gated Advanced CMOS page initializer |
| 0C52h | One-byte RET |
| 0C53h–0C7Ch | CPU clock/cache profile page initializer |
| 0C7Dh onward | Shared page engine, separately seeded |

The table's final four bytes at 0BDDh–0BE0h are 00 83 3E CA (words 8300h and CA3Eh). The executable entry at 0BDEh begins with 83 3E CA B7 00, so bytes 0BDEh–0BE0h are a genuine code/data overlap. Preserve both interpretations; do not shift the handler entry to 0BDDh.

## 2. Descriptor/handler table — 0B2Dh–0BE0h

The table contains 45 four-byte records. Each record is represented as two little-endian words: a descriptor/string offset followed by the associated handler/page offset. Examples from the first records:

| Record offset | Descriptor word | Handler word |
|---:|---:|---:|
| 0B2Dh | 0B25h | 0351h |
| 0B31h | 0B35h | 02F1h |
| 0B35h | 0B2Dh | 02DBh |
| 0B39h | 0B3Dh | 0236h |
| 0B3Dh | 0B35h | 02F1h |
| 0B41h | 0B45h | 026Fh |
| 0B45h | 0B3Dh | 0236h |

The remaining records use descriptor offsets in the 0B4Dh–0BD5h range and handler/page offsets mainly in the 060Eh–06AEh range. The final record at 0BDDh is 8300h/CA3Eh and overlaps the executable entry at 0BDEh. The exact UI meaning of every descriptor and the full dispatch semantics of all 45 records are not assigned from this table alone.

## 3. Advanced CMOS handler — 0BDEh–0C03h

The handler first compares the word at B7CAh with zero. If it is zero, it branches to the one-byte RET at 0C04h.

Otherwise it prepares the shared page-engine parameter block:

- E191h = B7D0h
- E193h = BD54h
- E197h = word at CS:8292h
- E195h = B7B2h
- BX = 305Bh

It then calls the shared page engine at 0C7Dh and returns. The gate at B7CAh is distinct from the B7CCh and B7CEh gates used by the following initializers.

## 4. B7CCh-gated page initializer — 0C05h–0C2Ah

The handler compares the word at B7CCh with zero. A zero value branches to the RET at 0C2Bh.

When enabled, it prepares:

- E191h = BD54h
- E193h = C5F9h
- E197h = word at CS:8292h
- E195h = B7B2h
- BX = 3071h

It calls the shared page engine at 0C7Dh and returns at 0C2Bh.

## 5. B7CEh-gated page initializer — 0C2Ch–0C51h

The handler compares the word at B7CEh with zero. A zero value branches to the RET at 0C52h.

When enabled, it prepares:

- E191h = C5F9h
- E193h = C5F9h
- E197h = word at CS:8292h
- E195h = B7B2h
- BX = 308Ah

It calls the shared page engine at 0C7Dh and returns at 0C52h.

## 6. CPU clock/cache profile page initializer — 0C53h–0C7Ch

This entry constructs the page-engine parameters from the profile pointer table:

- AX = word at CS:82C6h; store it at E191h.
- CX = word at CS:82C8h; store it at E193h.
- Compute CX-AX and test against FFE0h.
- If the masked difference is nonzero, load the words at CS:82BCh and CS:82D2h into E197h and E195h, respectively, load BX from CS:82CEh, and call the shared page engine at 0C7Dh.
- Return at 0C7Ch.

This ties the Advanced CMOS CPU/cache Setup page directly to the profile pointer data used by the CMOS 8Eh selector in the 81EEh–8377h region. It establishes the data flow but does not yet assign human-readable CPU-speed/cache labels to every profile record.

## 7. Generator correction

The candidate generator now uses these bounded entries:
- 0BDEh: 26h bytes, retaining the intentional overlap with the final table record.
- 0C04h: 01h byte (RET).
- 0C05h: 27h bytes.
- 0C2Bh: 01h byte (RET).
- 0C2Ch: 27h bytes.
- 0C52h: 01h byte (RET).
- 0C53h: 2Ah bytes, ending at the RET at 0C7Ch.

The previous seeds at 0C04h/0C2Bh/0C52h were incorrectly described as page initializers; their descriptions now identify the RET stubs, and the real entries are separately seeded.

Generator correction commit: 0f65a99fd1a1675c6bcae794eb2ff3e1c0da8388.

The global manifest has not yet been regenerated after this boundary correction. No new coverage percentage or CI pass is claimed.

## 8. Remaining uncertainties

- Full semantic labels and display strings for all 45 descriptor/handler records.
- The precise meaning of the B7CAh/B7CCh/B7CEh enable words.
- The field-level structure of the page-engine parameter block at E191h–E197h.
- The human-readable mapping of each CPU/cache profile record and the precise meaning of the FFE0h comparison.
