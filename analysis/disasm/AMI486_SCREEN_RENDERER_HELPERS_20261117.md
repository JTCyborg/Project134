# AMI486 screen-rendering and field-editor helper map

Date: 2026-11-17  
ROM: `ami486.bin`, 65,536 bytes  
Related reports:
- [Low-ROM screen-presentation stream](AMI486_LOW_ROM_SETUP_VIDEO_ENTRY_20261117.md)
- [Temporary IVT/calendar refresh](AMI486_TEMPORARY_IVT_CALENDAR_REFRESH_20261117.md)

## 1. Text output primitives

### 0862h / 084Fh / 086Fh / 0879h / 0883h

These are entry variants into the common string renderer beginning at 0892h.

- 0862h takes the display attribute from `[E1A2h]`, ORs it with `[55EAh]` through 08C8h, then enters the common renderer.
- 084Fh takes the attribute from `[E1A3h]`.
- 086Fh takes the attribute from `[E1A4h]`.
- 0879h and 0883h use `[E1A2h]`; 0883h also reads an initial cursor coordinate word from `CS:[SI]`, swaps its bytes, and advances SI.
- The common loop at 0892h sets the cursor with INT 10h AH=02h, reads NUL-terminated characters from CS:SI, handles CR (reset column to 3), LF (increment row) and BS (decrement column), then writes ordinary characters using INT 10h AH=09h.

### 08C8h — attribute mask

```asm
08C8 OR BL,[55EAh]
08CC RET
```

This combines the selected UI attribute in BL with a global mask byte at 55EAh.

### 098Eh — clear cells

```asm
098E MOV AH,09h
0990 MOV AL,20h
0992 INT 10h
0994 RET
```

The caller supplies BH, BL, CX and cursor position. This writes a run of spaces with the requested attribute.

### 09CEh — recolor existing cells

For each of CX cells, starting at the cursor coordinate in AX:
1. Set the cursor through 09C1h / INT 10h AH=02h.
2. Read the current character/attribute with INT 10h AH=08h.
3. OR the existing attribute with the mask at 55EAh via 08C8h.
4. Write the same character back with INT 10h AH=09h.
5. Advance the cursor column and repeat.

The 00EFh screen routine calls this at AX=0517h and AX=0617h with CX=0010h, so it updates 16 cells on each of two rows.

### 09C1h — set cursor

Copies AX to DX, sets BH=0 and invokes INT 10h AH=02h; preserves BX and DX.

## 2. Numeric field output

### 09FDh — unsigned decimal printer

Uses repeated division by ten. It recursively emits the quotient while preserving the remainder, then prints the current digit with INT 10h AH=0Eh. The routine handles zero as a single digit.

### 0970h / 0975h — unit suffix

- 0970h emits a leading space followed by `KB`.
- 0975h emits a leading space followed by `MB`.

### 0A15h — fixed-width numeric field

- Positions the cursor using AX.
- Clears nine character cells through 098Eh.
- Prints the unsigned decimal value through 09FDh.
- Appends the unit suffix through 0970h.

The 00EFh screen routine calls 0A15h at coordinates 0543h and 0643h using values from its BP-relative frame. The exact source-field names remain unresolved, but the display contract is numeric value plus KB suffix.


### 04B0h — hard-disk geometry capacity calculation

The helper consumes the working geometry fields prepared by 0538h:
- cylinders: word `[BP+40h]`;
- heads: byte `[BP+42h]`;
- write-precomp/related word: `[BP+43h]`;
- landing-zone word: `[BP+45h]`;
- sectors per track: byte `[BP+47h]`.

It multiplies sectors × heads × cylinders to obtain a 32-bit sector count, divides by `0800h` (2048 sectors per MiB for 512-byte sectors), and rounds to the nearest MiB using the `0400h` half-unit threshold. If the quotient would exceed 16 bits, it saturates the size field to FFFFh. It stores the calculated capacity at `[BP+48h]`, then displays the geometry fields and the capacity with the MB suffix from 0975h. The capacity arithmetic is confirmed; the source record's vendor-specific field names beyond the observed offsets remain partly unresolved.

## 3. Cursor visibility and panel clearing

### 0995h / 099Dh — cursor-shape normalization

Both read the current cursor shape with INT 10h AH=03h, mask the scan-line values, apply compare/swap logic and write the shape with INT 10h AH=01h.
- 0995h uses BL=20h and ORs bit 20h into CH, which is the BIOS text-cursor disable bit; this hides the cursor while drawing.
- 099Dh uses BL=00h and normalizes the scan-line ordering without forcing the disable bit.

The 00EFh routine calls 0995h at entry and 099Dh on its exit path.

### 05EBh — clear lower screen panel

Starts at row 12h, column 03h, uses attribute `[E1A6h]`, and clears 2Eh cells per row. It advances through rows 12h, 13h and 14h, stopping when DH reaches 15h.

## 4. Grid and panel renderers

