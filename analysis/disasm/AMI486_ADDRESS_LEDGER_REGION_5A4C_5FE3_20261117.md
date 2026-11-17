# AMI486 address ledger — POST/Setup region 5A4Ch–5FE3h

Date: 2026-11-17  
Repository: JTCyborg/Project134, branch main  
ROM: ami486.bin, 65,536 bytes; SHA-256 91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b

## 1. Region boundaries and confidence

The former uncovered interval was 5A4Ch–5FE3h (1,432 bytes). It begins immediately after the NUL terminator of the Setup prompt string at 5A19h–5A4Bh:

"Load Power-On Default Values from ROM Table (Y/N) ?"

The byte stream contains several independently recognizable Setup callbacks, stack-threaded POST continuations, and a large POST initialization path. The final subrange 5E88h–5F64h and two called helpers at 5F65h/5FA7h remain opaque; they are not force-classified as ordinary 16-bit code.

## 2. Setup/configuration callbacks

| Entry | Evidence / role | Incoming references |
|---|---|---|
| 5A4Ch | Code-looking stream immediately after the Power-On Defaults prompt; initial instruction alignment is plausible but no direct near CALL/JMP reference was found. Keep as candidate, not confirmed function. | unresolved |
| 5AA2h | Reads E187h, forms a bit mask (1 << value), ANDs it with 8282h, returns the result in AX. | direct CALL candidates from 3C87h and 3E19h |
| 5AB5h | Copies a 16-byte record into ES:E411h. Normal path selects a record from CS:E3F1h using AL × 16; AL=2Fh selects a small template at E01Bh, with DL choosing one of two subrecords. | direct CALL candidates from 4797h and 4B8Dh |
| 5AECh | Updates drive/configuration state. Saves E012h/E019h state as needed, calls AB34h with DL=AL+80h, and updates E012h/E019h/E01Ah plus a descriptor at E01Bh/E020h/E021h/E023h. | direct CALL candidate from 5076h |
| 5B7Ch | Merges the high/low nibbles of E092h and E012h according to AL, stores E012h, then copies nine bytes between corresponding E080h/E000h shadow offsets. | direct CALL candidate from 508Fh |
| 5BD5h | Multiplies values at E41Fh, E413h and E411h, divides by 0800h, rounds using the 0400h remainder threshold, and saturates to FFFFh if the high product word is too large. | direct CALL candidate from 486Dh |

The call-site addresses above were recovered by scanning the ROM for 16-bit relative CALL encodings and checking that the computed target equals the listed entry. They should be treated as strong xref candidates until each caller's complete instruction context is incorporated into the function map.

## 3. Stack-threaded memory-test path

The POST continuation at DA9Fh jumps to 5BF8h. This sequence writes POST code 20h to port 80h, sets SP=5C02h, and jumps to F5A9h. The word at 5C02h is 5C04h, the return destination consumed by the diagnostic helper.

At 5C04h the firmware performs a low-memory pattern/alias test. It writes the current AX pattern at DS:DI and DS:DI+2, checks the result, advances through power-of-two addresses using SI/DI, and branches to error handling if the readback differs. The exact memory ceiling and initial DS/AX preconditions still need caller-state confirmation.

Additional stack-return slots:
- 5C24h–5C25h = 5C26h, consumed after the 5C1Eh/5C21h diagnostic trampoline through helper 5520h.
- 5C56h–5C57h = 5C58h, consumed after POST code 21h and the F5A9h diagnostic helper.
- 5C66h–5C67h = 5C68h, consumed after POST code 22h and helper 552Ah.

The continuations at 5C1Eh, 5C26h, 5C4Bh and 5C58h are distinct code streams; the four words above are data and must not be decoded as ordinary instructions.

## 4. Keyboard-controller and IVT initialization

The 5C68h continuation returns into the memory-test status path, emits POST code 23h, establishes ES=0000h, DS=0040h, SS=0030h and SP=0100h, then probes port 60h and sends commands through port 64h. The path tests BP bit 1000h and includes command/status polling before proceeding.

At 5D0Ch it sends FFh to port 64h and emits POST code 24h. At 5D13h:
- CX=0078h (120 iterations);
- AX=EA97h and BX=CS;
- DI starts at 0000h;
- each iteration writes EA97h then CS as a four-byte IVT entry.

This initializes vectors 00h–77h to the common CS:EA97h handler. It then clears ES:007Eh and 16 words at ES:0180h–019Fh.

## 5. FEE3h–FF32h IVT offset table: consumer proven

