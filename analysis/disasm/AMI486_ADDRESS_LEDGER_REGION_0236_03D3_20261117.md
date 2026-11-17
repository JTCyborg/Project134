# AMI486 address ledger — Standard CMOS Setup field handlers 0236h–03D3h

Date: 2026-11-17  
Repository: JTCyborg/Project134, branch main  
ROM: ami486.bin, 65,536 bytes; SHA-256 91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b

## 1. Relationship to Standard CMOS Setup

The main Standard CMOS Setup handler is the menu target at 00ECh. It builds a BP-relative configuration record and iterates a 16-entry, four-byte descriptor/handler table at CS:0AF5h. Each entry supplies a descriptor pointer and a near handler offset; the common dispatcher at 05B4h invokes the handler indirectly.

The table entries that enter this interval are:
- 0B1Dh → 0319h
- 0B25h → 0351h
- 0B2Dh → 02DBh
- 0B35h → 02F1h

The code in this interval implements the video/keyboard options, enable/disable field and fixed-disk type selectors used by that Setup page.

## 2. Video display type — 0236h

0236h reads the video-related bits from BP+14h, maps the current value through the lookup at CS:0ACBh using helper 0AADh, and displays the options string at CS:769Dh, coordinate 0C16h.

The visible options are:
- Monochrome
- Color 40x25
- VGA/PGA/EGA
- Color 80x25
- Not Installed

The handler writes the selected display type back into bits 4–5 of BP+14h and preserves/updates bit 3 as part of the same field state. The exact meaning of bit 3 is not assigned beyond the observed bit manipulation.

## 3. Keyboard test option — 026Fh

026Fh displays the options string at CS:77D7h, coordinate 0D16h:
- Installed: Test keyboard
- Not Installed: Do not test keyboard

It uses DI=14h and AL=04h to address bit 2 of the BP-relative configuration byte. The selected state is rendered through the descriptor tables at CS:0BA5h/0BADh and the common field dispatcher at 05B4h.

## 4. Enabled/Disabled field — 0288h/028Eh/02A4h

0288h and 028Eh are alternate display/input entries using:
- CS:74F6h: "Enabled"
- CS:7502h: "Disabled"

Both enter the shared selection loop at 02BAh. 02A4h is the common bit-update helper: it calls 05B4h to render/select the option, then clears or sets the selected bit in the BP-relative configuration byte. The bit operation targets BP+14h, bit 6.

The exact higher-level setting represented by this Enabled/Disabled field is not established from this callback alone; keep it as a bit-6 option rather than guessing a feature name.

The 16-byte block at 0294h–02A3h is an eight-word internal offset/dispatch table:
029Ch, 0288h, 029Ch, 0288h, 0294h, 028Eh, 0294h, 028Eh.
Its precise consumer is not yet proven, so it is classified as data and not decoded linearly.

## 5. Four fixed-disk type selectors

The help text at CS:7750h states:
- FIXED type = 01h–46h
- USER defined type = 47h
- For type 47h, enter cylinder, head, WPcom, landing zone and sector values.

The handlers edit four packed nibbles in the BP-relative disk configuration record:

| Entry | Field | Storage |
|---|---|---|
| 02DBh | Fixed-disk type selector | High nibble of BP+10h |
| 02F1h | Fixed-disk type selector | Low nibble of BP+10h |
| 0319h | Fixed-disk type selector | High nibble of BP+12h |
| 0351h | Fixed-disk type selector | Low nibble of BP+12h |

Each handler extracts the current nibble, invokes the shared type chooser, and merges the selected value back without disturbing the other nibble. The 0319h and 0351h entries are explicitly referenced by the 16-entry field table at 0AF5h.

## 6. Shared fixed-disk type chooser — 0367h/03B8h

0367h is the common type-selection routine. It displays the help text at CS:7750h and uses the screen coordinate supplied in DX. The selection cycles through the hexadecimal fixed types 0–0Fh and the special user-defined type 2Fh (decimal 47).

It handles the observed selector/navigation scan codes (including AH=49h, 3Ch and 3Dh), updates the selection, and calls the shared prompt/refresh helpers at 05C4h and 05CFh. 03B8h is an alternate entry into the same adjustment logic for the wrap/decrement path.

## 7. Data/code boundary and generator integration

The interval is split as follows:
- 0236h–0293h: executable field handlers and option-entry stubs.
- 0294h–02A3h: 16-byte, eight-word dispatch/offset table; semantics unresolved.
- 02A4h–03D3h: executable bit-update, fixed-disk type selection and return paths.

The candidate generator now seeds the video, keyboard-test, Enabled/Disabled, four fixed-disk nibble handlers and shared type chooser separately. The 0294h–02A3h table is a data range.

GitHub Actions run 44086705207 completed successfully. The manifest reports 851 candidate windows, 240 data ranges, 42,274 unique code-window bytes, 19,721 unique data-range bytes, 293 overlap bytes, and a 61,702-byte union (94.15%). There are 61 uncovered intervals; the next largest is 81EEh–8377h (394 bytes).
