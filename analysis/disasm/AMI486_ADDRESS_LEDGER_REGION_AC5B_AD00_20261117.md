# AMI486 address ledger — Keyboard scan-code translation table prefix and AC60h map (AC5Bh–ACFFh)

Date: 2026-11-17  
Repository: JTCyborg/Project134, branch main  
Source: ami486.bin, 65,536 bytes  
SHA-1: 480c7520c93e6c7ed437cf3ad214da7503f82ec6  
ROM SHA-256 recorded by the existing ledger: 91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b

## 1. Corrected boundary after ATA routine

The candidate seed at AC00h previously used the default 80h-byte window and decoded bytes AC5Bh–AC7Fh as instructions. The ATA identify/read-transfer candidate ends at AC5Ah with RET. The following bytes are data:

- AC5Ah: C3 — RET
- AC5Bh: 00
- AC5Ch–AC5Fh: F0 78 79 7A
- AC60h: start of the confirmed keyboard translation table

The AC00h code window is now limited to 5Bh bytes, ending at AC5Ah. Data begins at AC5Bh.

## 2. Confirmed AC60h keyboard table

The keyboard handler at B031h loads BX=AC60h before calling its mapping helper. This is a direct pointer reference to the table base, independent of the separate AD00h–AE5Fh keyboard translation region already documented in AMI486_KEYBOARD_SUBSYSTEM_20261116.md.

The 160-byte table at AC60h–ACFFh contains scan-code-like values and marker bytes:
- F0h appears as a repeated prefix/separator, consistent with the F0h break-prefix handling already decoded in the keyboard IRQ path.
- FFh appears in repeated positions as a sentinel/unused-entry marker.
- Other values include contiguous groups such as 78h–83h, 10h–19h, 1Eh–26h, 2Ch–32h, 68h–71h, and the function-key scan-code group 01h–0Ch.

These patterns are consistent with a keyboard scan-code translation table. The exact row/column layout, modifier columns and mapping from each source scan code to the BIOS key word remain unresolved.

## 3. Adjacent prefix/header bytes — AC5Bh–AC5Fh

The five bytes preceding the confirmed AC60h base are retained as data with the table range. AC5Bh is 00h and AC5Ch–AC5Fh are F0h 78h 79h 7Ah. No separate consumer for this five-byte prefix has yet been identified, so it is not assigned a semantic field name.

## 4. Relation to the AD00h–AE5Fh tables

The existing AD00h–AE5Fh keyboard translation data remains a separate data range. It contains recognizable QWERTY/ASDF/ZXCVBNM and numeric-key sequences and is referenced from multiple keyboard handler paths. This pass does not merge the AC60h and AD00h tables into one assumed layout; both are retained as distinct tables until their selector/column logic is proven.

## 5. Generator integration

The candidate generator now:
- limits the ATA candidate at AC00h to 5Bh bytes (AC00h–AC5Ah);
- adds AC5Bh–ACFFh as keyboard translation data;
- preserves the existing AD00h–AE5Fh keyboard translation data range.

Generator update commit: 7227215784dca6c9ffd34174cca3e3adaeb92a66.

The manifest has not yet been regenerated after this correction. No new global coverage percentage or CI pass is claimed.

## 6. Remaining uncertainties

- Whether AC5Ch–AC5Fh is a table header, prefix sequence or separate small mapping.
- Exact AC60h table subtable boundaries and selector logic.
- Exact mapping of scan-code entries to BIOS key words and modifier states.
- Whether AC60h and AD00h are alternate layouts, different scan-code sets or separate stages of one translation pipeline.
