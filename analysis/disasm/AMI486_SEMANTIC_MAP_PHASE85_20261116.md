# AMI486 semantic map — phase 85 (2026-11-16)

## 1. Indirect callback table at 0AF5h

The dispatcher at 01EDh..020Dh uses a four-byte record cursor. Its operations are:

```asm
01ED  MOV BX,0AF5h
01F0  JMP 01F5h
01F2  ADD BX,4
01F5  MOV AX,CS:[BX]
01F8  MOV [BP+00h],AX
01FB  CALL 0995h
01FE  MOV AX,CS:[BX+2]
0202  PUSH BX
0203  CALL AX
0205  POP AX
0206  MOV BX,[BP+00h]
0209  JAE 01F2h
020B  JZ 01F5h
020D  CALL 099Dh
```

The second word of each record is an indirect callback target. The first word is copied into BP+00h and becomes the cursor base after the callback. The callback's returned CF/ZF control whether the dispatcher adds four, re-enters without adding, or exits to 099Dh. Therefore the table is not safely described as a simple fixed array; it is a flag-controlled threaded callback structure.

## 2. Static record/callback chain

Following the JAE continuation (BX = first_word + 4) from the initial cursor 0AF5h yields the following record sequence before it enters the repeating subchain:

| Record cursor | First word | Callback target |
|---:|---:|---:|
| 0AF5h | 0AEDh | 6373h |
| 0AF1h | 0AF5h | 63C9h |
| 0AF9h | 0AFDh | 641Fh |
| 0B01h | 0B05h | 6485h |
| 0B09h | 0B0Dh | 64E3h |
| 0B11h | 0B15h | 6541h |
| 0B19h | 0B1Dh | 0319h |
| 0B21h | 0B25h | 0351h |
| 0B29h | 0B2Dh | 02DBh |
| 0B31h | 0B35h | 02F1h |
| 0B39h | 0B3Dh | 0236h |
| 0B41h | 0B45h | 026Fh |
| 0B49h | 0AEDh | 6373h |

The final record points back into the same subchain (the next cursor under JAE is 0AF1h). This proves a threaded/repeating structure in the static data, but not that every callback is executed on every Setup visit: each callback's CF/ZF result can alter traversal.

## 3. Callback family structure

The six targets 6373h, 63C9h, 641Fh, 6485h, 64E3h and 6541h have a repeated prologue shape:
- load a distinct port/parameter pair into DX and CX;
- call a nearby shared helper;
- save flags with PUSHF;
- test the returned condition and, on one path, issue a second helper call;
- restore flags and return or continue through a secondary check.

The four targets 0319h, 0351h, 02DBh and 02F1h operate directly on BP-relative state bytes/nibbles and call display helpers at 0597h/05A5h. Targets 0236h and 026Fh are adjacent field-editor routines; 0236h was decoded in phase84, while 026Fh remains to be decoded.

These patterns support a Setup form/menu callback family, but individual labels and hardware meanings are not yet assigned.

## 4. What is established vs unresolved

Established:
- indirect dispatch through CALL AX at 0203h;
- callback target words at record offset +2;
- first-word cursor feedback through BP+00h;
- CF/ZF-dependent traversal;
- the static callback target sequence listed above.

Unresolved:
- exact semantics of helper 0995h and 099Dh in this dispatcher;
- actual branch/termination outcomes returned by each callback;
- labels/field names associated with each callback;
- complete decoding of callback 026Fh and the shared helper routines.

Next, follow the 6373h..6541h callback family into its shared helper and trace the four BP-relative field editors. This closes the callback mechanism rather than repeating the CMOS scan.
