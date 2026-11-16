# AMI486 semantic map — phase 94 (2026-11-16)

## 1. Exact 05B4h dispatcher instruction stream

05B4 CALL 05E0h; 05B7 ADD BX,04h; 05BA MOV AX,[CS:BX]; 05BD MOV [BP+02h],AX; 05C0 MOV AX,[CS:BX+02h]; 05C4 CALL AX.
05C6 PUSHF; 05C7 JNC 05DBh; 05C9 JZ 05DBh; 05CB CMP AH,01h; 05CE JZ 05DBh.
05D0 POPF; 05D1 MOV BX,[BP+02h]; 05D4 CMP AH,51h; 05D7 JZ 05B7h; 05D9 JMP 05BAh.
05DB CALL 05EBh; 05DE POPF; 05DF RET; 05E0 RET.

The call at 05B4h to 05E0h is a no-op stub (RET), not the prompt renderer. The renderer begins at 05EBh and is called only on the dispatcher exit path at 05DBh. This corrects the earlier phase-92 description.

## 2. Linked-record traversal and callback result contract

The dispatcher uses a four-byte record at CS:BX: word [BX] is copied to [BP+02h] as the next cursor; word [BX+02h] is called as a near callback in the current CS.

After callback return, PUSHF preserves callback flags. CF=0, ZF=1, or AH=01h exits through 05DBh. Otherwise flags are restored, BX is loaded from [BP+02h], and AH is tested. AH=51h advances BX by four before fetching the next record; any other AH uses BX as-is. This is not a simple linked-list traversal: callback return flags and AH select exit/skip/continue.

## 3. Initial records and unresolved 0B5Dh target mismatch

05A3h sets BX=0AE1h and calls 05B4h. After the RET stub and ADD BX,4h, record 0AE5h is selected:

| Record | Next cursor | Callback target |
|---:|---:|---:|
| 0AE5h | 0B55h | 0B5Dh |
| 0AE9h | 0B65h | 0B6Dh |
| 0AEDh | 0B45h | 026Fh |

The first two callback targets are offsets inside the dense four-byte record region beginning at 0B55h. Bytes at 0B5Dh begin 55 0B 0E 06; bytes at 0B6Dh begin 65 0B 1A 06. A direct 8086 decode produces implausible operations, while the surrounding bytes form regular record pairs.

This is an unresolved contradiction: the dispatcher performs CALL AX to 0B5Dh/0B6Dh, but the bytes at those raw-image offsets look like table data, not sensible callback code. Do not claim these are semantically valid code entries. Possible explanations include active CS mapping to a shadow/relocated image, intentional alternate instruction streams, or an incomplete understanding of the table setup. No explanation is selected.

## 4. Corrections to prior reports

- Phase 92: CALL 05E0h at dispatcher entry is a RET stub. Prompt rendering occurs via 05DBh -> CALL 05EBh, not before the first record.
- Phase 93: 0B5Dh/0B6Dh are raw-image indirect CALL targets, not confirmed valid instruction entries. The claimed linear path through 0BE5h is withdrawn as an established code path.
- Branches at 0B71h/0B85h/0BA1h belong only to speculative linear decoding of record bytes and are not confirmed control-flow facts.

## 5. Next work

1. Trace assignments/loads of CS and far transfers in POST and Setup, including shadow-copy operations.
2. Find references to source/destination ranges covering 0A00h..0C80h.
3. Reconstruct the full four-byte record chain at 0B45h..0BDD h using the exact 05B4h cursor/AH rules.
4. Identify valid callback code targets only after confirming active CS mapping or independent entry evidence.