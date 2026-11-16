# AMI486 semantic map — phase 95 (2026-11-16)

## 1. Correct entry sequence at 05A3h

Raw bytes and exact decode:

05A3 AND AL,0Fh
05A5 MOV SI,0AE1h
05A8 CALL 0AADh
05AB MOV BX,SI
05AD MOV SI,76F1h
05B0 CALL 05B4h
05B3 RET

The helper at 0AADh is:

0AAD PUSH AX
0AAE XOR AH,AH
0AB0 SHL AX,1
0AB2 ADD SI,AX
0AB4 MOV SI,[CS:SI]
0AB7 POP AX
0AB8 RET

This is a 16-entry word-pointer lookup indexed by AL (after AND AL,0Fh). The base of the pointer array is 0AE1h. The selected word is returned in SI, copied to BX, and used as the starting cursor for the 05B4h linked-record dispatcher. The earlier phase-92 claim that 05A3h calls a teletype helper at 0A0Dh and emits '6' is incorrect: there is no CALL 0A0Dh in this path.

## 2. Pointer array at 0AE1h

| AL index | Selected word | Role established so far |
|---:|---:|---|
| 0 | 0B75h | option-record chain base |
| 1 | 0B4Dh | option-record chain base |
| 2 | 0B55h | option-record chain base |
| 3 | 0B5Dh | option-record chain base |
| 4 | 0B65h | option-record chain base |
| 5 | 0B6Dh | option-record chain base |
| 6 | 0B45h | date/time callback chain base |
| 7 | 026Fh | overlapping code/table entry; first record at 0273h |
| 8 | 0AF5h | additional chain base; not fully classified |
| 9 | 63C9h | overlapping code/table entry; not fully classified |
| 10 | 0AEDh | additional chain base; not fully classified |
| 11 | 6373h | overlapping code/table entry; not fully classified |
| 12 | 0AFDh | additional chain base; not fully classified |
| 13 | 641Fh | overlapping code/table entry; not fully classified |
| 14 | 0AF5h | duplicate of index 8 |
| 15 | 63C9h | duplicate of index 9 |

The array is not itself a linked list. It selects one of several per-value chains or overlapping entries. The duplicated indices 8/14 and 9/15 are literal duplicate pointer values in the ROM.

## 3. Exact 05B4h record interpretation

05B4h begins with CALL 05E0h; 05E0h is a display/helper routine (`PUSH AX; PUSH DX; MOV DX,1203h; CALL 0845h; POP DX; POP AX; RET`). Then 05B7h adds four to BX and reads a four-byte record:

- [CS:BX] -> next cursor, saved at [BP+02h].
- [CS:BX+02h] -> near callback target, called with CALL AX.

Thus the dispatcher does not call the selected base pointer itself. It treats that pointer as a chain base, skips the first four bytes, and calls the callback field of the first record at base+4. This resolves the apparent contradiction at 0B5Dh/0B6Dh: those offsets are selected chain bases, not callback targets.

## 4. Verified chains for AL indices 0–6

| AL | Base | First record | Next cursor | Callback |
|---:|---:|---:|---:|---:|
| 0 | 0B75h | 0B79h | 0B4Dh | 064Ah |
| 1 | 0B4Dh | 0B51h | 0B55h | 060Eh |
| 2 | 0B55h | 0B59h | 0B5Dh | 0614h |
| 3 | 0B5Dh | 0B61h | 0B65h | 061Ah |
| 4 | 0B65h | 0B69h | 0B6Dh | 0620h |
| 5 | 0B6Dh | 0B71h | 0B75h | 0626h |
| 6 | 0B45h | 0B49h | 0AEDh | 6373h |

The callback wrappers 060Eh, 0614h, 061Ah, 0620h and 0626h load successive CS-resident option strings into SI and tail-jump to 05BAh. They are continuation callbacks, not conventional RET callbacks. This is why the dispatcher re-enters its record-fetch block after a callback.

## 5. Special overlapping entry at 026Fh

For AL=7, the lookup returns 026Fh. The dispatcher reads the first record at 0273h: next cursor=77D7h, callback target=16BAh. The same bytes at 026Fh also decode as an executable setup callback entry, so this is a real overlapping code/table case. Do not collapse the 026Fh code entry and 0273h record entry into one linear stream.

## 6. Dispatcher continuation protocol retained

After a callback returns, 05B4h saves flags and exits if CF=0, ZF=1, or AH=01h. Otherwise it restores flags, loads BX from [BP+02h], and tests AH. AH=51h advances BX by four before the next record; other AH values continue at the returned cursor. The exit path at 05DBh calls the renderer at 05EBh, then restores flags and returns. The initial CALL 05E0h is only a RET stub.

## 7. Corrections to phases 92–94

- 05A3h performs a nibble-indexed word lookup through 0AADh; it does not call 0A0Dh and does not print a fixed character.
- 0AE1h is a 16-entry pointer array. Its first eight entries select chain bases; it is not itself a four-byte callback record chain.
- 0B5Dh and 0B6Dh are chain-base pointers for AL=3 and AL=5, not callback code targets. The first callbacks on those chains are 061Ah and 0626h respectively.
- The four-byte records at 0B45h..0B9Dh are genuine linked callback records. The prior speculative linear decode from 0B5Dh through 0BE5h is invalid.
- 026Fh is a special overlapping case: it is both a reachable code entry and the selected base for a record beginning at 0273h.

## 8. Next work

1. Follow all records for AL=0..6 through the 05B4h AH/CF/ZF continuation rules and label each wrapper/string.
2. Resolve AL=7's record/callback and the overlap at 026Fh/0273h.
3. Decode the remaining pointer entries 8..15, especially overlaps at 63C9h, 6373h and 641Fh.
4. Reconcile the option chains with the Setup callbacks already mapped in phases 87–90.

## Audit correction — dispatcher display helper (2026-11-16)

The statement that `05E0h` is simply RET is withdrawn. Its entry is a real helper and the RET is at `05EAh`. The separate `05EBh` entry is invoked on the exit path. The raw bytes are recorded in phase 92's audit correction; the 05B4h linked-record and selected-base findings in this report are otherwise retained.
