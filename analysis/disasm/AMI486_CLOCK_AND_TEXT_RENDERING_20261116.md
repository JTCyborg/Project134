# AMI486 BIOS date/time and numeric text-rendering helpers — 2026-11-16

Source: ami486.bin, 65,536 bytes. Decode windows are in ami486_candidate_windows_20261116.txt.

## 1. Date/time access

### 6774h — RTC date read/display path

The routine calls BIOS INT 1Ah with AH=04h (Read RTC Date). It retries on CF, then processes the returned CH/CL/DH/DL fields and validates the date components before displaying them. It uses the display helpers below to render the values at fixed cursor positions. This is a BIOS RTC date path, not a CMOS register read by direct I/O.

### 67AEh — RTC time read/display path

The routine calls BIOS INT 1Ah with AH=02h (Read RTC Time), retries on CF, processes CH/CL/DH fields and displays the resulting hour/minute/second values. The exact arithmetic transform applied to the packed fields is isolated at 67D8h and is not yet assigned a standard BCD-conversion name.

### 6700h — field/grid display routine

The routine uses BP-relative fields at +06h/+07h/+08h, calls 6805h for sequential numeric labels and then displays the RTC fields at cursor coordinates including row 06h, columns 17h/1Ch/21h. It appears to support a date/time selection or editing screen; its caller and exact field meanings remain open.

## 2. Numeric and character rendering

| Entry | Observed behavior |
|---:|---|
| 6800h | Short register-transfer/return entry; not the main number renderer |
| 6805h | Iterates SI toward DI, prints sequential decimal numbers using 6841h, advances cursor positions and wraps to another row at the right edge. Uses BL as the display attribute and a BP-relative selected value for highlight. |
| 6841h | Decimal conversion/output helper; recursively divides the value into decimal digits and emits them through the character renderer. |
| 6860h | Reads the character/attribute at the current cursor with INT 10h AH=08h, merges the requested attribute and writes the character using INT 10h AH=09h. |
| 68B0h | Displays AL as two hexadecimal digits by extracting high and low nibbles. |
| 68C8h | BIOS INT 10h character/attribute output helper; writes a character at the current cursor and preserves/restores registers. |
| 67D8h | Nibble arithmetic transform: low nibble plus twice the high nibble. It is used by the RTC display path, but should not yet be called a standard BCD-to-binary conversion. |
| 68E2h | RET stub, not a formatting routine. |

The 6805h renderer is called from 6700h at 6708h, 6716h and 6721h. The direct callers and the RTC INT 1Ah services make a date/time UI role plausible, but the full screen layout and caller chain are not yet established.

## 3. Remaining work

1. Trace callers of 6700h, 6774h and 67AEh to confirm the UI entry and BP frame fields.
2. Determine why 67D8h uses high-nibble ×2 + low-nibble on the packed RTC fields.
3. Confirm the exact wrap/highlight behavior and cursor layout of 6805h.
4. Cross-reference the date/time display helpers with the 0Bxx Setup callback chain, without assuming they are the same execution path.

No claim is made that this region is a complete Setup screen or that all date/time editing behavior is mapped.
