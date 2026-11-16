# AMI486 semantic map — phase 91 (2026-11-16)

## 1. 0749h is the shared numeric list-selection editor

The field callbacks in the 0BA5h..0BD5h secondary table all call 0749h. The aligned entry begins:

```asm
0749  ADD DX,[BP+04h]
074C  MOV CX,SI
074E  PUSH DX
074F  DEC DX
0750  INC CX
0751  INC CX
0752  PUSH CX
0753  PUSH DX
0754  MOV DH,07h
0756  MOV BL,[E1A3h]
075A  MOV BH,00h
075C  CALL 65A7h
075F  POP DX
0760  POP CX
0761  MOV BL,[E1A3h]
0765  OR BL,80h
0768  CALL 65A7h
076B  MOV AH,03h
076D  INT 10h
076F  POP DX
0770  PUSH CX
0771  CALL 099Dh
0774  PUSH DX
0775  MOV AH,02h
0777  INT 10h
0779  XOR DI,DI
077B  MOV AH,00h
077D  INT 16h
```

This draws the selection area through the shared display-cell helper 65A7h, saves/restores cursor state, and enters a BIOS keyboard loop. It is a numeric list editor, not a hardware-port handler.

## 2. Keyboard and numeric-entry behavior

The keyboard loop has these confirmed paths:

- Backspace (AH=0Eh): if DI is nonzero, decrements the typed-digit count, emits a backspace through INT 10h/AH=0Eh, calls 098Eh, and returns to the keyboard loop.
- Arrow Right / Down (AX=4D00h / 5000h): calls 080Fh to parse any typed digits; if no digits are present, returns with CF clear. If digits exist, it redraws/re-enters the input loop.
- Arrow Left / Up (AX=4B00h / 4800h): calls 080Fh; if no digits are present, returns with CF set.
- Page Up / Page Down (AX=4900h / 5100h), and AH=01h: call 080Fh; if no digits are present, return with CF set.
- Enter (AH=1Ch): rewrites AH to 4Dh and follows the Right/Down completion path.
- ASCII digits '0'..'9': are stored at SS:BP+DI+0Ah, DI is incremented, and CX is recomputed as SI-DI. Invalid characters or excess digits go through the helper at F571h.

The exact distinction between all returned AH values and the higher-level callback dispatch remains a separate caller-contract question; CF and CX effects above are directly visible.

## 3. Decimal parser at 080Fh

The common conversion helper at 080Fh parses the digit buffer:

```asm
080F  PUSH AX
0810  PUSH SI
0811  MOV CX,DI
0813  JCXZ 0842h
0815  XOR SI,SI
0817  XOR AX,AX
0819  MOV DX,000Ah
081C  MUL DX
081E  JO 083Dh
0820  MOV DL,[BP+SI+0Ah]
0824  INC SI
0825  SUB DL,30h
0828  MOV DH,00h
082A  ADD AX,DX
082C  JB 083Eh
082E  LOOP 081Ch
0830  MOV DX,AX
0832  POP SI
0833  PUSH SI
0834  CMP SI,0005h
0838  JE 0842h
083A  CMP AX,00FFh
083D  CALL F571h
0840  MOV CX,DI
0842  POP SI
0843  POP AX
0844  RET
```

The helper accumulates a base-10 value in AX, returns it in DX, and returns the number of entered digits in CX. The 00FFh upper-bound check is bypassed when SI=5; otherwise values above 255 call F571h. The signed-overflow branch at 081Eh also calls F571h. A separate carry branch at 082Ch targets 083Eh, the second byte of that CALL displacement; the alternate stream is `XOR BP,BP; MOV CX,DI; POP SI; POP AX; RET`. This unusual BP-clearing error/alternate path is not yet explained and must not be merged with the aligned 083Dh CALL stream. The exact meaning of the SI=5 exception is not assigned globally; callers use both SI=3 and SI=5.

## 4. Alternate-entry warning

0745h and 0747h are not confirmed runtime entries for the 0749h list editor:
- 0745h is the second byte of the instruction beginning at 0744h (FF 76 FA); decoding from 0745h alone gives JBE 0741h.
- 0747h is the next instruction boundary and contains JMP 076Bh (EB 22).
- A raw-image scan found no direct relative CALL/JMP/Jcc target and no literal 16-bit pointer hit for either 0745h or 0747h.
- 0749h is the aligned ADD DX,[BP+04h] entry; its five direct CALL sites are 0656h, 0671h, 0690h, 06A2h and 06B4h, matching the callbacks mapped in phase 90.

Keep 0745h as an alternate-decode candidate and 0747h as an unreferenced instruction boundary, not proven callback entries. The actual callers of 0749h are established.

## 5. Callback return contract still open

The editor's return values are:
- DX: parsed decimal selection when digits were entered;
- CX: number of entered digits;
- CF: set/clear according to the navigation/completion path;
- AH: retains or is adjusted by the keyboard path and is interpreted by individual callbacks.

The field callbacks use CX!=0 as the gate for committing their BP-relative field updates. This explains why they do not write a value when the user exits the list without entering digits. The complete interpretation of the returned AH values and the secondary dispatcher's next-record selection remains to be proven from all callback callers.

Next: trace the caller-specific AH/CF branches and simulate the linked records in the 05B4h dispatcher with exact callback return states; retain 0745h/0747h only as unreferenced alternate-decode candidates.
