# AMI486 address ledger — POST/Setup metric display routines (714Eh–71E3h)

Date: 2026-11-17  
Repository: JTCyborg/Project134, branch main  
Source: ami486.bin, 65,536 bytes  
SHA-1: 480c7520c93e6c7ed437cf3ad214da7503f82ec6  
ROM SHA-256 recorded by the existing ledger: 91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b

## 1. Boundary and adjacent data

The preceding inline label occupies 7145h–714Dh and contains the unit text “KB/sec ms” without a NUL terminator. Executable code begins at 714Eh. The next separately seeded entry begins at 71E4h; its first byte is 80h, so the RET at 71E3h belongs to the 71A0h routine.

The interval is exactly split into two routines:

| Range | Classification |
|---|---|
| 714Eh–719Fh | Two-value metric display routine |
| 71A0h–71E3h | BP-framed metric display routine |
| 71E4h onward | Separate dispatch target, already mapped |

## 2. Two-value display routine — 714Eh–719Fh

Direct caller: 711Ch.

The routine reads the display row/column from E3CEh/E3CDh, positions the cursor with INT 10h AH=02h, and invokes the existing output helper at 57FDh. It writes eight spaces using INT 10h AH=09h and the attribute byte at E19Fh.

It then:
- loads the first value from E3C9h and calls the formatter at 7323h;
- positions the cursor again using E3CEh/E3CDh plus the offset at E3CFh;
- prints a decimal point with INT 10h AH=0Eh;
- loads the second value from E3CBh and calls the same formatter at 7323h;
- returns at 719Fh.

The nearby “KB/sec ms” label and the two formatted values indicate a performance/timing display. The exact units of each stored value are not inferred beyond the literal label.

## 3. BP-framed metric display routine — 71A0h–71E3h

The routine begins with PUSH BP / MOV BP,SP and reserves 10h bytes of local stack space. It calls helper 72D9h, selects DS from SS, reads display coordinates from E3C6h/E3C7h, adds six columns, and positions the cursor through INT 10h AH=02h.

It clears four character cells with INT 10h AH=09h and the attribute at E19Fh, loads the value at E1AFh, and calls formatting/display helpers at 7324h and 72F2h. It restores SP from BP, pops BP and returns at 71E3h.

No direct near CALL reference to 71A0h was found in the raw ROM scan; it is retained as a distinct sequential routine boundary.

## 4. Cross-reference ledger

| Source | Target | Meaning |
|---:|---:|---|
| 711Ch | 714Eh | Direct CALL to two-value metric display |
| 714Eh | 57FDh | Existing text/number output helper |
| 7179h / 719Bh | 7323h | Format and display values from E3C9h/E3CBh |
| 71A6h | 72D9h | BP-framed display setup helper |
| 71C7h | 57FEh | Existing display helper |
| 71DBh | 7324h | Format/display E1AFh value |
| 71DEh | 72F2h | Final display helper |

## 5. Generator integration

The candidate generator now seeds:
- 714Eh with a 52h-byte window ending at 71A0h;
- 71A0h with a 44h-byte window ending at 71E4h.

The existing 71E4h dispatch entry remains separate and unchanged.

Generator update commit: b9fe29583640d2967d2c5f1f41bdb126af1963cb.

The manifest has not yet been regenerated after this addition. No new global coverage percentage or CI pass is claimed.

## 6. Remaining uncertainties

- Exact unit/scaling of the values stored at E3C9h, E3CBh and E1AFh.
- The full caller/selection logic for the BP-framed routine at 71A0h.
- Whether the metric label is specific to a memory-speed test or a broader POST timing display.
