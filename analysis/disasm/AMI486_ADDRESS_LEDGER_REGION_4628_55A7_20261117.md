# AMI486 address-ledger extension: hard-disk utilities and POST memory paths

Date: 2026-11-17  
ROM: ami486.bin, 65,536 bytes  
SHA-256: 91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b

## 1. Why this region was selected

The previous candidate-window set left a contiguous 4600h–55A7h hole even though the linear listing contains coherent instruction streams and the rest of the ROM contains direct branches/calls into it. A raw direct-reference scan found incoming references from 23D7h, 5C21h, 5C63h, 5F5Bh, 5F62h, 5FBEh and 6CDEh. The Setup main-menu handler table at 3446h–345Bh also contains targets 5038h and 4628h.

This is a real analysis gap, not merely a page with no phase-number address token.

## 2. Confirmed data structures around the hard-disk utility

| Range | Classification | Evidence |
|---|---|---|
| 3873h–387Ch | Five-word string-pointer table | Values point to labels beginning at 381Ch, 382Dh, 383Dh, 384Fh and 3865h |
| 387Dh–38ACh | Three NUL-terminated hard-disk utility labels | “Hard Disk Format”, “Auto Interleave”, “Media Analysis” |
| 38ADh–38B8h | Three four-byte descriptors | Each contains a word pointer to one label plus two selector/flag bytes |
| 38B9h–38C2h | Five-word callback table | Little-endian targets: 4AEEh, 4B68h, 4B96h, 4BB1h, 5985h |
| 38C3h–3934h | Bad-track editor labels | “Bad Track #”, “No. Cyln. Head”, “Bad Track Edit Menu”, Add/Revise/Delete/Clear labels |
| 3935h–3944h | Eight-word action table | Targets: 38F5h, 3902h, 3912h, 3922h, 4DE7h, 4E1Fh, 4E2Eh, 4E5Fh |
| 3945h–3C5Bh | Mixed prompt/status/error strings and lookup data | Includes cylinder/head prompts, duplicate-entry warning, destructive-operation warning and error text |
| 4600h–4627h | Repeated CDh frame-fill bytes and trailing control bytes | The executable handler begins at 4628h |

Boundary correction: the previous generator described 3874h–3900h as one ASCII range and 3900h–3C5Bh as one mixed range. That incorrectly swallowed the 3873h pointer-table start and treated the 38ADh descriptors/callback words as text. The generator now splits the structures at the byte-aligned boundaries above.

The 38B9h callback offsets are confirmed by the five-word table; the 3935h action targets are confirmed by the eight-word table. They are not guesses based on nearby instruction-looking bytes.

## 3. Setup hard-disk utility handler family

### 3.1 Main-menu entry and display loop

- 4628h is a target in the Setup main-menu handler table at 3446h–345Bh.
- 4628h establishes a BP frame, sets the utility state at E422h, then jumps to the common screen setup at 4701h.
- 4633h is a distinct alternate stream entry reached by the back-edge at 4744h. It is not a fresh function prologue.
- The 4628h stream calls 4752h for coordinate calculation and 475Ch for the drive/status display, calls 4891h for the utility panel, then restores SP/BP and returns at 4751h.
- 4752h returns AX as 101Fh plus the selected utility index in AH.
- 475Ch reads the selected drive/status nibble from E012h, applies the selected-drive index E189h, resolves the special Fh case through the drive-type data, and calls 5AB5h to render the selected value.

### 3.2 Utility panel and callback dispatch

4891h is directly called from 46FEh. It selects one of the three four-byte descriptors at 38ADh using E1ACh, draws the associated title, and iterates the five option bits. For each active option it obtains the callback offset from 38B9h plus twice the option index and calls it indirectly. The callback return value is checked for ESC (1Bh); ESC exits the panel.

The five callback entry offsets are 4AEEh, 4B68h, 4B96h, 4BB1h and 5985h. The raw callback table establishes these as intentional indirect targets. Their detailed UI semantics are not all fully named yet; preserve them as five separate callback entry points.

### 3.3 Bad-track editing path

- 4BB1h calls 4BDAh to draw the bad-track list, calls 5985h for a Y/N response, and enters 4CEEh only when the response is Y.
- 4BDAh draws the bad-track editor frame and iterates three-byte records based at E436h. The record index is scaled by three; the word at record+0 and byte at record+2 are rendered as cylinder/head values.
- 4CEEh is the bad-track list event loop. It draws the list, reads input, and dispatches through the eight-word table at 3935h.
- 4DE7h, 4E1Fh, 4E2Eh and 4E5Fh are the four action-table targets at 393Dh, 393Fh, 3941h and 3943h.
- 4E66h is the shared keyboard/event helper used by the edit callbacks.
- 4EE7h displays the cylinder/head input dialog, uses the BIOS input helper at 06C9h, checks the proposed three-byte record against existing entries, and updates the E436h record array on acceptance.
- 4FCFh is a separate status/error prompt routine. 6CDEh calls it after a lookup in the status-code table at 6CB5h; it is not part of the 4CEEh local event loop.

The data table at 3935h contains four string pointers before the four callback pointers; do not treat all eight words as code addresses.

## 4. POST memory and controller paths

### 4.1 Entry from the POST path

