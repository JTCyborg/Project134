# AMI486 address ledger — indexed value table and accessor (8E09h–8E4Dh)

Date: 2026-11-17  
Repository: JTCyborg/Project134, branch main  
Source: ami486.bin, 65,536 bytes  
SHA-1: 480c7520c93e6c7ed437cf3ad214da7503f82ec6

## 1. Region split

The 69-byte uncovered interval is mixed:
- 8E09h–8E0Ch: four-byte prefix sequence 86 C4 FF E7; no direct call/branch target to 8E09h was found, so its code/data role remains provisional.
- 8E0Dh–8E42h: 55-byte lookup table.
- 8E44h–8E4Dh: ten-byte lookup accessor ending in RET at 8E4Dh.

The data table and accessor are directly related: the accessor embeds 8E0Dh as its table base.

## 2. Lookup accessor — 8E44h–8E4Dh

Direct near-CALL site: 8894h.

The routine:
- loads SI with 8E0Dh;
- subtracts 80h from AL;
- adds the zero-extended index to SI;
- executes LODSB and returns.

Therefore it returns table[AL-80h]. The table contains 55 entries, covering indices 80h–B6h inclusive.

## 3. Table observations

The 55-byte table at 8E0Dh–8E42h consists of repeated four-byte groups beginning 16h, 17h, 19h, 20h, followed by a group-specific value. The trailing values include 20h, 25h, 33h, 40h, 50h, 66h, 24h, 25h, 33h, 40h. The exact semantic meaning of these mapped values is not established by this accessor alone.

The four bytes at 8E09h–8E0Ch are preserved as an unresolved prefix. They decode as XCHG AH,AL; JMP DI if entered at 8E09h, but no direct near-call or near-branch reference to that entry was found. They are not merged into the table's 55-byte payload.

## 4. Disassembly

```asm
8E44  8D 36 0D 8E       lea si, [8E0D]
8E48  2C 80             sub al, 80
8E4A  03 F0             add si, ax
8E4C  AC                lodsb
8E4D  C3                ret
```

## 5. Generator integration and projected coverage

Add one exact code window at 8E44h with a 0Ah limit. Add a provisional data range at 8E09h–8E43h for the four-byte unresolved prefix and the 55-byte table.

Projected range-mask result:
- Candidate windows: 904
- Data ranges: 250
- Unique code-window bytes: 44,688
- Unique data-range bytes: 20,571
- Code/data overlap: 334 bytes
- Code/data union: 64,925 / 65,536 (99.07%)
- Uncovered intervals: 40
- Pages touched/full: 256 / 256, 223 / 256
- Next largest uncovered interval: 566Bh–56ADh (67 bytes)

These are range-mask projections; the generator and full Capstone candidate listing must be regenerated before these figures are treated as generated results.