The POST code at 5D36h copies 32 words from CS:FEE3h into the offset half of IVT vectors 00h–1Fh, advancing DI by four bytes per word. It then copies eight words from CS:FF23h into vectors 70h–77h. The segment words remain CS from the initial IVT fill. Therefore FEE3h–FF32h is a 40-word offset table, not executable code.

The entries are:

| Vector | Offset | Vector | Offset |
|---:|---:|---:|---:|
| 00h | EA97h | 10h | F065h |
| 01h | EA97h | 11h | F84Dh |
| 02h | E2C3h | 12h | F841h |
| 03h | EA97h | 13h | EC59h |
| 04h | EA97h | 14h | E739h |
| 05h | FF54h | 15h | F859h |
| 06h | EB43h | 16h | E82Eh |
| 07h | EAEBh | 17h | EFD2h |
| 08h | FEA5h | 18h | E000h |
| 09h | E987h | 19h | E6F2h |
| 0Ah | EA97h | 1Ah | FE6Eh |
| 0Bh | EA97h | 1Bh | FF53h |
| 0Ch | EA97h | 1Ch | FF53h |
| 0Dh | EA97h | 1Dh | F0A4h |
| 0Eh | EF57h | 1Eh | EFC7h |
| 0Fh | FF53h | 1Fh | 0000h |
| 70h | EA42h | 74h | EA97h |
| 71h | EED2h | 75h | EEDBh |
| 72h | EA97h | 76h | E845h |
| 73h | EA97h | 77h | 90B1h |

The range FEE3h–FF32h is 80 bytes. FEE3h–FF22h supplies the first 32 offsets; FF23h–FF32h supplies the eight IRQ8–IRQ15 offsets. FF33h–FF4Fh is zero padding.

## 6. Remaining POST and video path

After the IVT copy, the POST code at 5D4Eh reads status through F5D9h, stores the result at BDA:0012h, conditionally installs INT 08h as CS:1E44h, unmasks IRQ0 through port 21h, and reads/writes CMOS registers B8h, 8Eh, BEh and BFh.

The continuation at 5D9Ch updates BDA:0084h and BDA:0010h, calls the 1B5Fh stub, and invokes 90B3h with POST progress values F0h/F1h/F2h. It then selects INT 10h video modes 07h and 01h.

At 5E05h it calls the 1B60h option-ROM scan path, scans C000h–C7FFh through F6D9h, and conditionally calls 1BF6h to configure the C000h shadow window. It then reads CMOS 8Dh and compares CS with ES:0042h; mismatch calls 5F65h and jumps to 5F12h.

The video selection path at 5E3Dh chooses B800h or B000h from BDA:0012h, updates BDA:0010h, and probes video services through F598h. It calls 5FA7h at 5E53h and again at 5E83h; both callers branch on the returned ZF state.

## 7. Opaque bytes and unresolved helpers

- 5E88h–5F64h: 221-byte opaque block. Its bytes do not form a coherent linear 16-bit instruction stream at the tested alignment. It may be a table, encoded payload, or overlapping instruction/data view; do not classify it yet.
- 5F65h–5FA6h: 66-byte opaque helper entry called directly from 5E37h. The 16-bit linear decode is not semantically coherent.
- 5FA7h–5FE3h: 61-byte opaque helper entry called directly from 5E53h and 5E83h. The 16-bit linear decode is not semantically coherent.

These call targets are real control-flow references, but their internals need a separate execution-mode, overlap, and data-consumer analysis. Do not silently relabel them as data simply because the first-pass disassembly looks unusual.

## 8. Generator integration

The candidate generator now includes bounded seeds for the Setup callbacks, POST continuations and opaque direct-call entries. It excludes the four crafted stack-return words and classifies the IVT table as 40 words.

GitHub Actions run 44082883079 completed successfully after this integration. The regenerated manifest reports 753 candidate windows, 228 data ranges, 36,898 unique code-window bytes, 18,012 unique data-range bytes, 290 overlap bytes, and a 54,620-byte union (83.34%). There are 70 uncovered intervals; the largest is now 1365h–188Dh (1,321 bytes).

## 9. Next work

1. Resolve the 5A4Ch candidate entry's caller/indirect-entry mechanism.
2. Trace the opaque block 5E88h–5F64h and the called helpers 5F65h/5FA7h without assuming ordinary 16-bit code alignment.
3. Confirm the memory-test entry preconditions (DS, AX, upper memory bound) from the DA9Fh caller and the F5A9h diagnostic helper.
4. Trace the IVT handlers named by the 40-word table and map which vectors are intentional hooks versus common stubs.
5. Proceed to the next largest uncovered interval 1365h–188Dh only after preserving this region's stack-return boundaries and xrefs.
