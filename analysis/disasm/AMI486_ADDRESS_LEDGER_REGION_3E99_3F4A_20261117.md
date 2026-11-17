# AMI486 address ledger — Setup value parser and metric formatter (3E99h–3F49h)

Date: 2026-11-17  
Repository: JTCyborg/Project134, branch main  
Source: ami486.bin, 65,536 bytes  
SHA-1: 480c7520c93e6c7ed437cf3ad214da7503f82ec6  
ROM SHA-256 recorded by the existing ledger: 91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b

## 1. Corrected function boundaries

The existing 3E3Fh window used a default 80h-byte span and crossed two function boundaries. The corrected segmentation is:

| Range | Classification |
|---|---|
| 3E3Fh–3E98h | Existing screen-presentation routine; now bounded to 5Ah bytes |
| 3E99h–3EF1h | Setup value-input/parser routine |
| 3EF2h–3F49h | BP-framed metric/value formatter |
| 3F4Ah onward | Existing separate helper entry |

The 3E3Fh routine ends with RET at 3E98h. A new routine begins immediately at 3E99h. The parser's loop body begins at 3EBFh, and the formatter begins at 3EF2h.

## 2. Setup value-input/parser — 3E99h–3EF1h

The routine creates a BP frame with four bytes of local storage, saves BX/DI, and obtains the field text through helper 592Ah. It stores the current attribute from E1A8h into E19Fh/E1A0h, computes the buffer bounds, and then processes the characters.

The parser loop at 3EBFh:
- loads the current character through BX and decrements the saved buffer pointer;
- stores the character in the local byte at BP-1;
- treats ':' and space as special delimiters, calling separate helpers at 58F1h and 58B5h;
- sends the character through the output helper at 58EEh;
- compares the current buffer position with the saved lower bound and loops while the range remains.

Control-flow boundaries:
- 3EBDh: EB 26 — short JMP to the loop-bound check at 3EE5h.
- 3EEBh: 73 D2 — conditional back-edge to the loop body at 3EBFh.
- 3EF1h: RET.

The 3EBFh entry is therefore an internal loop target, not a separate top-level function. The full parser window starts at 3E99h and ends before 3EF2h.

## 3. Metric/value formatter — 3EF2h–3F49h

This routine establishes a BP frame with two bytes of local storage and saves BX/DI/SI. It calls the input/measurement helper at 5928h, bounds the returned value against 0019h, and performs a sequence of shifts, additions and subtraction around constants 0A28h and 0E28h to derive the display value.

It loads the display attribute from E1A6h into E19Fh, positions/formats the output through helper 578Dh, and then calls the text/field helpers at 58A0h, 58A1h, F571h and 5902h. It restores SI/DI/BX and the BP frame, then returns at 3F49h.

The nearby “KB/sec ms” label and the display routines mapped in 714Eh–71E3h show this is part of the Setup/POST measurement presentation path. The exact scaling represented by the arithmetic constants is not assigned without the caller's unit conversion context.

## 4. Cross-reference and loop ledger

| Source | Target | Meaning |
|---:|---:|---|
| 00EFh presentation stream | 3E3Fh | Existing screen-presentation routine |
| 3EBDh | 3EE5h | Initial skip to parser loop-bound check |
| 3EEBh | 3EBFh | Parser loop back-edge |
| 3E99h | 592Ah | Field text/input helper |
| 3EC Eh | 58F1h | Colon delimiter helper |
| 3ED9h | 58B5h | Space delimiter helper |
| 3EE2h | 58EEh | Character output helper |
| 3EF2h | 5928h | Value/input measurement helper |
| 3F28h | 578Dh | Display positioning/format helper |
| 3F31h / 3F3Bh | 58A0h / 58A1h | Field display helpers |
| 3F3Eh | F571h | BIOS/ROM helper |
| 3F41h | 5902h | Final formatting helper |

No direct near CALL to 3E99h or 3EF2h was found in the raw ROM scan; their external entry provenance remains unresolved.

## 5. Generator integration

The candidate generator now:
- bounds 3E3Fh to 5Ah bytes, ending at 3E98h;
- adds 3E99h with a 59h-byte parser window;
- adds 3EF2h with a 58h-byte formatter window, ending immediately before 3F4Ah.

Generator update commit: 3c87a27e0d387c1cce8d39a6c64c4db2d699661e.

The manifest has not yet been regenerated after this addition. No new global coverage percentage or CI pass is claimed.

## 6. Remaining uncertainties

- Exact field format and caller that selects the 3E99h parser.
- Scaling/unit meaning of the 0A28h/0E28h arithmetic in 3EF2h.
- Whether the 3EF2h output is the same metric pair shown by 714Eh or a separate Setup measurement.
