# AMI486 semantic map — phase 24 (2026-11-16)

## 1. Corrected interpretation of stock descriptor bytes at 8250h–826Fh

The linear disassembly around 8200h is data, not a continuous instruction stream. Reading the decoded byte stream at the fixed descriptor offsets gives these stock values:

| Offset | Stock bytes | Direct effect |
|---|---|---|
| 8250h–8255h | 01 00 00 00 00 00 | 8BA3h enters ALi helper 8D09h; no 8042 command or port RMW configured |
| 8258h–825Dh | 00 00 00 00 00 00 | 8C4Dh has no active descriptor operation |
| 825Eh–825Fh | 4E 00 | 8B2Dh compares AL against 4Eh for this descriptor family |
| 8260h–8265h | 01 00 00 00 00 00 | 8B5Eh enters ALi helper 8D39h; no 8042 command or port RMW configured |
| 8268h–826Dh | 00 00 00 00 00 00 | 8BE8h has no active descriptor operation |
| 826Eh–826Fh | 4A 00 | 8B2Dh compares AL against 4Ah for this descriptor family |
| 8281h | 00 | bit 6 bypass is clear in the stock image |

Important correction to phase 23: the descriptor blocks are not all inactive in the stock ROM. Groups 8250h and 8260h are active because their first bytes are 01h. Groups 8258h and 8268h are zero-filled.

## 2. What the two active stock descriptor operations do

8BA3h sees CS:[8250h]=1 and calls 8D09h:
- selects ALi index 18h, reads it, sets bit 2 and writes it, then clears bit 2 and writes it;
- selects ALi index 23h, reads it, sets bit 1 and writes it;
- writes 03h to ALi index 55h.

8B5Eh sees CS:[8260h]=1 and calls 8D39h:
- selects ALi index 23h, reads it, clears bit 1 and writes it;
- writes 03h to ALi index 55h.

Thus the two stock descriptor operations form a set/clear pair around ALi register 23h bit 1, with a separate pulse on register 18h bit 2 in the set path. Do not label these as a named chipset feature without an authoritative ALi1429 register map or further code evidence.

## 3. Keyboard intercept: 8AEEh–8B5Dh

8AEEh checks AH=4Fh, the BIOS INT 15h keyboard intercept function. It then reads BDA byte 0040:0017h and requires (flags AND 0Ch) = 0Ch before calling 8B2Dh with AL preserved.

8B2Dh disables interrupts and compares the incoming AL scan code against the fixed selector bytes:
- 4Ah -> descriptor family 8260h–8265h; dispatches 8BE8h if BDA flags [0017h]&3 are nonzero, otherwise 8B5Eh.
- 4Eh -> descriptor family 8250h–8255h; dispatches 8C4Dh if BDA flags [0017h]&3 are nonzero, otherwise 8BA3h.

The values 4Ah and 4Eh correspond to the standard Set-1 keypad minus and keypad plus scan codes, respectively. This identifies the intercept as keypad +/- handling under the specified BDA modifier-state gate. The code evidence establishes the scan-code mapping; the precise user-visible function of the hotkeys is still unresolved.

## 4. Separate POST path using the same active descriptors

At 1E1Ch the BIOS loads the byte at CS:B517h (stock byte 0Fh) as a Setup record key, calls 8300h to decode the corresponding option, then:
- nonzero decoded value -> calls 8BA3h (active 8250h descriptor);
- zero decoded value -> calls 8B5Eh (active 8260h descriptor).

This is a POST-time configuration decision, separate from the INT 15h AH=4Fh scan-code intercept. The byte at B517h is a key into the Setup record lookup mechanism, not itself a CMOS value.

## 5. 8281h bypass state

Stock CS:[8281h] is 00h. Therefore bit 6 tests at 8B11h, 8BE8h, 8C41h, 8C4Eh, 8CA6h, 9150h, 91FBh, D657h, D724h and F06Ah all take their clear-bit paths in the unmodified ROM image. F43Dh tests bit 7 separately.

Static linear disassembly still contains no direct write to CS:[8281h]. Its stock value is known, but its runtime mutation/patch source is not.

## 6. Confidence and unresolved points

Confirmed: exact stock descriptor bytes listed above; groups 8250h and 8260h are active in the ROM image; keypad scan codes 4Ah/4Eh select the two descriptor families; 8AEEh gates the intercept on INT 15h AH=4Fh and BDA flags; 1E1Ch is a separate POST path that selects between the same two active descriptor handlers.

Unresolved: exact function presented to the user by keypad +/-; semantic name of the Setup record selected by key 0Fh at B517h; whether firmware patches CS:[8281h] after reset, since no direct static write is present; exact electrical meaning of ALi1429 register 18h bit 2, register 23h bit 1 and register 55h value 03h.

## 7. Recognition accounting

Linear 16-bit decode coverage remains 65,536/65,536 bytes (100%). Semantic recognition percentage is still withheld until a complete byte-classification ledger is generated. This phase corrects the stock data interpretation and identifies two active descriptor operations; it is not a whole-ROM semantic percentage.