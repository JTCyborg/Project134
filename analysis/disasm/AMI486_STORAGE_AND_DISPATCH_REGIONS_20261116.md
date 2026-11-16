# AMI486 storage, keyboard and dispatch regions — 2026-11-16

Source: `ami486.bin`, 65,536 bytes, SHA-256 `91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b`  
Decode aid: `analysis/disasm/ami486_candidate_windows_20261116.txt`  
Generator: `tools/disasm_ami486_candidate_windows.py`  
Decoder: Capstone x86, 16-bit; independently seeded windows with near-branch targets wrapped to 16-bit IP.

## 1. A000h–AFFFh: IDE/ATA hard-disk and boot-sector protection code

This region is not a floppy-disk controller driver. Its I/O port set is the primary ATA task-file interface:
- 01F0h — data
- 01F1h — error/features
- 01F2h — sector count
- 01F6h — drive/head
- 01F7h — command/status
- 03F6h — alternate status/device control

### 1.1 Main routines and evidence

| Entry | Observed behavior | Confidence |
|---:|---|---|
| A1B3h | Writes 04h then 00h to 03F6h, waits via E93Ch, polls through A62Dh, reads 01F1h, checks for value 01h, then probes selectors 80h/81h using A501h and A337h. | High: direct I/O and control flow |
| A337h | Calls readiness/parameter helpers, writes sector count to 01F2h, selects drive/head through 01F6h, then sends command 91h through the command path. | High |
| A406h | Prepares ES:SI buffer and transfers 0100h words using `REP OUTSW` to 01F0h; optional path sends four extra bytes. | High |
| A501h | Selects a drive through 01F6h, writes feature/error value through 01F1h, sends command 10h through 01F7h, then polls status. | High |
| A52Bh | Sends command 90h, reads 01F1h and expects value 01h. | High |
| A621h | Writes AL to 01F1h. | High |
| A62Dh | Polls status through 01F7h with a bounded retry loop and stores status on timeout. | High |
| A655h | Selects the requested drive through 01F6h, waits, reads status from 01F7h and maps status bits to an error code. | High |
| A73Eh | Masks selected interrupt-controller bits, writes the command byte to 01F7h, restores state and waits. | High |
| AC00h | Selects a drive, sends command ECh (ATA IDENTIFY DEVICE), then reads 0100h words from 01F0h with `REP INSW` into ES:DI. | High |
| A76Ch | Converts ES:BX into a normalized ES:offset buffer address. | High |
| A847h | Renders one of the embedded prompts through BIOS INT 10h. | High |
| A8F4h | Reads a key with BIOS INT 16h and accepts Y/N; other keys repeat the prompt. | High |
| A95Eh | Writes through ES:[004Ch] and ES:[004Eh], saving displaced words at ES:[0100h]/ES:[0102h]. If ES=0, this replaces INT 13h and preserves its old vector. It also writes a second vector-like pair at ES:[01D8h]. | High for writes; ES base/caller context still to verify |
| AA00h | Calls BIOS INT 13h services including AH=14h, AH=08h, AH=04h, AH=09h and AH=11h while probing drive 80h/81h. | High |
| AABFh | Keyboard abort/poll helper using INT 16h AH=01h/AH=00h; checks Escape and uses a timed retry path. | High |
| AB34h | Reads and compares disk metadata against a CS-resident record array beginning E401h; full record semantics remain open. | Medium |

ATA command interpretation:
- 91h is the ATA Initialize Device Parameters command.
- 90h is Execute Device Diagnostic.
- ECh is IDENTIFY DEVICE.
- 10h is the ATA Recalibrate command.

The command values are directly present in the code; the names above are standard ATA command meanings. Device support and error handling still need to be traced through the callers.

### 1.2 Embedded warning and user decision

The padded message at A125h–A18Dh contains:
- `Format !!!`
- `BootSector Write !!!`
- `Possible VIRUS: Continue (Y/N)?`

A847h selects SI=A125h or SI=A148h, positions the cursor and renders the text with BIOS INT 10h. A8F4h waits for keyboard input with INT 16h, uppercases the response and explicitly compares against `Y` (59h) and `N` (4Eh). This ties the warning to a real user-confirmation path, not just an unused string.

### 1.3 A100h–A123h dispatch-like words

There are 18 two-byte entries. Their byte-reversed interpretations match plausible code offsets:
`A1A4, A137, A372, A381, A374, A49E, A18E, A18E, A1D3, A401, A58E, A18E, A12B, A5A9, A18E, A18E, A18E, A17B`.

This is a strong byte-swapped offset-table hypothesis. Do not call it a confirmed near-pointer table until the consumer is found and its byte order is proven.

