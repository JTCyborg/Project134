# AMI486 Setup editor — byte-aligned navigation and option rendering extension

Date: 2026-11-17  
ROM: `ami486.bin`, 65,536 bytes  
ROM SHA-256: `91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b`  
Related: `AMI486_SEMANTIC_MAP_PHASE7_20261116.md`, `AMI486_SEMANTIC_MAP_PHASE10_20261116.md`, `AMI486_SEMANTIC_MAP_PHASE12_20261116.md`.

## 1. Scope

This is an extension of phase 12, not a new numbered phase. It byte-checks the editor's event dispatch and follows the helpers beyond the earlier 0D34h–0E12h description. The generated Capstone windows were independently seeded at 0C7Dh, 0CFEh, 0D03h, 0D08h, 0D84h, 0E19h, 0E47h, 0E7Ch and 0EE2h. All offsets below are file offsets in the original 64 KiB ROM.

## 2. Confirmed editor flow and entry boundaries

- The common editor entry is 0C7Dh, directly called from 0C79h. Its prologue is `PUSH BP; MOV BP,SP`; it then calls 614Dh to count visible records.
- 0C84h copies the visible-record count from [E18E] to [E18D] and clamps [E18D] to 24h (36 decimal). 0C93h resets [E18C] and 0C98h resets [E185].
- The editor draws the page frame/title and enters the event loop. 0CE0h tests [E18B]; the value 2 returns to the frame redraw at 0C9Dh, while a nonzero state takes the selection-refresh path at 0D34h.
- The visible-item loop is at 0D08h–0D21h. 0D21h branches back to 0D08h while [E185] is below [E18D]. Each item is drawn by 0E7Ch; 6008h advances the visible record.
- 0CFEh is the beginning of `MOV BYTE [E185],0`. A decode seeded at 0D00h is therefore misaligned inside that instruction and must not be treated as a new entry.
- 0D84h is a branch target of the short conditional at 0D7Fh. It is the aligned event-code selector reached after the preceding comparisons; 0D80h is only the branch displacement byte and is not an entry.
- 0E15h is the shared frame epilogue (`MOV SP,BP; POP BP; RET`). 0E00h is a short branch/call fragment that returns to the editor frame at 0C9Dh; it is not a function prologue.

## 3. Event-code dispatch at 0D84h

The selector receives AX from the 5902h input/event helper. The exact dispatch values and destinations are:

| AX on entry | Action |
|---:|---|
| 0001h | Call 0E19h (decrement/wrap the current position) |
| 0002h | Set AL=FFh and call 60BBh (option-change path) |
| 0004h or 0006h | Run the coordinate/page adjustment at 0DB4h |
| 0008h | Set [E18C]=0, then call 0E19h |
| 0009h | Call 0E47h (increment/wrap the current position) |
| 000Ah | Set AL=01h and call 60BBh |
| 0025h | Set AL=0Ah and call 60BBh |
| 0033h | Set AL=F6h and call 60BBh |
| 0120h | Call 0EE2h (option-list/auxiliary-description renderer) |
| 001Bh | Exit through the shared epilogue at 0E15h |

Other values follow the existing default return/refresh path at 0CE0h. These are internal AX event values observed at this dispatcher; they are not assigned PC key names here.

The 0DB4h branch saves [E185], divides ([E185]+12h) by 24h, stores the remainder back to [E185], compares the resulting row with [E18D], and adjusts [E18C] by the difference from the saved position. This arithmetic is confirmed; its user-visible key name is not.

## 4. Previous/next position helpers

### 0E19h — decrement/wrap

```asm
0E19  CMP BYTE [E18C],00h
0E1E  JNZ 0E32h
0E20  MOV AL,[E18E]
0E23  DEC AL
0E25  MOV [E18C],AL
0E28  MOV AL,[E18D]
0E2B  DEC AL
0E2D  MOV [E185],AL
0E30  JMP 0E41h
0E32  DEC BYTE [E18C]
0E36  DEC BYTE [E185]
0E3A  JNS 0E46h
0E3C  MOV BYTE [E185],00h
0E41  MOV BYTE [E18B],00h
0E46  RET
```

This path decrements the current position. At the zero boundary it loads the last valid page/row values from [E18E]-1 and [E18D]-1; on the ordinary path it decrements [E18C] and [E185] and clamps the row to zero on underflow. It clears the editor event-state byte [E18B] before returning.

