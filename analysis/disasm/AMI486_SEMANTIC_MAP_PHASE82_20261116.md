# AMI486 semantic map — phase 82 (2026-11-16)

## 1. Immediate CMOS[8Eh] readers and masks

The ROM contains thirteen immediate `MOV AL,8Eh; CALL EE94h` sequences (the pattern begins at the first address below). All calls target the common CMOS read helper EE94h. Their immediate post-read tests are:

| Selector | Read call | Immediate consumer | Mask / action |
|---:|---:|---|---|
| 121Ah | 121Ch | 121Fh | `TEST AL,01h` |
| 1271h | 1273h | 1276h | `TEST AL,20h` |
| 1338h | 133Ah | 133Dh | `TEST AL,C0h` |
| 140Eh | 1410h | 1413h | `TEST AL,C0h` |
| 15ACh | 15AEh | 15B1h | `TEST AL,D0h` |
| 1C64h | 1C66h | 1C69h | `TEST AL,C0h` |
| 5D78h | 5D7Ah | 5D7Dh | `TEST AL,C0h` |
| 5EDFh | 5EE1h | 5EE4h | next selects 8Fh; tests AL,E0h |
| 84D3h | 84D5h | 84D8h | `TEST AL,C0h` |
| 8630h | 8632h | 8635h | `TEST AL,C0h` |
| 8649h | 864Bh | 864Eh | `TEST AL,C0h` |
| 8662h | 8664h | 8667h | `TEST AL,C0h` |
| F481h | F483h | F486h | `TEST AL,01h` |

This table documents the exact immediate consumer, not the full semantic meaning of the bit fields. Several paths branch or call additional helpers after the test; those are not interchangeable merely because they test the same mask.

## 2. Initial interpretation by site

- **121Ah / bit 0:** bit 0 gates the subsequent POST branch that checks the saved controller/status byte at DS:0012h and may call another initialization helper. This is a separate use from the 5D path.
- **1271h / bit 5:** bit 5 selects between two video/BIOS parameter paths; the clear path prepares AX=1001h and continues through INT 10h-related setup.
- **1338h / bits 6–7:** if either is set, the local block skips the following configuration writes; if clear, it reads other CMOS indices (including 92h/91h) and tests their returned values.
- **140Eh / bits 6–7:** gates the date/time service path. When clear, the routine calls INT 1Ah and validates returned date/time fields.
- **15ACh / mask D0h:** tests bits 7, 6 and 4 together; the following conditional path includes interrupt masking and a helper call. Exact per-bit semantics remain unknown.
- **1C64h / bits 6–7:** gates a far/indirect initialization branch. The test result affects whether the caller proceeds into the subsequent initialization chain.
- **5D78h / bits 6–7:** gates the CMOS BEh:BFh adjustment described in phases 80–81.
- **5EDFh:** after reading 8Eh, code selects CMOS[8Fh] and tests mask E0h. This is a compound configuration path; do not attribute the E0h test to CMOS[8Eh].
- **84D3h / bits 6–7:** gates a loop that copies/initializes a table using CS-relative data and a secondary CMOS[90h] read.
- **8630h, 8649h, 8662h / bits 6–7:** three small query helpers. If bits 6–7 are clear, each reads CMOS[90h] or CMOS[94h] and tests a different bit (respectively bit 3, bit 3, and bit 2) before optionally testing a CS status bit. These are distinct queries, not one generic “8Eh flag”.
- **F481h / bit 0:** bit 0 gates an additional device/status initialization sequence involving a helper call and a fixed data table.

## 3. EEAAh lookalikes are not included

The three byte-pattern matches at CC87h, CD8Bh and F10Dh resolve to EEAAh, not EE94h. They are deliberately excluded from the CMOS-read table. The helper at EEAAh starts at a different instruction boundary and must be analyzed as a separate operation before assigning a meaning to those sites.

## 4. Conclusions and remaining unknowns

CMOS[8Eh] is demonstrably a shared configuration/status byte consulted by multiple POST subsystems. The repeated C0h tests show a common two-bit gate at several sites, but do not establish that bits 6 and 7 have the same functional meaning in every subsystem. Bit 0, bit 5 and mask D0h are used independently elsewhere.

The next step is to follow the branch destinations and called helpers at each site, then identify who writes CMOS[8Eh]. Also unresolved: indirect CMOS access to B8h/8Eh, BEh:BFh update ordering, BP.13 producer, and dynamic entry into DA5Eh/DA61h.
