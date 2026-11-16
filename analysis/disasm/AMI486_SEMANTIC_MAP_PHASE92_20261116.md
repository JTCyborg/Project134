# AMI486 semantic map — phase 92 (2026-11-16)

## 1. Shared nibble-option helper at 05A3h

Both nibble callbacks (02DBh and 02F1h) call 05A3h, with different cursor coordinates in DX (0A16h and 0B16h). The helper is:

```asm
05A3  AND AL,0Fh
05A5  MOV SI,0AE1h
05A8  CALL 0A0Dh
05AB  MOV BX,SI
05AD  MOV SI,76F1h
05B0  CALL 05B4h
05B3  RET
```

The called helper at 0A0Dh is MOV AX,DX; OR AX,0E30h; INT 10h; RET. It emits the current low-nibble value as a BIOS teletype character. The subsequent string at 76F1h begins " Options:-". Thus 05A3h displays the current digit and enters a secondary option/callback menu; it is not the generic 0383h editor used by the BP+12h callbacks.

## 2. Secondary table at 0AE1h

05A3h sets BX=0AE1h before calling 05B4h. The dispatcher advances the cursor by four and reads linked records. The first record reached is at 0AE5h:

| Record offset | Next cursor | Indirect target |
|---:|---:|---:|
| 0AE5h | 0B55h | 0B5Dh |
| 0AE9h | 0B65h | 0B6Dh |
| 0AEDh | 0B45h | 026Fh |

Further records around 0AF1h feed the main Setup callback structure. The dispatcher at 05B4h applies its CF/ZF/AH continuation rules, so the table is not a simple sequential array.

## 3. Important unresolved target at 0B5Dh

The first indirect target read from the 0AE1h table is 0B5Dh. The raw ROM bytes at 0B5Dh begin 55 0B 0E 06 and overlap a dense sequence of four-byte-looking records extending through 0BDDh; a linear 16-bit decode from 0B5Dh does not immediately produce a coherent standalone callback contract. The region then reaches aligned Setup-page code at 0BE0h and later.

The call instruction at 05C4h is a near CALL AX, so a normal real-mode interpretation would enter CS:0B5Dh. However, the table-like bytes at that address do not yet establish a normal code entry. Do not infer that 0B5Dh is executable merely because it is the value loaded into AX; the runtime CS base/content, any relocated/shadow copy, and alternate instruction boundaries must be checked. This is a confirmed indirect target with unresolved execution semantics.

The next record at 0AE9h points to 0B6Dh, which is also within this dense region. The record at 0AEDh points to 026Fh, the already identified "Options:" callback. These relationships reinforce that the secondary table is threaded, but they do not prove that every target is a conventional code routine in the ROM byte stream.

## 4. Display helper preservation

The display helper 05E0h saves AX and DX, sets DX=1203h, calls 0845h, then restores DX and AX. The 0845h path saves/restores BX while rendering the CS-resident text, so the BX cursor established by 05A3h survives the prompt display before 05B4h advances it.

This rules out the simple explanation that 05E0h changes BX and thereby redirects the 05B4h table walk. SI is used as the string cursor by the display path, while the callback cursor remains in BX.

## 5. Current conclusions and next checks

Confirmed:
- 02DBh/02F1h both call 05A3h; 05A3h displays the current digit and the "Options:-" prompt before entering 05B4h.
- 05B4h is a linked callback dispatcher driven by record next-cursors and callback return flags/AH.
- The first table target is 0B5Dh; the next is 0B6Dh; a later record targets 026Fh.
- 05E0h/0845h preserve BX, so the initial table cursor is not lost during prompt rendering.

Unresolved:
- Whether CS:0B5Dh/0B6Dh are executable entries in the live runtime image, relocated code, or overlapping table/code regions.
- The exact callback contract and runtime traversal of the 0AE1h table.
- The relationship between the 05A3h digit-option menu and the BP+10h nibble validation state.

Next: establish the live CS value/base and whether the BIOS executes from a shadow/relocated image at the time of Setup callbacks; then trace 0B5Dh and 0B6Dh with the correct runtime address mapping before assigning semantics.
