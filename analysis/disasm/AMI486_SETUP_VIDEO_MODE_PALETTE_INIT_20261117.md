# AMI486 Setup video-mode and attribute-palette initializer: 566Bh–56ADh

Date: 2026-11-17  
ROM: ami486.bin, 65,536 bytes  
ROM SHA-256: 91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b

## 1. Why this range matters

The candidate mask left 566Bh–56ADh uncovered even though the full linear listing showed instruction-looking bytes. The direct-reference scan resolves the issue: 3C67h contains a near CALL to 566Bh. The entry is not a guess based on the linear decode.

The bytes immediately before 566Bh are not code. They are the final bytes of the 64-byte palette table at 562Bh–566Ah. The linear decoder had continued through that table and interpreted the last table byte at 566Ah as the opcode of a false instruction. The aligned routine starts at 566Bh.

## 2. Direct caller and surrounding context

The direct caller is:

~~~asm
3C5E  PUSH BP
3C5F  MOV BP,SP
3C61  SUB SP,2
3C64  CALL 84CBh
3C67  CALL 566Bh
3C6A  CALL 0995h
~~~

The caller is the Setup main-menu/presentation path. It invokes 566Bh before continuing with the normal screen setup and text-rendering helpers. This establishes 566Bh as a Setup UI video initialization helper, not an arbitrary alternate entry.

## 3. Aligned disassembly and behavior

~~~asm
566B  MOV AH,0Fh
566D  INT 10h
566F  CMP AL,07h
5671  JE 567Ah
5673  MOV AX,0003h
5676  INT 10h
5678  JMP 56C9h

567A  PUSH DS
567B  XOR AX,AX
567D  MOV DS,AX
567F  MOV AX,[0042h]
5682  POP DS
5683  CMP AX,0C800h
5686  JB 5697h
5688  CMP AX,0E000h
568B  JB 5692h
568D  CMP AX,0F000h
5690  JB 5697h
5692  MOV BYTE [55EAh],08h
5697  MOV WORD [55E8h],0B000h
569D  PUSH SI
569E  PUSH DI
569F  PUSH DS
56A0  POP ES
56A1  MOV SI,55EBh
56A4  MOV CX,0040h
56A7  MOV DI,562Bh
56AA  REP MOVSB
56AC  JMP 56CBh
~~~

Confirmed operations:

1. INT 10h AH=0Fh obtains the current video mode.
2. If AL is not 07h, the helper switches to mode 03h. Mode 07h is preserved.
3. On the preserved mode-07 path, it reads the segment word of the INT 10h vector from IVT address 0000:0042h.
4. It sets the attribute-mask byte at 55EAh to 08h when the vector segment is in [C800h,E000h) or is at least F000h. For vector segments below C800h or in [E000h,F000h), this branch leaves 55EAh unchanged.
5. It sets the display-buffer segment word at 55E8h to B000h.
6. It copies exactly 40h (64) bytes from CS:55EBh to CS:562Bh using DS as the source segment and ES=DS.
7. It jumps into the common attribute-table application at 56CBh.

The segment comparison is recorded literally; the code does not establish why those ranges were selected.

## 4. Palette table source and working copy

The source table is 55EBh–562Ah (64 bytes, 16 records × 4 bytes). The routine copies it to 562Bh–566Ah, which is the working table already used by the palette selector at 56AEh.

The source records, grouped as four bytes each:

| Record | Source address | Bytes |
|---:|---:|---|
| 0 | 55EBh | 07 70 70 07 |
| 1 | 55EFh | 70 70 70 70 |
| 2 | 55F3h | 07 07 07 07 |
| 3 | 55F7h | 70 07 07 70 |
| 4 | 55FBh | 70 70 07 07 |
| 5 | 55FFh | 07 70 70 70 |
| 6 | 5603h | 07 07 07 70 |
| 7 | 5607h | 70 07 07 07 |
| 8 | 560Bh | 70 70 70 07 |
| 9 | 560Fh | 07 70 07 07 |
| 10 | 5613h | 07 07 70 70 |
| 11 | 5617h | 70 07 70 07 |
| 12 | 561Bh | 07 70 07 70 |
| 13 | 561Fh | 07 07 70 07 |
| 14 | 5623h | 70 07 70 70 |
| 15 | 5627h | 70 70 07 70 |

The destination table at 562Bh–566Ah is read by the common routine at 56CBh. That routine takes the low nibble of [E037h] as an index, multiplies it by four, selects one record, then writes the record bytes and their rotated-nibble variants to E1A2h–E1A9h. The separate 56AEh handler updates the low nibble of [E037h] for the F2/F3 palette-selection path. This matches the existing AMI486_SCREEN_RENDERER_HELPERS_20261117.md description of the palette selector and attribute consumers.

## 5. Code/data boundary correction

| Range | Classification | Evidence |
|---|---|---|
| 55EBh–562Ah | Data: 16 × 4-byte palette source table | Copied as a 64-byte block by 56A1h–56AAh |
| 562Bh–566Ah | Data: 16 × 4-byte working palette table | Destination of the copy; consumed by 56CBh |
| 566Bh–56ADh | Code: Setup video-mode/INT 10h-vector initializer | Direct CALL from 3C67h; ends with JMP 56CBh |
| 56AEh–56F0h | Separate code entry: palette index update and apply helper | Direct callers include 0917h, 0E03h, 3D6Dh and 46EAh |

Thus 566Ah is data, not the start of an instruction. 566Bh is the first byte of the called routine. The existing palette-table data range was correctly bounded at 566Bh; the missing candidate code seed was 566Bh.

## 6. Generator update

tools/disasm_ami486_candidate_windows.py now:
- seeds a bounded code window at 566Bh with length 43h, ending after the JMP displacement at 56ADh;
- classifies 55EBh–562Ah as the source palette table;
- renames 562Bh–566Ah as the working copy.

The GitHub Actions workflow regenerated the candidate listing and manifest after this generator update. The latest checked-in mask reports 907 candidate windows, 251 data ranges and a 65,131/65,536-byte (99.38%) union. These are candidate inspection metrics, not semantic completion. No new linear disassembly is required; the byte-complete master listing already covers this range.

## 7. Remaining uncertainty

The ROM bytes prove the video-mode selection, IVT segment tests, B000h buffer-segment assignment, 64-byte table copy and palette application. They do not, by themselves, explain the OEM rationale for the INT 10h vector-segment intervals or the visual meaning of each four-byte palette record. Those interpretations remain deliberately open.
