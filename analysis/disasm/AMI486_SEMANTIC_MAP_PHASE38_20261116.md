# AMI486 semantic map — phase 38 (2026-11-16)

## Scope

This phase follows the measured category beyond the ALi timing-table code and resolves the neighboring CPU-speed display path at 19B0h–1A8Eh. It also clarifies the exact mode gates in 25C4h and the independent chipset setup at 1A60h.

## 1. BIOS display table: 19C2h

The byte table beginning at 19C2h contains these seven values:

| Category index | Byte | Decimal |
|---:|---:|---:|
| 0 | 10h | 16 |
| 1 | 14h | 20 |
| 2 | 19h | 25 |
| 3 | 21h | 33 |
| 4 | 28h | 40 |
| 5 | 32h | 50 |
| 6 | 42h | 66 |

The adjacent NUL-terminated strings include:
- 19C9h: " KB CACHE MEMORY"
- 19DCh: "MHz CPU Clock"
- 19ECh: "MHz DX2 CPU"

The status-display routine at 1A24h reads the category from BDA 0040:E2h, uses it as an index into the 19C2h byte table, prints the resulting numeric value, and chooses the label at 19DCh or 19ECh according to CMOS B3h bit 1. The code therefore explicitly labels the displayed values as CPU clock MHz or DX2 CPU MHz. Category 7 is outside the seven-byte numeric table; it indexes the following string byte rather than a valid numeric entry, so this phase does not assign a numeric MHz value to category 7.

This is a display/label lookup, distinct from the measurement itself. The measurement remains the PIT2 DIV timing differential established in phase37. The values 16, 20, 25, 33, 40, 50 and 66 are the BIOS's displayed nominal labels for categories 0–6, not direct readings from a frequency counter.

## 2. AUTO Config gate around the display

At 1A1Dh the routine calls 29EDh, the AUTO Config state test. When AUTO Config is enabled (nonzero result), it proceeds to read BDA 0040:E2h and display the category-derived MHz value. When AUTO Config is disabled, it branches to 1A60h and skips this category display path.

This confirms that the measured category is not merely an internal timing-table selector: the BIOS also uses it for a user-visible CPU-speed indication in the AUTO Config path.

## 3. CMOS B3h bit 1: two separate uses

CMOS B3h bit 1 has two independently confirmed effects:

- In the display path, it selects the label "MHz DX2 CPU" rather than "MHz CPU Clock".
- In 25C4h, only when the ordinary (non-offset) row bank is selected and the measured category equals 5, it substitutes row 7 for row 5.

Do not conflate these two uses: the label selection is unconditional within the display path, while the table-row substitution is conditional on category 5 and the base-bank path.

## 4. Exact 25C4h bank-selection conditions

25C4h reads CMOS B3h and applies this decision:

1. If B3h bit 2 is set, use category + 6.
2. Otherwise execute SMSW AX. If AH is nonzero (any CR0 bit 8–15 set), also use category + 6.
3. Only if both tests are false, use the base category. In that base-bank case, if category is 5 and B3h bit 1 is set, replace it with 7.
4. Multiply the final row number by 14h to return the 20-byte table offset.

The SMSW condition is a test of CR0's high byte, not a direct test of CR0.PE (bit 0).

## 5. Separate chipset action at 1A60h

When the display routine takes the AUTO Config-disabled branch, it reaches 1A60h:
- Reads CMOS B3h and tests bits 2–3 (mask 0Ch).
- If either bit is set, executes SMSW and tests AH.
- If that CR0-high-byte test is also nonzero, reads ALi register 12h, clears bit 4, writes it back, then writes 88h to ALi register 24h.
- Regardless of those conditions, writes 55h to ALi register 03h and returns.

This is a separate chipset mode/setup path. The instruction flow proves the register writes and gates but not the hardware meanings of ALi registers 12h, 24h or 03h.

## Confirmed vs. unresolved

Confirmed:
- BIOS display values for categories 0–6 are 16, 20, 25, 33, 40, 50 and 66, with explicit CPU Clock / DX2 CPU MHz labels.
- CMOS B3h bit 1 selects the displayed label and separately controls the special base-bank category-5 row substitution.
- AUTO Config state gates the category display path.
- 25C4h selects the +6 bank if CMOS B3h bit 2 or CR0 bits 8–15 are nonzero; otherwise it uses the base bank with the category-5 exception.
- The 1A60h ALi writes and their exact branch conditions.

Unresolved:
- Whether the seven displayed nominal MHz labels are intended as exact supported CPU clocks or rounded marketing categories.
- Why category 7 has no corresponding numeric entry in the table.
- Hardware meanings of the ALi registers written at 1A60h.

## Reproducibility

Primary listing: `analysis/disasm/ami486_full_linear_16bit.disasm.txt`.
ROM SHA-256: `91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b`.
Key ranges: 19B0h–19F9h, 19FBh–1A8Eh, 25C4h–2628h.
