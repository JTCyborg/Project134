# AMI486 semantic disassembly — phase 7

Date: 2026-11-16  
ROM: 64 KiB; SHA-256 `91fd62ce3ccb0b79b42f5fd6c6a7262ed52824b8ade917181b8a12267fec003b`

This phase resolves the meaning of `E187`, decodes the Setup main-menu tables at 342Eh/3446h, and corrects the earlier assumption that the 85D6 memory windows were hardware register windows.

## 1. E187 is the Setup main-menu item index

The code around 3C5E–3E3E establishes that E187 is a menu-item index, not a CPU model or chipset profile identifier.

- 3C78 saves the current `E187` in `E189`; 3C7E saves `E188` in `E18A`.
- 3E24 resets E187 and E188 to zero.
- 3DF9 changes E188 by the caller-supplied AL and changes E187 by a signed step held on the stack.
- If E187 becomes negative, 3E2D resets the pair; if it exceeds 10, 3E24 resets it.
- 3CBB calls 3DF9 with AL=1 and loops until E187 wraps to zero, then restores the saved E187/E188.
- 3CE0 indexes a word table at 342Eh with E187*2 to select the displayed menu label.
- 3D52 indexes a second word table at 3446h with E187*2 to select the corresponding handler address, then calls that handler indirectly.

This is direct evidence that E187 ranges over the 11 entries of the Setup main menu.

## 2. Main menu label and handler tables

The table at 342Eh contains 11 near pointers to menu-label strings. The table at 3446h contains 11 near handler offsets. Pairing the two tables yields:

| E187 | Menu item label | Handler offset |
|---:|---|---:|
| 0 | Standard CMOS Setup for Changing Time, Date, Hard Disk Type, etc. | 00ECh |
| 1 | Advanced CMOS Setup for Configuring ... | 0BDEh |
| 2 | Advanced CHIPSET Setup for Configuring ... | 0C05h |
| 3 | Power Management Setup for Configuring ... | 0C2Ch |
| 4 | Peripheral Management Setup for Configuring ... | 0C53h |
| 5 | Load BIOS Setup Default Values for Advanced CMOS and Advanced CHIPSET Setup | 5A7Ah |
| 6 | Load Power-On Default Values for Advanced CMOS and Advanced CHIPSET Setup | 5A7Ah |
| 7 | Change the User Password stored in the CMOS | F1C8h |
| 8 | Auto Detection of Hard Disk Type | 5038h |
| 9 | Format the Hard Disk, Auto Interleave Detection and Media Analysis | 4628h |
| 10 | Write the settings to the CMOS and Exit | 2F67h |

The full label strings for rows 1–4 continue with “Configuring ...”; the displayed prefix is enough to identify the menu category but should not be expanded without decoding the full string.

The handler mapping is particularly conclusive for E187=4: the fourth zero-based menu item is Peripheral Management Setup and its handler is 0C53h. The routine at 0C53h snapshots the extended setup-record range from 82C6h/82C8h and invokes the setup editor.

## 3. Why 5A5E dispatches by E187

The earlier 5A5E logic is now interpretable as menu-category-specific behavior:

- E187=0 or 1: jump to 85F5, the five-entry built-in prefix at 873Ch.
- E187=2: jump to 85C0, the 76-entry suffix at 8750h.
- E187=3: jump to 85CB, the zero-entry/no-op table.
- E187=4: jump to 85D6, the optional runtime table path.
- E187=5–10: jump to 85CB, the zero-entry/no-op table.

Thus the table-worker dispatch is not selecting a CPU/chipset class. It is keyed to which top-level Setup page/action is active. In particular, E187=4 is the Peripheral Management Setup page, matching the 0C53 handler and the extended setup-record area.

## 4. Corrected interpretation of the 85D6 windows

At 85FE–862F, BX is zero-extended from the entry's byte +0 index. The 16-bit effective offsets are:

- `BX - 1F80h = E080h + index` (modulo 10000h)
- `BX - 2000h = E000h + index` (modulo 10000h)

The routine reads its source byte from DS:E080h+index and updates DS:E000h+index with a masked merge. These are two DS-relative RAM/data windows, **not** direct ALi1429 register addresses.

Independent corroboration exists at 5BB8–5BCF:
- reads a byte at `[SI-1F80h]`;
- writes it at `[SI-2000h]`;
- sets ES=DS;
- copies nine bytes from DS:E080h+CX to ES:E000h+CX.

The setup initialization path at 84CB also sets ES=DS and copies 30h bytes from CS:8210h into ES:E010h before calling 85B3/85D6. This demonstrates that the E000h region is used as a writable working data area. The exact segment value of DS depends on the caller and has not been globally established; therefore the physical linear address should not be asserted from these offsets alone.

The actual ALi1429 register interface is separate: helper 8DCF writes an index to port 22h and reads data from port 23h; helper 8DDC writes the indexed data through the same ports.

## 5. Relationship between Setup menu and the table profiles

The recovered menu semantics align with the built-in table slices:

- Standard CMOS Setup (E187=0) and Advanced CMOS Setup (E187=1) use the five-entry prefix.
- Advanced CHIPSET Setup (E187=2) uses the 76-entry suffix.
- Power Management Setup (E187=3) has no entries in this table worker.
- Peripheral Management Setup (E187=4) uses the optional runtime table supplied through 82B0h/82CAh/82C0h.
- Default-loading, password, disk-detection, disk-format and save/exit actions do not use these table slices in the 5A5E dispatch.

This provides a functional explanation for the dispatch without inventing processor-type semantics.

## 6. Remaining unknowns

1. The actual producer/populator of the optional table pointers 82C0h/82C2h/82B0h/82CAh remains unlocated.
2. The complete label strings for menu entries 1–4 and the exact option names inside the Peripheral Management page still need full record decoding.
3. The runtime source and destination data segment for E000h/E080h should be traced through every caller; only the DS-relative offsets and copy semantics are proven here.
4. Handler 00ECh for Standard CMOS Setup should be examined in its true entry context because a raw near offset at the beginning of the ROM can overlap the reset/vector area.

## Evidence

- `ami486_full_linear_16bit.disasm.txt` (full linear disassembly; offsets 3C5E–3E3E, 5A5E–5AA5, 5BB8–5BCF, 85FE–862F)
- `ami486_config_tables_8400_20261116_01.txt`
- `ami486_pointer_init_85D0_8640_20261116_01.txt`
- `ami486_pointer_init_0C30_0C90_20261116_01.txt`
- `ami486_cmos_table_raw_873C_8888_20261116_01.txt`
- `AMI486_POST_FLOW_20261116_01.md`
