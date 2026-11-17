# AMI486 address ledger — Drive-type/status display helper continuation (475Ch–4890h)

Date: 2026-11-17  
Repository: JTCyborg/Project134, branch main  
Source: ami486.bin, 65,536 bytes  
SHA-1: 480c7520c93e6c7ed437cf3ad214da7503f82ec6  
ROM SHA-256 recorded by the existing ledger: 91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b

## 1. Boundary correction

The existing candidate window at 475Ch was limited to D5h bytes and ended at 4830h. Byte 4830h is BA, the opcode of MOV DX,0003h; the immediate bytes 03 00 at 4831h–4832h were omitted. The helper continues through 4890h, where it returns. The next function begins at 4891h with PUSH BP.

The 475Ch window is now 135h bytes long, covering 475Ch–4890h inclusive.

## 2. Drive-type/status rendering continuation — 4830h–4890h

The continuation performs repeated display/format operations using the state pointer at E180h and drive-related fields at E411h, E413h, E416h, E41Dh and E41Fh.

The repeated blocks:
- select a field using DX values 03h or 05h;
- load the associated state word/byte from the E4xxh block;
- call the shared helper at 09EBh;
- advance the E180h field offset in six-byte steps.

After the final field, the code adds 44h to the E180h state pointer and calls the display helper at 5BD5h. It then checks whether the returned value is FFFFh:
- if FFFFh, it loads the fallback label at 37BDh and jumps back to the shared display path at 47DEh;
- otherwise, it uses the returned value and exits through the common epilogue.

The epilogue restores SI, resets SP from BP, pops BP and returns at 4890h.

This confirms the 4830h–4890h bytes are the tail of the existing drive-type/status display helper, not a new top-level function.

## 3. Cross-reference ledger

| Source | Target | Meaning |
|---:|---:|---|
| 4628h screen stream | 475Ch | Drive-type/status display helper |
| 5038h screen stream | 475Ch | Alternate display caller |
| 46FEh | 4891h | Separate hard-disk utility option-panel renderer |
| 4833h / 4821h / 4843h / 4853h / 4865h | 09EBh | Repeated field helper calls |
| 486Dh | 5BD5h | Shared display/format helper |
| 487Eh | 47DEh | FFFFh fallback display path |

## 4. Generator integration

The candidate generator extends the 475Ch window from D5h to 135h bytes. No new seed is required; the existing seed now includes the complete helper and its RET at 4890h. The separate 4891h renderer remains unchanged.

Generator update commit: 86d414d730b3a35a9c339788033a4cc20ce77b98.

The regenerated manifest should be checked after the generator update; no post-update global percentage is claimed in this file.

## 5. Remaining uncertainties

- Exact field semantics of E411h/E413h/E416h/E41Dh/E41Fh.
- Whether the six-byte E180h stride corresponds to drive-type records, geometry fields or display slots.
- Exact return-value semantics of the 09EBh and 5BD5h helpers.
