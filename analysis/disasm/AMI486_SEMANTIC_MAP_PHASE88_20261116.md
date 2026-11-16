# AMI486 semantic map — phase 88 (2026-11-16)

## 1. Two callbacks are confirmed hexadecimal nibble editors

Targets 0319h and 0351h are aligned entry points in the callback table. Both call the common editor at 0383h and update one nibble of the byte at BP+12h.

### 0319h — high nibble of BP+12h

- Initializes BP+06h to zero.
- Loads the high nibble of BP+12h.
- If that nibble is Fh (sentinel), uses BP+19h as the displayed/editable fallback value.
- Calls 0383h with screen coordinate DX=0816h.
- On a valid edited nibble, shifts it left four bits, preserves the old low nibble, and stores the result in BP+12h; BP+19h is cleared.
- On the alternate/sentinel path, sets the high nibble of BP+12h to Fh and stores the edited value in BP+19h.

### 0351h — low nibble of BP+12h

- Initializes BP+06h to 0009h.
- Loads the low nibble of BP+12h.
- If it is Fh, uses BP+1Ah as the fallback.
- Calls 0383h with DX=0916h.
- On a valid edit, preserves the high nibble and replaces the low nibble; BP+1Ah is cleared.
- On the alternate/sentinel path, sets the low nibble to Fh and stores the edited value in BP+1Ah.

The paired use of Fh as a sentinel and BP+19h/BP+1Ah as side storage is confirmed by the actual load/store paths. The meaning of the containing configuration byte BP+12h is not yet established.

## 2. Common hexadecimal editor at 0383h

Entry 0383h begins by setting BP+09h to FFh, saving DX at BP+04h, selecting the prompt string at 7750h and calling the shared display helper at 05E0h. It then calls 03DEh to obtain/edit a character and stores the result at BP+08h.

The main loop interprets keyboard scan codes:
- AH=49h: decrement the hexadecimal digit;
- AH=3Ch / AH=3Dh: repeat/alternate editing control;
- otherwise increment the digit.

The digit is constrained to the hexadecimal range 0..F, with the display representation converted through the editor's character path. The helper returns flags and the edited value to the caller. This is a generic Setup hexadecimal digit editor, not an RTC callback.

The 0319h/0351h callers use this helper for the high and low nibbles of the same byte.

## 3. Important overlap at callback 02F1h

The callback table entry at 02F1h is an aligned instruction boundary immediately after a short jump beginning at 02EFh (EB 0E). The jump from the 02DBh high-nibble path skips the independent 02F1h low-nibble path and lands at the shared merge code at 02FFh. Thus 02DBh and 02F1h are two distinct callback entries that converge at 02FFh; 02F1h is not inside the jump instruction and is not a PUSH CS entry.

## 4. Remaining callback targets

- 02DBh: entry-aligned stream that reads/displays the high nibble of BP+10h and changes status bits in BP+14h; complete input/update semantics remain unresolved.
- 02F1h: overlapping alternate entry; decode separately from 02F0h.
- 026Fh: separate callback with a prompt/string pointer at 77D7h and a small dispatch/table area at 0280h..02A5h; not yet semantically labeled.

## 5. Coverage update

This phase closes the common hexadecimal input helper and the two BP+12h nibble callbacks. It does not assign a semantic name to BP+12h or the BP+10h/BP+14h pair. Next work is to resolve the overlapping 02F1h entry and the 026Fh callback/table, then return to the broader low-ROM coverage ledger.


## Raw-offset correction — 02DBh/02F1h entry alignment

The prior overlap description was off by one byte. Raw offsets are: short JMP at 02EFh (`EB 0E`), displacement at 02F0h, and the aligned low-nibble callback entry at 02F1h (`8A 46 10`). The high-nibble path jumps from 02EFh to 02FFh. Both paths converge at 02FFh (`PUSH AX`) and share the balanced epilogue `POP AX; POPF; RET` at 0316h..0318h. The earlier claim that 02F1h begins with PUSH CS is withdrawn.
