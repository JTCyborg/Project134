# AMI486 address ledger — Setup field-record renderer and selector wrappers (03D4h–04AFh)

Date: 2026-11-17  
Repository: JTCyborg/Project134, branch main  
Source: ami486.bin, 65,536 bytes  
SHA-1: 480c7520c93e6c7ed437cf3ad214da7503f82ec6  
ROM SHA-256 recorded by the existing ledger: 91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b

## 1. Boundary correction

The existing 03D4h candidate window used the default 80h-byte limit and ended at 0453h. This split the CALL at 0452h:

- 0452h: E8 35 05 — CALL 098Ah
- 0454h: 05h — high displacement byte
- 0455h: 58h — POP AX, the next instruction

The routine continues through RET at 04A9h. The 03D4h window is now 0D6h bytes, ending immediately before the separate selector wrapper at 04AAh.

The remaining six bytes 04AAh–04AFh form a second wrapper called by the 03D4h routine. They are separately seeded and enter the common calculation at 04BBh.

## 2. Setup field-record renderer — 03D4h–04A9h

Direct caller: 00EFh screen-presentation stream.

The routine obtains a field index through the existing helper calls, converts the index to a 16-byte record offset, and forms a pointer into the table beginning at E401h:

`(index - 1) * 10h + E401h`

It then copies selected record members into the caller's BP-relative frame:

| Record offset | Destination |
|---:|---:|
| +00h word | BP+40h |
| +02h byte | BP+42h |
| +05h word | BP+43h |
| +0Ch word | BP+45h |
| +0Eh byte | BP+47h |

The routine invokes the field-value selector at 04AAh, then uses helpers at 08CFh, 0579h, 098Ch and 09EEh to finish the update/display operation. It also calls the alternate selector wrapper at 04B2h. The common epilogue restores flags/register state and returns at 04A9h.

This is a Setup field-record renderer/update routine, not a standalone disk or memory test.

## 3. E1A3h selector wrapper — 04AAh–04AFh

Direct caller: 048Ah.

The wrapper loads BL from E1A3h, clears BH and falls through into the short jump at 04B0h, which transfers to the common calculation at 04BBh. It is a six-byte selector wrapper, not a new independent calculation routine.

## 4. Relationship to the existing 04B0h helper

The existing entry at 04B0h begins with a short JMP to 04BBh. A second entry at 04B2h loads BL from E1A2h, calls 08CAh, clears BH and joins the same calculation at 04BBh. The 03D4h renderer calls 04B2h at 04A4h; another caller at 0538h enters 04B0h directly.

The common code at 04BBh uses BP+40h/BP+42h/BP+47h values to perform a bounded multiplication/offset calculation. The exact unit of the result remains tied to the field record semantics.

## 5. Cross-reference ledger

| Source | Target | Meaning |
|---:|---:|---|
| 00EFh | 03D4h | Direct CALL to Setup field-record renderer |
| 0452h | 098Ah | Helper call whose high displacement byte was previously clipped |
| 048Ah | 04AAh | E1A3h selector wrapper |
| 0493h | 08CFh | Field update/display helper |
| 0498h | 0579h | Shared field helper |
| 049Bh | 098Ch | Shared record/helper path |
| 04A1h | 09EEh | Field formatting helper |
| 04A4h | 04B2h | Alternate E1A2h selector wrapper |
| 0538h | 04B0h | Existing direct caller of common field-value helper |

## 6. Generator integration

The candidate generator now:
- extends 03D4h from the default 80h bytes to 0D6h bytes, covering through RET at 04A9h;
- adds 04AAh with a six-byte wrapper window;
- retains 04B0h and its alternate entry at 04B2h.

Generator update commit: fee1d36bc61ef71410e760d1bbb7b9d92608a9f8.

The range-mask manifest must be refreshed after this update; no post-update global percentage is claimed in this file.

## 7. Remaining uncertainties

- Exact semantic names for the five record fields copied into BP+40h–BP+47h.
- Exact units and range meaning of the common calculation at 04BBh.
- The full selection semantics of E1A2h versus E1A3h.
