# AMI486 semantic map — phase 93 (2026-11-16)

## 1. 0B5Dh and 0B6Dh are executable entry candidates in a dual-use region

The first two indirect targets in the 05A3h option dispatcher are 0B5Dh and 0B6Dh. Both are aligned instruction boundaries in a 16-bit decode:

```asm
0B5D  PUSH BP
0B5E  OR CX,[06506h]
0B62  OR BX,[BP+SI]
0B64  PUSH ES
0B65  POP BP
0B66  OR DX,[SI]
0B68  PUSH ES
0B69  INSW
0B6A  OR SP,[BX+SI]
0B6C  PUSH ES
0B6D  GS: OR BX,[BP+SI]
0B70  PUSH ES
0B71  JNE 0B7Eh
```

The alternate entry at 0B6Dh begins at the GS-prefixed OR instruction and reaches the same conditional branch at 0B71h. This is not a continuation of the 0B5Dh prologue; it is a separate indirect entry into the same byte region.

## 2. The same bytes also align as four-byte callback records

Starting at 0B5Dh, the bytes can also be grouped into four-byte pairs that look like linked records, for example:

| Offset | First word | Second word |
|---:|---:|---:|
| 0B5Dh | 0B55h | 060Eh |
| 0B61h | 0B65h | 061Ah |
| 0B65h | 0B5Dh | 0614h |
| 0B69h | 0B6Dh | 0620h |
| 0B6Dh | 0B65h | 061Ah |
| 0B71h | 0B75h | 0626h |
| 0B75h | 0B6Dh | 0620h |
| 0B79h | 0B4Dh | 064Ah |
| 0B7Dh | 0B9Dh | 0638h |

These pairs match the same general next-cursor/handler shape used by the other callback tables. Yet the 05B4h dispatcher also calls 0B5Dh and 0B6Dh as code offsets. The region must therefore be treated as a confirmed dual-use/overlapping code-and-record candidate, not classified as plain data or plain linear code.

## 3. Control-flow observations from the 0B5Dh stream

A 16-bit decode from 0B5Dh has conditional branches at:
- 0B71h: JNE 0B7Eh
- 0B85h: JGE 0B92h
- 0BA1h: JGE 0BAEh

The stream continues through the mixed region and reaches a short epilogue/dispatch area around 0BE1h..0C04h. In the linear decode from this entry, 0BE1h is MOV BH,00h; 0BE3h is JZ 0C04h; the nonzero path enters the Setup-page initialization sequence at 0BE5h and calls 0C7Dh before RET at 0C04h.

The page-initialization path writes:
- DS:E191h = B7D0h
- DS:E193h = BD54h
- DS:E197h = the word at DS:8292h
- DS:E195h = B7B2h
- BX = 305Bh
- CALL 0C7Dh

This is consistent with the Setup-page descriptor/editor framework already mapped in earlier phases. It does not yet prove which table records or runtime input states select this path.

## 4. What is and is not proven

Confirmed:
- 05B4h's first table callback target is 0B5Dh; the next linked target is 0B6Dh.
- 0B5Dh and 0B6Dh are aligned 16-bit instruction entries.
- The same region has four-byte record-like structure at those offsets, creating an overlapping code/data interpretation.
- The 0B5Dh linear instruction stream reaches a conditional path into Setup-page initialization at 0BE5h and common editor 0C7Dh.

Not proven:
- Whether the record-like words are consumed as a second-level table during the same execution, or are merely bytes that overlap the executable stream.
- The live CS base and whether shadow/relocated code changes the runtime bytes.
- The register/stack contract at entry 0B5Dh and alternate entry 0B6Dh.
- Which exact Setup item labels correspond to the record chain.

Next: reconstruct the control-flow and stack state from each entry (0B5Dh and 0B6Dh) through 0C04h, and compare it with the 05B4h caller's expected CF/ZF/AH result. Then trace whether the four-byte record view is actually read at runtime or is only an overlapping static interpretation.
