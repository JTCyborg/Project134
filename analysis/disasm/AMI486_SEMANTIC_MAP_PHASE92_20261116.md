# AMI486 semantic map — phase 92 (2026-11-16)

## 1. Shared nibble-option helper at 05A3h

Both nibble callbacks (02DBh and 02F1h) call 05A3h, with different cursor coordinates in DX (0A16h and 0B16h). The helper is:

```asm
05A3  AND AL,0Fh
05A5  MOV SI,0AE1h
05A8  CALL 0AADh
05AB  MOV BX,SI
05AD  MOV SI,76F1h
05B0  CALL 05B4h
05B3  RET
```

The helper at 0AADh indexes the 16-word pointer array at 0AE1h using AL (after AND AL,0Fh): it zero-extends AL into AX, doubles it, adds it to SI, and loads the selected word from CS:[SI]. The selected chain base is copied to BX; SI is then set to the " Options:-" string at 76F1h for the dispatcher exit renderer. Thus the nibble in AL selects a callback chain.

## 2. Secondary table at 0AE1h

05A3h sets BX=0AE1h before calling 05B4h. The dispatcher advances the cursor by four and reads linked records. The first record reached is at 0AE5h:

| Record offset | Next cursor | Indirect target |
|---:|---:|---:|
| 0AE5h | 0B55h | 0B5Dh |
| 0AE9h | 0B65h | 0B6Dh |
| 0AEDh | 0B45h | 026Fh |

Further records around 0AF1h feed the main Setup callback structure. The dispatcher at 05B4h applies its CF/ZF/AH continuation rules, so the table is not a simple sequential array.

## 3. Important unresolved target at 0B5Dh

The first indirect target read from the 0AE1h table is 0B5Dh. The raw ROM bytes at 0B5Dh begin 55 0B 0E 06. They can be grouped into four-byte next-cursor/target-looking records, but a 16-bit decode from 0B5Dh also yields aligned instruction entries at 0B5Dh and 0B6Dh with conditional branches. The same region therefore has a confirmed dual-use/overlapping code-and-record interpretation; it must not be classified as plain data. See phase 93 for the initial control-flow map.

The call instruction at 05C4h is a near CALL AX, so a normal real-mode interpretation would enter CS:0B5Dh. However, the table-like bytes at that address do not yet establish a normal code entry. Do not infer that 0B5Dh is executable merely because it is the value loaded into AX; the runtime CS base/content, any relocated/shadow copy, and alternate instruction boundaries must be checked. This is a confirmed indirect target with unresolved execution semantics.

The next record at 0AE9h points to 0B6Dh, an aligned alternate instruction entry in the same region. The record at 0AEDh points to 026Fh, the already identified "Options:" callback. These relationships reinforce the threaded/overlapping structure, but do not yet prove whether the four-byte record view is consumed during the same execution.

## 4. Display helper preservation

The display helper 05E0h saves AX and DX, sets DX=1203h, calls 0845h, then restores DX and AX. The 0845h path saves/restores BX while rendering the CS-resident text, so the BX cursor established by 05A3h survives the prompt display before 05B4h advances it.

This rules out the simple explanation that 05E0h changes BX and thereby redirects the 05B4h table walk. SI is used as the string cursor by the display path, while the callback cursor remains in BX.

## 5. Current conclusions and next checks

Confirmed:
- 02DBh/02F1h both call 05A3h; 05A3h emits the character '6' from DL=16h, then displays the "Options:-" prompt and enters 05B4h. The masked AL value is overwritten and its purpose remains open.
- 05B4h is a linked callback dispatcher driven by record next-cursors and callback return flags/AH.
- The first table target is 0B5Dh; the next is 0B6Dh; a later record targets 026Fh.
- 05E0h/0845h preserve BX, so the initial table cursor is not lost during prompt rendering.

Unresolved:
- Whether CS:0B5Dh/0B6Dh are executable entries in the live runtime image, relocated code, or overlapping table/code regions.
- The exact callback contract and runtime traversal of the 0AE1h table.
- The relationship between the 05A3h digit-option menu and the BP+10h nibble validation state.

Next: establish the live CS value/base and whether the BIOS executes from a shadow/relocated image at the time of Setup callbacks; then trace 0B5Dh and 0B6Dh with the correct runtime address mapping before assigning semantics.


## Correction — 0A0Dh output value

The earlier description that 0A0Dh displays the current nibble was incorrect. 0A0Dh loads AX from DX, then ORs AX with 0E30h before INT 10h/AH=0Eh. With DX=0A16h or 0B16h, the emitted character is '6'. The AL nibble masked at 05A3h is overwritten by MOV AX,DX and has no proven downstream use in this helper path.


## Phase 93 correction — dual-use 0B5Dh region

The 0B5Dh/0B6Dh region is not merely a table-like byte block. Both offsets are indirect callback targets and aligned 16-bit instruction entries; the same bytes also form four-byte record-like pairs. The classification is now dual-use/overlap candidate pending runtime proof.


## Phase 94 correction — 05B4h entry behavior

The initial CALL at 05B4h targets 05E0h, which is a single RET stub. It does not render the prompt. The renderer at 05EBh is called only on the dispatcher exit path at 05DBh. The dispatcher reads [CS:BX] as the next cursor, calls [CS:BX+2], then uses CF/ZF/AH to decide whether to exit, skip one record, or continue at the returned cursor. See phase 94 for the exact instruction and branch map.


## Phase 95 correction — nibble lookup

The 05A3h call is to 0AADh, not 0A0Dh. 0AADh performs a 16-entry word-pointer lookup from 0AE1h indexed by AL. The returned SI is the selected callback-chain base and is copied to BX. The previous claim that this path prints a fixed '6' is withdrawn. See phase 95 for the pointer array and first-record map.
