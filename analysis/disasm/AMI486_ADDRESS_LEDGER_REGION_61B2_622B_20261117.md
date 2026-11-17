# AMI486 address ledger — Calendar display grid template (61B2h–622Ah)

Date: 2026-11-17  
Repository: JTCyborg/Project134, branch main  
Source: ami486.bin, 65,536 bytes  
SHA-1: 480c7520c93e6c7ed437cf3ad214da7503f82ec6  
ROM SHA-256 recorded by the existing ledger: 91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b

## 1. Data classification and boundary

The 121-byte interval 61B2h–622Ah is not executable code. It continues the calendar UI template whose preceding portion at 6194h–61B1h contains weekday labels and vertical separators.

The combined data range is now 6194h–622Ah inclusive (end-exclusive 622Bh). The next byte, 622Bh, is the separately seeded renderer entry called from the 00EFh screen-presentation stream.

## 2. Grid structure

The bytes use the IBM PC text-mode box-drawing character set and blank-cell fill values. The continuation contains:
- vertical double-line separators (BAh) and single-line separators (B3h);
- horizontal border runs (CDh/C4h);
- corner and junction glyphs (CCh, D8h, C7h, C5h, B6h, CAh, CFh, BCh);
- NUL separators between border fragments;
- repeated space-filled day cells.

The sequence at 61D0h–61E7h forms the blank-cell rows, with vertical separators between columns. The sequence at 61E8h–622Ah forms the lower/upper border and corner/junction fragments that complete the calendar frame.

Together with the weekday labels already mapped at 6194h–61B1h, this is a static calendar display template rather than a code stream. The exact mapping of each blank cell to a date position is determined by the renderer and is not assigned from the byte pattern alone.

## 3. Renderer cross-reference

The 00EFh screen-presentation stream directly calls 622Bh. The renderer begins by loading SI=6177h and DX=0A33h, then calls the existing display helper path. This confirms the calendar template is consumed by a code renderer rather than executed.

## 4. Generator integration

The candidate generator's prior data range 6194h–61B1h has been extended to 6194h–622Ah. No new code seed was added; 622Bh remains the renderer entry.

Generator update commit: dc1b930b4e68ccce53251df74f60be8f6cbfcdd0.

The manifest has not yet been regenerated after this update. No new global coverage percentage or CI pass is claimed.

## 5. Remaining uncertainties

- Exact date-to-cell placement algorithm in the renderer at 622Bh.
- Whether the NUL bytes are separators, terminators or control markers for the display helper.
- Whether the calendar is used for date setup, a POST date/time panel or another Setup page.
