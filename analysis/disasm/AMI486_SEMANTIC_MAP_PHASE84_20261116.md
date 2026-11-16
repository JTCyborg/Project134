# AMI486 semantic map — phase 84 (2026-11-16)

## 1. New low-ROM region: 0000h..0235h

The first 00EFh bytes are not a single instruction stream. Offsets 0000h..00EEh contain a structured OEM/signature area and copyright/date text:

- 0000h..005Fh: repeated ASCII marker fields (digits and repeated A/M/I/B/O/S/C characters, followed by date-like digit groups). Treat as opaque metadata/signature data until the field schema is recovered.
- 0060h onward: `Date:-04/04/93`, `(C)1985-1993,AMI`, `American Megatrends Inc.`, and the rights/product-name notice.
- 00ECh..00EEh end with `UVW`; the first code byte is 00EFh.

The first confidently aligned code entry begins at 00EFh:

```asm
00EF  PUSH ES
00F0  PUSH DS
00F1  PUSH SS
00F2  POP ES
00F3  MOV AH,03h
00F5  MOV BH,00h
00F7  INT 10h                 ; read cursor position
00F9  PUSH CX
00FA  PUSH DX
00FB  SUB SP,0080h
00FF  MOV BP,SP
0101  MOV DI,SP
0103  MOV CX,0020h
0106  MOV SI,E000h
0109  REP MOVSW               ; save 64 words from DS:E000 to SS:SP
010B  MOV BX,3045h
010E  MOV AX,732Eh
0111  CALL 3E3Fh
0114  CALL 0995h
0117  MOV BL,[E1A2h]
011B  MOV BH,00h
011D  MOV SI,738Eh
0120  MOV DX,[SI]
0122  XCHG DL,DH
0124  ADD SI,2
0127  MOV AH,02h
0129  INT 10h                 ; set cursor position
012B  CALL F52Eh
012E  CALL 622Bh
0131  MOV AX,0517h
0134  MOV CX,0010h
0137  CALL 09CEh
013A  MOV AX,0617h
013D  MOV CX,0010h
0140  CALL 09CEh
0143  MOV BL,[E1A6h]
0147  CALL 05EBh
014A  MOV AL,[E1A6h]
014D  MOV [E19Fh],AL
0150  MOV BX,0003h
0153  MOV AX,1102h
0156  MOV DX,1531h
0159  CALL 578Dh
015C  MOV BL,[E1A2h]
0160  CALL 08C8h
0163  MOV BH,00h
0165  MOV DX,0543h
0168  MOV AX,[BP+15h]
016B  CALL 0A15h
016E  MOV DX,0643h
0171  MOV AX,[BP+17h]
0174  CALL 0A15h
0177  MOV AL,[BP+10h]
017A  PUSH AX
017B  SHR AL,4
017E  MOV DX,0A16h
0181  CALL 0597h
0184  POP AX
0185  MOV DX,0B16h
0188  CALL 0597h
018B  MOV WORD [BP+06h],0000h
0190  MOV AL,[BP+12h]
0193  SHR AL,4
0196  AND AL,0Fh
0198  CMP AL,0Fh
019A  JNZ 019Fh
019C  MOV BL,[BP+19h]
019F  MOV DX,0816h
01A2  CALL 03D4h
01A5  MOV WORD [BP+06h],0009h
01AA  MOV AL,[BP+12h]
01AD  AND AL,0Fh
01AF  CMP AL,0Fh
01B1  JNZ 01B6h
01B3  MOV BL,[BP+1Ah]
01B6  MOV DX,0916h
01B9  CALL 03D4h
01BC  MOV AL,[BP+14h]
01BF  AND AL,30h
01C1  TEST BYTE [BP+14h],08h
01C5  JNZ 01C9h
01C7  MOV AL,40h
01C9  ROL AL,4
01CC  MOV SI,0AC1h
01CF  CALL 0AADh
01D2  MOV DX,0C16h
01D5  CALL 0862h
01D8  TEST BYTE [BP+14h],04h
01DC  MOV SI,74E5h
01DF  JZ 01E4h
01E1  MOV SI,74D4h
01E4  MOV DX,0D16h
01E7  CALL 0862h
01EA  CALL 626Bh
01ED  MOV BX,0AF5h
01F0  JMP 01F5h
01F2  ADD BX,4
01F5  MOV AX,CS:[BX]
01F8  MOV [BP+00h],AX
01FB  CALL 0995h
01FE  MOV AX,CS:[BX+2]
0202  PUSH BX
0203  CALL AX                 ; indirect callback
0205  POP AX
0206  MOV BX,[BP+00h]
0209  JAE 01F2h
020B  JZ 01F5h
020D  CALL 099Dh
0210  CALL 62BDh
0213  CLI
0214  MOV DI,E000h
0217  MOV SI,SP
0219  MOV CX,0020h
021C  PUSH DS
021D  POP ES
021E  SS: REP MOVSW           ; restore 64 words to DS:E000
0221  ADD SP,0080h
0225  MOV BH,00h
0227  POP AX
0228  CALL 09C1h
022B  POP CX
022C  MOV AH,01h
022E  INT 10h
0230  POP DS
0231  POP ES
0232  POP DI
0233  POP SI
0234  POP BP
0235  RET
```

