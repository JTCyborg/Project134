# AMI486 address ledger — RTC date/time editor 639Ch–6615h

Date: 2026-11-17  
Repository: JTCyborg/Project134, branch main  
ROM: ami486.bin, 65,536 bytes; SHA-256 91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b

## 1. Region role and entry context

The 634-byte interval 639Ch–6615h is executable 16-bit BIOS Setup code for editing RTC date and time. It is a continuation of the larger field-edit routine beginning at 6373h (just before this uncovered interval); 639Ch is not claimed as an independently called function entry.

The preceding code at 6373h sets screen coordinate 051Bh and invokes the date-field editor. The continuation handles the remaining date fields and all three time fields. The firmware reads and writes the RTC through INT 1Ah:
- AH=04h: read date
- AH=05h: set date
- AH=02h: read time
- AH=03h: set time

## 2. Date editor

The visible date fields are:
- Day: screen coordinate 051Bh (the first field is set up at 6373h).
- Month: coordinate 051Fh, editor loop at 63C9h.
- Year: coordinate 0522h, editor loop at 641Fh.

The month and year loops read the current date through helper 6774h, adjust the selected field, validate it, and return to the editor. The month path wraps between 01 and 12. The year path is constrained to 1901–2099 and wraps between the configured endpoints.

The strings used by the field editor are outside this region:
- CS:75D2h: "Month : Jan, Feb,.....Dec", "Date : 01, 02, 03,...31", "Year : 1901, 1902,...2099".
- CS:7625h: "Time is 24 hour format", "Hour:(00-23), Minute:(00-59), Second:(00-59)", plus 12-hour/24-hour examples.

The editor recognizes keyboard scan code 49h as a field-navigation/control path and scan code 01h as an exit/cancel path. These are scan-code comparisons in the BIOS input helper; preserve the numeric values rather than replacing them with guessed key labels.

## 3. Time editor

The time fields are:
- Hour: coordinate 0616h, editor loop at 6485h.
- Minute: coordinate 061Bh, editor loop at 64E3h.
- Second: coordinate 0620h, editor loop at 6541h.

Each loop reads the current RTC time through 67AEh, adjusts the selected BCD field, and writes it through INT 1Ah/AH=03h. The UI explicitly uses 24-hour format: hour 00–23, minute 00–59, second 00–59.

## 4. Date validation and RTC helpers

65BFh and 65C4h are two entry variants into the shared day-of-month validator at 65C7h:
- 65BFh enters with CH=0.
- 65C4h enters with CH=1.

The validator receives month in DH, day in DL and year in CL (packed BCD). It chooses the month's maximum day:
- February: 28 days, or 29 when the binary year is divisible by four.
- Months 1–7: odd months have 31 days, even months 30, with February handled separately.
- Months 8–12: even months have 31 days, odd months 30.

If the current day exceeds the selected maximum, the CH mode chooses whether to clamp to the maximum or reset to day 1. The helper then writes the corrected date with INT 1Ah/AH=05h. The leap-year test is year modulo four; there is no separate century exception, while the accepted year range stops at 2099.

6774h reads RTC date through INT 1Ah/AH=04h, converts packed BCD through 68E2h, and validates year 1901–2099, month 1–12 and day 1–31. Invalid values are replaced by 1980-01-01.

67AEh reads RTC time through INT 1Ah/AH=02h, converts packed BCD through 68E2h, and validates hour <=23, minute <=59 and second <=59. Invalid values are replaced by 00:00:00.

## 5. Field rendering helpers

| Entry | Behavior | Direct CALL references |
|---|---|---|
| 656Eh | Date field editor/display entry using format text at CS:75D2h | 6379h, 63CFh, 6425h |
| 6573h | Time field editor/display entry using format text at CS:7625h | 648Bh, 64E9h, 6547h |
| 6576h | Shared display/input loop; calls 05E0h and character renderer 65A7h | fall-through from 656Eh/6573h |
| 659Bh | Alternate field refresh path | 638Ch, 63E2h, 6438h, 649Eh, 64FCh, 655Ah |
| 65A7h | Draws characters through INT 10h cursor/read/write services | 075Ch, 0768h, 6583h |
| 65BFh | Day-validator entry with CH=0 | 641Ah |
| 65C4h | Day-validator entry with CH=1; shared validator begins at 65C7h | 63ABh, 63C4h, 6401h, 645Fh, 6480h |

The common character renderer uses INT 10h/AH=02h to position the cursor, AH=08h to read the current character/attribute, and AH=09h to write the replacement character. It preserves the selected color/attribute bits and advances the cursor.

## 6. Calendar display relationship

The adjacent display routine at 6616h is called from 6363h and from the date/time update loops (64C1h, 64DEh, 651Fh, 653Ch and 6569h). It:
- reads date/time through INT 1Ah;
- calculates the weekday using two seven-byte lookup tables at CS:6164h and CS:616Bh;
- displays weekday abbreviations from CS:7829h ("Sun" through "Sat");
- displays month abbreviations from CS:7845h ("Jan" through "Dec");
- draws the date and 24-hour time fields at the corresponding screen coordinates.

The strings at 7829h/7845h and the small calendar lookup tables at 6164h/616Bh are already represented as data in the candidate map; they must not be decoded as instructions.

## 7. Generator integration

The candidate generator now includes the 639Ch continuation and bounded entries for the date/time field helpers at 656Eh, 6573h, 6576h, 659Bh, 65A7h, 65BFh and 65C4h. No data range is added inside 639Ch–6615h; this interval is instruction code.

GitHub Actions run 44084872234 completed successfully. The manifest reports 819 candidate windows, 238 data ranges, 39,724 unique code-window bytes, 19,703 unique data-range bytes, 293 overlap bytes, and a 59,134-byte union (90.23%). There are 66 uncovered intervals; the next largest is AF86h–B1E8h (611 bytes).

## 8. Next work

1. Continue with AF86h–B1E8h (611 bytes), the largest remaining uncovered interval.
2. Map the caller/menu path that enters the date/time editor at 6373h.
3. Verify the keyboard event semantics for scan codes 49h and 01h from the helper paths at 05E0h/08CDh.
4. Preserve the RTC BCD validation, 1901–2099 year range, leap-year handling and 24-hour display when implementing the independent BIOS.
