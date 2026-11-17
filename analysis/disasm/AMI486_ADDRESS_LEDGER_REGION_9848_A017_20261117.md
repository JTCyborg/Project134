# AMI486 address-ledger extension: INT 10h video BIOS

Date: 2026-11-17  
ROM: ami486.bin, 65,536 bytes  
SHA-256: 91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b

## 1. Dispatcher and table boundary

The executable INT 10h dispatcher begins at 9870h. It special-cases AH=0Eh (teletype), AH=02h (set cursor position), AH=03h (get cursor position) and AH=05h (select active page). Other supported functions use the 20-word table at 9848h–986Fh.

The table base is independently established by the instruction at 98A? that calls through CS:[DI-67B8h] after DI=2*AH. In 16-bit IP arithmetic, the effective base for AH=0 is 9848h. The table is data, not instructions; the linear decoder's apparent opcodes at 9848h–986Fh are an overlapping view.

Exact little-endian table:

| AH | Target | BIOS function |
|---:|---:|---|
| 00h | 98C3h | Set video mode |
| 01h | 999Fh | Set cursor shape |
| 02h | 99A8h | Set cursor position (also special-cased) |
| 03h | 99FBh | Get cursor position (also special-cased) |
| 04h | 9A13h | Read light-pen position |
| 05h | 9ABBh | Select active display page (also special-cased) |
| 06h | 9AEAh | Scroll window up |
| 07h | 9AEEh | Scroll window down |
| 08h | 9C4Bh | Read character/attribute at cursor |
| 09h | 9D37h | Write character and attribute |
| 0Ah | 9DADh | Write character only |
| 0Bh | 9ED4h | Set palette/color select |
| 0Ch | 9EF9h | Write graphics pixel |
| 0Dh | 9F16h | Read graphics pixel |
| 0Eh | 9F21h | Teletype output (special-cased) |
| 0Fh | 9F6Ah | Return current video mode |
| 10h | 9F7Dh | RET stub |
| 11h | 9F7Dh | RET stub |
| 12h | 9F7Dh | RET stub |
| 13h | 9F7Eh | Write string |

The dispatcher rejects AH>13h, sets DS=0040h, selects the B000h or B800h display segment based on the current mode, then calls the selected handler. The table confirms the handler entry offsets independently of the global linear decode.

## 2. Mode and cursor services

### 2.1 AH=00h — 98C3h set video mode

98C3h updates BDA mode byte 0040:0049h and related state, selects the CRTC base at BDA 0040:0063h (3D4h or 3B4h), derives mode-dependent parameters and writes the CRTC register set from the BIOS video parameter table referenced through BDA 0040:0074h. It updates columns, rows/page geometry and cursor state, clears the active display buffer with REP STOSW, and writes the final mode/control values to the CRTC.

The mode-dependent paths distinguish text and graphics modes and use B000h/B800h display memory. The routine returns at 999Eh.

### 2.2 AH=01h — 999Fh set cursor shape

999Fh stores CX at BDA 0040:0060h, selects CRTC register 0Ah, and writes the cursor start/end scan-line values through the active CRTC base. It joins the common CRTC writer at 99E1h.

### 2.3 AH=02h / AH=03h — 99A8h / 99FBh

99A8h stores DX in the selected page's cursor slot at BDA 0040:0050h + 2*BH. If BH is the active page, it calls 99CDh to convert row/column to a CRTC cursor address and update registers.

99FBh reads the selected page's cursor position and the cursor-shape word at BDA 0040:0060h, returning them in DX/CX.

### 2.4 AH=04h — 9A13h read light-pen position

9A13h reads the display status port at CRTC base+6, checks the light-pen status bits, selects CRTC register 10h and reads the captured coordinates. It converts the raw values according to the active video mode and geometry, writes the resulting fields into the caller's saved register frame, and returns AH=1 when the light-pen status path is active.

## 3. Display-page and scrolling services

### 3.1 AH=05h — 9ABBh select active page

9ABBh saves the caller state, writes AL to BDA 0040:0062h, computes the page start address using the current page size at BDA 0040:004Ch, writes the CRTC start address through 99E1h, and restores the cursor position for the newly active page through 99CDh.

### 3.2 AH=06h / AH=07h — 9AEAh / 9AEEh

The two table targets are alternate entries into one shared scroll engine:
- 9AEAh clears BL and jumps to common entry 9AF3h (scroll up).
- 9AEEh sets BL=FFh, saves the source position in SI, sets DF and falls into 9AF3h (scroll down).