## 2. Function role

This is a video/Setup presentation routine, not generic reset code:

- Uses INT 10h/AH=03h and AH=02h to save and set the text cursor.
- Reserves 80h bytes on the stack and saves 40h words from DS:E000h; it restores those words before returning.
- Uses several display/format helpers and reads state bytes at E1A2h, E1A6h and E19Fh.
- Builds display values from a BP-based record (fields at +10h, +12h, +14h, +15h, +17h, +19h, +1Ah).
- Traverses a CS-resident callback structure beginning at 0AF5h. For each iteration it reads a word at CS:[BX], calls helper 0995h, loads the word at CS:[BX+2] and invokes it indirectly with CALL AX. The callback's returned flags control the loop through JAE/JZ. Exact record schema and callback meaning are not yet assigned.
- Restores the E000h buffer, cursor state and saved registers, then RETs.

The indirect callback is a real control-flow edge class that a simple direct-CALL scan will miss. Its target set must be extracted from the table and followed independently.

## 3. Adjacent alternate entry at 0236h

The byte after the RET begins a distinct routine/entry stream:

```asm
0236  MOV AL,[BP+14h]
0239  AND AL,30h
023B  TEST BYTE [BP+14h],08h
023F  JNZ 0243h
0241  MOV AL,40h
0243  ROL AL,4
0246  MOV SI,0ACBh
0249  CALL 0AADh
024C  MOV BX,SI
024E  MOV SI,769Dh
0251  MOV DX,0C16h
0254  CALL 05B4h
0257  PUSHF
0258  AND BYTE [BP+14h],0F7h
025C  OR AL,AL
025E  JZ 0264h
0260  OR BYTE [BP+14h],08h
0264  AND AL,30h
0266  AND BYTE [BP+14h],0CFh
026A  OR [BP+14h],AL
026D  POPF
026E  RET
```

This routine merges a selected two-bit field into BP+14h while preserving bit 3 according to a separate AL test. It is consistent with a Setup field editor, but its caller and UI label are not yet proven.

## 4. Coverage and next work

- Newly classified: 0000h..00EEh as metadata/text data; 00EFh..0235h as a coherent display/Setup routine; 0236h..026Eh as an adjacent field-edit helper.
- 026Fh onward is not included in this phase.
- No direct near CALL to 00EFh was found in a raw opcode-pattern scan. That is not a complete xref proof: far calls, pointer tables and runtime/indirect dispatch remain possible.
- Next target is the continuation from 026Fh and the callback chain behind the 0AF5h structure, then a range-based coverage ledger for the remaining low ROM.
