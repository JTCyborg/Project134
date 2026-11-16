# AMI486 semantic map — phase 36 (2026-11-16)

## Scope

This phase resolves the shared row selector used by the AUTO Config and POST A4 ALi programming routines at 2537h, 256Ah, 2588h and 25A6h. It also decodes the row layout beginning at 87A9h and traces the source of the selector returned by 25C4h.

The underlying listing is the 64 KiB linear 16-bit decode. The byte-level table interpretation is based on the ROM bytes represented in that listing; it does not imply that every byte in the ROM is executable code.

## 1. Shared row selector: 25C4h

25C4h reads CMOS B3h, then forms a row number from two sources:

1. If CMOS B3h bit 2 is set, it takes the BDA byte 0040:E2h, masks it to three bits, adds 6, and converts that row number to a byte offset by multiplying by 14h.
2. If CMOS B3h bit 2 is clear, it checks SMSW AX. A nonzero AH from SMSW AX (that is, any set bit in CR0 bits 8–15) selects the same BDA-derived row+6 path. This test does not directly test CR0.PE, which is bit 0 of AL. Otherwise it uses the BDA byte 0040:E2h masked to 3 bits directly.
3. In the non-offset path only, if the masked category is 5 and CMOS B3h bit 1 is set, it substitutes row 7.
4. The selected row number is multiplied by 14h (20 decimal) and returned in AX.

The resulting AX is therefore a 20-byte row stride, not a chipset register number.

## 2. Source of BDA 0040:E2h: 8F12h

8F12h calls 8F50h to obtain a measurement in AX. It then maps the measured value into a category DI using inclusive upper thresholds:

| Category written to 0040:E2h | Measured AX upper bound |
|---:|---:|
| 0 | 0010h |
| 1 | 0014h |
| 2 | 0019h |
| 3 | 0021h |
| 4 | 0028h |
| 5 | 0032h |
| 6 | 0042h |
| 7 | greater than 0042h |

The category is also output to POST port 80h. These are BIOS-defined measurement buckets; this phase does not assign physical CPU frequencies or MHz values to them.

8F50h prepares test regions at segment 1000h, offsets 0000h and 0800h, fills them with repeated words and a CBh terminator, then calls 9033h. 8F50h/9033h/9096h constitute the measurement machinery, but the present evidence is not sufficient to label the result as a calibrated frequency in MHz. Treat E2h as an opaque BIOS speed/performance category.

## 3. Table layout at 87A9h

The four consumers use four word fields in a common 20-byte record:

| Routine | Base address | Field offset in row | Target ALi index |
|---|---:|---:|---:|
| 2588h | 87A9h | +00h | 16h |
| 256Ah | 87ADh | +04h | 17h |
| 25A6h | 87B1h | +08h | 19h |
| 2537h | 87B5h | +0Ch | 20h |

Each routine calls 25C4h, adds the returned row offset to its own field base, loads a CS-relative word, and uses that word as a masked value when updating the corresponding ALi register. The row size is 14h bytes; the four field bases are four bytes apart within each row.

The table contains repeated and varying field values. The interpretation is a set of BIOS-selected per-category register bit patterns, not a table of direct complete register values: each routine preserves bits in the current ALi register and ORs in only selected bits from the row word.

## 4. Per-register update semantics

### 2537h — ALi register 20h

- Calls 25C4h; SI = 87B5h + row offset.
- Reads ALi register 20h through 8DCFh.
- If current bit 3 is set, advances SI by one byte before LODSW and masks AH with 07h.
- Otherwise loads the word at the original field position and computes AH &= AL.
- Saves the resulting AH in BH.
- Reads ALi register 20h again, preserves bits F8h, ORs the selected low three bits, and writes it through 8DDCh.

This routine has a two-way field selection dependent on the current ALi register 20h bit 3. The table word is not simply copied as the new register value.

### 256Ah — ALi register 17h

- Uses field 87ADh + row offset.
- Loads a word and computes AH &= AL.
- Preserves current register bits 7Ch and ORs the table-derived value.

### 2588h — ALi register 16h

- Uses field 87A9h + row offset.
- Loads a word and computes AH &= AL.
- Preserves current register bits F0h and ORs the table-derived value.

### 25A6h — ALi register 19h

- Uses field 87B1h + row offset.
- Loads a word and computes AH &= AL.
- Preserves current register bits 9Fh and ORs the table-derived value.

## 5. Call-site relationship

The linear listing shows these direct callers:

- 1C7Ch calls 2537h, followed by 1C7Fh calling 256Ah in the AUTO Config path.
- 1F57h calls 2588h and 1F5Ah calls 25A6h in the later POST A4 AUTO Config branch.
- 23FAh also calls 2537h after 23F7h calls 8F12h.

Thus the same selector and row table are reused by both the earlier AUTO Config setup and a later POST A4 stage. The 8F12h measurement is refreshed at the listed call sites rather than relying solely on a previously cached category.

## Confirmed vs. unresolved

Confirmed from instruction flow and bytes:
- 25C4h returns a 20-byte row offset.
- BDA 0040:E2h is a three-bit category produced by 8F12h.
- CMOS B3h bit 2 selects the +6 row bank; bit 1 supplies a special row-5-to-row-7 substitution in the base bank.
- The four table fields drive masked updates to ALi registers 16h, 17h, 19h and 20h.
- ALi register 20h bit 3 selects an alternate byte within its table field.

Not established:
- The physical unit represented by the 8F12h measurement.
- The hardware meaning of ALi registers 16h/17h/19h/20h and their individual bits.
- Whether the +6 bank corresponds to a particular CPU family, board revision, or chipset mode. The code proves only the CMOS/PE conditions and row arithmetic.

## Reproducibility

Primary source: `analysis/disasm/ami486_full_linear_16bit.disasm.txt`, ROM SHA-256 `91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b`.

Key ranges: 2537h–25C3h, 25C4h–2628h, 8F12h–8F4Fh, 8F50h–9032h, and table bytes 87A9h onward.
