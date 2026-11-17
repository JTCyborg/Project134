# AMI486 address ledger — ATA command tail and AC60h keyboard translation map (AC5Fh–ACFFh)

Date: 2026-11-17  
Repository: JTCyborg/Project134, branch main  
Source: ami486.bin, 65,536 bytes  
SHA-1: 480c7520c93e6c7ed437cf3ad214da7503f82ec6  
ROM SHA-256 recorded by the existing ledger: 91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b

## 1. Corrected boundary after ATA command helper

The earlier data boundary at AC5Bh was incorrect. The ATA recalibrate helper beginning at AC34h continues through AC5Eh:
- AC5Bh–AC5Dh: CALL A6DCh
- AC5Eh: RET
- AC5Fh: 00h, the single prefix/header byte before the confirmed keyboard table
- AC60h: start of the confirmed keyboard translation table

The AC00h candidate remains limited to 5Bh bytes (AC00h–AC5Ah). The separate AC34h helper is documented in [AMI486_ADDRESS_LEDGER_REGION_ABAD_AC5F_20261117.md](AMI486_ADDRESS_LEDGER_REGION_ABAD_AC5F_20261117.md). Data now begins at AC5Fh.

## 2. Confirmed AC60h keyboard table

The keyboard handler at B031h loads BX=AC60h before calling its mapping helper. This is a direct pointer reference to the table base, independent of the separate AD00h–AE5Fh keyboard translation region already documented in AMI486_KEYBOARD_SUBSYSTEM_20261116.md.

The 160-byte table at AC60h–ACFFh contains scan-code-like values and marker bytes:
- F0h appears as a repeated prefix/separator, consistent with F0h break-prefix handling in the keyboard IRQ path.
- FFh appears in repeated positions as a sentinel/unused-entry marker.
- Other values include contiguous groups such as 78h–83h, 10h–19h, 1Eh–26h, 2Ch–32h, 68h–71h, and the function-key scan-code group 01h–0Ch.

These patterns are consistent with a keyboard scan-code translation table. The exact row/column layout, modifier columns and mapping from each source scan code to the BIOS key word remain unresolved.

## 3. Adjacent prefix byte — AC5Fh

AC5Fh is the single 00h byte preceding the confirmed AC60h table base. It remains classified as data with the table range; no separate consumer has yet been identified.

## 4. Relation to the AD00h–AE5Fh tables

The existing AD00h–AE5Fh keyboard translation data remains a separate data range. It contains recognizable QWERTY/ASDF/ZXCVBNM and numeric-key sequences and is referenced from multiple keyboard handler paths. This pass does not merge the AC60h and AD00h tables into one assumed layout; both are retained as distinct tables until their selector/column logic is proven.

## 5. Generator integration

The candidate generator:
- limits the ATA candidate at AC00h to 5Bh bytes (AC00h–AC5Ah);
- adds AC5Fh–ACFFh as keyboard translation data;
- preserves the existing AD00h–AE5Fh keyboard translation data range.

The corrected AC34h ATA recalibrate code window is tracked separately in the ABADh–AC5Eh ledger. The generator update is pending commit and the candidate listing must be regenerated after the boundary correction.

## 6. Remaining uncertainties

- Exact AC60h table subtable boundaries and selector logic.
- Exact mapping of scan-code entries to BIOS key words and modifier states.
- Whether AC60h and AD00h are alternate layouts, different scan-code sets or separate stages of one translation pipeline.