The shared routine computes the rectangle geometry, chooses text or graphics addressing from BDA mode 0040:0049h, waits for display status when required, moves rows with REP MOVSB/MOVSW and fills the vacated rows with the requested attribute/color. The graphics-mode paths account for the 2000h plane offset and the 50h row stride. The routine returns at 9C4Ah.

Preserve 9AEAh and 9AEEh as separate public entry points even though their bodies converge.

## 4. Character and graphics services

### 4.1 AH=08h — 9C4Bh read character/attribute

9C4Bh computes the display-memory address from page, cursor row/column and mode geometry. Text modes read the character/attribute word from display memory. Graphics modes use the CRTC status and the 2000h plane spacing to obtain the relevant byte/word. The result is written into the caller's saved AX slot at [BP+14h]; the routine restores SP from BP and returns at 9D36h.

### 4.2 AH=09h — 9D37h write character and attribute

9D37h computes the page/cursor address and writes CX copies of the character/attribute word. Text modes use STOSW; graphics modes use the CRTC status path and repeated writes to the relevant plane/address. It returns at 9DACh.

### 4.3 AH=0Ah — 9DADh write character only

9DADh shares the page/cursor address calculation with AH=09h but writes the character without replacing the attribute. Text modes use STOSB; graphics modes use the plane-aware write path beginning at 9E20h. The graphics path handles both 16-bit and 8-bit mode layouts and returns at 9ED3h.

### 4.4 AH=0Bh — 9ED4h set palette/color select

9ED4h updates BDA 0040:0066h using BH/BL and writes the resulting color-select value to CRTC base+5. The function returns at 9EF8h.

### 4.5 AH=0Ch / AH=0Dh — 9EF9h / 9F16h

9EF9h computes a pixel address through A018h, applies the requested color/XOR mode and writes the pixel byte to ES:[SI]. 9F16h uses the same address helper, extracts the selected pixel bits and stores the return value into the caller's saved AX frame.

## 5. Text-output services

### 5.1 AH=0Eh — 9F21h teletype output

The dispatcher routes AH=0Eh directly to 9F21h. The routine saves DS/registers, selects BDA segment 0040h, gets the active page, and handles control characters:
- CR and LF update the cursor/line;
- BS and BEL take dedicated paths;
- printable characters use the BIOS character-write path;
- cursor position is restored through AH=02h.

9FD9h is a shared character-output/cursor-wrap helper; 9FE8h is an alternate line-advance entry used by the BEL/LF paths. The scroll/line-wrap code eventually calls the existing video services rather than writing the BDA cursor blindly.

### 5.2 AH=0Fh — 9F6Ah return current mode

9F6Ah returns AL=mode, AH=column count and BH=active page from BDA 0040h. It stores the AX result in the caller's saved frame and returns.

### 5.3 AH=10h–12h — 9F7Dh

The table maps these three services to a one-byte RET stub. This ROM path does not implement the later palette/DAC service family at these function numbers.

### 5.4 AH=13h — 9F7Eh write string

9F7Eh consumes a string at ES:BP, length CX, page BH and mode/attribute flags in AL/BL. It iterates the string, routes control characters through AH=0Eh, writes printable characters through AH=09h, and restores cursor state. It calls the separate cursor-wrap helper at 9FD9h (and the line-advance alternate entry at 9FE8h) and returns at 9FD8h.

## 6. Data/code boundary and alternate entries

- 9848h–986Fh is the 20-word INT 10h service table. It is data despite the linear decode showing instructions.
- 9AEAh and 9AEEh are two distinct scroll-service entries which converge at 9AF3h.
- 9DADh branches to the graphics-specific continuation at 9E20h.
- 9F21h has internal control-character branches to 9FD9h and 9FE8h.
- 9F7Dh is a shared RET target for AH=10h/11h/12h.
- 9F7Eh ends at 9FD8h; the separate cursor-wrap/line-advance helpers at 9FD9h/9FE8h end at A017h; A018h is a separate graphics helper entry.

The byte at 9847h before the pointer table remains unclassified; do not absorb it into the table without a consumer.

## 7. Candidate-generator update and remaining items

The generator now seeds the INT 10h dispatcher, all 20 table targets, the two scroll alternate entries and the shared output helpers. It emits 9848h–986Fh as a separate 20-word data range.

The current report does not claim that the entire video subsystem beyond A017h is complete. Pixel-address helpers at A018h/A050h/A067h are cross-region dependencies and should be audited together with the graphics modes. Runtime installation/source of the INT 10h vector and the exact semantics of all graphics-mode edge cases remain open.

This is a bounded INT 10h subsystem map, not a whole-ROM semantic completion claim.
