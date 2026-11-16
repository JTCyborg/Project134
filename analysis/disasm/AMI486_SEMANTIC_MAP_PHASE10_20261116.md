# AMI486 semantic disassembly — phase 10

Date: 2026-11-16  
ROM: 64 KiB; SHA-256 `91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b`

This phase follows the Setup main-menu handler pointers into the page handlers and checks the actual page-enable fields in the ROM data.

## 1. Setup page handler map

The menu handler pointer table at 3446h resolves these entries:

| E187 | Menu item | Handler | Record range / behavior |
|---:|---|---:|---|
| 0 | Standard CMOS Setup | 00ECh | Standard CMOS page; alternate stream starts at 00ECh |
| 1 | Advanced CMOS Setup | 0BDEh | [B7D0h, BD54h), if [B7CA] != 0 |
| 2 | Advanced CHIPSET Setup | 0C05h | [BD54h, C5F9h), if [B7CC] != 0 |
| 3 | Power Management Setup | 0C2Ch | [C5F9h, C5F9h), but [B7CE] is zero in the ROM, so handler returns |
| 4 | Peripheral Management Setup | 0C53h | [82C6h, 82C8h), zero-length in the ROM, so handler returns |

The three fixed Setup pages share the editor at 0C7Dh. The handler supplies start/end pointers in E191/E193 and the editor uses the common metadata/state fields E195/E197.

## 2. Page availability fields

ROM bytes at B7C0h–B7CFh:

```
B7C0: 91 2B D3 2B 1D 2C 69 2C
B7C8: CF 2C 84 05 A5 08 00 00
```

Relevant little-endian words:
- `[B7CA] = 0584h` — nonzero, so Advanced CMOS handler 0BDEh proceeds.
- `[B7CC] = 08A5h` — nonzero, so Advanced CHIPSET handler 0C05h proceeds.
- `[B7CE] = 0000h` — zero, so Power Management handler 0C2Ch returns immediately.

These fields are used as boolean presence gates by the handlers. Their nonzero values should not be described as record counts or memory pointers without additional evidence.

## 3. Alternate entry 0BDEh — Advanced CMOS Setup

The full linear decoder starts an instruction at 0BDDh, but the menu dispatch enters at 0BDEh. Decoding from the actual handler entry gives:

```
0BDE  cmp word [B7CA],0
0BE3  jz 0C04
0BE5  mov word [E191],B7D0
0BEB  mov word [E193],BD54
0BF1  mov ax,[8292]
0BF4  mov [E197],ax
0BF7  mov word [E195],B7B2
0BFD  lea bx,[305B]
0C01  call 0C7D
0C04  ret
```

This confirms that the Advanced CMOS page edits the fixed Setup-record range B7D0h–BD53h.

## 4. Handler 0C05h — Advanced CHIPSET Setup

```
0C05  cmp word [B7CC],0
0C0A  jz 0C2B
0C0C  mov word [E191],BD54
0C12  mov word [E193],C5F9
0C18  mov ax,[8292]
0C1B  mov [E197],ax
0C1E  mov word [E195],B7B2
0C24  lea bx,[3071]
0C28  call 0C7D
0C2B  ret
```

This confirms the Advanced CHIPSET page edits [BD54h, C5F9h).

## 5. Handler 0C2Ch — Power Management Setup

```
0C2C  cmp word [B7CE],0
0C31  jz 0C52
0C33  mov word [E191],C5F9
0C39  mov word [E193],C5F9
...
0C4F  call 0C7D
0C52  ret
```

The record range is empty even on the nonzero-gate path. In the stock ROM the gate itself is zero, so the handler exits at 0C31 without entering the editor. This is stronger evidence than the earlier inference from the equal start/end addresses alone.

## 6. Handler 0C53h — Peripheral Management Setup

This handler copies [82C6] and [82C8] into E191/E193 and tests the range span. Phase 8 established both pointer words are zero in the stock ROM, so the span test returns directly at 0C7C. The page is an optional extension point with no active records in the base image.

## 7. Conclusions

- Advanced CMOS and Advanced CHIPSET Setup pages are active and point to distinct fixed record ranges.
- Power Management Setup is present in the menu text but disabled by its zero availability field.
- Peripheral Management Setup has an optional dynamic range but the stock ROM initializes both boundaries to zero.
- The record walkers/editor are shared; each page handler supplies its own range and title/help metadata.
- This explains the distinct page dispatch without attributing the table selector to a CPU or chipset model.

## Evidence

- Full disassembly: alternate entry at 0BDEh and handlers 0C05h, 0C2Ch, 0C53h.
- `ami486_config_table_B7D0_20261116_01.txt`
- `ami486_setup_table_BCD4_20261116_01.txt`
- `ami486_pointer_init_0C30_0C90_20261116_01.txt`
- `ami486_pointer_area_82A0_82FF_20261116_01.txt`
- `AMI486_SEMANTIC_MAP_PHASE7_20261116.md`
- `AMI486_SEMANTIC_MAP_PHASE8_20261116.md`
