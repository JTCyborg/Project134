# AMI486 semantic map — phase 90 (2026-11-16)

## 1. Corrected secondary option table

The 026Fh callback selects a cursor in a four-byte linked callback table. Raw little-endian records in the ROM include:

| Record offset | Next cursor | Callback target |
|---:|---:|---:|
| 0BA5h | 0BADh | 0644h |
| 0BA9h | 0BADh | 064Ah |
| 0BADh | 0BA5h | 064Ah |
| 0BB1h | 0BD5h | 06AEh |
| 0BB5h | 0BBDh | 066Bh |
| 0BB9h | 0BB5h | 0650h |
| 0BBDh | 0BC5h | 068Ah |
| 0BC1h | 0BBDh | 066Bh |
| 0BC5h | 0BCDh | 069Ch |
| 0BC9h | 0BC5h | 068Ah |
| 0BCDh | 0BD5h | 06AEh |
| 0BD1h | 0BCDh | 069Ch |
| 0BD5h | 0BB5h | 0650h |

The 026Fh branch selects:
- BP+14h bit 2 set: BX=0BA5h; 05B4h advances to record 0BA9h and invokes 064Ah.
- BP+14h bit 2 clear: BX=0BADh; 05B4h advances to record 0BB1h and invokes 06AEh.

This corrects the initial phase-89 table alignment. 0BA5h is a record offset, not an indirect code target. The earlier claim that 05B4h calls 0BA5h is withdrawn.

## 2. Installed / Not Installed prompt entries

Two callback targets are alternate entries into the common prompt/input helper at 02BAh:

```asm
0644  MOV SI,74D4h       ; " Installed"
0647  JMP 02BAh
064A  MOV SI,74E5h       ; " Not Installed"
064D  JMP 02BAh
```

The strings at 74D4h and 74E5h are confirmed from the ROM bytes. The common 02BAh path displays/handles the selected prompt, calls the shared input path, retries on AH=3Ch/3Dh, and returns AL from CS:[SI] on its normal exit. These are distinct callback choices, not executable bytes embedded in the 0BA5h table.

## 3. Shared list-selection helper at 0749h

The field callbacks below call the common list-selection helper at 0749h with a screen-position value in DX and an option-count/limit in SI:

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

The helper renders a row/column selection region using the shared INT 10h display-cell helper at 65A7h, then reads keyboard input through INT 16h. Entry 0749h is the common setup path used by the field callbacks. 0745h and 0747h are alternate entries into the same nearby instruction region and must not be conflated with the aligned 0749h entry.

## 4. Field callbacks reached from the table

| Callback | Parameters to 0749h | Conditional write |
|---:|---|---|
| 0650h | DX=0012h, SI=0005h | If CX!=0, stores DX at BP+1Bh; maps AH=4Bh to AH=48h while preserving flags |
| 066Bh | DX=0018h, SI=0003h | If CX!=0, stores DL at BP+1Dh; sets BP+20h to 00h when DL<=08h, otherwise 08h |
| 068Ah | DX=001Eh, SI=0005h | If CX!=0, stores DX at BP+1Eh |
| 069Ch | DX=0024h, SI=0005h | If CX!=0, stores DX at BP+21h |
| 06AEh | DX=002Ah, SI=0003h | If CX!=0, stores DL at BP+23h; maps AH=4Dh to AH=50h while preserving flags |

The callback bodies use BP-relative storage and the same UI list helper. Their exact Setup labels and hardware meanings are not established by these offsets alone.

## 5. Dispatcher behavior and remaining uncertainty

The secondary dispatcher at 05B4h stores the record's next-cursor word at BP+02h, calls the target at record+2, and examines returned CF/ZF and AH. If it continues, it reloads the next cursor and either advances by another four bytes when AH=51h or reads at the cursor directly. It exits through 05EEh when the callback's flags or AH meet the stop conditions.

This confirms a linked, flag-/AH-controlled callback sequence rather than a fixed list. The static table is decoded, but the exact runtime route depends on callback results. Next work is to decode the full keyboard-selection return contract of 0749h (including its alternate entries 0745h/0747h), then simulate each reachable table transition without assuming every record executes.