### 0E47h — increment/wrap

```asm
0E47  INC BYTE [E18C]
0E4B  MOV AL,[E18E]
0E4E  CMP BYTE [E18C],AL
0E52  JNZ 0E60h
0E54  MOV BYTE [E185],00h
0E59  MOV BYTE [E18C],00h
0E5E  JMP 0E76h
0E60  INC BYTE [E185]
0E64  MOV AL,[E185]
0E67  CBW
0E68  MOV CL,[E18D]
0E6C  SUB CH,CH
0E6E  CMP AX,CX
0E70  JNZ 0E7Bh
0E72  DEC BYTE [E185]
0E76  MOV BYTE [E18B],00h
0E7B  RET
```

This is the corresponding increment path. It wraps [E18C] to zero when it reaches [E18E], resets [E185] at that boundary, otherwise increments [E185] and clamps it to [E18D]-1. It also clears [E18B].

## 5. Single-item renderer at 0E7Ch

Direct callers found in aligned code: 0D0Bh, 0D3Ah, 0D46h and 60BFh.

The routine saves the input AL at [E19F], calculates a screen row through 6137h using [E185], and chooses one of two horizontal positions depending on whether [E185] is below 12h. It draws the active record label from [E18F], emits a colon, then calls 6115h to resolve the selected option-code to its display-string pointer.

The input AL is saved at [BP-4] and compared with [E1A5]. Equal values take the 58D3h output path; unequal values take 58AFh. Thus [E1A5] selects the highlighted item/field, while the current record's label and translated option string are drawn through the shared text routines. The routine returns at 0EE1h.

## 6. Option-list and auxiliary-description renderer at 0EE2h–10DEh

0DFDh directly calls 0EE2h. The routine is one continuous aligned stream through its RET at 10DEh; the instruction at 0FFFh is `MOV AX,[BP-10h]` and crosses the 1000h boundary. 1000h is not a separate entry.

The renderer reads the active record pointer [E18F]:
- [record+1Fh] is the option-code count;
- [record+1Eh] bit 7 selects the auxiliary-tail path;
- [record+20h] begins the option-code bytes;
- the auxiliary NUL-terminated strings, when present, begin immediately after the option-code bytes.

It computes the auxiliary-string lengths through 592Ah and uses them to lay out the option panel. It derives screen coordinates from [E185] and the local maximum-width/row counters, stores the active output coordinate in [E180], and uses [E181] as a row counter. It calls 578Dh/5862h for panel/frame drawing, 58BEh for record-associated text, 58AFh/58D3h for alternate text attributes, and 6122h while rendering auxiliary text.

The routine references these confirmed strings:
- 36ABh: `Available Options are :-`
- 36A6h: `Default values loaded. Press any key to continue`
- 36DBh: footer/text payload used by the final 58BEh call.

It conditionally displays the auxiliary strings and the “Available Options” heading, renders the associated text rows, and calls 5902h before restoring SI/DI/BP and returning at 10DEh. The exact visual meaning of every local layout variable is not inferred beyond its use in this stream.

## 7. Direct-reference map

| Target | Verified direct caller(s) |
|---|---|
| 0C7Dh | 0C79h |
| 0E19h | 0DE5h |
| 0E47h | 0DEBh |
| 0E7Ch | 0D0Bh, 0D3Ah, 0D46h, 60BFh |
| 0EE2h | 0DFDh |
| 0D08h | conditional branch at 0D21h |
| 0D84h | conditional branch at 0D7Fh |

## 8. Corrections and remaining questions

- The entry is 0E19h, not 0E1Ah. A seed at 0E1Ah misses the opcode byte 80h of the initial `CMP BYTE [E18C],0`.
- The entry at 0CFEh begins a five-byte MOV; 0D00h is inside it. Do not use 0D00h as a code seed.
- The 0EE2h routine continues across 1000h; the byte at 1000h belongs to the instruction beginning at 0FFFh.
- The exact names of the AX event values at 0D84h and the precise user-facing meaning of the [E18C]/[E185] axes remain open. The arithmetic and direct-call relationships are byte-verified.
- This extension does not resolve the remaining callback-table/option-code meanings already listed in phase 12.
