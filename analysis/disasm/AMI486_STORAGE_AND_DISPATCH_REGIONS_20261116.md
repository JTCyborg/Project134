# AMI486 storage, keyboard and dispatch regions — 2026-11-16

Source: `ami486.bin`, 65,536 bytes, SHA-256 `91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b`  
Decode aid: `analysis/disasm/ami486_candidate_windows_20261116.txt`  
Generator: `tools/disasm_ami486_candidate_windows.py`  
Decoder: Capstone x86, 16-bit; independently seeded windows with near-branch targets wrapped to 16-bit IP.

## 1. A000h–AFFFh: IDE/ATA hard-disk and boot-sector protection code

This region is the hard-disk half of a hooked BIOS INT 13h implementation, not a floppy-disk controller driver. Entry A08Dh handles INT 13h requests for DL>=80h and forwards DL<80h requests to INT 40h. Its I/O port set is the primary ATA task-file interface:
- 01F0h — data
- 01F1h — error/features
- 01F2h — sector count
- 01F6h — drive/head
- 01F7h — command/status
- 03F6h — alternate status/device control

### 1.1 Main routines and evidence

| Entry | Observed behavior | Confidence |
|---:|---|---|
| A08Dh | INT 13h handler entry. If DL<80h it executes INT 40h and RETF 2; otherwise it enters the hard-disk path. | High: exact branch and software interrupt |
| A0A0h | Saves registers, sets DS=0040h, validates AH<=19h and dispatches through CS:[DI-5F0Fh]. Unsupported AH returns error 0100h with CF set. | High: exact instruction stream |
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
| A95Eh | Writes handler offset A08Dh to ES:[004Ch] and CS to ES:[004Eh], saving the displaced words at ES:[0100h]/ES:[0102h]. Because 004Ch is the INT 13h vector slot, this is the INT 13h hook installer when ES=0; the caller's ES provenance is still to be checked. It also writes a second vector-like pair at ES:[01D8h]. | High for INT 13h slot and handler target; ES base/caller context still to verify |
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

### 1.3 A0F1h–A124h: 26-entry INT 13h function table

The indirect call at A0BDh uses CS:[DI-5F0Fh]. Before the call, DI is set to twice the incoming AH selector. With 16-bit offset arithmetic, selector zero resolves to A0F1h; each entry is a native little-endian near offset. The guard at A0B6h rejects AH>19h, so the table has 26 entries.

| AH | Target | Notes |
|---:|---:|---|
| 00h | A197h | Disk reset / device probe path |
| 01h | A20Bh | Return and clear saved status |
| 02h | A216h | Read sectors: routes to command 20h and REP INSW |
| 03h | A226h | Write sectors: routes to command 30h and REP OUTSW |
| 04h | A23Eh | Verify sectors: sends command 40h |
| 05h | A25Fh | Format track: sends command 50h after a write/format guard and user prompt |
| 06h | A18Eh | Unsupported/error stub |
| 07h | A18Eh | Unsupported/error stub |
| 08h | A1A4h | Get drive parameters; derives geometry through A2F1h |
| 09h | A337h | Initialize device parameters; sends ATA command 91h |
| 0Ah | A372h | Read long: 204h-byte buffer, command 22h |
| 0Bh | A381h | Write long: 204h-byte buffer, command 32h |
| 0Ch | A474h | Seek: sends command 70h |
| 0Dh | A19Eh | Checks drive presence, then enters reset path A1B3h |
| 0Eh | A18Eh | Unsupported/error stub |
| 0Fh | A18Eh | Unsupported/error stub |
| 10h | A4D3h | Test-drive-ready/status path |
| 11h | A501h | Recalibrate: sends command 10h |
| 12h | A18Eh | Unsupported/error stub |
| 13h | A18Eh | Unsupported/error stub |
| 14h | A52Bh | Controller diagnostic: sends command 90h |
| 15h | A1A9h | Get disk type/capacity; A552h returns AH=03h and total sectors in CX:DX |
| 16h | A18Eh | Unsupported/error stub |
| 17h | A18Eh | Unsupported/error stub |
| 18h | A18Eh | Unsupported/error stub |
| 19h | A57Bh | Additional drive-parameter/seek path; exact service contract unresolved |

The table occupies A0F1h–A124h inclusive. A100h is inside the table, not its start. The repeated A18Eh target is a shared error-return stub. Names marked “candidate” require full parameter/caller tracing before mapping them to a specific BIOS service.

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

1. Trace the INT 13h hook installation at A95Eh through the caller to prove ES=0 and validate the companion vector at 01D8h.
2. Confirm the parameters and error contracts for the 26 INT 13h service handlers, especially A216h/A226h/A23Eh/A25Fh and A372h/A381h/A374h.
3. Recover complete routine boundaries and error contracts for A5CAh, A5A9h, A655h, A694h, A6BBh, A6DCh, A798h and A7BAh.
4. Identify the FDC commands in D400h–D5FFh and connect DMA channel programming to the command/result paths.
5. Establish the interrupt/vector source and selector contract for the F92Ah dispatch table.
6. Trace the 2100h memory-probe caller and the meaning of the 00800000h comparison.

## 6. Method and confidence

The report is based on raw source bytes and independently seeded Capstone decodes. Direct port operands, branch targets and literal message bytes are high-confidence. Routine names are descriptive labels only where the actual hardware command or BIOS service is explicit. Candidate entry offsets are not promoted to confirmed entries without caller or vector evidence.

No semantic completion percentage is inferred from these sampled windows.


## 7. Corrected INT 13h dispatch finding

The previous note that A100h–A123h might be a separate byte-swapped table is withdrawn. The actual dispatcher is A08Dh/A0A0h: A08Dh is the INT 13h hard-disk handler entry; DL<80h is forwarded to INT 40h via INT 40h / RETF 2; A0A0h dispatches by incoming AH, accepts selectors 00h–19h, and calls through the 26-word native little-endian table at A0F1h. The table runs through A124h; A100h is an interior address. The indirect-call base is derived from the displacement at A0BFh: DI-5F0Fh, with 16-bit offset wraparound. This correction supersedes the earlier A100h–A123h byte-swapped-table hypothesis in the first-pass address ledger.


## 8. INT 13h service semantics resolved from the handler table

The seeded code now supports the standard service interpretation for the principal entries:
- AH=02h reads sectors through ATA command 20h and REP INSW.
- AH=03h writes sectors through ATA command 30h and REP OUTSW.
- AH=04h verifies sectors through ATA command 40h.
- AH=05h formats a track through ATA command 50h, after the guard/prompt path.
- AH=08h returns drive parameters from the parameter table.
- AH=09h initializes device parameters with ATA command 91h.
- AH=0Ah/AH=0Bh perform read/write-long paths using 204h-byte buffers and ATA commands 22h/32h.
- AH=0Ch seeks with ATA command 70h.
- AH=0Dh checks the selected drive and enters the reset path.
- AH=10h is a drive-ready/status path.
- AH=11h recalibrates with ATA command 10h.
- AH=14h runs controller diagnostics with ATA command 90h.
- AH=15h returns hard-disk type and capacity; A552h returns AH=03h and total sector count in CX:DX.

Entries 06h, 07h, 0Eh, 0Fh, 12h, 13h, 16h, 17h and 18h all select the shared A18Eh error stub. AH=19h is present but remains an OEM/extended path until its complete caller contract is established.