- 509Eh is a direct JMP target from 5F62h.
- 509Eh begins a POST/BIOS transition sequence: it writes diagnostic bytes to port 80h, copies a 48-word structure from CS:E260h to ES:0600h, and invokes INT 15h AH=89h with SI=0600h and BX=0800h.
- The subsequent code saves/restores IVT words through segment 0038h, emits POST diagnostic bytes 45h–59h, and uses helpers in 5305h–53C5h.
- 50DBh is an error continuation inside this larger stream: it loads SI=7AB2h and jumps to the ROM string/output helper at F509h. It is not a separately proven routine entry.
- The sequence includes a stack-crafted RET at 5189h–518Fh (PUSH 5190h; PUSH FA4Eh; RET). This is an intentional transfer to an external ROM offset before execution resumes at 5190h; a single linear stream does not show the complete control flow.

### 4.2 Memory-test helpers

- 5305h writes 55AAh and AA55h at ES:[DI] and ES:[DI+2], verifies both, checks the sentinel at segment 0038h:0000h, and advances the address pair held through SI. It returns the current low/high address bytes in AX.
- 534Ch is a byte-write/verify path that walks the address bit through DI and compares the evolving address against the target pair in [SI] and [SI+3].
- 5371h increments the candidate address and checks the expected pair; on mismatch it exercises ES memory locations using a rotating DI bit.
- 53A6h performs repeated read/write accesses to ES:0000h and ES:0002h, preserving AX/DI.
- 53C5h coordinates the memory/controller probe and calls the above helpers; the success/error paths use the keyboard-controller helpers below.

### 4.3 8042 helpers and protected-mode transitions

- 5434h sends command AEh to port 64h and waits through ROM delay helpers.
- 543Dh sends command ADh and reads port 60h.
- 5448h reads port 60h, distinguishes responses 01h and 53h, and uses CMOS register 8Eh through EE94h/EE9Dh on the 53h path.
- 546Ch saves the 16-bit register frame, records SP at 0067h, invokes the ROM control-register helper and transfers to the F068h/8AD6h paths according to CS:8281h.
- 5494h is an aligned stream after the 5493h RET. It performs stack/register work, a ROM control-register call, and INT 15h AH=89h with SI=0600h/BX=0800h. Its runtime entry/caller is not yet established; do not merge it into 546Ch merely because the bytes are adjacent.

### 4.4 Memory fill/test and timing helpers

- 5520h clears 8000h words (64 KiB) at ES:0000h using REP STOSW.
- 552Ah loads BX=8000h and falls through into 552Dh.
- 552Dh fills and verifies 8000h words at ES:0000h using patterns 8080h, 5555h, 3333h and 0000h. It returns at 5571h with flags reflecting the compare result. It has direct incoming references from 23D7h and 5FBEh.
- 23D7h reaches 552Dh via a stack-threaded JMP; 5FBEh calls it after setting ES from BX. The caller contexts are distinct and must be retained.
- 5572h checks the CS:B50Dh feature byte and, on the enabled path, programs PIT channel 2 through ports 43h/42h and toggles port 61h; it is a timing/beep helper. Its exact audible purpose is not asserted.

## 5. Direct incoming-reference map

| Target | Incoming source | Evidence |
|---|---|---|
| 4628h | Setup handler table at 3458h | Indirect main-menu callback |
| 4633h | 4744h | Relative JMP back-edge |
| 4752h | 464Dh, 467Ch | Direct CALLs |
| 475Ch | 4729h, 4730h, 5089h | Direct CALLs |
| 4891h | 46FEh | Direct CALL |
| 4AEEh / 4B68h / 4B96h / 4BB1h | 38B9h–38C2h | Five-word callback table |
| 4BDAh | 4AE2h, 4BB1h, 4EC3h | Direct CALLs |
| 4CEEh | 4AE5h | Direct CALL |
| 4DE7h / 4E1Fh / 4E2Eh / 4E5Fh | 393Dh–3944h | Four callback words in the eight-word action table |
| 4FCFh | 6CDEh | Direct CALL |
| 5038h | Setup handler table at 3456h | Indirect main-menu callback |
| 509Eh | 5F62h | Direct JMP |
| 54E5h | 5F5Bh | Direct CALL |
| 5520h | 5C21h | Stack-threaded direct JMP |
| 552Ah | 5C63h | Stack-threaded direct JMP |
| 552Dh | 23D7h, 5FBEh | Direct JMP and CALL |
| 5572h | 548Bh | Direct CALL |

## 6. Candidate-window generator update

The candidate generator now seeds the previously omitted hard-disk utility and POST memory/controller streams with explicit per-window bounds. It also splits data ranges at the pointer/descriptor/callback boundaries:
- 3873h–387Ch pointer words;
- 387Dh–38ACh strings;
- 38ADh–38B8h descriptors;
- 38B9h–38C2h callback words;
- 38C3h–3934h labels;
- 3935h–3944h action pointers.

The new generated listing and manifest must be checked after the GitHub Actions run. Until the regenerated artifact is verified, do not report a new candidate-window footprint.

## 7. Remaining open items

- The five hard-disk utility callback contracts need to be traced through their full callees and side effects; the table targets themselves are confirmed.
- The runtime path into 5494h is not established.
- The stack-crafted transfer through FA4Eh and the corresponding return/continuation require a separate control-flow reconstruction.
- The single byte at 55A7h, between the 5572h RET and the 55A8h CP437 glyph table, remains unclassified.
- The direct-entry status of any unreferenced prologue-shaped bytes must not be inferred from a linear decode alone.

This is a region-level extension, not a new numbered semantic phase and not a whole-ROM completion claim.
