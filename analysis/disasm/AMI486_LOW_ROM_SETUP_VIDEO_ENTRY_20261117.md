# AMI486 low-ROM screen-presentation stream — 00EFh–0235h

Date: 2026-11-17  
ROM: `ami486.bin`, 65,536 bytes  
ROM SHA-256: `91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b`  
Evidence: raw-byte inspection and independently seeded Capstone x86 16-bit window.

## 1. Low-ROM data/code boundary

`0000h–00EEh` is an AMI identity/copyright block, not a confirmed instruction stream. It contains the repeated-letter AMIBIOS marker, embedded date `04/04/93`, copyright `1985–1993`, American Megatrends attribution, trademark wording and trailing `UVW` bytes. The generator emits this 239-byte range as data.

At `00EFh` the bytes switch to a coherent executable-looking stream that ends at the aligned `RET` at `0235h`. The candidate window is now `00EFh–0235h` (327 bytes). This is a separately seeded decode, not proof of runtime reachability.

## 2. Byte-aligned instruction stream

```asm
00EF PUSH ES
00F0 PUSH DS
00F1 PUSH SS
00F2 POP ES
00F3 MOV AH,03h
00F5 MOV BH,00h
00F7 INT 10h
00F9 PUSH CX
00FA PUSH DX
00FB SUB SP,0080h
00FF MOV BP,SP
0101 MOV DI,SP
0103 MOV CX,0020h
0106 MOV SI,E000h
0109 REP MOVSW
010B MOV BX,3045h
010E MOV AX,732Eh
0111 CALL 3E3Fh
0114 CALL 0995h
0117 MOV BL,[E1A2h]
011B MOV BH,00h
011D MOV SI,738Eh
0120 MOV DX,[SI]
0122 XCHG DH,DL
0124 ADD SI,02h
0127 MOV AH,02h
0129 INT 10h
012B CALL F52Eh
012E CALL 622Bh
0131 MOV AX,0517h
0134 MOV CX,0010h
0137 CALL 09CEh
013A MOV AX,0617h
013D MOV CX,0010h
0140 CALL 09CEh
0143 MOV BL,[E1A6h]
0147 CALL 05EBh
014A MOV AL,[E1A6h]
014D MOV [E19Fh],AL
0150 MOV BX,0003h
0153 MOV AX,1102h
0156 MOV DX,1531h
0159 CALL 578Dh
015C MOV BL,[E1A2h]
0160 CALL 08C8h
0163 MOV BH,00h
0165 MOV DX,0543h
0168 MOV AX,[BP+15h]
016B CALL 0A15h
016E MOV DX,0643h
0171 MOV AX,[BP+17h]
0174 CALL 0A15h
0177 MOV AL,[BP+10h]
017A PUSH AX
017B SHR AL,04h
017E MOV DX,0A16h
0181 CALL 0597h
0184 POP AX
0185 MOV DX,0B16h
0188 CALL 0597h
018B MOV WORD [BP+06h],0000h
0190 MOV AL,[BP+12h]
0193 SHR AL,04h
0196 AND AL,0Fh
0198 CMP AL,0Fh
019A JNE 019Fh
019C MOV AL,[BP+19h]
019F MOV DX,0816h
01A2 CALL 03D4h
01A5 MOV WORD [BP+06h],0009h
01AA MOV AL,[BP+12h]
01AD AND AL,0Fh
01AF CMP AL,0Fh
01B1 JNE 01B6h
01B3 MOV AL,[BP+1Ah]
01B6 MOV DX,0916h
01B9 CALL 03D4h
01BC MOV AL,[BP+14h]
01BF AND AL,30h
01C1 TEST BYTE [BP+14h],08h
01C5 JNE 01C9h
01C7 MOV AL,40h
01C9 ROL AL,04h
01CC MOV SI,0AC1h
01CF CALL 0AADh
01D2 MOV DX,0C16h
01D5 CALL 0862h
01D8 TEST BYTE [BP+14h],04h
01DC MOV SI,74E5h
01DF JE 01E4h
01E1 MOV SI,74D4h
01E4 MOV DX,0D16h
01E7 CALL 0862h
01EA CALL 626Bh
01ED MOV BX,0AF5h
01F0 JMP 01F5h
01F2 ADD BX,04h
01F5 MOV AX,[CS:BX]
01F8 MOV [BP+00h],AX
01FB CALL 0995h
01FE MOV AX,[CS:BX+02h]
0202 PUSH BX
0203 CALL AX
0205 POP AX
0206 MOV BX,[BP+00h]
0209 JAE 01F2h
020B JZ 01F5h
020D CALL 099Dh
0210 CALL 6220h
0213 CLI
0214 MOV DI,E000h
0217 MOV SI,SP
0219 MOV CX,0020h
021C PUSH DS
021D POP ES
021E SS: REP MOVSW
0221 ADD SP,0080h
0225 MOV BH,00h
0227 POP AX
0228 CALL 09C1h
022B POP CX
022C MOV AH,01h
022E INT 10h
0230 POP DS
0231 POP ES
0232 POP DI
0233 POP SI
0234 POP BP
0235 RET
```

