# AMI486 semantic map — phase 86 (2026-11-16)

## 1. The six 63xx callbacks share one real helper family

The six indirect targets found in phase85 are not independent device-port handlers. Their first instructions load small parameter blocks into DX/CX and call into a shared UI/input path:

| Callback | Initial DX | Initial CX | Shared entry |
|---:|---:|---:|---:|
| 6373h | 051Bh | 0005h | 656Eh |
| 63C9h | 051Fh | 0004h | 656Eh |
| 641Fh | 0522h | 0006h | 656Eh |
| 6485h | 0616h | 0004h | 6573h |
| 64E3h | 061Bh | 0004h | 6573h |
| 6541h | 0620h | 0004h | 6573h |

656Eh and 6573h are alternate entries in one routine:

```asm
656E  MOV SI,75D2h
6571  JMP 6576h
6573  MOV SI,7625h
6576  PUSH SI
6577  CALL 05E0h
657A  POP SI
657B  MOV BL,[E1A3h]
657F  MOV BH,00h
6581  PUSH CX
6582  PUSH DX
6583  CALL 65A7h
6586  POP DX
6587  POP CX
6588  CALL 08CDh
658B  PUSHF
658C  CMP AH,3Ch
658F  JZ 6598h
6591  CMP AH,3Dh
6594  JZ 6598h
6596  POPF
6597  RET
6598  POPF
6599  JMP 6576h
```

The routine selects one of two CS-resident text strings, calls a shared display routine, invokes the input/validation helper at 08CDh, and repeats for the two special AH return values 3Ch/3Dh. The two entries therefore distinguish two prompt/string sets; the exact user-visible strings still need decoding from 75D2h and 7625h.

## 2. Alternate entry at 659Bh and its display helper

The callback's second stage calls 659Bh. This is an intentional alternate entry inside the byte sequence that is reached from the 6598h loop path; do not decode it by starting at 659Ah.

```asm
659B  CALL 05EEh
659E  MOV BL,[E1A2h]
65A2  CALL 08C8h
65A5  MOV BH,00h
65A7  PUSH AX
65A8  MOV AH,02h
65AA  INT 10h
65AC  INC DL
65AE  MOV AH,08h
65B0  INT 10h
65B2  PUSH CX
65B3  MOV CX,0001h
65B6  MOV AH,09h
65B8  INT 10h
65BA  POP CX
65BB  LOOP 65A7h
65BD  POP AX
65BE  RET
```

65A7h writes a one-character cell at successive cursor columns, reading the current character/attribute first and then using INT 10h/AH=09h. This is a display-cell operation, not a raw hardware I/O handler. The entry at 659Bh also shows that the callback path uses a second prompt/display operation after the common input routine.

## 3. Input conversion helper at 65BFh

There are two entries into the conversion helper:

- 65BFh: PUSH CX; MOV CH,00h; JMP 65C6h
- 65C3h: PUSH CX; MOV CH,01h; then fall through to 65C6h

The common body compares DH against 2 and 8, tests DH bit0, chooses ASCII bounds '0'/'1' or computes a decimal digit from CL (high nibble × 10 plus low nibble), and uses the result to compare DL. It finally restores CX and invokes INT 1Ah with AH=05h. This is consistent with date/time field validation and RTC update, but the exact INT 1Ah calling convention and the meanings of the two entry modes need to be traced through the callers before assigning specific calendar fields.

## 4. Callback-specific work after the common prompt

The handlers diverge after the shared routine:

- 6373h and 63C9h branch through 6774h / 65C4h and return to their own entry on a retry path.
- 641Fh and 6485h compare returned values against constants around 1900h–2099h and 2000h, then normalize/validate the year-like value before returning to the callback loop.
- 64E3h and 6541h compare against ASCII constants 59h ('Y') and 00h, and use INT 1Ah calls in their continuation. Their exact field semantics are not assigned yet.

The constant ranges and use of INT 1Ah make a date/time configuration interpretation plausible, but this phase deliberately does not label each callback as year/month/day/hour/minute/second without completing the shared helper and string-table cross references.

## 5. Next steps

1. Decode strings at 75D2h and 7625h to identify the two prompt families.
2. Trace 05E0h, 05EEh, 08C8h, 08CDh, 6774h, 67AEh and 6616h from their real entry boundaries.
3. Finish the remaining callbacks 0319h, 0351h, 02DBh, 02F1h and 026Fh.
4. Keep callback table traversal separate from the semantics of each callback; the table's first word is a next-cursor value, while the second word is the indirect callback target.
