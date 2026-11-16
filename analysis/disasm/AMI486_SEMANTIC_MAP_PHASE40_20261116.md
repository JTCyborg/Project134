# AMI486 semantic map — phase 40 (2026-11-16)

## Scope

This phase consolidates the observed CMOS B3h bitfield consumers and the two in-ROM writers. It distinguishes direct bit-level behavior from possible board-level meanings.

## 1. CMOS B3h bit 7: threshold flag derived from the BDA memory-size word

At 11C8h–11DCh the BIOS:

1. Reads CMOS B3h.
2. Clears bit 7 with `AND AL,7Fh`, preserving bits 0–6.
3. Compares the word at DS:0013h with 0200h.
4. If the word is greater than 0200h, sets bit 7.
5. Writes the resulting byte back to CMOS B3h.

The comparison is strict: values greater than 0200h set bit 7; values less than or equal to 0200h leave it clear. In the surrounding BIOS context, 0040:0013h is the conventional-memory-size word, but this code uses DS:0013h; the segment assumption should be validated from the full caller/segment setup before treating that BDA identity as unconditional.

## 2. CMOS B3h bit 0: set at the end of the memory-address scan

At 27DEh–27FBh, after the loop advances DS in 0400h increments until DS+0400h equals 9000h, the BIOS reads CMOS B3h, sets bit 0 with `OR AL,1`, and writes the byte back.

This proves that bit 0 is set on this completion path and that other B3h bits are preserved. The precise semantic label of this flag is not established by the write alone; describe it as a memory-scan completion-associated flag, not as a specific memory-size or cache feature.

## 3. Confirmed B3h bit consumers

| Bit(s) | Address / path | Observed effect |
|---|---|---|
| 0 | 27E8h–27FBh | Set after the DS-segment scan reaches the 9000h boundary. |
| 1 | 1A35h–1A5Dh | Selects the "MHz DX2 CPU" label instead of "MHz CPU Clock". |
| 1 | 25EBh–25FAh | If the selected base-bank category is 5, substitutes row 7. |
| 1 | 417Fh–41A3h, 41B2h–41D1h | Participates in selection of BIOS diagnostic/status text. |
| 2 | 1AFBh–1B1Eh | Selects the longer B3h-dependent ALi index/value list at 8E4Eh–8E61h rather than the short list at 8E76h–8E79h. |
| 2 | 25C4h–2615h | Forces the +6 row bank in the shared 20-byte ALi table selector. |
| 2–3 | 1A60h–1A88h | Only if both bits are clear and SMSW AH is nonzero, clears bit 4 of ALi register 12h and writes 88h to ALi register 24h; always writes 55h to ALi register 03h on this path. |
| 2–3 | 1EECh–1F16h | With SMSW AH zero, selects one of two small ALi word lists: bit 2 chooses 8E62h–8E75h; bit 2 clear with bit 3 set chooses 8E7Ah–8E7Dh. |
| 2–3 | 41A5h–41DAh | Selects alternate diagnostic/status text branches, with additional tests of bit 1, INT 11h equipment flags and an OEM record lookup. |

The table lists only direct consumers recovered in this audit. It does not imply that unlisted bits are unused by external firmware, Setup records or runtime patches.

## 4. Interpretation limits

- B3h bit 7 is set from a greater-than-0200h comparison against DS:0013h; the BIOS does not encode the compared value into B3h.
- B3h bit 0 is set after the DS scan reaches its terminal segment boundary; the exact intended name/purpose is unknown.
- Bits 1–3 have multiple independent consumers. Their effects must not be collapsed into a single "DX2" or "protected-mode" flag.
- The status-string branches at 41A5h also depend on CPU mode and equipment/OEM checks; B3h alone does not determine the final string.
- No evidence in these routines establishes hardware semantics for the selected ALi register lists.

## Confirmed vs. unresolved

Confirmed:
- Exact B3h bit-7 read/modify/write and its strict 0200h threshold.
- Exact B3h bit-0 set operation at the end of the DS scan.
- Direct consumer sites and masks for bits 1, 2 and 3, as itemized above.
- Existing phase 38/39 CPU/cache interpretations remain distinct from these B3h consumers.

Unresolved:
- Whether DS:0013h is guaranteed to be BDA 0040:0013h at 11C8h in every entry path.
- Intended semantic names of B3h bits 0 and 7.
- Whether bits 4–6 have consumers outside the inspected in-ROM references or runtime extensions.
- Hardware meanings of the ALi register writes and B3h-selected tables.

## Reproducibility

Primary listing: `analysis/disasm/ami486_full_linear_16bit.disasm.txt`.
ROM SHA-256: `91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b`.
Key ranges: 11C8h–11DCh, 1AFBh–1B2Ah, 1A60h–1A8Eh, 1EC8h–1F18h, 25C4h–2628h, 27DEh–2800h, 4142h–41E3h.