### 1.4 Keyboard data island

AD00h–AE5Fh contains scan-code/character translation candidates, including recognizable QWERTY, ASDF, ZXCVBNM and numeric-key sequences. Treat this as data, not code, despite the linear decoder producing instructions.

AE60h onward returns to executable code. AE73h invokes INT 15h with AH=4Fh, consistent with the BIOS keyboard intercept service; subsequent code tracks modifier/event state and branches into B2xx handlers.

## 2. D100h–D5FFh: separate floppy-disk controller (FDC) and DMA code

This is a distinct subsystem from the ATA code above.

Observed ports:
- 03F2h — FDC Digital Output Register
- 03F4h — Main Status Register
- 03F5h — FIFO/data
- 03F7h — Digital Input / Configuration Control
- DMA controller ports 000Ch, 000Bh, 0005h and 0004h

### 2.1 Routine map

| Entry | Observed behavior |
|---:|---|
| D156h | Programs DMA controller: writes AL to ports 0Ch, 0Bh, 05h and 04h with delays; saves/restores AX/DX and disables interrupts during setup. |
| D216h | Coordinates an FDC/DMA operation using the state byte at 003Eh; calls D1C0h and BIOS INT 15h with AX=9001h on one path. |
| D243h | Waits on FDC MSR at 03F4h, then writes the command byte to FIFO 03F5h. |
| D294h | Waits on MSR at 03F4h, checks the result phase and reads one byte from FIFO 03F5h. |
| D2BDh | Converts FDC status bits in the byte at 0042h into AH error codes. |
| D2FDh | FDC reset/status sequence using D348h and the MSR. |
| D348h | Resets/re-enables the controller by modifying state and writing to DOR 03F2h; waits and calls BIOS INT 15h AX=9001h. |
| D400h–D4FFh | Command/retry sequences with multiple FDC command bytes and per-drive state updates. Exact command names require full caller/parameter analysis. |
| D500h–D51Fh | Updates drive/head-related bits and writes a value to port 03F7h. |
| D520h–D5DCh | Reads and validates multi-byte FDC result sequences, including expected status bytes and drive-state flags. |
| D5DDh | Helper that derives a selector from AL, invokes D216h and D294h, and compares the returned byte. |

The D100h seed begins with a short register/return fragment and should not be assumed to be the subsystem's true entry. Direct call targets such as D156h, D216h, D243h, D294h and D348h are better-aligned analysis roots.

## 3. F900h–F9FCh: indirect I/O dispatch wrapper and handler table

The six words at F92Ah–F935h decode little-endian to:
- F936h
- F986h
- F9C4h
- F977h
- F999h
- F9D3h

The F900h–F929h stream computes an index, loads a target through CS-relative memory at F92Ah, calls the selected handler indirectly through AX, restores the saved context and executes IRET. This is a dispatch wrapper; the exact interrupt/vector entry that reaches it is not yet established.

Important overlap: F977h is inside the F936h routine's sequential instruction stream (F936h through F985h) and is also a table-selected entry. Preserve both interpretations. F986h, F999h, F9C4h and F9D3h are additional handler entries. F9FDh onward appears to transition into non-code data, but its exact table boundary is not yet verified.

## 4. 2100h: memory-pattern probe candidate

The stream writes and compares 5555h/AAAAh patterns using 16-/32-bit operand/address prefixes. It probes offsets including 0000h, 0100h, 0800h, 1000h, 2000h and a 32-bit effective address 00800000h. This is consistent with memory alias/size probing, but the ES value, caller setup and exact memory map are not yet established.

## 5. Remaining unknowns

1. Confirm the true entry into the A000h ATA subsystem and the caller/consumer of A100h–A123h's byte-swapped entries.
2. Trace the INT 13h hook installation and its companion vector at 01D8h with ES provenance.
3. Recover complete routine boundaries and error contracts for A5CAh, A5A9h, A655h, A694h, A6BBh, A6DCh, A798h and A7BAh.
4. Identify the FDC commands in D400h–D5FFh and connect DMA channel programming to the command/result paths.
5. Establish the interrupt/vector source and selector contract for the F92Ah dispatch table.
6. Trace the 2100h memory-probe caller and the meaning of the 00800000h comparison.

## 6. Method and confidence

The report is based on raw source bytes and independently seeded Capstone decodes. Direct port operands, branch targets and literal message bytes are high-confidence. Routine names are descriptive labels only where the actual hardware command or BIOS service is explicit. Candidate entry offsets are not promoted to confirmed entries without caller or vector evidence.

No semantic completion percentage is inferred from these sampled windows.
