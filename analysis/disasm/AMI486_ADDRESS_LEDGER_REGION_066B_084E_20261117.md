# AMI486 address ledger — BIOS Setup numeric/text field editor 066Bh–084Eh

Date: 2026-11-17  
Repository: JTCyborg/Project134, branch main  
ROM: ami486.bin, 65,536 bytes; SHA-256 91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b

## 1. Region role

The 484-byte interval 066Bh–084Eh is BIOS Setup user-interface code for editing numeric fields and entering text. It is not POST instruction flow. The generic numeric editor is directly called by Setup routines at 4BA3h, 4F4Ch and 4F67h; these callers operate on the fixed-disk parameter/configuration records around CS:E401h–E6F0h.

No embedded data table is identified inside this interval. The code uses external prompt/format strings and shared character-rendering routines elsewhere in the ROM.

## 2. Structure-field helpers

Four short entries at 066Bh, 068Ah, 069Ch and 06AEh call the shared numeric renderer/editor at 0749h and store the returned value into a caller-owned BP-relative structure:

- 066Bh: uses DX=0018h and SI=3, stores a byte at BP+SI+1Dh, and sets the companion width/format byte at BP+SI+20h according to whether the value is <=8.
- 068Ah: uses DX=001Eh and SI=5, stores a word at BP+SI+1Eh.
- 069Ch: uses DX=0024h and SI=5, stores a word at BP+SI+21h.
- 06AEh: uses DX=002Ah and SI=3, stores a byte at BP+SI+23h; if the returned AH is 4Dh it normalizes it to 50h.

No direct relative CALL xrefs to these four entries were found. Preserve them as bounded indirect-entry candidates; do not invent a caller.

## 3. Generic numeric field editor: 06C9h

06C9h is called directly from:
- 4BA3h: edits a byte/field associated with the fixed-disk Setup record at CS:E422h.
- 4F4Ch and 4F67h: edits values obtained from a three-byte-per-entry table based at CS:E436h.

The routine establishes a BP-relative local frame, saves the caller's AX/BX/CX/DX/SI/DI state, positions the cursor, displays the current value and enters the keyboard loop at 076Bh. Parameters supplied by the callers determine field width, range and destination.

The editor returns the numeric value in DX and the entered digit count in CX. The carry state distinguishes the accept/cancel/error paths; callers check the returned value and the Escape result (001Bh).

## 4. Rendering and cursor helpers

| Entry | Behavior | Direct CALL references |
|---|---|---|
| 0731h | Refreshes/formats the current field value | 06E2h, 072Bh |
| 0744h | Cursor/input wrapper using the current BP-relative field buffer | 06ECh |
| 0749h | Draws the field at the supplied screen coordinates and invokes the shared character renderer 65A7h | 0656h, 0671h, 0690h, 06A2h, 06B4h |

0749h saves the cursor coordinates, writes the field using INT 10h/AH=03h and the 65A7h character renderer, then restores the cursor. It uses the color attribute at CS:E1A3h and its high-bit variant for the selected field.

## 5. Keyboard input loop: 076Bh–080Eh

The numeric editor reads keystrokes through INT 16h/AH=00h and handles:
- Backspace (scan code 0Eh): removes the last digit and refreshes the field.
- Enter (scan code 1Ch): accepts the current value.
- Escape (scan code 01h): returns the cancel path.
- Right/left arrows (4Dh/4Bh): move the cursor/selection.
- Down/up arrows (50h/48h): adjust the selected field.
- PageUp/PageDown (49h/51h): use the field's alternate adjustment paths.
- ASCII digits 30h–39h: append digits to the temporary buffer, bounded by the field width.

Invalid keys or invalid digits call F571h (audible/visual error feedback). The loop returns the field's accepted state to 06C9h.

## 6. Decimal conversion and range checking: 080Fh–0844h

080Fh parses the digit buffer as a base-10 integer:
1. Starts AX at zero.
2. Multiplies by ten for each digit.
3. Converts ASCII digits by subtracting 30h.
4. Adds each digit and checks carry/overflow.
5. Applies the width-dependent upper bound (five-digit fields may use the 16-bit range; shorter fields are limited to FFh).
6. On overflow, calls F571h and returns the current digit count for correction.

The routine returns the numeric value in DX and preserves the caller's SI/AX state.

## 7. Text-input entry: 0845h

0845h is a short text-input entry called from 05E5h. It loads the current color attribute from CS:E1A6h, saves DX and jumps to the shared text editor at 0892h. The caller at 05E0h supplies screen coordinate 1203h. The body at 0892h lies outside this uncovered interval and is handled by the existing candidate map.

The exact Setup field edited through this text path remains unresolved; retain the confirmed entry/caller relationship without assigning it a password or drive-label meaning.

## 8. Generator integration

The candidate generator now includes bounded entries for the four BP-relative field helpers, generic numeric editor, render/cursor helpers, keyboard loop, decimal parser and text-input prologue. The entire 066Bh–084Eh interval is treated as executable code.

The CI manifest is the verification gate for this update; the next largest uncovered interval will be taken from the completed run.