## 3. Confirmed behavior

### Video cursor and scratch preservation

- INT 10h AH=03h obtains the current cursor shape/position; CX and DX are saved.
- The routine allocates 80h bytes on the stack, uses BP as a local frame, and copies 20h words (40h bytes) from `DS:E000h` to `SS:SP`.
- Before returning, it copies those 20h words back from `SS:SP` to `DS:E000h`, releases the 80h-byte stack allocation, calls 09C1h with the saved DX word in AX, then restores saved CX through INT 10h AH=01h.
- The 64-byte save/restore is confirmed; the semantic identity of the DS:E000h block is not.

### Screen content and field formatting

- The routine uses the cursor-coordinate word at `738Eh`; after byte-swapping DX it positions the cursor at row 05h, column 00h. The text block begins at `7390h` and contains Date, Time, Hard Disk C/D, Floppy A/B, Primary Display and Keyboard labels.
- It reads state bytes `[E1A2h]` and `[E1A6h]`, formats several BP-relative fields at +10h/+12h/+14h/+15h/+17h/+19h/+1Ah, and uses helpers 0A15h, 0597h, 03D4h, 0AADh and 0862h.
- It selects the strings at `74D4h` and `74E5h` for the Installed/Not Installed display field.
- The screen-presentation role is clear from the cursor, label, field and video-helper accesses. The exact runtime screen state (POST summary versus a Setup page or another entry path) is not established; do not merge it with the separate renderer at 3F7Bh–4141h.

### Linked callback-record loop

The routine initializes `BX=0AF5h` and reads four-byte records:
- `[CS:BX]` is copied to `[BP+00h]` as the next cursor.
- `[CS:BX+02h]` is called indirectly through AX.
- After the callback, BX is reloaded from `[BP+00h]`.
- CF=0 branches to `01F2h`, adds four to BX, then fetches the next record.
- If CF=1 and ZF=1, execution branches directly to `01F5h` and fetches at the next cursor without adding four.
- If CF=1 and ZF=0, execution takes the exit path through 099Dh and 6220h.

This is a linked callback walker with a flags-driven record-skip/continue/exit contract. It is **not byte-for-byte the same entry convention as dispatcher 05B4h**: this routine reads from `BX=0AF5h` directly and does not first add four. At 0AF5h the raw record is `next=0AEDh, callback=6373h`. The 05B4h dispatcher uses its selected base plus four; keep these two entry conventions separate.

## 4. Entry and calling-convention limits

A raw scan of the 64 KiB ROM found no direct near CALL/JMP target to `00EFh` and no literal little-endian `00EFh` pointer. This does not rule out a runtime-installed far pointer, indirect jump/call, or stack-threaded entry.

The visible stream pushes ES and DS, but does not push BP, SI or DI before using them; the epilogue at 0232h–0234h pops DI, SI and BP before RET. Therefore the incoming stack/register convention is nonstandard or incomplete in this stream. The caller/entry mechanism and the required saved BP/SI/DI frame remain unresolved. Also, CLI at 0213h is observed; the final interrupt-enable state is not inferred.

## 5. Relationship to existing regions

- The 00EFh callback loop uses the same four-byte `next/callback` record shape as the 05B4h dispatcher, but its initial BX handling differs.
- The first raw record at 0AF5h is `ED 0A 73 63` (next 0AEDh, callback 6373h). Phase 96's 05B4h selector map starts at base+4 and therefore has a different first record for the same table base.
- The strings at 7390h onward and 74D4h/74E5h are now classified in the address ledger's 732Bh–7CE8h data ranges.
- The 3F7Bh POST summary renderer is a separate, byte-backed routine; identical subject matter in the labels does not prove the two renderers share a runtime caller.

## 6. Next unresolved checks

1. Find the runtime caller or installed pointer that enters 00EFh and prove the required BP/SI/DI stack frame.
2. Decode the contracts of 3E3Fh, 0995h, F52Eh, 622Bh, 09CEh, 05EBh, 578Dh, 08C8h, 0A15h, 0597h, 03D4h, 0AADh, 0862h, 626Bh, 099Dh, 6220h and 09C1h only as needed to identify the screen's runtime role.
3. Trace the E1A2h/E1A6h state producers and the BP-relative source block.
4. Preserve the distinction between this 00EFh walker and the 05B4h dispatcher when documenting the 0AF5h records.