### 622Bh — draw calendar/grid frame

Uses the strings/line patterns at 6177h, 6195h, 61B3h, 61D1h, 61EFh and 620Dh, with the shared 086Fh text renderer. It places horizontal/vertical separators at rows 0Ah–0Dh and returns. This is the frame helper used by the 00EFh presentation path.

### 3E3Fh — secondary screen panel

The entry saves BP/AX/BX, copies `[E1A8h]` to `[E19Fh]`, and invokes text/box helpers 578Dh, 58AFh, 58C6h, 5862h and 5802h. It later switches `[E19Fh]` to `[E1A2h]` and calls 5802h again. The inner 3E99h continuation is a separate renderer path. Its exact screen title/panel identity remains tied to the caller-supplied strings and is not named here.

### 5802h — rectangular cell fill

Uses ES:DI as a text-screen cell buffer. It fills CX rows with spaces, writes words with STOSW, and advances DI by 00A0h bytes per row (80 text columns × 2 bytes). It then jumps to the common box/text continuation at 5711h.


### 56AEh — select one of 16 UI attribute palettes

The handler reads the low nibble of `[E037h]` as a palette index. F2 (scan code 3Ch) increments it; F3 (scan code 3Dh) decrements it; the result wraps to four bits while preserving the high nibble of `[E037h]`. It indexes a 16-entry, four-byte table at `562Bh–566Ah`, then expands each table byte into two nibble-swapped attribute bytes and writes eight bytes at `E1A2h–E1A9h`. This supplies the attribute variants consumed by the text and fill helpers.

### 5821h — apply attributes to a text rectangle

Computes the starting text-buffer offset through 57E7h, then loops over caller-supplied rows and columns. For each cell it updates only the attribute byte (character byte is left untouched), preserving bits 7 and 3, ORing the selected attribute bits, and applying `[55EAh]` when bit 3 is set. The row stride is `00A0h` bytes (80 columns × 2 bytes). The F2/F3 keyboard path calls 56AEh to choose a palette and 5821h to apply the new attributes to the existing screen.

## 5. Numeric/option field editor

### 03D4h — field editing dispatcher

The routine stores the input value and cursor coordinate in its BP frame, then branches on the input byte:
- For AL=2Fh, it calls 0538h and, when the local status byte is set, walks four-byte records starting from the table at 0BD5h, invoking callback addresses indirectly through AX.
- For AL=00h, it calls 0566h to draw the hard-disk geometry header and clear a 38h-character field; it may invoke the keyboard handler at 08CDh, then calls 0577h to redraw the header using the alternate attribute.
- Other values take the local validation/return path.

The record callbacks and the meaning of the local status byte at BP+09h remain unresolved.

### 0566h / 0577h — geometry header and field clearing

Both use the header string at 74ACh and cursor coordinate 0727h. They then position the cursor at the caller-supplied coordinate `[BP+04h]` and clear 38h cells with 098Eh. They differ in attribute source:
- 0566h uses `[E1A3h]` through 084Fh.
- 0577h uses `[E1A2h]` and 08C8h.

### 08CDh — keyboard navigation/input handler

Reads a key with INT 16h AH=00h. It explicitly recognizes:
- scan codes 3Ch/3Dh (F2/F3),
- 4Dh/50h (Right/Down),
- 4Bh/48h (Left/Up),
- 1Ch (Enter).

The F2/F3 path enters a larger screen-update path (0910h onward), saves registers/segments, calls 56AEh and display helper 5821h, and changes the global attribute mask at 55EAh. The exact high-level action associated with F2/F3 is not inferred from scan codes alone.

## 6. Additional direct callees queued for decode

The following direct targets were added to the candidate generator because they are reached from the above aligned streams:
- 04B0h — called by 0538h (field-record update).
- 56AEh — called by 08CDh (keyboard update).
- 5821h — called by 08CDh (display update).

These three windows have now been generated and reviewed. Their confirmed contracts are documented above: 04B0h calculates disk capacity, 56AEh selects the attribute palette, and 5821h applies attributes to the text rectangle.

## 7. Integrated interpretation

The 00EFh–0235h stream is a screen presenter built from:
- cursor hide/restore;
- attribute-aware NUL-terminated string output;
- fixed-width numeric fields and KB/MB suffixes;
- rectangular fill and border drawing;
- a four-byte callback walker;
- a keyboard-driven field editor;
- temporary INT 10h/1Ah/1Ch hooks and timer-driven calendar refresh.

This supports a System Configuration/Setup-style presentation, but the static entry into 00EFh and its caller stack precondition remain unresolved. The helper map does not prove which boot/Setup path invokes it.


## 8. Palette table

The 64 bytes at `562Bh–566Ah` are a 16-entry × 4-byte attribute palette table. The selector at 56AEh indexes it with `[E037h]&0Fh`; the selected four bytes are expanded to eight display attributes at E1A2h–E1A9h. This range is now added to the explicit data-range ledger.
