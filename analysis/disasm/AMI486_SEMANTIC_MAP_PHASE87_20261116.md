# AMI486 semantic map — phase 87 (2026-11-16)

## 1. Prompt strings identify the form unambiguously

The two string bases selected by the shared callback routine are readable ROM strings:

At 75D2h:
```text
 Month : Jan, Feb,.....Dec
 Date  : 01, 02, 03,...31
 Year  : 1901, 1902,...2099
```

At 7625h:
```text
 Time is 24 hour format:-
 Hour:(00-23), Minute:(00-59), Second:(00-59)
 (1:30 AM = 01:30:00),   (1:30 PM = 13:30:00)
```

This confirms the six 63xx callbacks are the BIOS Setup date/time editor. The string content removes the earlier uncertainty about whether these were generic configuration fields.

## 2. Six callback identities now resolved

| Callback | Prompt family | Field | Evidence |
|---:|---|---|---|
| 6373h | Date | Month | Uses date prompt base 75D2h; converts input to DH and wraps at 1/12 |
| 63C9h | Date | Day | Uses date prompt; converts input to DH and wraps at 1/31 |
| 641Fh | Date | Year | Uses date prompt; bounds/rollover around 1901h, 1999h, 2000h and 2099h |
| 6485h | Time | Hour | Uses time prompt base 7625h; updates CH with 00h..23h wrap |
| 64E3h | Time | Minute | Uses time prompt; updates CL with 00h..59h wrap |
| 6541h | Time | Second | Uses time prompt; enters common time-update path and retries the callback |

The year callback contains two directional paths. One path wraps 2099h to 1901h and the other wraps 1901h to 2099h; 1999h/2000h are handled specially to preserve the century transition. The hour callback similarly wraps 23h to 00h and 00h to 23h. Minute wraps 59h to 00h and 00h to 59h.

## 3. BIOS RTC service usage

The handlers call the standard BIOS INT 1Ah date/time services:

- AH=04h appears in the date-validation path at 6774h (read RTC date).
- AH=05h is issued by the date setter/conversion path at 660Fh.
- AH=02h appears in the time-validation path at 67AEh (read RTC time).
- AH=03h is issued by the time callbacks (for example 64BDh and 64D8h; the seconds path at 6565h).

This is consistent with the standard BIOS interface: date reads/updates are separated from time reads/updates. The callbacks are not directly accessing CMOS ports; they use BIOS RTC services.

## 4. Confirmed display/input behavior

- 656Eh and 6573h select date and time explanatory strings respectively.
- The date string documents month/day/year ranges and the 1901–2099 year range.
- The time string explicitly states 24-hour format and the valid hour/minute/second ranges.
- 659Bh is an alternate entry into a shared display path; 65A7h uses INT 10h cursor/read-character/write-character services to redraw a character cell.
- The key-input helper at 08CDh uses INT 16h and interprets scan-code values for navigation/editing. The form therefore uses BIOS keyboard and video services, not direct keyboard-controller or VGA port access.

## 5. Scope and remaining work

The six callbacks in the 63xx range are now semantically identified as Month, Day, Year, Hour, Minute and Second. This closes one complete indirect callback family.

Still open in this Setup form:
- callback targets 0319h, 0351h, 02DBh, 02F1h and 026Fh;
- exact shared helper contracts at 05E0h/05EEh, 08C8h/08CDh, 6774h and 67AEh;
- whether the RTC update helper at 6616h also updates the BIOS tick/date rollover state.

Next work should close the remaining Setup editor callbacks and the helper contracts, then move to another low-ROM range.
