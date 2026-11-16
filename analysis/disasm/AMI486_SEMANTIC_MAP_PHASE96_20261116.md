# AMI486 semantic map — phase 96 (2026-11-16)

## 1. Complete first-record map for the 0AE1h selector

05A3h masks AL to 0..15 and 0AADh selects one word from CS:0AE1h. 05B4h then adds four to that selected base and reads the first linked record.

| AL | Pointer at 0AE1h | First record | Next cursor | Callback target |
|---:|---:|---:|---:|---:|
| 0 | 0B75h | 0B79h | 0B4Dh | 064Ah |
| 1 | 0B4Dh | 0B51h | 0B55h | 060Eh |
| 2 | 0B55h | 0B59h | 0B5Dh | 0614h |
| 3 | 0B5Dh | 0B61h | 0B65h | 061Ah |
| 4 | 0B65h | 0B69h | 0B6Dh | 0620h |
| 5 | 0B6Dh | 0B71h | 0B75h | 0626h |
| 6 | 0B45h | 0B49h | 0AEDh | 6373h |
| 7 | 026Fh | 0273h | 77D7h | 16BAh |
| 8 | 0AF5h | 0AF9h | 0AFDh | 641Fh |
| 9 | 63C9h | 63CDh | 0004h | 9CE8h |
| 10 | 0AEDh | 0AF1h | 0AF5h | 63C9h |
| 11 | 6373h | 6377h | 0005h | 01F2h |
| 12 | 0AFDh | 0B01h | 0B05h | 6485h |
| 13 | 641Fh | 6423h | 0006h | 46E8h |
| 14 | 0AF5h | 0AF9h | 0AFDh | 641Fh |
| 15 | 63C9h | 63CDh | 0004h | 9CE8h |

The values for indices 9, 11 and 13 are obtained by applying the dispatcher literally to the four bytes at base+4. These are overlapping entries inside executable sequences (for example 63C9h is followed by MOV CX,4; the selected record at 63CDh begins in that instruction's immediate bytes). The target offsets 9CE8h, 01F2h and 46E8h are therefore raw indirect-call values, not yet semantically identified callbacks. Keep these as overlap cases pending caller/target analysis.

## 2. AL=6 chain is the date/time editor family

The chain selected by AL=6 begins at base 0B45h. Its linked records resolve as follows:

| Record | Next cursor | Callback | Known semantic label |
|---:|---:|---:|---|
| 0B49h | 0AEDh | 6373h | Month |
| 0AF1h | 0AF5h | 63C9h | Day |
| 0AF9h | 0AFDh | 641Fh | Year |
| 0B01h | 0B05h | 6485h | Hour |
| 0B05h | 0AFDh | 641Fh | Year (alternate link) |
| 0B09h | 0B0Dh | 64E3h | Minute |
| 0B0Dh | 0B05h | 6485h | Hour (alternate link) |
| 0B11h | 0B15h | 6541h | Second |
| 0B15h | 0B0Dh | 64E3h | Minute (alternate link) |
| 0B19h | 0B1Dh | 0319h | hexadecimal nibble editor |
| 0B1Dh | 0B15h | 6541h | Second (alternate link) |

This is not a linear array. The repeated/backward next-cursors allow the dispatcher to revisit earlier fields based on callback return AH/CF/ZF. The handler labels are cross-checked against phase 87 (date/time callbacks) and phase 88 (0319h nibble editor).

## 3. AL=0..5 are option-label chains

The bases 0B75h, 0B4Dh, 0B55h, 0B5Dh, 0B65h and 0B6Dh select short option chains. The first callback wrappers are 064Ah, 060Eh, 0614h, 061Ah, 0620h and 0626h. The wrappers at 060Eh..0626h load a CS-resident string into SI and tail-jump to 05BAh, which fetches the next record. Thus they are dispatcher continuations that display option text, not independent conventional callback/RET routines.

## 4. AL=7 and the 026Fh/0273h overlap

AL=7 selects base 026Fh. The dispatcher starts at 0273h and reads next=77D7h, callback=16BAh. The same byte range beginning at 026Fh has a separately established executable entry used by the Setup Options path. This is a confirmed overlap between a callable entry and a table record view; preserve both entry interpretations.

## 5. Current open items

- Resolve the raw callback targets 9CE8h, 01F2h and 46E8h for selector indices 9, 11 and 13.
- Trace the full continuation branches for AL=0..5 and determine which AH values each string wrapper returns or inherits.
- Verify the exact callback/return behavior of 16BAh for AL=7.
- Do not infer semantics for pointer entries 8..15 from the first record alone where the selected base overlaps executable bytes.